/**
 * Service: Admin
 *
 * Feature: admin-account-management (Fase 1)
 *
 * Queries e regras de negócio para gerenciamento de contas pelo admin:
 *   - Listar/alterar status de usuários (hóspedes)
 *   - Listar/alterar status de hotéis (anfitriões)
 *
 * Estratégia de status (Opção A da spec): reutiliza `ativo BOOLEAN` existente
 * e traduz para o enum de status na serialização. Zero migrations adicionais.
 */
import { masterPool } from '../database/masterDb';

// ── Tipos ─────────────────────────────────────────────────────────────────────

export type UserStatus  = 'ativo' | 'suspenso';
export type HotelStatus = 'ativo' | 'inativo';

export interface AdminUserDTO {
  id:        string;
  nome:      string;
  email:     string;
  telefone:  string | null;
  fotoUrl:   string | null;
  status:    UserStatus;
  criadoEm:  string;
}

export interface AdminHotelDTO {
  id:               string;
  nome:             string;
  emailResponsavel: string;
  capaUrl:          string | null;
  status:           HotelStatus;
  totalQuartos:     number | null;
  criadoEm:         string;
}

export interface Pagination {
  limit?:  number;
  offset?: number;
}

// ── Constantes ────────────────────────────────────────────────────────────────

const DEFAULT_LIMIT = 100;
const MAX_LIMIT     = 500;

function normalizeLimit(limit?: number): number {
  if (!limit || limit <= 0) return DEFAULT_LIMIT;
  return Math.min(limit, MAX_LIMIT);
}

function normalizeOffset(offset?: number): number {
  if (!offset || offset < 0) return 0;
  return offset;
}

// ── Serializers ───────────────────────────────────────────────────────────────

interface UsuarioRow {
  user_id:         string;
  nome_completo:   string;
  email:           string;
  numero_celular:  string | null;
  ativo:           boolean;
  criado_em:       Date;
}

function serializeUser(row: UsuarioRow): AdminUserDTO {
  return {
    id:       row.user_id,
    nome:     row.nome_completo,
    email:    row.email,
    telefone: row.numero_celular,
    fotoUrl:  null, // usuário não tem foto de perfil persistida no schema atual
    status:   row.ativo ? 'ativo' : 'suspenso',
    criadoEm: row.criado_em.toISOString(),
  };
}

interface AnfitriaoRow {
  hotel_id:           string;
  nome_hotel:         string;
  email:              string;
  cover_storage_path: string | null;
  ativo:              boolean;
  criado_em:          Date;
  total_quartos:      string | null; // COUNT() retorna string no pg
}

function serializeHotel(row: AnfitriaoRow): AdminHotelDTO {
  return {
    id:               row.hotel_id,
    nome:             row.nome_hotel,
    emailResponsavel: row.email,
    capaUrl:          row.cover_storage_path,
    status:           row.ativo ? 'ativo' : 'inativo',
    totalQuartos:     row.total_quartos != null ? parseInt(row.total_quartos, 10) : null,
    criadoEm:         row.criado_em.toISOString(),
  };
}

// ── Exports ───────────────────────────────────────────────────────────────────

export async function listUsers(pagination: Pagination = {}): Promise<AdminUserDTO[]> {
  const limit  = normalizeLimit(pagination.limit);
  const offset = normalizeOffset(pagination.offset);

  const { rows } = await masterPool.query<UsuarioRow>(
    `SELECT user_id, nome_completo, email, numero_celular, ativo, criado_em
     FROM usuario
     WHERE papel = 'usuario'
     ORDER BY criado_em DESC
     LIMIT $1 OFFSET $2`,
    [limit, offset],
  );

  return rows.map(serializeUser);
}

export async function setUserStatus(userId: string, status: UserStatus): Promise<AdminUserDTO> {
  const novoAtivo = status === 'ativo';

  const { rows } = await masterPool.query<UsuarioRow>(
    `UPDATE usuario
        SET ativo = $1
      WHERE user_id = $2 AND papel = 'usuario'
     RETURNING user_id, nome_completo, email, numero_celular, ativo, criado_em`,
    [novoAtivo, userId],
  );

  if (!rows[0]) throw new Error('Usuário não encontrado');

  // Revoga refresh tokens ativos quando o usuário é suspenso
  if (!novoAtivo) {
    await masterPool.query(`DELETE FROM refresh_tokens WHERE user_id = $1`, [userId]);
  }

  return serializeUser(rows[0]);
}

export async function listHotels(pagination: Pagination = {}): Promise<AdminHotelDTO[]> {
  const limit  = normalizeLimit(pagination.limit);
  const offset = normalizeOffset(pagination.offset);

  const { rows } = await masterPool.query<AnfitriaoRow>(
    `SELECT a.hotel_id, a.nome_hotel, a.email, a.cover_storage_path, a.ativo, a.criado_em,
            NULL::text AS total_quartos
     FROM anfitriao a
     ORDER BY a.criado_em DESC
     LIMIT $1 OFFSET $2`,
    [limit, offset],
  );

  return rows.map(serializeHotel);
}

export async function setHotelStatus(hotelId: string, status: HotelStatus): Promise<AdminHotelDTO> {
  const novoAtivo = status === 'ativo';

  const { rows } = await masterPool.query<AnfitriaoRow>(
    `UPDATE anfitriao
        SET ativo = $1
      WHERE hotel_id = $2
     RETURNING hotel_id, nome_hotel, email, cover_storage_path, ativo, criado_em,
               NULL::text AS total_quartos`,
    [novoAtivo, hotelId],
  );

  if (!rows[0]) throw new Error('Hotel não encontrado');

  // Revoga refresh tokens ativos quando o hotel é desativado
  if (!novoAtivo) {
    await masterPool.query(`DELETE FROM hotel_refresh_tokens WHERE hotel_id = $1`, [hotelId]);
  }

  return serializeHotel(rows[0]);
}
