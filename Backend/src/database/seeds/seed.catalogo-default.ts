/**
 * Popula o catálogo padrão de comodidades em todos os schemas de tenant existentes.
 * Seguro para rodar múltiplas vezes (ON CONFLICT DO NOTHING).
 *
 * Uso: ts-node --transpile-only src/database/seeds/seed.catalogo-default.ts
 */

import { masterPool } from '../masterDb';
import { withTenant }  from '../schemaWrapper';

const CATALOGO_ITENS = [
  { nome: 'Wi-Fi',              categoria: 'COMODIDADE' },
  { nome: 'Ar-condicionado',    categoria: 'COMODIDADE' },
  { nome: 'TV a cabo',          categoria: 'COMODIDADE' },
  { nome: 'Frigobar',           categoria: 'COMODIDADE' },
  { nome: 'Cofre digital',      categoria: 'COMODIDADE' },
  { nome: 'Cama king-size',     categoria: 'COMODO'     },
  { nome: 'Cama queen-size',    categoria: 'COMODO'     },
  { nome: 'Cama de solteiro',   categoria: 'COMODO'     },
  { nome: 'Banheiro privativo', categoria: 'COMODO'     },
  { nome: 'Varanda',            categoria: 'COMODO'     },
  { nome: 'Piscina',            categoria: 'LAZER'      },
  { nome: 'Academia',           categoria: 'LAZER'      },
  { nome: 'Spa',                categoria: 'LAZER'      },
  { nome: 'Restaurante',        categoria: 'LAZER'      },
];

async function run(): Promise<void> {
  const { rows: hoteis } = await masterPool.query<{ schema_name: string; hotel_id: string; nome_hotel: string }>(
    `SELECT schema_name, hotel_id, nome_hotel FROM anfitriao WHERE ativo = TRUE ORDER BY nome_hotel`,
  );

  console.log(`[seed] ${hoteis.length} hotel(s) encontrado(s)\n`);

  for (const hotel of hoteis) {
    process.stdout.write(`  ⏳ ${hotel.nome_hotel} (${hotel.schema_name})... `);
    try {
      await withTenant(hotel.schema_name, async (client) => {
        const values = CATALOGO_ITENS.map((_, i) => `($${i * 2 + 1}, $${i * 2 + 2})`).join(', ');
        const params = CATALOGO_ITENS.flatMap(item => [item.nome, item.categoria]);
        const { rowCount } = await client.query(
          `INSERT INTO catalogo (nome, categoria) VALUES ${values} ON CONFLICT (nome, categoria) DO NOTHING`,
          params,
        );
        console.log(`${rowCount} item(s) inserido(s)`);
      });
    } catch (err) {
      console.log(`❌ erro: ${(err as Error).message}`);
    }
  }

  console.log('\n[seed] Concluído.');
  await masterPool.end();
}

run().catch(err => {
  console.error('[seed] Falha fatal:', err);
  process.exit(1);
});
