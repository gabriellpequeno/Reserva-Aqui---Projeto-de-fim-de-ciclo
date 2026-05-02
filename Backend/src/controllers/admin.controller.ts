/**
 * Controller: Admin
 *
 * Feature: admin-account-management (Fase 1 + extensão de edição de dados)
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
  updateUser,
  updateHotel,
  UserStatus,
  HotelStatus,
  AdminUpdateUserInput,
  AdminUpdateHotelInput,
} from '../services/admin.service';

// ── Helpers ───────────────────────────────────────────────────────────────────

interface PgError { code?: string }

function isUniqueViolation(err: unknown): boolean {
  return !!err && typeof err === 'object' && (err as PgError).code === '23505';
}

function mapErrorStatus(message: string): number {
  if (message.includes('não encontrado')) return 404;
  if (message.includes('inválid'))         return 400;
  if (message.includes('vazio'))           return 400;
  if (message.includes('Nenhum campo'))    return 400;
  return 500;
}

function sendError(res: Response, err: unknown): void {
  if (isUniqueViolation(err)) {
    res.status(409).json({ error: 'Email já cadastrado em outra conta' });
    return;
  }
  const message = err instanceof Error ? err.message : 'Erro interno';
  res.status(mapErrorStatus(message)).json({ error: message });
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

const USER_DATA_FIELDS  = ['nome_completo', 'email', 'numero_celular'] as const;
const HOTEL_DATA_FIELDS = [
  'nome_hotel', 'email', 'telefone', 'descricao',
  'cep', 'uf', 'cidade', 'bairro', 'rua', 'numero', 'complemento',
] as const;

function pickFields<K extends string>(
  body: Record<string, unknown>,
  fields: readonly K[],
): Partial<Record<K, string>> {
  const out: Partial<Record<K, string>> = {};
  for (const f of fields) {
    const v = body[f];
    if (typeof v === 'string') out[f] = v;
  }
  return out;
}

// ── Handlers: Usuários ────────────────────────────────────────────────────────

/** GET /api/v1/admin/users */
export async function listUsersController(req: Request, res: Response): Promise<void> {
  try {
    const users = await listUsers(parsePagination(req));
    res.json({ users });
  } catch (err) {
    sendError(res, err);
  }
}

/**
 * PATCH /api/v1/admin/users/:id
 *
 * Body aceita `status` e/ou campos de dados (nome_completo, email, numero_celular).
 * Se ambos presentes, status é aplicado primeiro, depois os dados.
 */
export async function updateUserController(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const body = (req.body ?? {}) as Record<string, unknown>;

    const status    = typeof body.status === 'string' ? body.status : undefined;
    const dataPatch = pickFields(body, USER_DATA_FIELDS) as AdminUpdateUserInput;

    if (!status && Object.keys(dataPatch).length === 0) {
      res.status(400).json({ error: 'Body vazio: informe status e/ou campos de dados' });
      return;
    }

    if (status !== undefined && !VALID_USER_STATUS.includes(status as UserStatus)) {
      res.status(400).json({
        error: `Status inválido. Valores permitidos: ${VALID_USER_STATUS.join(', ')}`,
      });
      return;
    }

    let user = undefined;
    if (status) {
      user = await setUserStatus(id, status as UserStatus);
    }
    if (Object.keys(dataPatch).length > 0) {
      user = await updateUser(id, dataPatch);
    }

    res.json({ user });
  } catch (err) {
    sendError(res, err);
  }
}

// Alias para compatibilidade com tooling existente (nome antigo).
export const updateUserStatusController = updateUserController;

// ── Handlers: Hotéis ──────────────────────────────────────────────────────────

/** GET /api/v1/admin/hotels */
export async function listHotelsController(req: Request, res: Response): Promise<void> {
  try {
    const hotels = await listHotels(parsePagination(req));
    res.json({ hotels });
  } catch (err) {
    sendError(res, err);
  }
}

/**
 * PATCH /api/v1/admin/hotels/:id
 *
 * Body aceita `status` e/ou campos de dados do hotel (nome, email, telefone,
 * descricao, endereço completo). Status aplicado antes dos dados se ambos vierem.
 */
export async function updateHotelController(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const body = (req.body ?? {}) as Record<string, unknown>;

    const status    = typeof body.status === 'string' ? body.status : undefined;
    const dataPatch = pickFields(body, HOTEL_DATA_FIELDS) as AdminUpdateHotelInput;

    if (!status && Object.keys(dataPatch).length === 0) {
      res.status(400).json({ error: 'Body vazio: informe status e/ou campos de dados' });
      return;
    }

    if (status !== undefined && !VALID_HOTEL_STATUS.includes(status as HotelStatus)) {
      res.status(400).json({
        error: `Status inválido. Valores permitidos: ${VALID_HOTEL_STATUS.join(', ')}`,
      });
      return;
    }

    let hotel = undefined;
    if (status) {
      hotel = await setHotelStatus(id, status as HotelStatus);
    }
    if (Object.keys(dataPatch).length > 0) {
      hotel = await updateHotel(id, dataPatch);
    }

    res.json({ hotel });
  } catch (err) {
    sendError(res, err);
  }
}

export const updateHotelStatusController = updateHotelController;
