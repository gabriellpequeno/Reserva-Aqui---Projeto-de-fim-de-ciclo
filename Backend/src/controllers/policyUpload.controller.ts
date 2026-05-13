import { Request, Response } from 'express';
import path from 'path';
import fs from 'fs';
import { v4 as uuidv4 } from 'uuid';
import { GoogleGenerativeAIEmbeddings } from '@langchain/google-genai';
import { HotelRequest } from '../middlewares/hotelGuard';
import {
  buildHotelPolicyPath,
  deleteFile,
  moveFile,
  toRelativePath,
} from '../services/storage.service';
import { masterPool } from '../database/masterDb';

// ── Helpers ───────────────────────────────────────────────────────────────────

function isPdfMagicBytes(filePath: string): boolean {
  const buffer = Buffer.alloc(5);
  const fd = fs.openSync(filePath, 'r');
  fs.readSync(fd, buffer, 0, 5, 0);
  fs.closeSync(fd);
  return buffer.toString('ascii') === '%PDF-';
}

/**
 * Divide o texto em chunks de até `maxChars` caracteres respeitando
 * quebras de parágrafo. Retorna array vazio se o conteúdo for vazio.
 */
function chunkText(text: string, maxChars = 800): string[] {
  // Normaliza Markdown: garante dupla quebra antes de headers e itens de lista,
  // para que cada seção vire um chunk semântico independente.
  const normalized = text
    .replace(/\r\n/g, '\n')
    .replace(/\n(#{1,6}\s)/g, '\n\n$1')       // # Headers
    .replace(/\n([-*]\s)/g, '\n\n$1')          // - * listas
    .replace(/\n(\d+\.\s)/g, '\n\n$1');        // 1. listas numeradas

  const paragraphs = normalized
    .split(/\n{2,}/)
    .map((p) => p.trim())
    .filter((p) => p.length > 0);

  const chunks: string[] = [];
  let current = '';

  for (const para of paragraphs) {
    if (current.length + para.length + 2 > maxChars && current.length > 0) {
      chunks.push(current);
      current = para;
    } else {
      current = current ? `${current}\n\n${para}` : para;
    }
  }
  if (current) chunks.push(current);
  return chunks;
}

/**
 * Lê o conteúdo textual do arquivo (apenas .txt e .md),
 * gera embeddings via Gemini e faz upsert em documento_hotel.
 * Falha silenciosa: erro de indexação não cancela o upload.
 */
async function ingestPolicyToRag(
  hotelId: string,
  filePath: string,
  ext: string,
  nomeArquivo: string,
): Promise<{ chunks: number } | null> {
  if (!['.txt', '.md'].includes(ext)) return null;

  const apiKey = process.env.GEMINI_API_KEY?.split(',')[0]?.trim();
  if (!apiKey) {
    console.warn('[ingestPolicyToRag] GEMINI_API_KEY não configurada. Pulando indexação RAG.');
    return null;
  }

  const content = fs.readFileSync(filePath, 'utf-8');
  const chunks = chunkText(content);
  if (chunks.length === 0) return null;

  const embeddings = new GoogleGenerativeAIEmbeddings({
    apiKey,
    model: 'gemini-embedding-001',
  });

  const vectors = await embeddings.embedDocuments(chunks);

  // Remove chunks antigos da política deste hotel antes de inserir os novos
  await masterPool.query(
    `DELETE FROM documento_hotel WHERE hotel_id = $1 AND metadata->>'source' = 'politica'`,
    [hotelId],
  );

  for (let i = 0; i < chunks.length; i++) {
    const vectorStr = `[${vectors[i].join(',')}]`;
    await masterPool.query(
      `INSERT INTO documento_hotel (hotel_id, content, embedding, metadata)
       VALUES ($1, $2, $3::vector, $4)`,
      [
        hotelId,
        chunks[i],
        vectorStr,
        JSON.stringify({ source: 'politica', arquivo: nomeArquivo, chunk: i }),
      ],
    );
  }

  return { chunks: chunks.length };
}

// ── Endpoints ─────────────────────────────────────────────────────────────────

/**
 * POST /api/v1/uploads/hotels/:hotel_id/policy
 * Body: multipart/form-data — campo "policy" (PDF, TXT ou MD, máx 5 MB)
 * Autorização: anfitrião dono do hotel_id
 */
export async function uploadHotelPolicy(req: HotelRequest, res: Response): Promise<void> {
  const file = (req as Request & { file?: Express.Multer.File }).file;

  if (!file) {
    res.status(400).json({ error: 'Nenhum arquivo enviado' });
    return;
  }

  const { hotel_id } = req.params;

  // Multer já normaliza originalname com path.basename(). Garantimos aqui
  // que o nome não tem null bytes e extraímos apenas o basename para exibição.
  const displayName = path.basename(file.originalname);
  if (!displayName || displayName.includes('\0')) {
    fs.unlinkSync(file.path);
    res.status(422).json({ error: 'Nome de arquivo inválido' });
    return;
  }

  const ext = path.extname(displayName).toLowerCase();

  // Valida magic bytes para PDF
  if (ext === '.pdf' && !isPdfMagicBytes(file.path)) {
    fs.unlinkSync(file.path);
    res.status(422).json({ error: 'Arquivo PDF inválido ou corrompido' });
    return;
  }

  try {
    // Verifica ownership
    const hotelCheck = await masterPool.query(
      'SELECT hotel_id FROM anfitriao WHERE hotel_id = $1 AND email = $2 AND ativo = TRUE',
      [hotel_id, req.hotelEmail],
    );
    if (hotelCheck.rowCount === 0) {
      fs.unlinkSync(file.path);
      res.status(403).json({ error: 'Acesso negado' });
      return;
    }

    // Remove arquivo anterior do disco
    const existing = await masterPool.query(
      'SELECT storage_path FROM documento_politica_hotel WHERE hotel_id = $1',
      [hotel_id],
    );
    if (existing.rowCount && existing.rows[0].storage_path) {
      deleteFile(existing.rows[0].storage_path);
    }

    // Move para destino final
    const fileId = uuidv4();
    const dest = buildHotelPolicyPath(hotel_id, fileId, ext);
    moveFile(file.path, dest);

    const storagePath = toRelativePath(dest);

    const upserted = await masterPool.query(
      `INSERT INTO documento_politica_hotel (hotel_id, storage_path, mime_type, nome_arquivo)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (hotel_id) DO UPDATE
         SET storage_path  = EXCLUDED.storage_path,
             mime_type     = EXCLUDED.mime_type,
             nome_arquivo  = EXCLUDED.nome_arquivo,
             atualizado_em = now()
       RETURNING id, storage_path, mime_type, nome_arquivo, atualizado_em`,
      [hotel_id, storagePath, file.mimetype, displayName],
    );

    // Indexa conteúdo no RAG (falha silenciosa: não cancela o upload)
    let ragResult: { chunks: number } | null = null;
    try {
      ragResult = await ingestPolicyToRag(hotel_id, dest, ext, displayName);
    } catch (ragErr) {
      console.error('[uploadHotelPolicy] Falha na indexação RAG (upload salvo com sucesso):', ragErr);
    }

    res.status(201).json({
      message: 'Política do hotel enviada com sucesso',
      policy: upserted.rows[0],
      rag: ragResult
        ? { indexado: true, chunks: ragResult.chunks }
        : { indexado: false, motivo: ext === '.pdf' ? 'PDF não suportado para indexação automática' : 'Falha na indexação' },
    });
  } catch (err) {
    try { fs.unlinkSync(file.path); } catch { /* já removido ou movido */ }
    console.error('[uploadHotelPolicy]', err);
    res.status(500).json({ error: 'Erro interno ao processar o arquivo' });
  }
}

/**
 * GET /api/v1/uploads/hotels/:hotel_id/policy
 * Retorna metadados da política atual + status de indexação RAG.
 */
export async function getHotelPolicy(req: HotelRequest, res: Response): Promise<void> {
  const { hotel_id } = req.params;

  try {
    const hotelCheck = await masterPool.query(
      'SELECT hotel_id FROM anfitriao WHERE hotel_id = $1 AND email = $2 AND ativo = TRUE',
      [hotel_id, req.hotelEmail],
    );
    if (hotelCheck.rowCount === 0) {
      res.status(403).json({ error: 'Acesso negado' });
      return;
    }

    const [policyResult, ragResult] = await Promise.all([
      masterPool.query(
        'SELECT nome_arquivo, atualizado_em FROM documento_politica_hotel WHERE hotel_id = $1',
        [hotel_id],
      ),
      masterPool.query(
        `SELECT COUNT(*) AS chunks FROM documento_hotel
         WHERE hotel_id = $1 AND metadata->>'source' = 'politica'`,
        [hotel_id],
      ),
    ]);

    res.status(200).json({
      policy: policyResult.rows[0] ?? null,
      rag: {
        indexado: parseInt(ragResult.rows[0].chunks, 10) > 0,
        chunks: parseInt(ragResult.rows[0].chunks, 10),
      },
    });
  } catch (err) {
    console.error('[getHotelPolicy]', err);
    res.status(500).json({ error: 'Erro interno ao buscar política' });
  }
}
