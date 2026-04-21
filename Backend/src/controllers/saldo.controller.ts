import { Response } from 'express';
import { HotelRequest } from '../middlewares/hotelGuard';
import { getSaldo, sacarSaldo } from '../services/saldo.service';

function mapError(message: string): number {
  if (message.includes('insuficiente'))   return 400;
  if (message.includes('não encontrado')) return 404;
  return 500;
}

function sendError(res: Response, err: unknown): void {
  const message = err instanceof Error ? err.message : 'Erro interno';
  res.status(mapError(message)).json({ error: message });
}

/** GET /api/hotel/saldo */
export async function getSaldoController(req: HotelRequest, res: Response): Promise<void> {
  try {
    const data = await getSaldo(req.hotelId!);
    res.json({ data });
  } catch (err) {
    sendError(res, err);
  }
}

/** POST /api/hotel/saldo/saque */
export async function sacarSaldoController(req: HotelRequest, res: Response): Promise<void> {
  try {
    const result = await sacarSaldo(req.hotelId!);
    res.status(201).json({ data: result });
  } catch (err) {
    sendError(res, err);
  }
}
