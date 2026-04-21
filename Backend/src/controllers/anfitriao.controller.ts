import { Request, Response } from 'express';
import {
  registerAnfitriao,
  loginAnfitriao,
  refreshAnfitriaoToken,
  logoutAnfitriao,
  getAnfitriaoById,
  updateAnfitriao,
  changeAnfitriaoPassword,
  deleteAnfitriao,
} from '../services/anfitriao.service';

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Mapeia mensagens de erro do serviço para status HTTP.
 * Nunca expõe stack traces em produção.
 */
function mapError(message: string): number {
  if (message.includes('já cadastrado') || message.includes('já existe'))  return 409;
  if (message.includes('inválid') || message.includes('fraca'))            return 400;
  if (message.includes('não encontrado') || message.includes('inativo'))   return 404;
  if (message.includes('Credenciais') || message.includes('token'))        return 401;
  if (message.includes('incorreta'))                                        return 401;
  if (message.includes('Nenhum campo'))                                     return 400;
  return 500;
}

function sendError(res: Response, err: unknown): void {
  const message = err instanceof Error ? err.message : 'Erro interno';
  const status  = mapError(message);
  res.status(status).json({ error: message });
}

// ── Handlers ──────────────────────────────────────────────────────────────────

/** POST /api/hotel/register */
export async function registerAnfitriaoController(req: Request, res: Response): Promise<void> {
  try {
    const hotel = await registerAnfitriao(req.body);
    console.log('[register hotel] sucesso, hotel_id =', hotel.hotel_id);
    res.status(201).json({ data: hotel });
  } catch (err) {
    console.error('[register hotel] erro =', err);
    sendError(res, err);
  }
}

/** POST /api/hotel/login */
export async function loginAnfitriaoController(req: Request, res: Response): Promise<void> {
  try {
    const { email, senha } = req.body;
    const result = await loginAnfitriao(email, senha);
    res.json({ data: result.hotel, tokens: result.tokens });
  } catch (err) {
    if (process.env.NODE_ENV !== 'production') console.error('[login hotel]', err);
    res.status(401).json({ error: 'Credenciais inválidas' });
  }
}

/** POST /api/hotel/refresh */
export async function refreshAnfitriaoTokenController(req: Request, res: Response): Promise<void> {
  try {
    const { refreshToken } = req.body;
    const tokens = await refreshAnfitriaoToken(refreshToken);
    res.json({ tokens });
  } catch (err) {
    res.status(401).json({ error: 'Refresh token inválido ou expirado' });
  }
}

/** POST /api/hotel/logout */
export async function logoutAnfitriaoController(req: Request, res: Response): Promise<void> {
  try {
    const { refreshToken } = req.body;
    await logoutAnfitriao(refreshToken);
    res.json({ message: 'Logout realizado com sucesso' });
  } catch (err) {
    // Logout sempre retorna sucesso do ponto de vista do cliente
    res.json({ message: 'Logout realizado com sucesso' });
  }
}

/** GET /api/hotel/me */
export async function getHotelMeController(req: Request, res: Response): Promise<void> {
  try {
    const hotel = await getAnfitriaoById((req as any).hotelId);
    res.json({ data: hotel });
  } catch (err) {
    sendError(res, err);
  }
}

/** PATCH /api/hotel/me */
export async function updateHotelMeController(req: Request, res: Response): Promise<void> {
  try {
    const hotel = await updateAnfitriao((req as any).hotelId, req.body);
    res.json({ data: hotel });
  } catch (err) {
    sendError(res, err);
  }
}

/** POST /api/hotel/change-password */
export async function changeHotelPasswordController(req: Request, res: Response): Promise<void> {
  try {
    const { senhaAtual, novaSenha } = req.body;
    await changeAnfitriaoPassword((req as any).hotelId, senhaAtual, novaSenha);
    res.json({ message: 'Senha alterada com sucesso. Faça login novamente.' });
  } catch (err) {
    sendError(res, err);
  }
}

/** DELETE /api/hotel/me */
export async function deleteHotelMeController(req: Request, res: Response): Promise<void> {
  try {
    await deleteAnfitriao((req as any).hotelId);
    res.json({ message: 'Conta desativada com sucesso' });
  } catch (err) {
    sendError(res, err);
  }
}
