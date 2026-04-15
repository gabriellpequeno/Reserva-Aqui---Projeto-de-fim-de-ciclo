import { Request, Response } from 'express';
import {
  listCategoriasQuarto,
  getCategoriaQuarto,
  createCategoriaQuarto,
  updateCategoriaQuarto,
  deleteCategoriaQuarto,
  addItemToCategoria,
  removeItemFromCategoria,
} from '../services/categoriaQuarto.service';
import { CategoriaQuarto } from '../entities/CategoriaQuarto';

// ── Helpers ───────────────────────────────────────────────────────────────────

function mapError(message: string): number {
  if (message.includes('Já existe') || message.includes('já associado')) return 409;
  if (message.includes('possui quartos ativos'))                          return 409;
  if (message.includes('inválid') || message.includes('Nenhum campo'))   return 400;
  if (message.includes('não encontrada') || message.includes('não encontrado')) return 404;
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

// ── Handlers — Categoria ──────────────────────────────────────────────────────

/** GET /api/hotel/:hotel_id/categorias */
export async function listCategoriasController(req: Request, res: Response): Promise<void> {
  try {
    const items = await listCategoriasQuarto(req.params.hotel_id);
    res.json({ data: items });
  } catch (err) {
    sendError(res, err);
  }
}

/** GET /api/hotel/:hotel_id/categorias/:id */
export async function getCategoriaController(req: Request, res: Response): Promise<void> {
  try {
    const id = parseId(req.params.id);
    if (!id) { res.status(400).json({ error: 'ID inválido' }); return; }

    const item = await getCategoriaQuarto(req.params.hotel_id, id);
    res.json({ data: item });
  } catch (err) {
    sendError(res, err);
  }
}

/** POST /api/hotel/categorias */
export async function createCategoriaController(req: Request, res: Response): Promise<void> {
  try {
    const input = CategoriaQuarto.validate(req.body);
    const item  = await createCategoriaQuarto((req as any).hotelId, input);
    res.status(201).json({ data: item });
  } catch (err) {
    sendError(res, err);
  }
}

/** PATCH /api/hotel/categorias/:id */
export async function updateCategoriaController(req: Request, res: Response): Promise<void> {
  try {
    const id = parseId(req.params.id);
    if (!id) { res.status(400).json({ error: 'ID inválido' }); return; }

    const input = CategoriaQuarto.validatePartial(req.body);
    const item  = await updateCategoriaQuarto((req as any).hotelId, id, input);
    res.json({ data: item });
  } catch (err) {
    sendError(res, err);
  }
}

/** DELETE /api/hotel/categorias/:id */
export async function deleteCategoriaController(req: Request, res: Response): Promise<void> {
  try {
    const id = parseId(req.params.id);
    if (!id) { res.status(400).json({ error: 'ID inválido' }); return; }

    await deleteCategoriaQuarto((req as any).hotelId, id);
    res.status(204).send();
  } catch (err) {
    sendError(res, err);
  }
}

// ── Handlers — Itens da Categoria ─────────────────────────────────────────────

/** POST /api/hotel/categorias/:id/itens */
export async function addItemCategoriaController(req: Request, res: Response): Promise<void> {
  try {
    const id = parseId(req.params.id);
    if (!id) { res.status(400).json({ error: 'ID inválido' }); return; }

    const input = CategoriaQuarto.validateItem(req.body);
    const item  = await addItemToCategoria((req as any).hotelId, id, input);
    res.status(201).json({ data: item });
  } catch (err) {
    sendError(res, err);
  }
}

/** DELETE /api/hotel/categorias/:id/itens/:catalogo_id */
export async function removeItemCategoriaController(req: Request, res: Response): Promise<void> {
  try {
    const id         = parseId(req.params.id);
    const catalogoId = parseId(req.params.catalogo_id);
    if (!id || !catalogoId) { res.status(400).json({ error: 'ID inválido' }); return; }

    await removeItemFromCategoria((req as any).hotelId, id, catalogoId);
    res.status(204).send();
  } catch (err) {
    sendError(res, err);
  }
}
