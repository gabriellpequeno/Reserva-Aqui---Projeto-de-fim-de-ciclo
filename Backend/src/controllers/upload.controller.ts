import { Request, Response } from 'express';
import path from 'path';
import fs from 'fs';
import { v4 as uuidv4 } from 'uuid';
import { AuthRequest } from '../middlewares/authGuard';
import {
  buildHotelCoverPath,
  buildRoomPhotoPath,
  deleteFile,
  moveFile,
  streamFile,
  toRelativePath,
} from '../services/storage.service';
import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';

// ── Limites configuráveis via ENV ─────────────────────────────────────────────
const MAX_HOTEL_COVER = parseInt(process.env.UPLOAD_MAX_HOTEL_COVER || '5', 10);
const MAX_ROOM_PHOTOS = parseInt(process.env.UPLOAD_MAX_ROOM_PHOTOS || '10', 10);

type Orientacao = 'portrait' | 'landscape';

function isValidOrientacao(value: unknown): value is Orientacao {
  return value === 'portrait' || value === 'landscape';
}

/**
 * Valida o tipo real do arquivo via magic bytes (primeiros 12 bytes).
 * Protege contra ataques de MIME confusion onde o cliente declara um tipo falso.
 */
async function validateMagicBytes(filePath: string): Promise<boolean> {
  const buffer = Buffer.alloc(12);
  const fd = fs.openSync(filePath, 'r');
  fs.readSync(fd, buffer, 0, 12, 0);
  fs.closeSync(fd);

  const jpegMagic = buffer.slice(0, 3).equals(Buffer.from([0xff, 0xd8, 0xff]));
  const pngMagic  = buffer.slice(0, 4).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47]));
  const webpRiff  = buffer.slice(0, 4).toString('ascii') === 'RIFF';
  const webpMark  = buffer.slice(8, 12).toString('ascii') === 'WEBP';

  return jpegMagic || pngMagic || (webpRiff && webpMark);
}

// ─────────────────────────────────────────────────────────────────────────────
// HOTEL COVER PHOTOS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * POST /api/uploads/hotels/:hotel_id/cover
 * Body: multipart/form-data — campo "foto" + campo "orientacao" (portrait|landscape)
 * Autorização: anfitriao dono do hotel_id
 */
export async function uploadHotelCover(req: AuthRequest, res: Response): Promise<void> {
  const file = (req as Request & { file?: Express.Multer.File }).file;

  if (!file) {
    res.status(400).json({ error: 'Nenhuma imagem enviada' });
    return;
  }

  const { hotel_id } = req.params;
  const orientacao = req.body.orientacao as string;

  if (!isValidOrientacao(orientacao)) {
    fs.unlinkSync(file.path);
    res.status(400).json({ error: 'Campo "orientacao" deve ser "portrait" ou "landscape"' });
    return;
  }

  const isValid = await validateMagicBytes(file.path);
  if (!isValid) {
    fs.unlinkSync(file.path);
    res.status(422).json({ error: 'Arquivo inválido — conteúdo não é uma imagem reconhecida' });
    return;
  }

  // Verifica que o anfitrião é dono do hotel
  const hotelCheck = await masterPool.query(
    'SELECT hotel_id FROM anfitriao WHERE hotel_id = $1 AND email = $2 AND ativo = TRUE',
    [hotel_id, req.userEmail]
  );
  if (hotelCheck.rowCount === 0) {
    fs.unlinkSync(file.path);
    res.status(403).json({ error: 'Acesso negado — hotel não pertence ao anfitrião autenticado' });
    return;
  }

  // Verifica limite de fotos por orientação
  const countResult = await masterPool.query(
    'SELECT COUNT(*) FROM foto_hotel WHERE hotel_id = $1 AND orientacao = $2',
    [hotel_id, orientacao]
  );
  if (parseInt(countResult.rows[0].count, 10) >= MAX_HOTEL_COVER) {
    fs.unlinkSync(file.path);
    res.status(422).json({
      error: `Limite atingido: máximo de ${MAX_HOTEL_COVER} fotos ${orientacao} por hotel`,
    });
    return;
  }

  // Move para destino final
  const fileId = uuidv4();
  const ext    = path.extname(file.originalname).toLowerCase();
  const dest   = buildHotelCoverPath(hotel_id, orientacao, fileId, ext);

  moveFile(file.path, dest);

  const storagePath = toRelativePath(dest);

  const inserted = await masterPool.query(
    `INSERT INTO foto_hotel (hotel_id, storage_path, orientacao)
     VALUES ($1, $2, $3)
     RETURNING id, storage_path, orientacao, criado_em`,
    [hotel_id, storagePath, orientacao]
  );

  res.status(201).json({
    message: 'Foto de capa enviada com sucesso',
    foto: inserted.rows[0],
  });
}

/**
 * DELETE /api/uploads/hotels/:hotel_id/cover/:foto_id
 * Remove uma foto de capa específica do hotel.
 */
export async function deleteHotelCover(req: AuthRequest, res: Response): Promise<void> {
  const { hotel_id, foto_id } = req.params;

  const hotelCheck = await masterPool.query(
    'SELECT hotel_id FROM anfitriao WHERE hotel_id = $1 AND email = $2 AND ativo = TRUE',
    [hotel_id, req.userEmail]
  );
  if (hotelCheck.rowCount === 0) {
    res.status(403).json({ error: 'Acesso negado' });
    return;
  }

  const fotoResult = await masterPool.query(
    'DELETE FROM foto_hotel WHERE id = $1 AND hotel_id = $2 RETURNING storage_path',
    [foto_id, hotel_id]
  );

  if (fotoResult.rowCount === 0) {
    res.status(404).json({ error: 'Foto não encontrada' });
    return;
  }

  deleteFile(fotoResult.rows[0].storage_path);
  res.status(200).json({ message: 'Foto removida com sucesso' });
}

/**
 * GET /api/uploads/hotels/:hotel_id/cover/:foto_id
 * Serve uma foto de capa. Público-read (sem autenticação).
 */
export async function serveHotelCover(req: Request, res: Response): Promise<void> {
  const { hotel_id, foto_id } = req.params;

  const result = await masterPool.query(
    'SELECT storage_path FROM foto_hotel WHERE id = $1 AND hotel_id = $2',
    [foto_id, hotel_id]
  );

  if (result.rowCount === 0) {
    res.status(404).json({ error: 'Foto não encontrada' });
    return;
  }

  const served = streamFile(result.rows[0].storage_path, res);
  if (!served) {
    res.status(404).json({ error: 'Arquivo não encontrado no servidor' });
  }
}

/**
 * GET /api/uploads/hotels/:hotel_id/cover?orientacao=portrait
 * Lista metadados de todas as fotos de capa. Público-read.
 */
export async function listHotelCovers(req: Request, res: Response): Promise<void> {
  const { hotel_id } = req.params;
  const { orientacao } = req.query;

  let query = `
    SELECT id, orientacao, criado_em
    FROM foto_hotel
    WHERE hotel_id = $1
  `;
  const params: unknown[] = [hotel_id];

  if (orientacao && isValidOrientacao(orientacao as string)) {
    query += ' AND orientacao = $2';
    params.push(orientacao);
  }

  query += ' ORDER BY criado_em ASC';

  const result = await masterPool.query(query, params);

  const fotos = result.rows.map((row) => ({
    ...row,
    url: `/api/uploads/hotels/${hotel_id}/cover/${row.id}`,
  }));

  res.status(200).json({ fotos });
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOM PHOTOS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * POST /api/uploads/hotels/:hotel_id/rooms/:quarto_id
 * Body: multipart/form-data — campo "foto" + campo "orientacao" (portrait|landscape)
 */
export async function uploadRoomPhoto(req: AuthRequest, res: Response): Promise<void> {
  const file = (req as Request & { file?: Express.Multer.File }).file;

  if (!file) {
    res.status(400).json({ error: 'Nenhuma imagem enviada' });
    return;
  }

  const { hotel_id, quarto_id } = req.params;

  const isValid = await validateMagicBytes(file.path);
  if (!isValid) {
    fs.unlinkSync(file.path);
    res.status(422).json({ error: 'Arquivo inválido — conteúdo não é uma imagem reconhecida' });
    return;
  }

  // Verifica ownership do hotel e recupera o schema do tenant
  const hotelCheck = await masterPool.query(
    'SELECT schema_name FROM anfitriao WHERE hotel_id = $1 AND email = $2 AND ativo = TRUE',
    [hotel_id, req.userEmail]
  );
  if (hotelCheck.rowCount === 0) {
    fs.unlinkSync(file.path);
    res.status(403).json({ error: 'Acesso negado — hotel não pertence ao anfitrião autenticado' });
    return;
  }

  const schemaName = hotelCheck.rows[0].schema_name;

  await withTenant(schemaName, async (client) => {
    // Verifica que o quarto existe no tenant
    const quartoCheck = await client.query(
      'SELECT id FROM quarto WHERE id = $1 AND deleted_at IS NULL',
      [quarto_id]
    );
    if (quartoCheck.rowCount === 0) {
      fs.unlinkSync(file.path);
      res.status(404).json({ error: 'Quarto não encontrado' });
      return;
    }

    // Verifica limite total de fotos do quarto (sem distincão de orientação)
    const countResult = await client.query(
      'SELECT COUNT(*) FROM quarto_foto WHERE quarto_id = $1',
      [quarto_id]
    );
    if (parseInt(countResult.rows[0].count, 10) >= MAX_ROOM_PHOTOS) {
      fs.unlinkSync(file.path);
      res.status(422).json({
        error: `Limite atingido: máximo de ${MAX_ROOM_PHOTOS} fotos por quarto`,
      });
      return;
    }

    // Move para destino final
    const fileId = uuidv4();
    const ext    = path.extname(file.originalname).toLowerCase();
    const dest   = buildRoomPhotoPath(hotel_id, quarto_id, fileId, ext);

    moveFile(file.path, dest);

    const storagePath = toRelativePath(dest);

    const inserted = await client.query(
      `INSERT INTO quarto_foto (quarto_id, storage_path)
       VALUES ($1, $2)
       RETURNING id, storage_path, ordem, criado_em`,
      [quarto_id, storagePath]
    );

    res.status(201).json({
      message: 'Foto do quarto enviada com sucesso',
      foto: inserted.rows[0],
    });
  });
}

/**
 * DELETE /api/uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id
 */
export async function deleteRoomPhoto(req: AuthRequest, res: Response): Promise<void> {
  const { hotel_id, quarto_id, foto_id } = req.params;

  const hotelCheck = await masterPool.query(
    'SELECT schema_name FROM anfitriao WHERE hotel_id = $1 AND email = $2 AND ativo = TRUE',
    [hotel_id, req.userEmail]
  );
  if (hotelCheck.rowCount === 0) {
    res.status(403).json({ error: 'Acesso negado' });
    return;
  }

  const schemaName = hotelCheck.rows[0].schema_name;

  await withTenant(schemaName, async (client) => {
    const fotoResult = await client.query(
      'DELETE FROM quarto_foto WHERE id = $1 AND quarto_id = $2 RETURNING storage_path',
      [foto_id, quarto_id]
    );

    if (fotoResult.rowCount === 0) {
      res.status(404).json({ error: 'Foto não encontrada' });
      return;
    }

    deleteFile(fotoResult.rows[0].storage_path);
    res.status(200).json({ message: 'Foto removida com sucesso' });
  });
}

/**
 * GET /api/uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id
 * Serve uma foto de quarto. Público-read.
 */
export async function serveRoomPhoto(req: Request, res: Response): Promise<void> {
  const { hotel_id, quarto_id, foto_id } = req.params;

  const hotelResult = await masterPool.query(
    'SELECT schema_name FROM anfitriao WHERE hotel_id = $1',
    [hotel_id]
  );
  if (hotelResult.rowCount === 0) {
    res.status(404).json({ error: 'Hotel não encontrado' });
    return;
  }

  const schemaName = hotelResult.rows[0].schema_name;

  await withTenant(schemaName, async (client) => {
    const result = await client.query(
      'SELECT storage_path FROM quarto_foto WHERE id = $1 AND quarto_id = $2',
      [foto_id, quarto_id]
    );

    if (result.rowCount === 0) {
      res.status(404).json({ error: 'Foto não encontrada' });
      return;
    }

    const served = streamFile(result.rows[0].storage_path, res);
    if (!served) {
      res.status(404).json({ error: 'Arquivo não encontrado no servidor' });
    }
  });
}

/**
 * GET /api/uploads/hotels/:hotel_id/rooms/:quarto_id?orientacao=landscape
 * Lista metadados das fotos do quarto, filtráveis por orientação. Público-read.
 */
export async function listRoomPhotos(req: Request, res: Response): Promise<void> {
  const { hotel_id, quarto_id } = req.params;

  const hotelResult = await masterPool.query(
    'SELECT schema_name FROM anfitriao WHERE hotel_id = $1',
    [hotel_id]
  );
  if (hotelResult.rowCount === 0) {
    res.status(404).json({ error: 'Hotel não encontrado' });
    return;
  }

  const schemaName = hotelResult.rows[0].schema_name;

  await withTenant(schemaName, async (client) => {
    const result = await client.query(
      `SELECT id, ordem, criado_em
       FROM quarto_foto
       WHERE quarto_id = $1
       ORDER BY ordem ASC, criado_em ASC`,
      [quarto_id]
    );

    const fotos = result.rows.map((row) => ({
      ...row,
      url: `/api/uploads/hotels/${hotel_id}/rooms/${quarto_id}/${row.id}`,
    }));

    res.status(200).json({ fotos });
  });
}
