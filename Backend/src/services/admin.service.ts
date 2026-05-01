/**
 * Service: Admin
 *
 * Feature: admin-account-management (Fase 1 + extensão de edição de dados)
 *
 * Queries e regras de negócio para gerenciamento de contas pelo admin:
 *   - Listar/alterar status de usuários (hóspedes)
 *   - Listar/alterar status de hotéis (anfitriões)
 *   - Editar dados não-sensíveis de usuários e hotéis
 *
 * Estratégia de status (Opção A da spec): reutiliza `ativo BOOLEAN` existente
 * e traduz para o enum de status na serialização. Zero migrations adicionais.
 */
import { masterPool } from '../database/masterDb';
import { Usuario } from '../entities/Usuario';
import { Anfitriao } from '../entities/Anfitriao';

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
  telefone:         string;
  descricao:        string | null;
  cep:              string;
  uf:               string;
  cidade:           string;
  bairro:           string;
  rua:              string;
  numero:           string;
  complemento:      string | null;
  capaUrl:          string | null;
  status:           HotelStatus;
  totalQuartos:     number | null;
  criadoEm:         string;
}

export interface Pagination {
  limit?:  number;
  offset?: number;
}

/**
 * Entradas de edição de dados pelo admin. Campos opcionais — só o que
 * vier no body é atualizado. `null` é tratado como "ausente" (não limpa).
 */
export interface AdminUpdateUserInput {
  nome_completo?:  string;
  email?:          string;
  numero_celular?: string;
}

export interface AdminUpdateHotelInput {
  nome_hotel?:  string;
  email?:       string;
  telefone?:    string;
  descricao?:   string;
  cep?:         string;
  uf?:          string;
  cidade?:      string;
  bairro?:      string;
  rua?:         string;
  numero?:      string;
  complemento?: string;
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
  telefone:           string;
  descricao:          string | null;
  cep:                string;
  uf:                 string;
  cidade:             string;
  bairro:             string;
  rua:                string;
  numero:             string;
  complemento:        string | null;
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
    telefone:         row.telefone,
    descricao:        row.descricao,
    cep:              row.cep,
    uf:               row.uf,
    cidade:           row.cidade,
    bairro:           row.bairro,
    rua:              row.rua,
    numero:           row.numero,
    complemento:      row.complemento,
    capaUrl:          row.cover_storage_path,
    status:           row.ativo ? 'ativo' : 'inativo',
    totalQuartos:     row.total_quartos != null ? parseInt(row.total_quartos, 10) : null,
    criadoEm:         row.criado_em.toISOString(),
  };
}

const HOTEL_COLUMNS = `hotel_id, nome_hotel, email, telefone, descricao,
                       cep, uf, cidade, bairro, rua, numero, complemento,
                       cover_storage_path, ativo, criado_em,
                       NULL::text AS total_quartos`;

// ── Exports: listagem e status ────────────────────────────────────────────────

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
    `SELECT ${HOTEL_COLUMNS}
     FROM anfitriao
     ORDER BY criado_em DESC
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
     RETURNING ${HOTEL_COLUMNS}`,
    [novoAtivo, hotelId],
  );

  if (!rows[0]) throw new Error('Hotel não encontrado');

  // Revoga refresh tokens ativos quando o hotel é desativado
  if (!novoAtivo) {
    await masterPool.query(`DELETE FROM hotel_refresh_tokens WHERE hotel_id = $1`, [hotelId]);
  }

  return serializeHotel(rows[0]);
}

// ── Exports: edição de dados ──────────────────────────────────────────────────

/**
 * Edita dados não-sensíveis de um usuário.
 * Difere do `PATCH /usuarios/me`: não filtra por `ativo = TRUE` — admin
 * também corrige contas suspensas. Senha e CPF ficam fora do escopo.
 * Email duplicado cai em erro `23505` do postgres; o controller traduz para 409.
 */
export async function updateUser(
  userId: string,
  input: AdminUpdateUserInput,
): Promise<AdminUserDTO> {
  Usuario.validatePartial(input);

  const fields: string[] = [];
  const values: unknown[] = [];
  let idx = 1;

  if (input.nome_completo  != null) { fields.push(`nome_completo = $${idx++}`);  values.push(input.nome_completo); }
  if (input.email          != null) { fields.push(`email = $${idx++}`);          values.push(input.email.toLowerCase()); }
  if (input.numero_celular != null) { fields.push(`numero_celular = $${idx++}`); values.push(input.numero_celular); }

  if (!fields.length) throw new Error('Nenhum campo para atualizar');

  values.push(userId);

  const { rows } = await masterPool.query<UsuarioRow>(
    `UPDATE usuario SET ${fields.join(', ')}
      WHERE user_id = $${idx} AND papel = 'usuario'
     RETURNING user_id, nome_completo, email, numero_celular, ativo, criado_em`,
    values,
  );

  if (!rows[0]) throw new Error('Usuário não encontrado');

  // Email alterado invalida sessões ativas — força relogin.
  if (input.email != null) {
    await masterPool.query(`DELETE FROM refresh_tokens WHERE user_id = $1`, [userId]);
  }

  return serializeUser(rows[0]);
}

/**
 * Edita dados não-sensíveis de um hotel.
 * CNPJ, saldo e schema_name ficam fora — dados de identidade/financeiros.
 * Email duplicado cai em erro `23505` do postgres; o controller traduz para 409.
 */
export async function updateHotel(
  hotelId: string,
  input: AdminUpdateHotelInput,
): Promise<AdminHotelDTO> {
  Anfitriao.validatePartial(input);

  const fields: string[] = [];
  const values: unknown[] = [];
  let idx = 1;

  if (input.nome_hotel  != null) { fields.push(`nome_hotel = $${idx++}`);  values.push(input.nome_hotel); }
  if (input.email       != null) { fields.push(`email = $${idx++}`);       values.push(input.email.toLowerCase()); }
  if (input.telefone    != null) { fields.push(`telefone = $${idx++}`);    values.push(input.telefone); }
  if (input.descricao   != null) { fields.push(`descricao = $${idx++}`);   values.push(input.descricao); }
  if (input.cep         != null) { fields.push(`cep = $${idx++}`);         values.push(input.cep.replace(/\D/g, '')); }
  if (input.uf          != null) { fields.push(`uf = $${idx++}`);          values.push(input.uf.toUpperCase()); }
  if (input.cidade      != null) { fields.push(`cidade = $${idx++}`);      values.push(input.cidade); }
  if (input.bairro      != null) { fields.push(`bairro = $${idx++}`);      values.push(input.bairro); }
  if (input.rua         != null) { fields.push(`rua = $${idx++}`);         values.push(input.rua); }
  if (input.numero      != null) { fields.push(`numero = $${idx++}`);      values.push(input.numero); }
  if (input.complemento != null) { fields.push(`complemento = $${idx++}`); values.push(input.complemento); }

  if (!fields.length) throw new Error('Nenhum campo para atualizar');

  values.push(hotelId);

  const { rows } = await masterPool.query<AnfitriaoRow>(
    `UPDATE anfitriao SET ${fields.join(', ')}
      WHERE hotel_id = $${idx}
     RETURNING ${HOTEL_COLUMNS}`,
    values,
  );

  if (!rows[0]) throw new Error('Hotel não encontrado');

  if (input.email != null) {
    await masterPool.query(`DELETE FROM hotel_refresh_tokens WHERE hotel_id = $1`, [hotelId]);
  }

  return serializeHotel(rows[0]);
}
