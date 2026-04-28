/**
 * Seed: Quartos Recomendados
 *
 * Cenários de recomendação cobertos:
 * - Bloco A (3 quartos): nota_media 5.0 — garantidos no topo
 * - Bloco B (5 quartos): nota_media 4.0 — 2 slots sorteados aleatoriamente
 * - Bloco C (3 quartos): nota_media 2.0 — não deve aparecer nas recomendações
 * - Sem avaliação (2 quartos): usados apenas no fallback aleatório
 *
 * Estrutura: para cada quarto avaliado, cria-se uma reserva CONCLUIDA
 * e avaliações vinculadas a ela — seguindo o modelo de dados real.
 *
 * Guard: executar apenas em ambiente de desenvolvimento.
 */
import 'dotenv/config';
import { masterPool } from '../masterDb';
import { withTenant } from '../schemaWrapper';

if (process.env.NODE_ENV === 'production') {
  console.log('[seed/recommendedRooms] Seed ignorado em produção');
  process.exit(0);
}

// Configuração dos blocos de quartos e suas notas
interface BlocoConfig {
  label: string;
  quartos: { numero: string; valor: number }[];
  nota: number | null; // null = sem avaliação
  avaliacoesPorQuarto: number;
}

const BLOCOS: BlocoConfig[] = [
  {
    label: 'Bloco A — nota 5.0 (garantidos no topo)',
    quartos: [
      { numero: 'SEED-A1', valor: 450 },
      { numero: 'SEED-A2', valor: 520 },
      { numero: 'SEED-A3', valor: 480 },
    ],
    nota: 5,
    avaliacoesPorQuarto: 3,
  },
  {
    label: 'Bloco B — nota 4.0 (sorteio entre 5 quartos para 2 slots)',
    quartos: [
      { numero: 'SEED-B1', valor: 350 },
      { numero: 'SEED-B2', valor: 380 },
      { numero: 'SEED-B3', valor: 420 },
      { numero: 'SEED-B4', valor: 360 },
      { numero: 'SEED-B5', valor: 400 },
    ],
    nota: 4,
    avaliacoesPorQuarto: 2,
  },
  {
    label: 'Bloco C — nota 2.0 (não deve aparecer)',
    quartos: [
      { numero: 'SEED-C1', valor: 200 },
      { numero: 'SEED-C2', valor: 220 },
      { numero: 'SEED-C3', valor: 180 },
    ],
    nota: 2,
    avaliacoesPorQuarto: 1,
  },
  {
    label: 'Sem avaliação (fallback aleatório)',
    quartos: [
      { numero: 'SEED-N1', valor: 280 },
      { numero: 'SEED-N2', valor: 310 },
    ],
    nota: null,
    avaliacoesPorQuarto: 0,
  },
];

async function seedRecommendedRooms(): Promise<void> {
  // Busca hotel ativo para inserir os quartos de seed
  const { rows: hoteis } = await masterPool.query<{ hotel_id: string; schema_name: string }>(
    `SELECT hotel_id, schema_name FROM anfitriao WHERE ativo = TRUE LIMIT 1`
  );

  if (!hoteis.length) {
    console.warn('[seed/recommendedRooms] Nenhum hotel ativo encontrado — rode seed-hotel.ts primeiro');
    process.exit(1);
  }

  const hotel = hoteis[0];
  console.log(`[seed/recommendedRooms] Hotel alvo: ${hotel.hotel_id} (${hotel.schema_name})`);

  await withTenant(hotel.schema_name, async (client) => {
    // Busca categoria existente no tenant
    const { rows: categorias } = await client.query<{ id: number }>(
      `SELECT id FROM categoria_quarto WHERE deleted_at IS NULL LIMIT 1`
    );

    if (!categorias.length) {
      console.warn('[seed/recommendedRooms] Nenhuma categoria encontrada no tenant — seed abortado');
      return;
    }

    const catId = categorias[0].id;

    // Garante um usuário para testes (para avaliações)
    const { rows: userRows } = await masterPool.query<{ user_id: string }>(
      `INSERT INTO usuario (nome_completo, email, senha, cpf, data_nascimento) 
       VALUES ('Hóspede Seed', 'hospede_seed@example.com', 'dummy_hash', '00000000000', '1990-01-01') 
       ON CONFLICT (email) DO UPDATE SET nome_completo = EXCLUDED.nome_completo
       RETURNING user_id`
    );
    const mockUserId = userRows[0].user_id;

    // Garante hospede no schema do hotel
    await client.query(
      `INSERT INTO hospede (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING`,
      [mockUserId]
    );

    for (const bloco of BLOCOS) {
      console.log(`\n[seed] ${bloco.label}`);

      for (const q of bloco.quartos) {
        // Insere ou atualiza o quarto no schema do tenant
        await client.query(
          `INSERT INTO quarto (numero, categoria_quarto_id, valor_override, disponivel)
           VALUES ($1, $2, $3, TRUE)
           ON CONFLICT (numero) DO UPDATE SET valor_override = EXCLUDED.valor_override`,
          [q.numero, catId, q.valor]
        );

        // Busca ID do quarto inserido
        const { rows: quartoRows } = await client.query<{ id: number }>(
          `SELECT id FROM quarto WHERE numero = $1 LIMIT 1`,
          [q.numero]
        );

        if (!quartoRows.length) {
          console.warn(`[seed] Quarto ${q.numero} não encontrado após insert`);
          continue;
        }

        const quartoId = quartoRows[0].id;

        // Quartos sem avaliação: apenas insere o quarto, sem reserva nem avaliação
        if (bloco.nota === null) {
          console.log(`  [seed] Quarto ${q.numero} (id=${quartoId}) inserido sem avaliação`);
          continue;
        }

        // Cria reservas CONCLUIDAS e avaliações vinculadas para demonstrar o ranking
        for (let i = 0; i < bloco.avaliacoesPorQuarto; i++) {
          // Insere reserva com status CONCLUIDA para que a avaliação seja elegível
          const { rows: reservaRows } = await client.query<{ id: number }>(
            `INSERT INTO reserva
               (quarto_id, user_id, num_hospedes, data_checkin, data_checkout, status, canal_origem, valor_total, codigo_publico)
             VALUES
               ($1, $2, 1, '2025-01-01', '2025-01-02', 'CONCLUIDA', 'APP', $3, gen_random_uuid())
             RETURNING id`,
            [quartoId, mockUserId, q.valor]
          );

          if (!reservaRows.length) continue;

          const reservaId = reservaRows[0].id;
          const nota = bloco.nota as number;

          // Insere avaliação vinculada à reserva CONCLUIDA
          await client.query(
            `INSERT INTO avaliacao
               (user_id, reserva_id, nota_limpeza, nota_atendimento, nota_conforto, nota_organizacao, nota_localizacao, nota_total)
             VALUES ($1, $2, $3, $3, $3, $3, $3, $3)
             ON CONFLICT DO NOTHING`,
            [mockUserId, reservaId, nota]
          );
        }

        console.log(
          `  [seed] Quarto ${q.numero} (id=${quartoId}) — ${bloco.avaliacoesPorQuarto} reserva(s) + avaliação(ões) com nota ${bloco.nota}`
        );
      }
    }

    console.log('\n[seed/recommendedRooms] Seed concluído com sucesso');
  });
}

seedRecommendedRooms()
  .catch((err) => {
    console.error('[seed/recommendedRooms] Erro fatal:', err);
    process.exit(1);
  })
  .finally(() => masterPool.end());
