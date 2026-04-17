import { Request, Response } from 'express';
import {
  listCatalogo,
  createCatalogo,
  updateCatalogo,
  deleteCatalogo,
} from '../services/catalogo.service';
import { Catalogo } from '../entities/Catalogo';

// ── Helpers ───────────────────────────────────────────────────────────────────

function mapError(message: string): number {
  if (message.includes('já existe') || message.includes('Já existe')) return 409;
  if (message.includes('inválid') || message.includes('obrigatório'))  return 400;
  if (message.includes('não encontrado'))                               return 404;
  return 500;
}

function sendError(res: Response, err: unknown): void {
  const message = err instanceof Error ? err.message : 'Erro interno';
  res.status(mapError(message)).json({ error: message });
}

// ── Handlers ──────────────────────────────────────────────────────────────────

/** GET /api/hotel/:hotel_id/catalogo — público */
export async function listCatalogoController(req: Request, res: Response): Promise<void> {
  try {
    const items = await listCatalogo(req.params.hotel_id);
    res.json({ data: items });
  } catch (err) {
    sendError(res, err);
  }
}

/** POST /api/hotel/catalogo — hotelGuard */
export async function createCatalogoController(req: Request, res: Response): Promise<void> {
  try {
    const input = Catalogo.validate(req.body);
    const item  = await createCatalogo((req as any).hotelId, input);
    res.status(201).json({ data: item });
  } catch (err) {
    sendError(res, err);
  }
}

/** PATCH /api/hotel/catalogo/:id — hotelGuard */
export async function updateCatalogoController(req: Request, res: Response): Promise<void> {
  try {
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) { res.status(400).json({ error: 'ID inválido' }); return; }

    const input = Catalogo.validatePartial(req.body);
    const item  = await updateCatalogo((req as any).hotelId, id, input);
    res.json({ data: item });
  } catch (err) {
    sendError(res, err);
  }
}

/** DELETE /api/hotel/catalogo/:id — hotelGuard */
export async function deleteCatalogoController(req: Request, res: Response): Promise<void> {
  try {
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) { res.status(400).json({ error: 'ID inválido' }); return; }

    await deleteCatalogo((req as any).hotelId, id);
    res.status(204).send();
  } catch (err) {
    sendError(res, err);
  }
}
