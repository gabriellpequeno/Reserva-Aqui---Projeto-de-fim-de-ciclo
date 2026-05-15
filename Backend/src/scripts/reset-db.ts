import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { Pool } from 'pg';

const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     Number(process.env.DB_PORT) || 5432,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_MASTER_NAME,
});

const INIT_MASTER_SQL = path.resolve(
  __dirname,
  '../../database/scripts/init_master.sql',
);

const MASTER_TABLES = [
  'saldo_transacao',
  'mensagem_chat',
  'sessao_chat',
  'historico_reserva_global',
  'reserva_routing',
  'hotel_favorito',
  'foto_hotel',
  'dispositivo_fcm',
  'hotel_refresh_tokens',
  'refresh_tokens',
  'anfitriao',
  'usuario',
];

async function reset(): Promise<void> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Drop all hotel tenant schemas
    const { rows: schemas } = await client.query<{ schema_name: string }>(
      `SELECT schema_name FROM information_schema.schemata
       WHERE schema_name LIKE 'hotel_%' OR schema_name LIKE 'schema_hotel_%'`,
    );

    for (const { schema_name } of schemas) {
      await client.query(`DROP SCHEMA IF EXISTS "${schema_name}" CASCADE`);
      console.log(`  schema removido: ${schema_name}`);
    }

    // Only truncate tables that actually exist
    const { rows: existing } = await client.query<{ tablename: string }>(
      `SELECT tablename FROM pg_tables
       WHERE schemaname = 'public' AND tablename = ANY($1)`,
      [MASTER_TABLES],
    );

    const toTruncate = existing.map((r) => `"${r.tablename}"`).join(', ');

    if (toTruncate) {
      await client.query(`TRUNCATE ${toTruncate} RESTART IDENTITY CASCADE`);
      console.log(`  tabelas limpas: ${existing.map((r) => r.tablename).join(', ')}`);
    }

    // Garante que o schema master está aplicado — idempotente via IF NOT EXISTS,
    // então roda tanto em banco vazio (cria tudo) quanto em banco populado (no-op).
    const initSql = fs.readFileSync(INIT_MASTER_SQL, 'utf-8');
    await client.query(initSql);
    console.log('  schema master aplicado (init_master.sql)');

    await client.query('COMMIT');
    console.log('Banco resetado com sucesso.');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

reset().catch((err) => {
  console.error('Erro ao resetar banco:', err.message);
  process.exit(1);
});
