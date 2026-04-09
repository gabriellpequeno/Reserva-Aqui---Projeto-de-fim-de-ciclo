import { v4 as uuidv4 } from 'uuid';
import bcrypt from 'bcrypt';
import { masterPool } from '../../database/masterDb';
import { getTenantPool } from '../../database/tenantPool';
import { provisionTenant } from '../../database/tenantManager';

// ── Tipos ─────────────────────────────────────────────────────────────────────

export interface RegisterHotelInput {
  nome:       string;
  cnpj:       string;
  email:      string;
  senha:      string;
  cep:        string;
  uf:         string;
  cidade:     string;
  bairro:     string;
  rua:        string;
  numero:     string;
  descricao?: string;
  path?:      string;  // caminho da logo/imagem
}

export interface HotelRegistrado {
  hotel_id:   string;
  nome:       string;
  email:      string;
  db_name:    string;
  criado_em:  Date;
}

// ── Funções ───────────────────────────────────────────────────────────────────

/**
 * Registra um novo hotel:
 *  1. Gera UUID
 *  2. Faz hash da senha
 *  3. Provisiona banco tenant (pasta + DB PostgreSQL + schema)
 *  4. Insere na tabela `anfitriao` do master DB
 */
export async function registerHotel(
  input: RegisterHotelInput,
): Promise<HotelRegistrado> {
  const hotelId    = uuidv4();
  const senhaHash  = await bcrypt.hash(input.senha, 12);

  // Provisiona: cria pasta bancos/{id}_{nome}/ e o banco PostgreSQL
  const { dbName, dirPath } = await provisionTenant(hotelId, input.nome);

  // Registra o hotel no master DB
  const { rows } = await masterPool.query<HotelRegistrado>(
    `INSERT INTO anfitriao (
       hotel_id, nome, cnpj, email, senha,
       cep, uf, cidade, bairro, rua, numero,
       descricao, path, db_name, db_dir
     ) VALUES (
       $1,  $2,  $3,  $4,  $5,
       $6,  $7,  $8,  $9,  $10, $11,
       $12, $13, $14, $15
     ) RETURNING hotel_id, nome, email, db_name, criado_em`,
    [
      hotelId,     input.nome,   input.cnpj,     input.email, senhaHash,
      input.cep,   input.uf,     input.cidade,   input.bairro, input.rua, input.numero,
      input.descricao ?? null,   input.path ?? null,
      dbName,      dirPath,
    ],
  );

  return rows[0];
}

/**
 * Busca o nome do banco (db_name) de um hotel pelo seu UUID.
 * Usado por middlewares que precisam rotear queries para o tenant correto.
 */
export async function getHotelDbName(hotelId: string): Promise<string | null> {
  const { rows } = await masterPool.query<{ db_name: string }>(
    `SELECT db_name FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  return rows[0]?.db_name ?? null;
}

/**
 * Retorna o Pool de conexão do tenant de um hotel.
 * Throws se o hotel não existir ou estiver inativo.
 */
export async function getHotelPool(hotelId: string) {
  const dbName = await getHotelDbName(hotelId);

  if (!dbName) {
    throw new Error(`Hotel não encontrado ou inativo: ${hotelId}`);
  }

  return getTenantPool(dbName);
}
