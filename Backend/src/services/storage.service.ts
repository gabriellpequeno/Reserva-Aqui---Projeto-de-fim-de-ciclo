import fs from 'fs';
import path from 'path';
import { Response } from 'express';

/**
 * Raiz absoluta do diretório de armazenamento.
 * Fica fora do diretório public/ — nunca exposto diretamente.
 */
export const UPLOAD_DIR = path.resolve(
  process.env.UPLOAD_DIR || path.join(__dirname, '../../storage')
);

/**
 * Garante que um diretório existe, criando-o recursivamente se necessário.
 */
export function ensureDir(dirPath: string): void {
  fs.mkdirSync(dirPath, { recursive: true });
}

/**
 * Move um arquivo do diretório temporário do multer para o destino final.
 * Cria o diretório de destino se não existir.
 */
export function moveFile(tempPath: string, destPath: string): void {
  ensureDir(path.dirname(destPath));
  fs.renameSync(tempPath, destPath);
}

/**
 * Deleta um arquivo pelo seu storage path relativo à UPLOAD_DIR.
 * Falha silenciosa se o arquivo não existir (ignoreNotFound).
 */
export function deleteFile(storagePath: string): void {
  const absolutePath = resolveSafe(storagePath);
  if (!absolutePath) return;

  try {
    fs.unlinkSync(absolutePath);
  } catch {
    // Arquivo já não existe — sem problema
  }
}

/**
 * Faz stream de um arquivo para a Response do Express.
 * Retorna false se o arquivo não existir ou o path for inválido.
 */
export function streamFile(storagePath: string, res: Response): boolean {
  const absolutePath = resolveSafe(storagePath);
  if (!absolutePath || !fs.existsSync(absolutePath)) return false;

  res.sendFile(absolutePath);
  return true;
}

/**
 * Constrói o path absoluto final de uma foto de capa do hotel.
 * Pattern: {UPLOAD_DIR}/hotels/{hotel_id}/cover/{orientacao}/{uuid}.{ext}
 */
export function buildHotelCoverPath(
  hotelId: string,
  orientacao: 'portrait' | 'landscape',
  fileId: string,
  ext: string
): string {
  return path.join(UPLOAD_DIR, 'hotels', hotelId, 'cover', orientacao, `${fileId}${ext}`);
}

/**
 * Constrói o path absoluto final de uma foto de quarto.
 * Pattern: {UPLOAD_DIR}/hotels/{hotel_id}/rooms/{quarto_id}/{uuid}.{ext}
 * Quartos não usam orientação — 10 fotos no total independente de dispositivo.
 */
export function buildRoomPhotoPath(
  hotelId: string,
  quartoId: string,
  fileId: string,
  ext: string
): string {
  return path.join(UPLOAD_DIR, 'hotels', hotelId, 'rooms', quartoId, `${fileId}${ext}`);
}

/**
 * Resolve um storage path relativo para absoluto, validando que o resultado
 * fica dentro de UPLOAD_DIR (previne path traversal).
 * Retorna null se o path tentar escapar do diretório raiz.
 */
export function resolveSafe(storagePath: string): string | null {
  const absolute = path.resolve(UPLOAD_DIR, storagePath);
  if (!absolute.startsWith(UPLOAD_DIR + path.sep) && absolute !== UPLOAD_DIR) {
    return null;
  }
  return absolute;
}

/**
 * Retorna o path relativo à UPLOAD_DIR a partir de um path absoluto.
 * Usado para salvar no banco de dados.
 */
export function toRelativePath(absolutePath: string): string {
  return path.relative(UPLOAD_DIR, absolutePath);
}
