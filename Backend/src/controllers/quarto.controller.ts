import { Request, Response } from 'express';
import {
  listQuartos,
  getQuarto,
  createQuarto,
  updateQuarto,
  deleteQuarto,
} from '../services/quarto.service';
import { Quarto } from '../entities/Quarto';

// ── Helpers ───────────────────────────────────────────────────────────────────

function mapError(message: string): number {
  if (message.includes('Já existe'))                                       return 409;
  if (message.includes('inválid') || message.includes('Nenhum campo'))    return 400;
  if (message.includes('não encontrad') || message.includes('inativos'))  return 404;
  return 500;
}

function sendError(res: Response, err: unknown): void {
  const message = err instanceof Error ? err.message : 'Erro interno';
  res.status(mapError(message)).json({ error: message });
}

function parseId(raw: string): number | null {
  const id = parseInt(raw, 10);
  return isNaN(id) ? null : id;
}

// ── Handlers ──────────────────────────────────────────────────────────────────

/** GET /api/hotel/quartos */
export async function listQuartosController(req: Request, res: Response): Promise<void> {
  try {
    const items = await listQuartos((req as any).hotelId);
    res.json({ data: items });
  } catch (err) {
    sendError(res, err);
  }
}

/** GET /api/hotel/quartos/:id */
export async function getQuartoController(req: Request, res: Response): Promise<void> {
  try {
    const id = parseId(req.params.id);
    if (!id) { res.status(400).json({ error: 'ID inválido' }); return; }

    const item = await getQuarto((req as any).hotelId, id);
    res.json({ data: item });
  } catch (err) {
    sendError(res, err);
  }
}

/** POST /api/hotel/quartos */
export async function createQuartoController(req: Request, res: Response): Promise<void> {
  try {
    const input = Quarto.validate(req.body);
    const item  = await createQuarto((req as any).hotelId, input);
    res.status(201).json({ data: item });
  } catch (err) {
    sendError(res, err);
  }
}

/** PATCH /api/hotel/quartos/:id */
export async function updateQuartoController(req: Request, res: Response): Promise<void> {
  try {
    const id = parseId(req.params.id);
    if (!id) { res.status(400).json({ error: 'ID inválido' }); return; }

    const input = Quarto.validatePartial(req.body);
    const item  = await updateQuarto((req as any).hotelId, id, input);
    res.json({ data: item });
  } catch (err) {
    sendError(res, err);
  }
}

/** DELETE /api/hotel/quartos/:id */
export async function deleteQuartoController(req: Request, res: Response): Promise<void> {
  try {
    const id = parseId(req.params.id);
    if (!id) { res.status(400).json({ error: 'ID inválido' }); return; }

    await deleteQuarto((req as any).hotelId, id);
    res.status(204).send();
  } catch (err) {
    sendError(res, err);
  }
}
