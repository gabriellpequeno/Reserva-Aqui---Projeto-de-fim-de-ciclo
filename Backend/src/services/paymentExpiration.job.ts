import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import { sendPush, getHotelTokens } from './fcm.service';
import { insertNotificacao } from './notificacaoHotel.service';
import { sendEmail } from './email.service';
import { reservaExpiradaTemplate } from './emailTemplates';
import { _ensureReservaFluxoColumns } from './reserva.service';

// ── Intervalo ────────────────────────────────────────────────────────────────
const TICK_INTERVAL_MS = 60 * 1000; // 1 min

let _timer: NodeJS.Timeout | null = null;

export function startPaymentExpirationJob(): void {
  if (_timer) return;
  _timer = setInterval(() => {
    tick().catch((err) => console.warn('[paymentExpiration] tick failed:', err));
  }, TICK_INTERVAL_MS);
  // Não bloquear o encerramento do processo quando só este timer estiver rodando
  _timer.unref?.();
  console.log('[paymentExpiration] job iniciado — tick a cada 60s.');
}

export function stopPaymentExpirationJob(): void {
  if (_timer) {
    clearInterval(_timer);
    _timer = null;
  }
}

// ── Tick ─────────────────────────────────────────────────────────────────────
//
// Varre todos os tenants que têm pelo menos uma reserva no `reserva_routing`.
// Para cada tenant, busca pagamentos PENDENTES com `expires_at < NOW()` e
// cancela a reserva associada. Emite email/FCM para hotel e hóspede.

interface ExpiredPagamento {
  pagamento_id:    number;
  reserva_id:      number;
  codigo_publico:  string;
  nome_hospede:    string | null;
  email_hospede:   string | null;
  user_email:      string | null;
  user_nome:       string | null;
}

async function tick(): Promise<void> {
  // Pega todos os schemas ativos (um por hotel). A lista é pequena.
  const { rows: schemas } = await masterPool.query<{ schema_name: string; hotel_id: string; nome_hotel: string }>(
    `SELECT schema_name, hotel_id, nome_hotel FROM anfitriao WHERE ativo = TRUE`,
  );

  for (const s of schemas) {
    try {
      await expireInTenant(s.schema_name, s.hotel_id, s.nome_hotel);
    } catch (err) {
      console.warn(`[paymentExpiration] tenant ${s.schema_name}:`, err);
    }
  }
}

async function expireInTenant(schemaName: string, hotelId: string, nomeHotel: string): Promise<void> {
  const expired = await withTenant(schemaName, async (client) => {
    // Garante que email_hospede e expires_at existem neste tenant — tenants
    // que nunca passaram por criação de reserva/pagamento após a migration
    // ainda não têm as colunas. Idempotente.
    await _ensureReservaFluxoColumns(client);

    // Encontra pagamentos pendentes expirados
    const { rows } = await client.query<ExpiredPagamento>(
      `SELECT p.id AS pagamento_id,
              r.id AS reserva_id,
              r.codigo_publico,
              r.nome_hospede,
              r.email_hospede,
              u.email        AS user_email,
              u.nome_completo AS user_nome
       FROM pagamento_reserva p
       JOIN reserva r ON r.id = p.reserva_id
       LEFT JOIN public.usuario u ON u.user_id = r.user_id
       WHERE p.status       = 'PENDENTE'
         AND p.expires_at IS NOT NULL
         AND p.expires_at  < NOW()
         AND r.status NOT IN ('CANCELADA', 'CONCLUIDA')
       LIMIT 50`,
    );

    if (rows.length === 0) return [];

    // Cancela em lote (transação implícita pelo pool client)
    const ids = rows.map((r) => r.pagamento_id);
    await client.query(
      `UPDATE pagamento_reserva SET status = 'CANCELADO' WHERE id = ANY($1::int[])`,
      [ids],
    );

    const reservaIds = rows.map((r) => r.reserva_id);
    await client.query(
      `UPDATE reserva SET status = 'CANCELADA' WHERE id = ANY($1::int[])`,
      [reservaIds],
    );

    return rows;
  });

  if (expired.length === 0) return;

  console.log(`[paymentExpiration] ${expired.length} pagamento(s) expirado(s) em ${schemaName}`);

  // Efeitos colaterais fora da transação — fire-and-forget
  for (const e of expired) {
    // Notifica hotel
    Promise.all([
      getHotelTokens(hotelId).then((tokens) =>
        sendPush(tokens, {
          title: 'Reserva cancelada por tempo',
          body:  `Reserva #${e.reserva_id} cancelada — pagamento não recebido.`,
          data:  { tipo: 'RESERVA_CANCELADA', reserva_id: String(e.reserva_id), codigo_publico: e.codigo_publico },
        }),
      ),
      insertNotificacao(hotelId, {
        titulo:   'Reserva expirada',
        mensagem: `Reserva #${e.reserva_id} cancelada automaticamente — link de pagamento expirou.`,
        tipo:     'RESERVA_CANCELADA',
        payload:  { reserva_id: e.reserva_id, codigo_publico: e.codigo_publico },
      }),
    ]).catch(() => {});

    // Email ao hóspede — prioriza email_hospede, senão do user
    const destinoEmail = e.email_hospede ?? e.user_email ?? null;
    const nomeDestino  = e.nome_hospede  ?? e.user_nome  ?? 'Hóspede';

    if (destinoEmail) {
      const { subject, html } = reservaExpiradaTemplate({
        nomeHospede:   nomeDestino,
        codigoPublico: e.codigo_publico,
        nomeHotel,
      });
      sendEmail({ to: destinoEmail, subject, html }).catch(() => {});
    }
  }
}
