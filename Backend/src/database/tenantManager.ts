import fs from 'fs';
import path from 'path';
import { masterPool } from './masterDb';

const INIT_TENANT_SQL = path.resolve(
  __dirname,
  '../../database/scripts/init_tenant.sql',
);

/**
 * Remove acentos, espaços e caracteres especiais de uma string,
 * retornando somente letras minúsculas, dígitos e underscores.
 */
function sanitize(name: string): string {
  return name
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')   // remove acentos
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '_')        // qualquer outro char → _
    .replace(/_+/g, '_')               // colapsa múltiplos _
    .replace(/^_+|_+$/g, '')           // remove _ no início/fim
    .slice(0, 40);
}

/**
 * Nome do schema lógico do tenant.
 * Formato: schema_hotel_{nome_sanitizado}_{8 chars UUID}
 */
export function buildSchemaName(hotelId: string, hotelName: string): string {
  const shortId = hotelId.replace(/-/g, '').slice(0, 8);
  return `schema_hotel_${sanitize(hotelName)}_${shortId}`;
}

export interface ProvisionResult {
  schemaName: string;
}

/**
 * Provisiona um novo tenant lógico (Schema) para um hotel recém-registrado.
 *
 * O que faz:
 *  1. Cria o Schema no banco Mestre
 *  2. Executa init_tenant.sql dentro do escopo deste Schema
 */
export async function provisionTenant(schemaName: string): Promise<ProvisionResult> {

  // Lê o script do tenant
  const initSql = fs.readFileSync(INIT_TENANT_SQL, 'utf-8');

  // Adquire um client exclusivo do pool mestre
  const client = await masterPool.connect();

  try {
    // Transaction
    await client.query('BEGIN');
    
    // Cria o schema
    await client.query(`CREATE SCHEMA IF NOT EXISTS "${schemaName}"`);
    console.log(`[TenantManager] Schema criado: ${schemaName}`);

    // Alterna o contexto desta conexão para o schema criado
    await client.query(`SET search_path TO "${schemaName}"`);

    // Executa as tabelas
    await client.query(initSql);
    console.log(`[TenantManager] Tabelas aplicadas no schema: ${schemaName}`);

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    // O pulo do gato: Limpar o search_path antes de devolver o client pro Pool!
    await client.query('RESET search_path');
    client.release();
  }

  return { schemaName };
}

/**
 * Remove o schema de um tenant.
 * ⚠️  IRREVERSÍVEL — use apenas para desativação definitiva de um hotel.
 */
export async function deprovisionTenant(schemaName: string): Promise<void> {
  const client = await masterPool.connect();
  try {
    await client.query(`DROP SCHEMA IF EXISTS "${schemaName}" CASCADE`);
    console.log(`[TenantManager] Schema removido: ${schemaName}`);
  } finally {
    client.release();
  }
}
