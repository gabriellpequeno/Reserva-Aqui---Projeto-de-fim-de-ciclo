import crypto from 'crypto';
import argon2 from 'argon2';
import jwt from 'jsonwebtoken';
import { masterPool } from '../database/masterDb';
import { Anfitriao } from '../entities/Anfitriao';

// ── Tipos ─────────────────────────────────────────────────────────────────────

export interface RegisterAnfitriaoInput {
  nome_hotel:   string;
  cnpj:         string;
  telefone:     string;
  email:        string;
  senha:        string;
  cep:          string;
  uf:           string;
  cidade:       string;
  bairro:       string;
  rua:          string;
  numero:       string;
  complemento?: string;
  descricao?:   string;
}

export interface UpdateAnfitriaoInput {
  nome_hotel?:  string;
  telefone?:    string;
  email?:       string;
  descricao?:   string;
  cep?:         string;
  uf?:          string;
  cidade?:      string;
  bairro?:      string;
  rua?:         string;
  numero?:      string;
  complemento?: string;
}

export interface AnfitriaoSafe {
  hotel_id:     string;
  nome_hotel:   string;
  cnpj:         string;
  telefone:     string;
  email:        string;
  cep:          string;
  uf:           string;
  cidade:       string;
  bairro:       string;
  rua:          string;
  numero:       string;
  complemento:  string | null;
  saldo:        string;
  descricao:    string | null;
  schema_name:  string;
  criado_em:    Date;
  ativo:        boolean;
}

export interface AuthTokens {
  accessToken:  string;
  refreshToken: string;
}

// ── Helpers JWT ───────────────────────────────────────────────────────────────

const JWT_SECRET          = process.env.JWT_SECRET!;
const JWT_ACCESS_EXPIRES  = process.env.JWT_ACCESS_EXPIRES  ?? '1h';
const JWT_REFRESH_EXPIRES = process.env.JWT_REFRESH_EXPIRES ?? '7d';

function signAccessToken(payload: { hotel_id: string; email: string }): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_ACCESS_EXPIRES } as jwt.SignOptions);
}

function signRefreshToken(payload: { hotel_id: string }): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_REFRESH_EXPIRES } as jwt.SignOptions);
}

function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function refreshExpiresAt(): Date {
  return new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
}

// ── Argon2id ──────────────────────────────────────────────────────────────────

const ARGON2_OPTIONS: argon2.Options = {
  type:        argon2.argon2id,
  memoryCost:  process.env.ARGON2_MEMORY_COST  ? parseInt(process.env.ARGON2_MEMORY_COST, 10)  : 65536,
  timeCost:    process.env.ARGON2_TIME_COST    ? parseInt(process.env.ARGON2_TIME_COST, 10)    : 3,
  parallelism: process.env.ARGON2_PARALLELISM  ? parseInt(process.env.ARGON2_PARALLELISM, 10)  : 1,
};

// ── Funções Exportadas (Wrappers) ─────────────────────────────────────────────

export async function registerAnfitriao(input: RegisterAnfitriaoInput): Promise<AnfitriaoSafe> {
  return _registerAnfitriao(input);
}

export async function loginAnfitriao(email: string, senha: string): Promise<{ hotel: AnfitriaoSafe; tokens: AuthTokens }> {
  return _loginAnfitriao(email, senha);
}

export async function refreshAnfitriaoToken(refreshToken: string): Promise<AuthTokens> {
  return _refreshAnfitriaoToken(refreshToken);
}

export async function logoutAnfitriao(refreshToken: string): Promise<void> {
  return _logoutAnfitriao(refreshToken);
}

export async function getAnfitriaoById(hotelId: string): Promise<AnfitriaoSafe> {
  return _getAnfitriaoById(hotelId);
}

export async function updateAnfitriao(hotelId: string, input: UpdateAnfitriaoInput): Promise<AnfitriaoSafe> {
  return _updateAnfitriao(hotelId, input);
}

export async function changeAnfitriaoPassword(hotelId: string, senhaAtual: string, novaSenha: string): Promise<void> {
  return _changeAnfitriaoPassword(hotelId, senhaAtual, novaSenha);
}

export async function deleteAnfitriao(hotelId: string): Promise<void> {
  return _deleteAnfitriao(hotelId);
}

// ── Funções Privadas (Regras de Negócio) ─────────────────────────────────────

/**
 * Registra um novo hotel (anfitrião).
 * Valida → hash senha → gera schema_name → persiste → retorna payload seguro (sem senha).
 */
async function _registerAnfitriao(input: RegisterAnfitriaoInput): Promise<AnfitriaoSafe> {
  Anfitriao.validate(input);

  const senhaHash  = await argon2.hash(input.senha, ARGON2_OPTIONS);
  const cnpjDigits = input.cnpj.replace(/\D/g, '');

  // Schema name único por hotel — derivado do CNPJ para ser determinístico e URL-safe
  const schemaName = `hotel_${cnpjDigits}`;

  const { rows } = await masterPool.query<AnfitriaoSafe>(
    `INSERT INTO anfitriao
       (nome_hotel, cnpj, telefone, email, senha, cep, uf, cidade, bairro, rua, numero, complemento, descricao, schema_name)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
     RETURNING hotel_id, nome_hotel, cnpj, telefone, email, cep, uf, cidade, bairro, rua, numero,
               complemento, saldo, descricao, schema_name, criado_em, ativo`,
    [
      input.nome_hotel,
      cnpjDigits,
      input.telefone,
      input.email.toLowerCase(),
      senhaHash,
      input.cep.replace(/\D/g, ''),
      input.uf.toUpperCase(),
      input.cidade,
      input.bairro,
      input.rua,
      input.numero,
      input.complemento ?? null,
      input.descricao   ?? null,
      schemaName,
    ],
  );

  return rows[0];
}

/**
 * Autentica um anfitrião e emite access + refresh tokens.
 * Mensagem de erro genérica — nunca distingue "não existe" de "senha errada".
 */
async function _loginAnfitriao(
  email: string,
  senha: string,
): Promise<{ hotel: AnfitriaoSafe; tokens: AuthTokens }> {
  const { rows } = await masterPool.query<AnfitriaoSafe & { senha: string }>(
    `SELECT * FROM anfitriao WHERE email = $1 AND ativo = TRUE`,
    [email.toLowerCase()],
  );

  const hotel = rows[0];

  const senhaCorreta =
    hotel
      ? await argon2.verify(hotel.senha, senha)
      : (await argon2.hash('dummy_to_prevent_timing_attack', ARGON2_OPTIONS), false);

  if (!hotel || !senhaCorreta) throw new Error('Credenciais inválidas');

  const { senha: _, ...safeHotel } = hotel;

  const accessToken  = signAccessToken({ hotel_id: safeHotel.hotel_id, email: safeHotel.email });
  const refreshToken = signRefreshToken({ hotel_id: safeHotel.hotel_id });

  await masterPool.query(
    `INSERT INTO hotel_refresh_tokens (hotel_id, token_hash, expires_at)
     VALUES ($1, $2, $3)`,
    [safeHotel.hotel_id, hashToken(refreshToken), refreshExpiresAt()],
  );

  return { hotel: safeHotel as AnfitriaoSafe, tokens: { accessToken, refreshToken } };
}

/**
 * Renova o access token com um refresh token válido.
 * Invalida o token antigo (rotation) e emite um novo par.
 */
async function _refreshAnfitriaoToken(refreshToken: string): Promise<AuthTokens> {
  let payload: { hotel_id: string };
  try {
    payload = jwt.verify(refreshToken, JWT_SECRET) as { hotel_id: string };
  } catch {
    throw new Error('Refresh token inválido ou expirado');
  }

  const tokenHash = hashToken(refreshToken);

  const { rows } = await masterPool.query(
    `SELECT id FROM hotel_refresh_tokens WHERE token_hash = $1 AND expires_at > NOW()`,
    [tokenHash],
  );

  if (!rows[0]) throw new Error('Refresh token inválido ou expirado');

  await masterPool.query(`DELETE FROM hotel_refresh_tokens WHERE token_hash = $1`, [tokenHash]);

  const { rows: hotelRows } = await masterPool.query<AnfitriaoSafe>(
    `SELECT hotel_id, email FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [payload.hotel_id],
  );

  if (!hotelRows[0]) throw new Error('Hotel não encontrado ou inativo');

  const { hotel_id, email } = hotelRows[0];

  const newAccessToken  = signAccessToken({ hotel_id, email });
  const newRefreshToken = signRefreshToken({ hotel_id });

  await masterPool.query(
    `INSERT INTO hotel_refresh_tokens (hotel_id, token_hash, expires_at)
     VALUES ($1, $2, $3)`,
    [hotel_id, hashToken(newRefreshToken), refreshExpiresAt()],
  );

  return { accessToken: newAccessToken, refreshToken: newRefreshToken };
}

/**
 * Logout: revoga o refresh token do hotel no servidor.
 */
async function _logoutAnfitriao(refreshToken: string): Promise<void> {
  await masterPool.query(
    `DELETE FROM hotel_refresh_tokens WHERE token_hash = $1`,
    [hashToken(refreshToken)],
  );
}

/**
 * Retorna o perfil do hotel autenticado (sem senha).
 */
async function _getAnfitriaoById(hotelId: string): Promise<AnfitriaoSafe> {
  const { rows } = await masterPool.query<AnfitriaoSafe>(
    `SELECT hotel_id, nome_hotel, cnpj, telefone, email, cep, uf, cidade, bairro, rua, numero,
            complemento, saldo, descricao, schema_name, criado_em, ativo
     FROM anfitriao
     WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );

  if (!rows[0]) throw new Error('Hotel não encontrado');
  return rows[0];
}

/**
 * Atualiza dados não-sensíveis do anfitrião.
 * Campos financeiros (saldo) e de identidade (cnpj, schema_name) não são editáveis aqui.
 */
async function _updateAnfitriao(hotelId: string, input: UpdateAnfitriaoInput): Promise<AnfitriaoSafe> {
  Anfitriao.validatePartial(input);

  const fields: string[] = [];
  const values: unknown[] = [];
  let idx = 1;

  if (input.nome_hotel  != null) { fields.push(`nome_hotel = $${idx++}`);  values.push(input.nome_hotel); }
  if (input.telefone    != null) { fields.push(`telefone = $${idx++}`);    values.push(input.telefone); }
  if (input.email       != null) { fields.push(`email = $${idx++}`);       values.push(input.email.toLowerCase()); }
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

  const { rows } = await masterPool.query<AnfitriaoSafe>(
    `UPDATE anfitriao SET ${fields.join(', ')}
     WHERE hotel_id = $${idx} AND ativo = TRUE
     RETURNING hotel_id, nome_hotel, cnpj, telefone, email, cep, uf, cidade, bairro, rua, numero,
               complemento, saldo, descricao, schema_name, criado_em, ativo`,
    values,
  );

  if (!rows[0]) throw new Error('Hotel não encontrado');
  return rows[0];
}

/**
 * Troca a senha do anfitrião.
 * Invalida todos os refresh tokens ativos após a troca.
 */
async function _changeAnfitriaoPassword(hotelId: string, senhaAtual: string, novaSenha: string): Promise<void> {
  Anfitriao.validateNovaSenha(novaSenha);

  const { rows } = await masterPool.query<{ senha: string }>(
    `SELECT senha FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );

  if (!rows[0]) throw new Error('Hotel não encontrado');

  const senhaCorreta = await argon2.verify(rows[0].senha, senhaAtual);
  if (!senhaCorreta) throw new Error('Senha atual incorreta');

  const novaSenhaHash = await argon2.hash(novaSenha, ARGON2_OPTIONS);

  await masterPool.query(
    `UPDATE anfitriao SET senha = $1 WHERE hotel_id = $2`,
    [novaSenhaHash, hotelId],
  );

  // Revoga todas as sessões ativas do hotel
  await masterPool.query(`DELETE FROM hotel_refresh_tokens WHERE hotel_id = $1`, [hotelId]);
}

/**
 * Desativa a conta do hotel (soft delete).
 * Revoga todos os refresh tokens ativos.
 */
async function _deleteAnfitriao(hotelId: string): Promise<void> {
  const { rowCount } = await masterPool.query(
    `UPDATE anfitriao SET ativo = FALSE WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );

  if (!rowCount) throw new Error('Hotel não encontrado');

  await masterPool.query(`DELETE FROM hotel_refresh_tokens WHERE hotel_id = $1`, [hotelId]);
}
