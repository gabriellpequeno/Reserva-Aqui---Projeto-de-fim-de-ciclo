/**
 * Seed: Reservas variadas para popular Dashboards
 *
 * Cria ~15 reservas por hotel distribuídas em:
 *   - Check-ins de hoje (reservasHoje > 0)
 *   - Próximos check-ins nos próximos 7 dias
 *   - Reservas ativas (APROVADA com intervalo cobrindo hoje → topHoteis, ocupação)
 *   - Reservas concluídas/canceladas/solicitadas no mês corrente (breakdown + receita)
 *
 * Também marca ~40% dos quartos como `disponivel = false` para a métrica de
 * ocupacaoPercentual aparecer.
 *
 * Idempotente: remove reservas previamente seedadas (observacoes = '[seed-dashboard]')
 * antes de inserir novas — seguro rodar múltiplas vezes.
 *
 * Respeita o double-write em historico_reserva_global (master) para o Admin
 * Dashboard enxergar os dados agregados.
 *
 * Guard: ignorado em produção.
 */
import 'dotenv/config';
import { masterPool } from '../masterDb';
import { withTenant } from '../schemaWrapper';

if (process.env.NODE_ENV === 'production') {
  console.log('[seed/reservas] Seed ignorado em produção');
  process.exit(0);
}

type Status =
  | 'SOLICITADA'
  | 'AGUARDANDO_PAGAMENTO'
  | 'APROVADA'
  | 'CANCELADA'
  | 'CONCLUIDA';

interface ReservaPlan {
  daysFromToday: number;    // offset de data_checkin em dias
  nights: number;           // duração em noites
  status: Status;
  valor: number;
  numHospedes: number;
}

/**
 * Plano de reservas aplicado em cada hotel. Cobre métricas relevantes:
 * - 2 hoje (APROVADA) → reservasHoje + ocupação
 * - 3 próximos dias (APROVADA/AGUARDANDO_PAGAMENTO) → próximosCheckins
 * - 2 ativas (começaram antes, terminam depois de hoje) → topHoteis do admin
 * - 4 concluídas no mês → receitaPeriodo + reservasPorStatus
 * - 2 canceladas → reservasPorStatus
 * - 2 solicitadas recentes → reservasPorStatus
 */
const RESERVAS_PLAN: ReservaPlan[] = [
  // Hoje
  { daysFromToday:   0, nights: 2, status: 'APROVADA',              valor:  380, numHospedes: 2 },
  { daysFromToday:   0, nights: 1, status: 'APROVADA',              valor:  240, numHospedes: 1 },
  // Próximos 7 dias
  { daysFromToday:   1, nights: 3, status: 'APROVADA',              valor:  650, numHospedes: 2 },
  { daysFromToday:   3, nights: 2, status: 'AGUARDANDO_PAGAMENTO',  valor:  420, numHospedes: 3 },
  { daysFromToday:   6, nights: 4, status: 'APROVADA',              valor:  890, numHospedes: 4 },
  // Ativas (já check-in, check-out ainda não)
  { daysFromToday:  -1, nights: 3, status: 'APROVADA',              valor:  540, numHospedes: 2 },
  { daysFromToday:  -2, nights: 5, status: 'APROVADA',              valor: 1100, numHospedes: 4 },
  // Concluídas no mês
  { daysFromToday: -12, nights: 2, status: 'CONCLUIDA',             valor:  380, numHospedes: 2 },
  { daysFromToday: -18, nights: 4, status: 'CONCLUIDA',             valor:  820, numHospedes: 3 },
  { daysFromToday: -22, nights: 1, status: 'CONCLUIDA',             valor:  210, numHospedes: 1 },
  { daysFromToday: -28, nights: 3, status: 'CONCLUIDA',             valor:  650, numHospedes: 2 },
  // Canceladas
  { daysFromToday:  -5, nights: 2, status: 'CANCELADA',             valor:  380, numHospedes: 2 },
  { daysFromToday: -15, nights: 1, status: 'CANCELADA',             valor:  220, numHospedes: 1 },
  // Solicitadas recentes (aguardando aprovação)
  { daysFromToday:   8, nights: 2, status: 'SOLICITADA',            valor:  410, numHospedes: 2 },
  { daysFromToday:  12, nights: 3, status: 'SOLICITADA',            valor:  690, numHospedes: 3 },
];

const OBS_MARKER = '[seed-dashboard]';

function addDays(base: Date, days: number): string {
  const d = new Date(base);
  d.setDate(d.getDate() + days);
  return d.toISOString().slice(0, 10);
}

export async function seedReservas(): Promise<void> {
  console.log('--- Iniciando Seed de Reservas ---\n');

  // 1. Usuário seed (criado em seed.hotels)
  const { rows: userRows } = await masterPool.query<{ user_id: string }>(
    `SELECT user_id FROM usuario WHERE email = $1`,
    ['seed@reservaqui.dev'],
  );
  if (!userRows.length) {
    console.error('[seed/reservas] Usuário seed@reservaqui.dev não existe. Rode seed.hotels primeiro.');
    return;
  }
  const seedUserId = userRows[0].user_id;

  // 2. Hotéis ativos
  const { rows: hotels } = await masterPool.query<{
    hotel_id: string;
    nome_hotel: string;
    schema_name: string;
  }>(
    `SELECT hotel_id, nome_hotel, schema_name FROM anfitriao WHERE ativo = TRUE ORDER BY criado_em`,
  );

  if (!hotels.length) {
    console.warn('[seed/reservas] Nenhum hotel encontrado. Rode seed.hotels primeiro.');
    return;
  }

  const today = new Date();

  for (const hotel of hotels) {
    console.log(`⏳ ${hotel.nome_hotel}...`);

    // 3. Limpa reservas previamente seedadas (idempotência)
    await withTenant(hotel.schema_name, async (client) => {
      const { rows: oldReservas } = await client.query<{ id: number }>(
        `SELECT id FROM reserva WHERE observacoes = $1`,
        [OBS_MARKER],
      );
      const oldIds = oldReservas.map((r) => r.id);

      if (oldIds.length) {
        // Avaliações ligadas a essas reservas são removidas por CASCADE.
        await client.query(`DELETE FROM reserva WHERE id = ANY($1::int[])`, [oldIds]);

        // Limpa o espelho no master (usando hotel_id + reserva_tenant_id).
        await masterPool.query(
          `DELETE FROM historico_reserva_global WHERE hotel_id = $1 AND reserva_tenant_id = ANY($2::int[])`,
          [hotel.hotel_id, oldIds],
        );
      }

      // 4. Registra usuário seed como hóspede no tenant (idempotente)
      await client.query(
        `INSERT INTO hospede (user_id) VALUES ($1) ON CONFLICT DO NOTHING`,
        [seedUserId],
      );

      // 5. Busca quartos disponíveis neste hotel
      const { rows: quartos } = await client.query<{
        id: number;
        numero: string;
        categoria_id: number;
        categoria_nome: string;
      }>(
        `SELECT q.id, q.numero, q.categoria_quarto_id AS categoria_id, cq.nome AS categoria_nome
         FROM quarto q
         JOIN categoria_quarto cq ON cq.id = q.categoria_quarto_id
         WHERE q.deleted_at IS NULL
         ORDER BY q.numero`,
      );

      if (!quartos.length) {
        console.warn(`  ⚠️  ${hotel.nome_hotel}: sem quartos, pulando reservas`);
        return;
      }

      // 6. Insere reservas variadas
      let countPorStatus = { SOLICITADA: 0, AGUARDANDO_PAGAMENTO: 0, APROVADA: 0, CANCELADA: 0, CONCLUIDA: 0 };
      for (let i = 0; i < RESERVAS_PLAN.length; i++) {
        const plan = RESERVAS_PLAN[i];
        const quarto = quartos[i % quartos.length];
        const dataCheckin  = addDays(today, plan.daysFromToday);
        const dataCheckout = addDays(today, plan.daysFromToday + plan.nights);

        const { rows: inserted } = await client.query<{ id: number }>(
          `INSERT INTO reserva
             (quarto_id, tipo_quarto, user_id, canal_origem, num_hospedes,
              data_checkin, data_checkout, valor_total, observacoes, status, codigo_publico)
           VALUES ($1, $2, $3, 'APP', $4, $5, $6, $7, $8, $9, gen_random_uuid())
           RETURNING id`,
          [
            quarto.id,
            quarto.categoria_nome,
            seedUserId,
            plan.numHospedes,
            dataCheckin,
            dataCheckout,
            plan.valor,
            OBS_MARKER,
            plan.status,
          ],
        );
        const reservaId = inserted[0].id;

        // Espelha no master (historico_reserva_global) — mesmo padrão do _upsertHistoricoGlobal
        await masterPool.query(
          `INSERT INTO historico_reserva_global
             (user_id, hotel_id, reserva_tenant_id, nome_hotel, tipo_quarto,
              data_checkin, data_checkout, num_hospedes, valor_total, status)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
           ON CONFLICT (hotel_id, reserva_tenant_id)
           DO UPDATE SET
             status        = EXCLUDED.status,
             valor_total   = EXCLUDED.valor_total,
             data_checkin  = EXCLUDED.data_checkin,
             data_checkout = EXCLUDED.data_checkout,
             num_hospedes  = EXCLUDED.num_hospedes,
             atualizado_em = NOW()`,
          [
            seedUserId,
            hotel.hotel_id,
            reservaId,
            hotel.nome_hotel,
            quarto.categoria_nome,
            dataCheckin,
            dataCheckout,
            plan.numHospedes,
            plan.valor,
            plan.status,
          ],
        );

        countPorStatus[plan.status]++;
      }

      // 7. Marca ~40% dos quartos como ocupados para ocupacaoPercentual refletir
      const ocupar = Math.max(1, Math.floor(quartos.length * 0.4));
      for (let i = 0; i < ocupar; i++) {
        await client.query(
          `UPDATE quarto SET disponivel = FALSE WHERE id = $1`,
          [quartos[i].id],
        );
      }

      console.log(
        `  ✅ ${RESERVAS_PLAN.length} reservas | SOLIC:${countPorStatus.SOLICITADA} AG.PAG:${countPorStatus.AGUARDANDO_PAGAMENTO} APROV:${countPorStatus.APROVADA} CANCEL:${countPorStatus.CANCELADA} CONCL:${countPorStatus.CONCLUIDA} | ${ocupar}/${quartos.length} quartos ocupados`,
      );
    });
  }

  console.log('\n--- Seed de Reservas Finalizado ---');
}

// Auto-execução direta
if (require.main === module) {
  seedReservas()
    .catch((err) => {
      console.error('[seed/reservas] Erro fatal:', err);
      process.exit(1);
    })
    .finally(() => masterPool.end());
}
