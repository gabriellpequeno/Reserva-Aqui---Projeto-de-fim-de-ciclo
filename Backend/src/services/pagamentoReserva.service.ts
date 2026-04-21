import https from 'https';
import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import { sendPush, getHotelTokens, getUserTokens } from './fcm.service';
import { insertNotificacao } from './notificacaoHotel.service';
import { setQuartoDisponivel } from './quarto.service';
import { sendApprovedReservationConfirmation } from './whatsappReservation.service';
import {
  PagamentoReserva,
  PagamentoReservaSafe,
  InfinitePayWebhookPayload,
} from '../entities/PagamentoReserva';
import { ReservaSafe } from '../entities/Reserva';

// ── Tipos internos ────────────────────────────────────────────────────────────

interface HotelInfo {
  schema_name:  string;
  nome_hotel:   string;
}

interface UsuarioInfo {
  nome_completo:  string;
  email:          string;
  numero_celular: string | null;
}

// ── Funções Exportadas (Wrappers) ─────────────────────────────────────────────

export async function createPagamento(
  hotelId:   string,
  reservaId: number,
): Promise<PagamentoReservaSafe> {
  return _createPagamento(hotelId, reservaId);
}

export async function listPagamentos(
  hotelId:   string,
  reservaId: number,
): Promise<PagamentoReservaSafe[]> {
  return _listPagamentos(hotelId, reservaId);
}

export async function handleWebhook(
  payload: InfinitePayWebhookPayload,
): Promise<void> {
  return _handleWebhook(payload);
}

// ── Helpers Privados ──────────────────────────────────────────────────────────

async function _getHotelInfo(hotelId: string): Promise<HotelInfo> {
  const { rows } = await masterPool.query<HotelInfo>(
    `SELECT schema_name, nome_hotel FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  if (!rows[0]) throw new Error('Hotel não encontrado');
  return rows[0];
}

async function _getUsuarioInfo(userId: string): Promise<UsuarioInfo | null> {
  const { rows } = await masterPool.query<UsuarioInfo>(
    `SELECT nome_completo, email, numero_celular FROM usuario WHERE user_id = $1`,
    [userId],
  );
  return rows[0] ?? null;
}

/**
 * Garante que a constraint de unicidade no invoice_slug existe.
 * Executado na primeira chamada de pagamento do tenant — idempotente via IF NOT EXISTS.
 */
async function _ensureSlugConstraint(client: import('pg').PoolClient): Promise<void> {
  await client.query(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_pagamento_invoice_slug'
      ) THEN
        ALTER TABLE pagamento_reserva
          ADD CONSTRAINT uq_pagamento_invoice_slug
          UNIQUE (infinite_invoice_slug);
      END IF;
    END
    $$;
  `);
}

/**
 * Chama a API da InfinitePay para criar um link de pagamento.
 * Retorna a checkout_url.
 */
async function _callInfinitePay(body: Record<string, unknown>): Promise<string> {
  const handle = process.env.INFINITEPAY_HANDLE;
  if (!handle) {
    throw new Error('INFINITEPAY_HANDLE não configurado no .env');
  }

  return new Promise((resolve, reject) => {
    const bodyStr = JSON.stringify({ ...body, handle });

    const options = {
      hostname: 'api.infinitepay.io',
      path:     '/invoices/public/checkout/links',
      method:   'POST',
      headers:  {
        'Content-Type':   'application/json',
        'Content-Length': Buffer.byteLength(bodyStr),
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data) as Record<string, unknown>;
          const url = parsed.checkout_url ?? parsed.url ?? parsed.link;
          if (typeof url !== 'string' || !url) {
            reject(new Error(`InfinitePay não retornou checkout_url. Resposta: ${data}`));
            return;
          }
          resolve(url);
        } catch {
          reject(new Error(`Falha ao parsear resposta da InfinitePay: ${data}`));
        }
      });
    });

    req.on('error', (err) => {
      reject(new Error(`Erro na chamada à InfinitePay: ${err.message}`));
    });

    req.setTimeout(10000, () => {
      req.destroy();
      reject(new Error('Timeout na chamada à InfinitePay'));
    });

    req.write(bodyStr);
    req.end();
  });
}

// ── Funções Privadas (Regras de Negócio) ─────────────────────────────────────

async function _createPagamento(
  hotelId:   string,
  reservaId: number,
): Promise<PagamentoReservaSafe> {
  const { schema_name, nome_hotel } = await _getHotelInfo(hotelId);

  return withTenant(schema_name, async (client) => {
    await _ensureSlugConstraint(client);

    // Busca a reserva com dados do quarto/categoria para a descrição
    const { rows: reservaRows } = await client.query<
      ReservaSafe & { categoria_nome: string | null }
    >(
      `SELECT r.*,
              cq.nome AS categoria_nome
       FROM reserva r
       LEFT JOIN quarto q ON q.id = r.quarto_id
       LEFT JOIN categoria_quarto cq ON cq.id = q.categoria_quarto_id
       WHERE r.id = $1`,
      [reservaId],
    );
    if (!reservaRows[0]) throw new Error('Reserva não encontrada');

    const reserva = reservaRows[0];

    if (reserva.status === 'CANCELADA' || reserva.status === 'CONCLUIDA')
      throw new Error('Não é possível gerar pagamento para uma reserva cancelada ou concluída');

    // Verifica se já há pagamento PENDENTE (evita duplicar links)
    const { rows: pendente } = await client.query(
      `SELECT id FROM pagamento_reserva WHERE reserva_id = $1 AND status = 'PENDENTE'`,
      [reservaId],
    );
    if (pendente[0]) throw new Error('Já existe um pagamento pendente para esta reserva');

    // Monta descrição rica com dados da reserva
    const tipoQuarto = reserva.categoria_nome ?? reserva.tipo_quarto ?? 'Quarto';
    const descricao  = [
      `Hospedagem em ${nome_hotel}`,
      `Tipo: ${tipoQuarto}`,
      `Check-in: ${reserva.data_checkin}`,
      `Check-out: ${reserva.data_checkout}`,
      `${reserva.num_hospedes} hóspede(s)`,
    ].join(' | ');

    // Monta dados do cliente para pré-preencher o checkout
    let customer: Record<string, string> | undefined;
    if (reserva.user_id) {
      const usuario = await _getUsuarioInfo(reserva.user_id);
      if (usuario) {
        customer = { name: usuario.nome_completo, email: usuario.email };
        if (usuario.numero_celular) customer.phone_number = usuario.numero_celular;
      }
    } else if (reserva.nome_hospede) {
      customer = { name: reserva.nome_hospede };
      if (reserva.telefone_contato) customer.phone_number = reserva.telefone_contato;
    }

    // Monta payload para InfinitePay
    const backendUrl  = process.env.BACKEND_URL  ?? '';
    const frontendUrl = process.env.FRONTEND_URL ?? '';

    const infinitePayBody: Record<string, unknown> = {
      itens: [{
        quantity:    1,
        price:       Math.round(Number(reserva.valor_total) * 100), // centavos
        description: descricao,
      }],
      order_nsu:    reserva.codigo_publico,
      webhook_url:  `${backendUrl}/api/pagamentos/webhook/infinitepay`,
      redirect_url: `${frontendUrl}/reservas/${reserva.codigo_publico}/pagamento-concluido`,
    };

    if (customer) infinitePayBody.customer = customer;

    const checkout_url = await _callInfinitePay(infinitePayBody);

    // Registra pagamento como PENDENTE
    const { rows } = await client.query<PagamentoReservaSafe>(
      `INSERT INTO pagamento_reserva
         (reserva_id, valor_pago, forma_pagamento, status, checkout_url)
       VALUES ($1, $2, 'PIX', 'PENDENTE', $3)
       RETURNING *`,
      [reservaId, reserva.valor_total, checkout_url],
    );
    const pagamento = rows[0];

    // Atualiza status da reserva para AGUARDANDO_PAGAMENTO
    await client.query(
      `UPDATE reserva SET status = 'AGUARDANDO_PAGAMENTO' WHERE id = $1`,
      [reservaId],
    );

    // FCM → hóspede com o link de pagamento (conecta o TODO documentado)
    if (reserva.user_id) {
      Promise.all([
        getUserTokens(reserva.user_id).then(tokens =>
          sendPush(tokens, {
            title: 'Link de pagamento disponível',
            body:  `Sua reserva em ${nome_hotel} aguarda pagamento.`,
            data:  {
              tipo:          'APROVACAO_RESERVA',
              codigo_publico: reserva.codigo_publico,
              checkout_url,
            },
          }),
        ),
        insertNotificacao(hotelId, {
          titulo:          'Link de pagamento gerado',
          mensagem:        `Link gerado para reserva #${reservaId}. Aguardando pagamento do hóspede.`,
          tipo:            'APROVACAO_RESERVA',
          acao_requerida:  null,
          payload:         { reserva_id: reservaId, checkout_url },
        }),
      ]).catch(() => {});
    }

    return pagamento;
  });
}

async function _listPagamentos(
  hotelId:   string,
  reservaId: number,
): Promise<PagamentoReservaSafe[]> {
  const { schema_name } = await _getHotelInfo(hotelId);

  return withTenant(schema_name, async (client) => {
    const { rows: check } = await client.query(
      `SELECT id FROM reserva WHERE id = $1`,
      [reservaId],
    );
    if (!check[0]) throw new Error('Reserva não encontrada');

    const { rows } = await client.query<PagamentoReservaSafe>(
      `SELECT * FROM pagamento_reserva WHERE reserva_id = $1 ORDER BY data_pagamento DESC`,
      [reservaId],
    );
    return rows;
  });
}

async function _handleWebhook(payload: InfinitePayWebhookPayload): Promise<void> {
  PagamentoReserva.validateWebhook(payload);

  // Resolve o tenant via order_nsu = codigo_publico da reserva
  const { rows: routing } = await masterPool.query<{
    schema_name: string;
    hotel_id:    string;
  }>(
    `SELECT schema_name, hotel_id FROM reserva_routing WHERE codigo_publico = $1`,
    [payload.order_nsu],
  );
  if (!routing[0]) {
    console.warn(`[Webhook] order_nsu não encontrado no routing: ${payload.order_nsu}`);
    return; // retorna sem erro — InfinitePay não deve retentar para order_nsu desconhecido
  }

  const { schema_name, hotel_id } = routing[0];

  const { rows: hotelRows } = await masterPool.query<{ nome_hotel: string }>(
    `SELECT nome_hotel FROM anfitriao WHERE hotel_id = $1`,
    [hotel_id],
  );
  const nome_hotel = hotelRows[0]?.nome_hotel ?? '';

  await withTenant(schema_name, async (client) => {
    await _ensureSlugConstraint(client);

    // Busca a reserva pelo codigo_publico
    const { rows: reservaRows } = await client.query<ReservaSafe>(
      `SELECT * FROM reserva WHERE codigo_publico = $1`,
      [payload.order_nsu],
    );
    if (!reservaRows[0]) return;

    const reserva = reservaRows[0];

    // Atualiza o pagamento PENDENTE com os dados do webhook
    // ON CONFLICT no slug garante idempotência — segundo webhook não faz nada
    const { rows: pagRows } = await client.query<{ id: number }>(
      `UPDATE pagamento_reserva
       SET status                = 'APROVADO',
           forma_pagamento       = $1,
           infinite_invoice_slug = $2,
           transaction_nsu       = $3,
           metodo_captura        = $4,
           recibo_url            = $5,
           data_pagamento        = NOW()
       WHERE reserva_id = $6 AND status = 'PENDENTE'
       RETURNING id`,
      [
        payload.capture_method === 'pix' ? 'PIX' : 'CARTAO_CREDITO',
        payload.invoice_slug,
        payload.transaction_nsu,
        payload.capture_method,
        payload.receipt_url,
        reserva.id,
      ],
    );

    // Nenhuma linha afetada = pagamento já processado (webhook duplicado)
    if (!pagRows[0]) return;

    // Avança reserva para APROVADA
    await client.query(
      `UPDATE reserva SET status = 'APROVADA' WHERE id = $1`,
      [reserva.id],
    );

    // Marca quarto indisponível se atribuído
    if (reserva.quarto_id) {
      await setQuartoDisponivel(hotel_id, reserva.quarto_id, false);
    }

    // Sincroniza historico global
    if (reserva.user_id) {
      const tipoQuarto = reserva.tipo_quarto ?? 'Quarto';
      await masterPool.query(
        `INSERT INTO historico_reserva_global
           (user_id, hotel_id, reserva_tenant_id, nome_hotel, tipo_quarto,
            data_checkin, data_checkout, valor_total, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'APROVADA')
         ON CONFLICT (hotel_id, reserva_tenant_id)
         DO UPDATE SET status = 'APROVADA', atualizado_em = NOW()`,
        [
          reserva.user_id, hotel_id, reserva.id, nome_hotel, tipoQuarto,
          reserva.data_checkin, reserva.data_checkout, reserva.valor_total,
        ],
      );
    }

    // FCM + inbox — PAGAMENTO_CONFIRMADO (conecta o TODO documentado)
    Promise.all([
      getHotelTokens(hotel_id).then(tokens =>
        sendPush(tokens, {
          title: 'Pagamento confirmado!',
          body:  `Reserva #${reserva.id} paga via ${payload.capture_method === 'pix' ? 'PIX' : 'cartão'}.`,
          data:  { tipo: 'PAGAMENTO_CONFIRMADO', reserva_id: String(reserva.id) },
        }),
      ),
      insertNotificacao(hotel_id, {
        titulo:   'Pagamento confirmado',
        mensagem: `Reserva #${reserva.id} paga via ${payload.capture_method === 'pix' ? 'PIX' : 'cartão'}.`,
        tipo:     'PAGAMENTO_CONFIRMADO',
        payload:  {
          reserva_id:      reserva.id,
          codigo_publico:  reserva.codigo_publico,
          recibo_url:      payload.receipt_url,
          capture_method:  payload.capture_method,
        },
      }),
      reserva.user_id
        ? getUserTokens(reserva.user_id).then(tokens =>
            sendPush(tokens, {
              title: 'Pagamento confirmado!',
              body:  `Sua reserva em ${nome_hotel} está confirmada.`,
              data:  {
                tipo:           'PAGAMENTO_CONFIRMADO',
                codigo_publico: reserva.codigo_publico,
                recibo_url:     payload.receipt_url,
              },
            }),
          )
        : Promise.resolve(),
    ]).catch(() => {});

    Promise.resolve()
      .then(() => sendApprovedReservationConfirmation({ hotelId: hotel_id, reservaId: reserva.id }))
      .catch(() => {});
  });
}
