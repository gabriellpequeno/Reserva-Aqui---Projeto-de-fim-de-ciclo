/**
 * Controller: Admin
 *
 * Feature: admin-account-management (Fase 1)
 *
 * Expõe endpoints de gerenciamento de contas para admins da plataforma.
 * Todas as rotas são protegidas por `adminGuard` (verificação de papel feita lá,
 * não aqui — este controller assume que chegou aqui = admin autenticado).
 */
import { Request, Response } from 'express';
import {
  listUsers,
  listHotels,
  setUserStatus,
  setHotelStatus,
  UserStatus,
  HotelStatus,
} from '../services/admin.service';

// ── Helpers ───────────────────────────────────────────────────────────────────

function mapError(message: string): number {
  if (message.includes('não encontrado')) return 404;
  if (message.includes('inválid'))         return 400;
  return 500;
}

function sendError(res: Response, err: unknown): void {
  const message = err instanceof Error ? err.message : 'Erro interno';
  res.status(mapError(message)).json({ error: message });
}

function parsePagination(req: Request): { limit?: number; offset?: number } {
  const limit  = req.query.limit  ? parseInt(String(req.query.limit),  10) : undefined;
  const offset = req.query.offset ? parseInt(String(req.query.offset), 10) : undefined;
  return {
    limit:  Number.isFinite(limit)  ? limit  : undefined,
    offset: Number.isFinite(offset) ? offset : undefined,
  };
}

const VALID_USER_STATUS:  UserStatus[]  = ['ativo', 'suspenso'];
const VALID_HOTEL_STATUS: HotelStatus[] = ['ativo', 'inativo'];

// ── Handlers: Usuários ────────────────────────────────────────────────────────

/** GET /api/admin/users */
export async function listUsersController(req: Request, res: Response): Promise<void> {
  try {
    const users = await listUsers(parsePagination(req));
    res.json({ users });
  } catch (err) {
    sendError(res, err);
  }
}

/** PATCH /api/admin/users/:id */
export async function updateUserStatusController(req: Request, res: Response): Promise<void> {
  try {
    const { id }     = req.params;
    const { status } = req.body as { status?: string };

    if (!status || !VALID_USER_STATUS.includes(status as UserStatus)) {
      res.status(400).json({ error: `Status inválido. Valores permitidos: ${VALID_USER_STATUS.join(', ')}` });
      return;
    }

    const user = await setUserStatus(id, status as UserStatus);
    res.json({ user });
  } catch (err) {
    sendError(res, err);
  }
}

// ── Handlers: Hotéis ──────────────────────────────────────────────────────────

/** GET /api/admin/hotels */
export async function listHotelsController(req: Request, res: Response): Promise<void> {
  try {
    const hotels = await listHotels(parsePagination(req));
    res.json({ hotels });
  } catch (err) {
    sendError(res, err);
  }
}

/** PATCH /api/admin/hotels/:id */
export async function updateHotelStatusController(req: Request, res: Response): Promise<void> {
  try {
    const { id }     = req.params;
    const { status } = req.body as { status?: string };

    if (!status || !VALID_HOTEL_STATUS.includes(status as HotelStatus)) {
      res.status(400).json({ error: `Status inválido. Valores permitidos: ${VALID_HOTEL_STATUS.join(', ')}` });
      return;
    }

    const hotel = await setHotelStatus(id, status as HotelStatus);
    res.json({ hotel });
  } catch (err) {
    sendError(res, err);
  }
}
