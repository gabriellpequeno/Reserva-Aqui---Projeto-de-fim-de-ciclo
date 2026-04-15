import { Response } from 'express';
import { HotelRequest } from '../middlewares/hotelGuard';
import {
  listNotificacoes,
  marcarLida,
  marcarTodasLidas,
} from '../services/notificacaoHotel.service';

function mapError(message: string): number {
  if (message.includes('não encontrad')) return 404;
  return 500;
}

export async function listNotificacoesController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const apenasNaoLidas = req.query.nao_lidas === 'true';
    const result = await listNotificacoes(req.hotelId!, apenasNaoLidas);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function marcarLidaController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      res.status(400).json({ error: 'ID de notificação inválido' });
      return;
    }
    const result = await marcarLida(req.hotelId!, id);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function marcarTodasLidasController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    await marcarTodasLidas(req.hotelId!);
    res.status(204).send();
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(500).json({ error: message });
  }
}
