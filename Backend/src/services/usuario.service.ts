import crypto from 'crypto';
import argon2 from 'argon2';
import jwt from 'jsonwebtoken';
import { masterPool } from '../database/masterDb';
import { Usuario } from '../entities/Usuario';

// ── Tipos ─────────────────────────────────────────────────────────────────────

function parseDataBrToEn(data: string): string {
  const [dd, mm, yyyy] = data.split('/');
  return `${yyyy}-${mm}-${dd}`;
}

export interface RegisterUsuarioInput {
  nome_completo:   string;
  email:           string;
  senha:           string;
  cpf:             string;
  data_nascimento: string;
  numero_celular?: string;
}

export interface UpdateUsuarioInput {
  nome_completo?:  string;
  email?:          string;
  numero_celular?: string;
  data_nascimento?: string;
}

export type UsuarioPapel = 'usuario' | 'admin';

export interface UsuarioSafe {
  user_id:         string;
  nome_completo:   string;
  email:           string;
  cpf:             string;
  data_nascimento: Date;
  numero_celular:  string | null;
  papel:           UsuarioPapel;
  criado_em:       Date;
  ativo:           boolean;
}

export interface AuthTokens {
  accessToken:  string;
  refreshToken: string;
}

// ── Helpers JWT ───────────────────────────────────────────────────────────────

const JWT_SECRET          = process.env.JWT_SECRET!;
const JWT_ACCESS_EXPIRES  = process.env.JWT_ACCESS_EXPIRES  ?? '1h';
const JWT_REFRESH_EXPIRES = process.env.JWT_REFRESH_EXPIRES ?? '7d';

function signAccessToken(payload: { user_id: string; email: string; papel: UsuarioPapel }): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_ACCESS_EXPIRES } as jwt.SignOptions);
}

function signRefreshToken(payload: { user_id: string }): string {
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
  type:         argon2.argon2id,
  memoryCost:   process.env.ARGON2_MEMORY_COST ? parseInt(process.env.ARGON2_MEMORY_COST, 10) : 65536,
  timeCost:     process.env.ARGON2_TIME_COST ? parseInt(process.env.ARGON2_TIME_COST, 10) : 3,
  parallelism:  process.env.ARGON2_PARALLELISM ? parseInt(process.env.ARGON2_PARALLELISM, 10) : 1,
};

// ── Funções Exportadas (Wrappers) ─────────────────────────────────────────────

export async function registerUsuario(input: RegisterUsuarioInput): Promise<UsuarioSafe> {
  return _registerUsuario(input);
}

export async function loginUsuario(email: string, senha: string): Promise<{ user: UsuarioSafe; tokens: AuthTokens }> {
  return _loginUsuario(email, senha);
}

export async function refreshUsuarioToken(refreshToken: string): Promise<AuthTokens> {
  return _refreshUsuarioToken(refreshToken);
}

export async function logoutUsuario(refreshToken: string): Promise<void> {
  return _logoutUsuario(refreshToken);
}

export async function getUsuarioById(userId: string): Promise<UsuarioSafe> {
  return _getUsuarioById(userId);
}

export async function updateUsuario(userId: string, input: UpdateUsuarioInput): Promise<UsuarioSafe> {
  return _updateUsuario(userId, input);
}

export async function changePassword(userId: string, senhaAtual: string, novaSenha: string): Promise<void> {
  return _changePassword(userId, senhaAtual, novaSenha);
}

export async function deleteUsuario(userId: string): Promise<void> {
  return _deleteUsuario(userId);
}

// ── Funções Privadas (Regras de Negócio) ───────────────────────────────────────

/**
 * Registra um novo usuario.
 * Valida → hash senha → persiste → retorna payload seguro (sem senha).
 */
async function _registerUsuario(input: RegisterUsuarioInput): Promise<UsuarioSafe> {
  Usuario.validate(input);
  const senhaHash = await argon2.hash(input.senha, ARGON2_OPTIONS);

  const { rows } = await masterPool.query<UsuarioSafe>(
    `INSERT INTO usuario (nome_completo, email, senha, cpf, data_nascimento, numero_celular)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING user_id, nome_completo, email, cpf, data_nascimento, numero_celular, papel, criado_em, ativo`,
    [
      input.nome_completo,
      input.email.toLowerCase(),
      senhaHash,
      input.cpf.replace(/\D/g, ''),
      parseDataBrToEn(input.data_nascimento),
      input.numero_celular ?? null,
    ],
  );

  return rows[0];
}

/**
 * Autentica um usuario e emite access + refresh tokens.
 * Mensagem de erro genérica — nunca distingue "usuário não existe" de "senha errada".
 */
async function _loginUsuario(
  email: string,
  senha: string,
): Promise<{ user: UsuarioSafe; tokens: AuthTokens }> {
  const { rows } = await masterPool.query<UsuarioSafe & { senha: string }>(
    `SELECT * FROM usuario WHERE email = $1 AND ativo = TRUE`,
    [email.toLowerCase()],
  );

  const user = rows[0];

  const senhaCorreta =
    user
      ? await argon2.verify(user.senha, senha)
      : (await argon2.hash('dummy_to_prevent_timing_attack', ARGON2_OPTIONS), false);

  if (!user || !senhaCorreta) throw new Error('Credenciais inválidas');

  const { senha: _, ...safeUser } = user;

  const accessToken  = signAccessToken({
    user_id: safeUser.user_id,
    email:   safeUser.email,
    papel:   safeUser.papel,
  });
  const refreshToken = signRefreshToken({ user_id: safeUser.user_id });

  await masterPool.query(
    `INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
     VALUES ($1, $2, $3)`,
    [safeUser.user_id, hashToken(refreshToken), refreshExpiresAt()],
  );

  return { user: safeUser as UsuarioSafe, tokens: { accessToken, refreshToken } };
}

/**
 * Renova o access token com um refresh token válido.
 * Invalida o token antigo (rotation) e emite um novo par.
 */
async function _refreshUsuarioToken(
  refreshToken: string,
): Promise<AuthTokens> {
  let payload: { user_id: string };
  try {
    payload = jwt.verify(refreshToken, JWT_SECRET) as { user_id: string };
  } catch {
    throw new Error('Refresh token inválido ou expirado');
  }

  const tokenHash = hashToken(refreshToken);

  const { rows } = await masterPool.query(
    `SELECT id FROM refresh_tokens WHERE token_hash = $1 AND expires_at > NOW()`,
    [tokenHash],
  );

  if (!rows[0]) throw new Error('Refresh token inválido ou expirado');

  await masterPool.query(`DELETE FROM refresh_tokens WHERE token_hash = $1`, [tokenHash]);

  const { rows: userRows } = await masterPool.query<Pick<UsuarioSafe, 'user_id' | 'email' | 'papel'>>(
    `SELECT user_id, email, papel FROM usuario WHERE user_id = $1 AND ativo = TRUE`,
    [payload.user_id],
  );

  if (!userRows[0]) throw new Error('Usuário não encontrado ou inativo');

  const { user_id, email, papel } = userRows[0];

  const newAccessToken  = signAccessToken({ user_id, email, papel });
  const newRefreshToken = signRefreshToken({ user_id });

  await masterPool.query(
    `INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
     VALUES ($1, $2, $3)`,
    [user_id, hashToken(newRefreshToken), refreshExpiresAt()],
  );

  return { accessToken: newAccessToken, refreshToken: newRefreshToken };
}

/**
 * Logout: revoga o refresh token no servidor.
 */
async function _logoutUsuario(refreshToken: string): Promise<void> {
  await masterPool.query(
    `DELETE FROM refresh_tokens WHERE token_hash = $1`,
    [hashToken(refreshToken)],
  );
}

/**
 * Retorna o perfil do usuario autenticado (sem senha).
 */
async function _getUsuarioById(userId: string): Promise<UsuarioSafe> {
  const { rows } = await masterPool.query<UsuarioSafe>(
    `SELECT user_id, nome_completo, email, cpf, data_nascimento, numero_celular, papel, criado_em, ativo
     FROM usuario
     WHERE user_id = $1 AND ativo = TRUE`,
    [userId],
  );

  if (!rows[0]) throw new Error('Usuário não encontrado');
  return rows[0];
}

/**
 * Atualiza dados não-sensíveis do usuario.
 */
async function _updateUsuario(
  userId: string,
  input: UpdateUsuarioInput,
): Promise<UsuarioSafe> {
  Usuario.validatePartial(input);

  const fields: string[] = [];
  const values: unknown[] = [];
  let idx = 1;

  if (input.nome_completo  != null) { fields.push(`nome_completo = $${idx++}`);  values.push(input.nome_completo); }
  if (input.email          != null) { fields.push(`email = $${idx++}`);           values.push(input.email.toLowerCase()); }
  if (input.numero_celular != null) { fields.push(`numero_celular = $${idx++}`);  values.push(input.numero_celular); }
  if (input.data_nascimento!= null) { fields.push(`data_nascimento = $${idx++}`); values.push(parseDataBrToEn(input.data_nascimento)); }

  if (!fields.length) throw new Error('Nenhum campo para atualizar');

  values.push(userId);

  const { rows } = await masterPool.query<UsuarioSafe>(
    `UPDATE usuario SET ${fields.join(', ')}
     WHERE user_id = $${idx} AND ativo = TRUE
     RETURNING user_id, nome_completo, email, cpf, data_nascimento, numero_celular, papel, criado_em, ativo`,
    values,
  );

  if (!rows[0]) throw new Error('Usuário não encontrado');
  return rows[0];
}

/**
 * Troca a senha do usuario.
 */
async function _changePassword(
  userId: string,
  senhaAtual: string,
  novaSenha: string,
): Promise<void> {
  Usuario.validateNovaSenha(novaSenha);

  const { rows } = await masterPool.query<{ senha: string }>(
    `SELECT senha FROM usuario WHERE user_id = $1 AND ativo = TRUE`,
    [userId],
  );

  if (!rows[0]) throw new Error('Usuário não encontrado');

  const senhaCorreta = await argon2.verify(rows[0].senha, senhaAtual);
  if (!senhaCorreta) throw new Error('Senha atual incorreta');

  const novaSenhaHash = await argon2.hash(novaSenha, ARGON2_OPTIONS);

  await masterPool.query(
    `UPDATE usuario SET senha = $1 WHERE user_id = $2`,
    [novaSenhaHash, userId],
  );

  await masterPool.query(`DELETE FROM refresh_tokens WHERE user_id = $1`, [userId]);
}

/**
 * Desativa a conta do usuario.
 */
async function _deleteUsuario(userId: string): Promise<void> {
  const { rowCount } = await masterPool.query(
    `UPDATE usuario SET ativo = FALSE WHERE user_id = $1 AND ativo = TRUE`,
    [userId],
  );

  if (!rowCount) throw new Error('Usuário não encontrado');

  await masterPool.query(`DELETE FROM refresh_tokens WHERE user_id = $1`, [userId]);
}
