import { Request, Response } from 'express';
import { listFavoritos, addFavorito, removeFavorito } from '../services/favorito.service';
import { HotelFavorito } from '../entities/HotelFavorito';

// ── Helpers ───────────────────────────────────────────────────────────────────

function mapError(message: string): number {
  if (message.includes('já favoritado'))   return 409;
  if (message.includes('inválido'))        return 400;
  if (message.includes('não encontrado'))  return 404;
  return 500;
}

function sendError(res: Response, err: unknown): void {
  const message = err instanceof Error ? err.message : 'Erro interno';
  res.status(mapError(message)).json({ error: message });
}

// ── Handlers ──────────────────────────────────────────────────────────────────

/** GET /api/usuarios/favoritos */
export async function listFavoritosController(req: Request, res: Response): Promise<void> {
  try {
    const items = await listFavoritos((req as any).userId);
    res.json({ data: items });
  } catch (err) {
    sendError(res, err);
  }
}

/** POST /api/usuarios/favoritos — body: { hotel_id } */
export async function addFavoritoController(req: Request, res: Response): Promise<void> {
  try {
    const { hotel_id } = HotelFavorito.validate(req.body);
    const item = await addFavorito((req as any).userId, hotel_id);
    res.status(201).json({ data: item });
  } catch (err) {
    sendError(res, err);
  }
}

/** DELETE /api/usuarios/favoritos/:hotel_id */
export async function removeFavoritoController(req: Request, res: Response): Promise<void> {
  try {
    const hotelId = HotelFavorito.validateId(req.params.hotel_id);
    await removeFavorito((req as any).userId, hotelId);
    res.status(204).send();
  } catch (err) {
    sendError(res, err);
  }
}
