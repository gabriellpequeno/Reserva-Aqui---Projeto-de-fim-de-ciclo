import { v4 as uuidv4 } from 'uuid';
import bcrypt from 'bcrypt';
import { masterPool } from '../../database/masterDb';
import { buildSchemaName, provisionTenant } from '../../database/tenantManager';
import { withTenant } from '../../database/schemaWrapper';
import { PoolClient } from 'pg';

export interface RegisterHotelInput {
  nome:       string;
  cnpj:       string;
  telefone:   string;
  email:      string;
  senha:      string;
  cep:        string;
  uf:         string;
  cidade:     string;
  bairro:     string;
  rua:        string;
  numero:     string;
  descricao?: string;
  path?:      string;
}

export interface HotelRegistrado {
  hotel_id:    string;
  nome_hotel:  string;
  email:       string;
  schema_name: string;
  criado_em:   Date;
}

export async function registerHotel(
  input: RegisterHotelInput,
): Promise<HotelRegistrado> {
  const hotelId    = uuidv4();
  const senhaHash  = await bcrypt.hash(input.senha, 12);
  const schemaName = buildSchemaName(hotelId, input.nome);

  // Provisiona: cria schema logic no banco Master e constrói as tabelas daquele hotel
  await provisionTenant(schemaName);

  // Registra o hotel no master DB
  const { rows } = await masterPool.query<HotelRegistrado>(
    `INSERT INTO anfitriao (
       hotel_id, nome_hotel, cnpj, telefone, email, senha,
       cep, uf, cidade, bairro, rua, numero,
       descricao, cover_storage_path, schema_name
     ) VALUES (
       $1,  $2,  $3,  $4,  $5,  $6,
       $7,  $8,  $9,  $10, $11, $12,
       $13, $14, $15
     ) RETURNING hotel_id, nome_hotel, email, schema_name, criado_em`,
    [
      hotelId,     input.nome,   input.cnpj,     input.telefone, input.email, senhaHash,
      input.cep,   input.uf,     input.cidade,   input.bairro,   input.rua,   input.numero,
      input.descricao ?? null,   input.path ?? null,
      schemaName,
    ],
  );

  return rows[0];
}

export async function getHotelSchemaName(hotelId: string): Promise<string | null> {
  const { rows } = await masterPool.query<{ schema_name: string }>(
    `SELECT schema_name FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  return rows[0]?.schema_name ?? null;
}

/**
 * Função utilitária central.
 * Executa uma query de banco de dados magicamente injetada 
 * no schema correto sabendo apenas o ID do Hotel apontado.
 */
export async function executeInHotelDb<T>(
  hotelId: string, 
  callback: (client: PoolClient) => Promise<T>
): Promise<T> {
  const schemaName = await getHotelSchemaName(hotelId);
  if (!schemaName) {
    throw new Error(`Hotel não encontrado ou inativo: ${hotelId}`);
  }
  return withTenant(schemaName, callback);
}
