import { masterPool } from '../../database/masterDb';
import { withTenant } from '../../database/schemaWrapper';
import { resolvePeriod } from './period.utils';
import {
  Period,
  ReservaStatus,
  ReservaStatusCount,
  NextCheckin,
  TopHotel,
  HostDashboardResponse,
  AdminDashboardResponse,
} from './dashboard.types';

// Regex para blindar o schema_name lido do banco antes de interpolar em SQL.
// anfitriao.schema_name é gerado internamente via buildSchemaName (não vem de input
// do usuário), mas mantemos a guarda para defesa em profundidade.
const SCHEMA_NAME_REGEX = /^[a-z0-9_]+$/;

function assertValidSchema(schemaName: string): void {
  if (!SCHEMA_NAME_REGEX.test(schemaName)) {
    throw new Error('Schema tenant inválido');
  }
}

interface HotelInfo {
  schema_name: string;
}

async function resolveTenantSchema(hotelId: string): Promise<string> {
  const { rows } = await masterPool.query<HotelInfo>(
    `SELECT schema_name FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  if (!rows[0]) throw new Error('Hotel não encontrado');
  assertValidSchema(rows[0].schema_name);
  return rows[0].schema_name;
}

function toISODate(value: Date | string): string {
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return String(value).slice(0, 10);
}

// ── Host Dashboard ────────────────────────────────────────────────────────────

export async function getHostMetrics(
  hotelId: string,
  period:  Period,
): Promise<HostDashboardResponse> {
  const schema         = await resolveTenantSchema(hotelId);
  const { start, end } = resolvePeriod(period);

  return withTenant(schema, async (client) => {
    const [
      reservasHojeRes,
      ocupacaoRes,
      receitaRes,
      avaliacaoRes,
      checkinsRes,
      statusRes,
    ] = await Promise.all([
      client.query<{ count: string }>(
        `SELECT COUNT(*)::text AS count FROM reserva WHERE data_checkin = CURRENT_DATE`,
      ),
      client.query<{ ocupados: string; total: string }>(
        `SELECT
           COUNT(*) FILTER (WHERE NOT disponivel)::text AS ocupados,
           COUNT(*)::text                                AS total
         FROM quarto
         WHERE deleted_at IS NULL`,
      ),
      client.query<{ receita: string }>(
        `SELECT COALESCE(SUM(valor_total), 0)::text AS receita
         FROM reserva
         WHERE status IN ('APROVADA', 'CONCLUIDA')
           AND criado_em >= $1 AND criado_em < $2`,
        [start, end],
      ),
      client.query<{ media: string | null; total: string }>(
        `SELECT AVG(nota_total)::text AS media, COUNT(*)::text AS total FROM avaliacao`,
      ),
      client.query<{
        id: number;
        codigo_publico: string;
        nome_hospede: string | null;
        quarto_numero: string | null;
        tipo_quarto: string | null;
        data_checkin: Date;
      }>(
        `SELECT r.id,
                r.codigo_publico,
                r.nome_hospede AS nome_hospede,
                q.numero       AS quarto_numero,
                r.tipo_quarto,
                r.data_checkin
         FROM reserva r
         LEFT JOIN quarto q ON q.id = r.quarto_id
         WHERE r.data_checkin >= CURRENT_DATE
           AND r.status IN ('APROVADA', 'AGUARDANDO_PAGAMENTO')
         ORDER BY r.data_checkin ASC
         LIMIT 5`,
      ),
      client.query<{ status: ReservaStatus; count: string }>(
        `SELECT status, COUNT(*)::text AS count
         FROM reserva
         WHERE criado_em >= $1 AND criado_em < $2
         GROUP BY status`,
        [start, end],
      ),
    ]);

    const reservasHoje = Number(reservasHojeRes.rows[0]?.count ?? 0);

    const ocupados = Number(ocupacaoRes.rows[0]?.ocupados ?? 0);
    const total    = Number(ocupacaoRes.rows[0]?.total    ?? 0);
    const ocupacaoPercentual = total === 0 ? 0 : (ocupados / total) * 100;

    const receitaPeriodo = Number(receitaRes.rows[0]?.receita ?? 0);

    const totalAvaliacoes = Number(avaliacaoRes.rows[0]?.total ?? 0);
    const avaliacaoMedia  = totalAvaliacoes === 0
      ? null
      : Number(avaliacaoRes.rows[0]?.media ?? 0);

    // Para próximos check-ins, se o hóspede não for walk-in (nome_hospede NULL),
    // buscamos o nome do usuário no master. Fazemos em uma segunda rodada de
    // resolução só para os user_ids que faltam — mantém a query do tenant simples.
    // Por enquanto, quando nome_hospede for NULL, retornamos "Hóspede" como fallback
    // (padrão já usado em outras telas ao não ter o nome disponível).
    const proximosCheckins: NextCheckin[] = checkinsRes.rows.map((row) => ({
      reservaId:     row.id,
      codigoPublico: row.codigo_publico,
      nomeHospede:   row.nome_hospede ?? 'Hóspede',
      quartoNumero:  row.quarto_numero,
      tipoQuarto:    row.tipo_quarto,
      dataCheckin:   toISODate(row.data_checkin),
    }));

    const reservasPorStatus: ReservaStatusCount[] = statusRes.rows.map((r) => ({
      status: r.status,
      count:  Number(r.count),
    }));

    return {
      period,
      metrics: {
        reservasHoje,
        ocupacaoPercentual,
        receitaPeriodo,
        avaliacaoMedia,
        totalAvaliacoes,
      },
      proximosCheckins,
      reservasPorStatus,
    };
  });
}

// ── Admin Dashboard ───────────────────────────────────────────────────────────

export async function getAdminMetrics(
  period: Period,
): Promise<AdminDashboardResponse> {
  const { start, end } = resolvePeriod(period);

  const [
    totalUsuariosRes,
    totalHoteisRes,
    reservasHojeRes,
    receitaRes,
    topHoteisRes,
    statusRes,
    novosCadastrosRes,
  ] = await Promise.all([
    masterPool.query<{ count: string }>(
      `SELECT COUNT(*)::text AS count FROM usuario WHERE papel = 'usuario' AND ativo = TRUE`,
    ),
    masterPool.query<{ count: string }>(
      `SELECT COUNT(*)::text AS count FROM anfitriao WHERE ativo = TRUE`,
    ),
    masterPool.query<{ count: string }>(
      `SELECT COUNT(*)::text AS count FROM historico_reserva_global WHERE data_checkin = CURRENT_DATE`,
    ),
    masterPool.query<{ receita: string }>(
      `SELECT COALESCE(SUM(valor_total), 0)::text AS receita
       FROM historico_reserva_global
       WHERE status IN ('APROVADA', 'CONCLUIDA')
         AND criado_em >= $1 AND criado_em < $2`,
      [start, end],
    ),
    masterPool.query<{ hotel_id: string; nome_hotel: string; reservas_ativas: string }>(
      `SELECT hotel_id, nome_hotel, COUNT(*)::text AS reservas_ativas
       FROM historico_reserva_global
       WHERE status = 'APROVADA'
         AND data_checkin  <  $2
         AND data_checkout >  $1
       GROUP BY hotel_id, nome_hotel
       ORDER BY COUNT(*) DESC
       LIMIT 3`,
      [start, end],
    ),
    masterPool.query<{ status: ReservaStatus; count: string }>(
      `SELECT status, COUNT(*)::text AS count
       FROM historico_reserva_global
       WHERE criado_em >= $1 AND criado_em < $2
       GROUP BY status`,
      [start, end],
    ),
    masterPool.query<{ usuarios: string; hoteis: string }>(
      `SELECT
         (SELECT COUNT(*)::text FROM usuario   WHERE criado_em >= NOW() - INTERVAL '7 days') AS usuarios,
         (SELECT COUNT(*)::text FROM anfitriao WHERE criado_em >= NOW() - INTERVAL '7 days') AS hoteis`,
    ),
  ]);

  const topHoteis: TopHotel[] = topHoteisRes.rows.map((r) => ({
    hotelId:        r.hotel_id,
    nomeHotel:      r.nome_hotel,
    reservasAtivas: Number(r.reservas_ativas),
  }));

  const reservasPorStatus: ReservaStatusCount[] = statusRes.rows.map((r) => ({
    status: r.status,
    count:  Number(r.count),
  }));

  return {
    period,
    metrics: {
      totalUsuarios:  Number(totalUsuariosRes.rows[0]?.count ?? 0),
      totalHoteis:    Number(totalHoteisRes.rows[0]?.count   ?? 0),
      reservasHoje:   Number(reservasHojeRes.rows[0]?.count  ?? 0),
      receitaPeriodo: Number(receitaRes.rows[0]?.receita     ?? 0),
    },
    topHoteis,
    reservasPorStatus,
    novosCadastros: {
      usuarios: Number(novosCadastrosRes.rows[0]?.usuarios ?? 0),
      hoteis:   Number(novosCadastrosRes.rows[0]?.hoteis   ?? 0),
    },
  };
}
