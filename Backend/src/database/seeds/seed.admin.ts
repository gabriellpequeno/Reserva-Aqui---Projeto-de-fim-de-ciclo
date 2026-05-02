/**
 * Seed: Admin inicial
 *
 * Feature: admin-account-management (Fase 1)
 *
 * Cria um usuário admin inicial para a plataforma, necessário para:
 * - Acessar `AdminProfilePage` com dados reais
 * - Acessar `/admin/accounts` (gerenciamento de contas)
 *
 * Idempotente via `ON CONFLICT (email) DO NOTHING` — seguro executar múltiplas vezes.
 *
 * Credenciais são lidas de variáveis de ambiente (com defaults de demonstração):
 *   - ADMIN_SEED_EMAIL    (default: admin@reservaqui.dev)
 *   - ADMIN_SEED_SENHA    (default: Admin@2026)
 *   - ADMIN_SEED_NOME     (default: Admin Reserva Aqui)
 *   - ADMIN_SEED_CPF      (default: 00000000000)
 *   - ADMIN_SEED_NASC     (default: 1990-01-01)
 *
 * Diferente dos demais seeds, este NÃO é bloqueado em produção — admin seedado
 * é necessário em qualquer ambiente para a feature funcionar. Segurança é delegada
 * à rotação de senha pós-deploy e à idempotência do `ON CONFLICT`.
 *
 * Uso direto: `ts-node src/database/seeds/seed.admin.ts`
 * Ou via orquestrador: incluído em `seeds/index.ts`.
 */
import 'dotenv/config';
import argon2 from 'argon2';
import { masterPool } from '../masterDb';

const ADMIN_EMAIL = process.env.ADMIN_SEED_EMAIL ?? 'admin@reservaqui.dev';
const ADMIN_SENHA = process.env.ADMIN_SEED_SENHA ?? 'Admin@2026';
const ADMIN_NOME  = process.env.ADMIN_SEED_NOME  ?? 'Admin Reserva Aqui';
const ADMIN_CPF   = process.env.ADMIN_SEED_CPF   ?? '00000000000';
const ADMIN_NASC  = process.env.ADMIN_SEED_NASC  ?? '1990-01-01';

const ARGON2_OPTIONS: argon2.Options = {
  type:        argon2.argon2id,
  memoryCost:  process.env.ARGON2_MEMORY_COST ? parseInt(process.env.ARGON2_MEMORY_COST, 10) : 65536,
  timeCost:    process.env.ARGON2_TIME_COST   ? parseInt(process.env.ARGON2_TIME_COST, 10)   : 3,
  parallelism: process.env.ARGON2_PARALLELISM ? parseInt(process.env.ARGON2_PARALLELISM, 10) : 1,
};

export async function seedAdmin(): Promise<void> {
  console.log('--- Iniciando Seed de Admin ---');

  const senhaHash = await argon2.hash(ADMIN_SENHA, ARGON2_OPTIONS);

  const { rowCount, rows } = await masterPool.query<{ user_id: string; email: string; papel: string }>(
    `INSERT INTO usuario
       (nome_completo, email, senha, cpf, data_nascimento, papel, ativo)
     VALUES ($1, $2, $3, $4, $5, 'admin', TRUE)
     ON CONFLICT (email) DO NOTHING
     RETURNING user_id, email, papel`,
    [ADMIN_NOME, ADMIN_EMAIL.toLowerCase(), senhaHash, ADMIN_CPF, ADMIN_NASC],
  );

  if (rowCount && rows[0]) {
    console.log(`  ✅ Admin criado: ${rows[0].email} (papel: ${rows[0].papel})`);
  } else {
    const { rows: existing } = await masterPool.query<{ user_id: string; papel: string }>(
      `SELECT user_id, papel FROM usuario WHERE email = $1`,
      [ADMIN_EMAIL.toLowerCase()],
    );

    if (existing[0]?.papel !== 'admin') {
      console.log(
        `  ⚠️  Email ${ADMIN_EMAIL} já existe mas com papel "${existing[0]?.papel}" — promovendo a 'admin'`,
      );
      await masterPool.query(
        `UPDATE usuario SET papel = 'admin' WHERE email = $1`,
        [ADMIN_EMAIL.toLowerCase()],
      );
      console.log(`  ✅ Admin promovido: ${ADMIN_EMAIL}`);
    } else {
      console.log(`  ⚠️  Admin ${ADMIN_EMAIL} já existe (ignorado)`);
    }
  }

  console.log('--- Seed de Admin Finalizado ---');
}

if (require.main === module) {
  seedAdmin()
    .catch((err) => {
      console.error('[seed/admin] Erro fatal:', err);
      process.exit(1);
    })
    .finally(async () => {
      await masterPool.end();
      process.exit(0);
    });
}
