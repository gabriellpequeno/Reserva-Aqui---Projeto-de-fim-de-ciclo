import { Pool } from 'pg';

/**
 * Pool de conexão com o banco MASTER.
 * Contém: anfitriao, usuario (tabelas globais).
 * Cada query que não é tenant-específica usa este pool.
 */
export const masterPool = new Pool({
  host:     process.env.DB_HOST     ?? 'localhost',
  port:     Number(process.env.DB_PORT ?? 5432),
  user:     process.env.DB_USER     ?? 'postgres',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_MASTER_NAME ?? 'reservaqui_master',
  max:                    10,
  idleTimeoutMillis:  30_000,
  connectionTimeoutMillis: 5_000,
});

masterPool.on('error', (err) => {
  console.error('[MasterDB] Unexpected pool error:', err.message);
});
