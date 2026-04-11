import { Request, Response } from 'express';
import {
  registerUsuario,
  loginUsuario,
  refreshUsuarioToken,
  logoutUsuario,
  getUsuarioById,
  updateUsuario,
  changePassword,
  deleteUsuario,
} from '../services/usuario.service';

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Mapeia mensagens de erro do serviço para status HTTP.
 * Nunca expõe stack traces em produção.
 */
function mapError(message: string): number {
  if (message.includes('já cadastrado') || message.includes('já existe'))  return 409;
  if (message.includes('inválid') || message.includes('fraca'))            return 400;
  if (message.includes('não encontrado') || message.includes('inativo'))   return 404;
  if (message.includes('Credenciais')  || message.includes('token'))       return 401;
  if (message.includes('incorreta'))                                        return 401;
  if (message.includes('Nenhum campo'))                                     return 400;
  return 500;
}

function sendError(res: Response, err: unknown): void {
  const message = err instanceof Error ? err.message : 'Erro interno';
  const status  = mapError(message);

  // Never expose stack or internal details
  res.status(status).json({ error: message });
}

// ── Handlers ──────────────────────────────────────────────────────────────────

/** POST /api/usuario/register */
export async function registerUsuarioController(req: Request, res: Response): Promise<void> {
  try {
    const user = await registerUsuario(req.body);
    res.status(201).json({ data: user });
  } catch (err) {
    sendError(res, err);
  }
}

/** POST /api/usuario/login */
export async function loginUsuarioController(req: Request, res: Response): Promise<void> {
  try {
    const { email, senha } = req.body;
    const result = await loginUsuario(email, senha);
    res.json({ data: result.user, tokens: result.tokens });
  } catch (err) {
    // Always 401 for login failures — never reveal which field is wrong
    res.status(401).json({ error: 'Credenciais inválidas' });
  }
}

/** POST /api/usuario/refresh */
export async function refreshUsuarioTokenController(req: Request, res: Response): Promise<void> {
  try {
    const { refreshToken } = req.body;
    const tokens = await refreshUsuarioToken(refreshToken);
    res.json({ tokens });
  } catch (err) {
    res.status(401).json({ error: 'Refresh token inválido ou expirado' });
  }
}

/** POST /api/usuario/logout */
export async function logoutUsuarioController(req: Request, res: Response): Promise<void> {
  try {
    const { refreshToken } = req.body;
    await logoutUsuario(refreshToken);
    res.json({ message: 'Logout realizado com sucesso' });
  } catch (err) {
    // Logout always succeeds from the client's perspective
    res.json({ message: 'Logout realizado com sucesso' });
  }
}

/** GET /api/usuario/me */
export async function getMeController(req: Request, res: Response): Promise<void> {
  try {
    // req.userId is set by authGuard middleware
    const user = await getUsuarioById((req as any).userId);
    res.json({ data: user });
  } catch (err) {
    sendError(res, err);
  }
}

/** PATCH /api/usuario/me */
export async function updateMeController(req: Request, res: Response): Promise<void> {
  try {
    const user = await updateUsuario((req as any).userId, req.body);
    res.json({ data: user });
  } catch (err) {
    sendError(res, err);
  }
}

/** POST /api/usuario/change-password */
export async function changePasswordController(req: Request, res: Response): Promise<void> {
  try {
    const { senhaAtual, novaSenha } = req.body;
    await changePassword((req as any).userId, senhaAtual, novaSenha);
    res.json({ message: 'Senha alterada com sucesso. Faça login novamente.' });
  } catch (err) {
    sendError(res, err);
  }
}

/** DELETE /api/usuario/me */
export async function deleteMeController(req: Request, res: Response): Promise<void> {
  try {
    await deleteUsuario((req as any).userId);
    res.json({ message: 'Conta desativada com sucesso' });
  } catch (err) {
    sendError(res, err);
  }
}
