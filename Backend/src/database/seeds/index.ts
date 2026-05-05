/**
 * Orquestrador de Seeds
 *
 * Executa todos os seeds na ordem correta.
 * Para adicionar um novo seed: importe a função e adicione à lista SEEDS abaixo.
 *
 * Uso: npm run db:seed
 */
import 'dotenv/config';
import { masterPool } from '../masterDb';

if (process.env.NODE_ENV === 'production') {
  console.log('[seed] Seeds ignorados em produção');
  process.exit(0);
}

interface SeedEntry {
  name: string;
  run: () => Promise<void>;
}

// ── Ordem de execução ──────────────────────────────────────────────────────
// Cada seed deve exportar uma função assíncrona default ou nomeada.
// Adicione novos seeds respeitando a dependência: hotéis antes de quartos, etc.
const SEEDS: SeedEntry[] = [
  {
    name: 'admin',
    run: async () => {
      const { seedAdmin } = await import('./seed.admin');
      await seedAdmin();
    },
  },
  {
    name: 'hotels',
    run: async () => {
      const { seedHotels } = await import('./seed.hotels');
      await seedHotels();
    },
  },
  {
    name: 'recommendedRooms',
    run: async () => {
      const { seedRecommendedRooms } = await import('./seed.recommendedRooms');
      await seedRecommendedRooms();
    },
  },
  {
    name: 'myRoomsPage',
    run: async () => {
      const { seedMyRoomsPage } = await import('./seed.my-rooms-page');
      await seedMyRoomsPage();
    },
  },
  {
    name: 'reservas',
    run: async () => {
      const { seedReservas } = await import('./seed.reservas');
      await seedReservas();
    },
  },
  {
    name: 'pushFcm',
    run: async () => {
      const { seedPushFcm } = await import('./seed.push-fcm');
      await seedPushFcm();
    },
  },
  {
    name: 'completo',
    run: async () => {
      const { seedCompleto } = await import('./seed.completo');
      await seedCompleto();
    },
  },
];
// ──────────────────────────────────────────────────────────────────────────

async function runAll(): Promise<void> {
  console.log('=== Iniciando todos os seeds ===\n');

  for (const seed of SEEDS) {
    console.log(`\n--- [${seed.name}] ---`);
    try {
      await seed.run();
      console.log(`--- [${seed.name}] concluído ✅`);
    } catch (err: any) {
      console.error(`--- [${seed.name}] falhou ❌: ${err.message}`);
      process.exit(1);
    }
  }

  console.log('\n=== Todos os seeds concluídos ===');
}

runAll()
  .catch((err) => {
    console.error('[seed/index] Erro fatal:', err);
    process.exit(1);
  })
  .finally(() => masterPool.end());
