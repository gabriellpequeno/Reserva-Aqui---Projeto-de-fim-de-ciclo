import { Pool } from 'pg';

// Pool por nome de banco — carregados sob demanda (lazy)
const tenantPools = new Map<string, Pool>();

/**
 * Retorna (ou cria) o Pool de conexão para um banco tenant específico.
 * @param dbName  Nome do banco PostgreSQL do hotel (ex: "hotel_grand_hyatt_a1b2c3d4")
 */
export function getTenantPool(dbName: string): Pool {
  if (!tenantPools.has(dbName)) {
    const pool = new Pool({
      host:     process.env.DB_HOST     ?? 'localhost',
      port:     Number(process.env.DB_PORT ?? 5432),
      user:     process.env.DB_USER     ?? 'postgres',
      password: process.env.DB_PASSWORD,
      database: dbName,
      max:      Number(process.env.DB_TENANT_MAX_CONNECTIONS ?? 5),
      idleTimeoutMillis:       30_000,
      connectionTimeoutMillis:  5_000,
    });

    pool.on('error', (err) => {
      console.error(`[TenantPool:${dbName}] Pool error:`, err.message);
    });

    tenantPools.set(dbName, pool);
    console.log(`[TenantPool] Pool criado para: ${dbName}`);
  }

  return tenantPools.get(dbName)!;
}

/** Fecha e remove o pool de um tenant específico. */
export async function closeTenantPool(dbName: string): Promise<void> {
  const pool = tenantPools.get(dbName);
  if (pool) {
    await pool.end();
    tenantPools.delete(dbName);
    console.log(`[TenantPool] Pool encerrado: ${dbName}`);
  }
}

/** Fecha todos os pools tenant (usar no graceful shutdown). */
export async function closeAllTenantPools(): Promise<void> {
  const jobs = [...tenantPools.entries()].map(async ([name, pool]) => {
    await pool.end();
    console.log(`[TenantPool] Pool encerrado: ${name}`);
  });
  await Promise.all(jobs);
  tenantPools.clear();
}
