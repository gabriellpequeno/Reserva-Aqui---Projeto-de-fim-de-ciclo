import { Client } from 'pg';
import fs from 'fs';
import path from 'path';

// ── Caminhos base ─────────────────────────────────────────────────────────────

const BANCOS_BASE_DIR = path.resolve(
  process.env.BANCOS_DIR ?? path.join(process.cwd(), '..', 'bancos'),
);

const INIT_TENANT_SQL = path.resolve(
  __dirname,
  '../../database/scripts/init_tenant.sql',
);

// ── Helpers de nomenclatura ───────────────────────────────────────────────────

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
 * Nome da pasta dentro de /bancos.
 * Formato: {8 chars do UUID sem hífens}_{nome_sanitizado}
 * Exemplo: "a1b2c3d4_grand_hyatt_rio"
 */
export function buildTenantDirName(hotelId: string, hotelName: string): string {
  const shortId = hotelId.replace(/-/g, '').slice(0, 8);
  return `${shortId}_${sanitize(hotelName)}`;
}

/**
 * Nome do banco PostgreSQL do tenant.
 * Formato: hotel_{nome_sanitizado}_{8 chars UUID}
 * Deve ser único e válido como identificador SQL (sem hífens, lowercase).
 */
export function buildTenantDbName(hotelId: string, hotelName: string): string {
  const shortId = hotelId.replace(/-/g, '').slice(0, 8);
  return `hotel_${sanitize(hotelName)}_${shortId}`;
}

// ── Funções internas ──────────────────────────────────────────────────────────

/** Conecta ao banco 'postgres' (default) para executar CREATE DATABASE. */
function createAdminClient(): Client {
  return new Client({
    host:     process.env.DB_HOST     ?? 'localhost',
    port:     Number(process.env.DB_PORT ?? 5432),
    user:     process.env.DB_USER     ?? 'postgres',
    password: process.env.DB_PASSWORD,
    database: 'postgres',
  });
}

/** Conecta ao banco tenant recém-criado para rodar o schema. */
function createTenantClient(dbName: string): Client {
  return new Client({
    host:     process.env.DB_HOST     ?? 'localhost',
    port:     Number(process.env.DB_PORT ?? 5432),
    user:     process.env.DB_USER     ?? 'postgres',
    password: process.env.DB_PASSWORD,
    database: dbName,
  });
}

/**
 * Cria o banco PostgreSQL se ainda não existir.
 * CREATE DATABASE não pode ser executado em transação, por isso usa Client direto.
 */
async function ensureTenantDatabase(dbName: string): Promise<void> {
  const client = createAdminClient();
  await client.connect();

  try {
    const { rowCount } = await client.query(
      `SELECT 1 FROM pg_database WHERE datname = $1`,
      [dbName],
    );

    if (!rowCount) {
      // Interpolação segura: dbName é gerado internamente (apenas a-z, 0-9, _)
      await client.query(`CREATE DATABASE "${dbName}"`);
      console.log(`[TenantManager] Banco criado: ${dbName}`);
    } else {
      console.warn(`[TenantManager] Banco já existia: ${dbName}`);
    }
  } finally {
    await client.end();
  }
}

/**
 * Conecta ao banco tenant e executa o init_tenant.sql inteiro.
 * Registra resultado em migrations.log dentro da pasta do tenant.
 */
async function runInitSchema(dbName: string, tenantDir: string): Promise<void> {
  const initSql = fs.readFileSync(INIT_TENANT_SQL, 'utf-8');
  const client  = createTenantClient(dbName);

  await client.connect();

  try {
    await client.query(initSql);

    const logLine = `[${new Date().toISOString()}] init_tenant.sql aplicado com sucesso em "${dbName}"\n`;
    fs.appendFileSync(path.join(tenantDir, 'migrations.log'), logLine, 'utf-8');
    console.log(`[TenantManager] Schema iniciado: ${dbName}`);
  } finally {
    await client.end();
  }
}

// ── API Pública ───────────────────────────────────────────────────────────────

export interface ProvisionResult {
  dbName:  string;  // nome do banco PostgreSQL
  dirName: string;  // nome da subpasta em bancos/
  dirPath: string;  // caminho absoluto da pasta
}

/**
 * Provisiona um novo tenant para um hotel recém-registrado.
 *
 * O que faz:
 *  1. Cria a pasta  bancos/{shortId}_{nome}/
 *  2. Salva tenant.json com metadados
 *  3. Cria um banco PostgreSQL exclusivo para o hotel
 *  4. Executa init_tenant.sql no novo banco (cria todas as tabelas)
 *
 * @param hotelId    UUID do hotel (gerado antes de chamar esta função)
 * @param hotelName  Nome do hotel (ex: "Grand Hyatt Rio")
 */
export async function provisionTenant(
  hotelId:   string,
  hotelName: string,
): Promise<ProvisionResult> {
  const dirName   = buildTenantDirName(hotelId, hotelName);
  const dbName    = buildTenantDbName(hotelId, hotelName);
  const tenantDir = path.join(BANCOS_BASE_DIR, dirName);

  // 1. Criar diretório  bancos/{id}_{nome}/
  fs.mkdirSync(tenantDir, { recursive: true });

  // 2. Persistir metadados do tenant
  const metadata = { hotelId, hotelName, dbName, dirName, provisionedAt: new Date().toISOString() };
  fs.writeFileSync(
    path.join(tenantDir, 'tenant.json'),
    JSON.stringify(metadata, null, 2),
    'utf-8',
  );

  // 3. Criar banco PostgreSQL
  await ensureTenantDatabase(dbName);

  // 4. Rodar schema de inicialização
  await runInitSchema(dbName, tenantDir);

  return { dbName, dirName, dirPath: tenantDir };
}

/**
 * Remove o banco de dados de um tenant.
 * ⚠️  IRREVERSÍVEL — use apenas para desativação definitiva de um hotel.
 */
export async function deprovisionTenant(dbName: string): Promise<void> {
  const client = createAdminClient();
  await client.connect();

  try {
    // Encerra conexões ativas antes de dropar
    await client.query(
      `SELECT pg_terminate_backend(pid)
       FROM   pg_stat_activity
       WHERE  datname = $1 AND pid <> pg_backend_pid()`,
      [dbName],
    );

    await client.query(`DROP DATABASE IF EXISTS "${dbName}"`);
    console.log(`[TenantManager] Banco removido: ${dbName}`);
  } finally {
    await client.end();
  }
}
