import { Request, Response } from 'express';
import {
  getConfiguracaoHotel,
  createConfiguracaoHotel,
  updateConfiguracaoHotel,
} from '../services/configuracao.service';
import { ConfiguracaoHotel } from '../entities/ConfiguracaoHotel';

// ── Helpers ───────────────────────────────────────────────────────────────────

function mapError(message: string): number {
  if (message.includes('já existe'))       return 409;
  if (message.includes('inválid') || message.includes('Nenhum campo')) return 400;
  if (message.includes('não encontrada') || message.includes('não encontrado')) return 404;
  return 500;
}

function sendError(res: Response, err: unknown): void {
  const message = err instanceof Error ? err.message : 'Erro interno';
  res.status(mapError(message)).json({ error: message });
}

// ── Handlers ──────────────────────────────────────────────────────────────────

/** GET /api/hotel/:hotel_id/configuracao — público */
export async function getConfiguracaoHotelController(req: Request, res: Response): Promise<void> {
  try {
    const config = await getConfiguracaoHotel(req.params.hotel_id);
    res.json({ data: config });
  } catch (err) {
    sendError(res, err);
  }
}

/** POST /api/hotel/configuracao — hotelGuard */
export async function createConfiguracaoHotelController(req: Request, res: Response): Promise<void> {
  try {
    const input  = ConfiguracaoHotel.validate(req.body);
    const config = await createConfiguracaoHotel((req as any).hotelId, input);
    res.status(201).json({ data: config });
  } catch (err) {
    sendError(res, err);
  }
}

/** PATCH /api/hotel/configuracao — hotelGuard */
export async function updateConfiguracaoHotelController(req: Request, res: Response): Promise<void> {
  try {
    const input  = ConfiguracaoHotel.validatePartial(req.body);
    const config = await updateConfiguracaoHotel((req as any).hotelId, input);
    res.json({ data: config });
  } catch (err) {
    sendError(res, err);
  }
}
