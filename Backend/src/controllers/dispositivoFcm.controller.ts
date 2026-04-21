import { Response } from 'express';
import { AuthRequest }  from '../middlewares/authGuard';
import { HotelRequest } from '../middlewares/hotelGuard';
import {
  registerUserToken,
  registerHotelToken,
  removeToken,
} from '../services/dispositivoFcm.service';
import { DispositivoFcm } from '../entities/DispositivoFcm';

function mapError(message: string): number {
  if (message.includes('obrigatório') || message.includes('inválid')) return 400;
  return 500;
}

/**
 * Registra token FCM para usuário hóspede.
 * Chamado pelo app Flutter após login do usuário.
 */
export async function registerUserTokenController(
  req: AuthRequest,
  res: Response,
): Promise<void> {
  try {
    const input = DispositivoFcm.validate(req.body);
    await registerUserToken(req.userId!, input);
    res.status(204).send();
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

/**
 * Registra token FCM para hotel anfitrião.
 * Chamado pelo dashboard web após login do hotel.
 */
export async function registerHotelTokenController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const input = DispositivoFcm.validate(req.body);
    await registerHotelToken(req.hotelId!, input);
    res.status(204).send();
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

/**
 * Remove token FCM (logout ou troca de conta).
 * Aceito tanto por usuários quanto por hotéis — a deleção é pelo token apenas.
 */
export async function removeTokenController(
  req: AuthRequest | HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const { fcm_token } = req.body;
    if (typeof fcm_token !== 'string' || !fcm_token.trim()) {
      res.status(400).json({ error: 'fcm_token obrigatório' });
      return;
    }
    await removeToken(fcm_token.trim());
    res.status(204).send();
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(500).json({ error: message });
  }
}
