import https from 'https';
import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import { sendPush, getHotelTokens, getUserTokens } from './fcm.service';
import { insertNotificacao } from './notificacaoHotel.service';
import { setQuartoDisponivel } from './quarto.service';
import { _ensureReservaFluxoColumns } from './reserva.service';
import { sendApprovedReservationConfirmation } from './whatsappReservation.service';
import { sendEmail } from './email.service';
import { reservaConfirmadaTemplate } from './emailTemplates';
import {
  PagamentoReserva,
  PagamentoReservaSafe,
  InfinitePayWebhookPayload,
  FormaPagamento,
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

// ── Fluxo FAKE (sem PSP real) ────────────────────────────────────────────────
//
// Usado durante a apresentação/desenvolvimento. Replica a forma da InfinitePay
// sem chamar HTTP externo. O /confirmar reaproveita `_aplicarAprovacao`.

export interface CriarPagamentoFakeInput {
  codigoPublico: string;
  canal:         'APP' | 'WHATSAPP';
}

export interface PagamentoFakeResumo {
  pagamento_id:   number;
  reserva_id:     number;
  codigo_publico: string;
  status:         'PENDENTE' | 'APROVADO' | 'CANCELADO';
  valor_total:    string;
  expires_at:     string | null;
  modalidades:    FormaPagamento[];
}

export async function createPagamentoFake(input: CriarPagamentoFakeInput): Promise<PagamentoFakeResumo> {
  return _createPagamentoFake(input);
}

export async function getPagamentoPublic(codigoPublico: string, pagamentoId: number): Promise<PagamentoFakeResumo> {
  return _getPagamentoPublic(codigoPublico, pagamentoId);
}

export async function confirmarPagamentoFake(
  codigoPublico:  string,
  pagamentoId:    number,
  formaPagamento: FormaPagamento,
): Promise<PagamentoFakeResumo> {
  return _confirmarPagamentoFake(codigoPublico, pagamentoId, formaPagamento);
}

export async function cancelarPagamentoFake(
  codigoPublico: string,
  pagamentoId:   number,
): Promise<PagamentoFakeResumo> {
  return _cancelarPagamentoFake(codigoPublico, pagamentoId);
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
    `SELECT nome_completo, email, numero_celular FROM public.usuario WHERE user_id = $1`,
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
    await _ensureReservaFluxoColumns(client);

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

// ── Efeitos colaterais da aprovação de pagamento ─────────────────────────────
//
// Isolada do webhook para ser reaproveitada no fluxo fake (sem PSP real).
// Tudo executado em fire-and-forget: se FCM ou email falharem, o status no
// banco já foi atualizado — a transação não volta atrás.

interface AprovacaoOpts {
  capture_method?:  string;  // 'pix' | 'credit_card' | modalidade fake
  receipt_url?:     string | null;
  invoice_slug?:    string | null;
  transaction_nsu?: string | null;
}

/**
 * Pós-processamento de "pagamento aprovado". Chame SEMPRE que o status da
 * reserva avança para APROVADA — tanto via webhook InfinitePay quanto via
 * confirmação fake. NÃO executa UPDATEs — só dispara efeitos colaterais:
 * FCM, notificação inbox, histórico global, WhatsApp e email.
 *
 * Pré-requisito: `pagamento_reserva` e `reserva` já foram atualizados pelo
 * chamador dentro da mesma transação.
 */
async function _aplicarAprovacao(
  hotelId:         string,
  nomeHotel:       string,
  reserva:         ReservaSafe,
  formaPagamento:  FormaPagamento,
  opts:            AprovacaoOpts = {},
): Promise<void> {
  // Quarto indisponível
  if (reserva.quarto_id) {
    await setQuartoDisponivel(hotelId, reserva.quarto_id, false).catch(() => {});
  }

  // Histórico global (somente para reservas com user_id — guest não tem)
  if (reserva.user_id) {
    const tipoQuarto = reserva.tipo_quarto ?? 'Quarto';
    await masterPool.query(
      `INSERT INTO historico_reserva_global
         (user_id, hotel_id, reserva_tenant_id, nome_hotel, tipo_quarto,
          data_checkin, data_checkout, num_hospedes, valor_total, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'APROVADA')
       ON CONFLICT (hotel_id, reserva_tenant_id)
       DO UPDATE SET status = 'APROVADA', atualizado_em = NOW()`,
      [
        reserva.user_id, hotelId, reserva.id, nomeHotel, tipoQuarto,
        reserva.data_checkin, reserva.data_checkout, reserva.num_hospedes, reserva.valor_total,
      ],
    ).catch((err) => console.warn('[aprovacao] historico global:', err));
  }

  const formaLabel = formaPagamento === 'PIX'            ? 'PIX'
                   : formaPagamento === 'CARTAO_DEBITO'  ? 'cartão de débito'
                   : 'cartão de crédito';

  // FCM para o hotel
  Promise.all([
    getHotelTokens(hotelId).then((tokens) =>
      sendPush(tokens, {
        title: 'Pagamento confirmado!',
        body:  `Reserva #${reserva.id} paga via ${formaLabel}.`,
        data:  { tipo: 'PAGAMENTO_CONFIRMADO', reserva_id: String(reserva.id), codigo_publico: reserva.codigo_publico },
      }),
    ),
    insertNotificacao(hotelId, {
      titulo:   'Pagamento confirmado',
      mensagem: `Reserva #${reserva.id} paga via ${formaLabel}.`,
      tipo:     'PAGAMENTO_CONFIRMADO',
      payload:  {
        reserva_id:     reserva.id,
        codigo_publico: reserva.codigo_publico,
        recibo_url:     opts.receipt_url ?? null,
        capture_method: opts.capture_method ?? formaPagamento,
      },
    }),
    reserva.user_id
      ? getUserTokens(reserva.user_id).then((tokens) =>
          sendPush(tokens, {
            title: 'Pagamento confirmado!',
            body:  `Sua reserva em ${nomeHotel} está confirmada.`,
            data:  {
              tipo:           'PAGAMENTO_CONFIRMADO',
              codigo_publico: reserva.codigo_publico,
              recibo_url:     opts.receipt_url ?? '',
            },
          }),
        )
      : Promise.resolve(),
  ]).catch(() => {});

  // WhatsApp (canal já definido internamente pelo serviço)
  Promise.resolve()
    .then(() => sendApprovedReservationConfirmation({ hotelId, reservaId: reserva.id }))
    .catch(() => {});

  // Email ao hóspede — prioridade: email_hospede (guest ou reserva pra terceiro),
  // depois email do user autenticado se disponível via lookup.
  let destinoEmail: string | null = reserva.email_hospede ?? null;
  let nomeDestino                 = reserva.nome_hospede ?? '';

  console.log(`[aprovacao] resolvendo email destino: email_hospede="${reserva.email_hospede ?? ''}" user_id="${reserva.user_id ?? ''}"`);

  if (!destinoEmail && reserva.user_id) {
    try {
      const usuario = await _getUsuarioInfo(reserva.user_id);
      if (usuario) {
        destinoEmail = usuario.email;
        if (!nomeDestino) nomeDestino = usuario.nome_completo;
        console.log(`[aprovacao] email do user autenticado: ${destinoEmail}`);
      } else {
        console.warn(`[aprovacao] usuario ${reserva.user_id} não encontrado em public.usuario`);
      }
    } catch (err) {
      console.warn('[aprovacao] _getUsuarioInfo falhou:', err);
    }
  }

  if (destinoEmail) {
    console.log(`[aprovacao] disparando email de confirmação para ${destinoEmail} (reserva ${reserva.codigo_publico})`);
    const frontend     = process.env.FRONTEND_URL ?? 'http://localhost:8080';
    const ticketUrl    = `${frontend.replace(/\/+$/, '')}/reservas/${reserva.codigo_publico}`;
    const { subject, html } = reservaConfirmadaTemplate({
      nomeHospede:   nomeDestino || 'Hóspede',
      codigoPublico: reserva.codigo_publico,
      ticketUrl,
      resumo: {
        nomeHotel,
        tipoQuarto:    reserva.tipo_quarto ?? 'Quarto',
        dataCheckin:   reserva.data_checkin,
        dataCheckout:  reserva.data_checkout,
        numHospedes:   reserva.num_hospedes,
        valorTotal:    reserva.valor_total,
      },
    });
    sendEmail({ to: destinoEmail, subject, html }).catch(() => {});
  } else {
    console.log(`[aprovacao] nenhum email de destino encontrado — reserva ${reserva.codigo_publico} user_id=${reserva.user_id} email_hospede=${reserva.email_hospede}`);
  }
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

  // Dados que vamos precisar após a transação, pra passar a _aplicarAprovacao
  let reservaAprovada: ReservaSafe | null = null;
  const formaPagamento: FormaPagamento =
    payload.capture_method === 'pix' ? 'PIX' : 'CARTAO_CREDITO';

  await withTenant(schema_name, async (client) => {
    await _ensureSlugConstraint(client);
    await _ensureReservaFluxoColumns(client);

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
        formaPagamento,
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

    reservaAprovada = { ...reserva, status: 'APROVADA' };
  });

  if (reservaAprovada) {
    try {
      await _aplicarAprovacao(hotel_id, nome_hotel, reservaAprovada, formaPagamento, {
        capture_method:  payload.capture_method,
        receipt_url:     payload.receipt_url,
        invoice_slug:    payload.invoice_slug,
        transaction_nsu: payload.transaction_nsu,
      });
    } catch (err) {
      console.warn('[handleWebhook] _aplicarAprovacao falhou (não fatal):', err);
    }
  }
}

// ── Helpers do fluxo fake ────────────────────────────────────────────────────

const MODALIDADES_FAKE: FormaPagamento[] = ['PIX', 'CARTAO_CREDITO', 'CARTAO_DEBITO'];

async function _resolveTenantByCodigoPublico(codigoPublico: string): Promise<{
  schema_name: string;
  hotel_id:    string;
  nome_hotel:  string;
}> {
  const { rows: routing } = await masterPool.query<{
    schema_name: string;
    hotel_id:    string;
  }>(
    `SELECT schema_name, hotel_id FROM reserva_routing WHERE codigo_publico = $1`,
    [codigoPublico],
  );
  if (!routing[0]) throw new Error('Reserva não encontrada');

  const { rows: hotelRows } = await masterPool.query<{ nome_hotel: string }>(
    `SELECT nome_hotel FROM anfitriao WHERE hotel_id = $1`,
    [routing[0].hotel_id],
  );

  return {
    schema_name: routing[0].schema_name,
    hotel_id:    routing[0].hotel_id,
    nome_hotel:  hotelRows[0]?.nome_hotel ?? '',
  };
}

function _toResumo(
  row: {
    id: number;
    reserva_id: number;
    status: string;
    expires_at: Date | string | null;
  },
  codigoPublico: string,
  valorTotal:    string,
): PagamentoFakeResumo {
  const expires_at = row.expires_at
    ? (row.expires_at instanceof Date ? row.expires_at.toISOString() : String(row.expires_at))
    : null;

  return {
    pagamento_id:   row.id,
    reserva_id:     row.reserva_id,
    codigo_publico: codigoPublico,
    status:         row.status as PagamentoFakeResumo['status'],
    valor_total:    valorTotal,
    expires_at,
    modalidades:    MODALIDADES_FAKE,
  };
}

// ── Fluxo FAKE: implementações privadas ──────────────────────────────────────

async function _createPagamentoFake(input: CriarPagamentoFakeInput): Promise<PagamentoFakeResumo> {
  const { schema_name, hotel_id, nome_hotel } = await _resolveTenantByCodigoPublico(input.codigoPublico);

  return withTenant(schema_name, async (client) => {
    await _ensureSlugConstraint(client);
    await _ensureReservaFluxoColumns(client);

    const { rows: reservaRows } = await client.query<ReservaSafe>(
      `SELECT * FROM reserva WHERE codigo_publico = $1`,
      [input.codigoPublico],
    );
    if (!reservaRows[0]) throw new Error('Reserva não encontrada');

    const reserva = reservaRows[0];

    if (reserva.status === 'CANCELADA' || reserva.status === 'CONCLUIDA')
      throw new Error('Não é possível gerar pagamento para uma reserva cancelada ou concluída');

    // Evita duplicar link — se já existe pendente, retorna ele (idempotente)
    const { rows: existente } = await client.query<{
      id: number; reserva_id: number; status: string; expires_at: Date | null;
    }>(
      `SELECT id, reserva_id, status, expires_at
       FROM pagamento_reserva
       WHERE reserva_id = $1 AND status = 'PENDENTE'
       ORDER BY id DESC LIMIT 1`,
      [reserva.id],
    );
    if (existente[0]) {
      // Se ainda não expirou, reutiliza
      const ex = existente[0];
      const stillValid = !ex.expires_at || ex.expires_at > new Date();
      if (stillValid) return _toResumo(ex, reserva.codigo_publico, reserva.valor_total);
    }

    const expiresAt = input.canal === 'WHATSAPP'
      ? new Date(Date.now() + 30 * 60 * 1000)
      : null;

    const { rows: inserted } = await client.query<{
      id: number; reserva_id: number; status: string; expires_at: Date | null;
    }>(
      `INSERT INTO pagamento_reserva
         (reserva_id, valor_pago, forma_pagamento, status, expires_at)
       VALUES ($1, $2, 'PIX', 'PENDENTE', $3)
       RETURNING id, reserva_id, status, expires_at`,
      [reserva.id, reserva.valor_total, expiresAt],
    );

    // Avança reserva para AGUARDANDO_PAGAMENTO
    await client.query(
      `UPDATE reserva SET status = 'AGUARDANDO_PAGAMENTO' WHERE id = $1 AND status = 'SOLICITADA'`,
      [reserva.id],
    );

    // Log silencioso pra facilitar debug sem poluir; hotel receberá notificação ao aprovar
    void hotel_id; void nome_hotel;

    return _toResumo(inserted[0], reserva.codigo_publico, reserva.valor_total);
  });
}

async function _getPagamentoPublic(codigoPublico: string, pagamentoId: number): Promise<PagamentoFakeResumo> {
  const { schema_name } = await _resolveTenantByCodigoPublico(codigoPublico);

  return withTenant(schema_name, async (client) => {
    const { rows } = await client.query<{
      id: number; reserva_id: number; status: string; valor_pago: string; expires_at: Date | null;
      codigo_publico: string;
    }>(
      `SELECT p.id, p.reserva_id, p.status, p.valor_pago, p.expires_at, r.codigo_publico
       FROM pagamento_reserva p
       JOIN reserva r ON r.id = p.reserva_id
       WHERE p.id = $1 AND r.codigo_publico = $2`,
      [pagamentoId, codigoPublico],
    );
    if (!rows[0]) throw new Error('Pagamento não encontrado');

    return _toResumo(rows[0], rows[0].codigo_publico, rows[0].valor_pago);
  });
}

async function _confirmarPagamentoFake(
  codigoPublico:  string,
  pagamentoId:    number,
  formaPagamento: FormaPagamento,
): Promise<PagamentoFakeResumo> {
  if (!MODALIDADES_FAKE.includes(formaPagamento)) {
    throw new Error('forma_pagamento inválida');
  }

  const { schema_name, hotel_id, nome_hotel } = await _resolveTenantByCodigoPublico(codigoPublico);

  let reservaAprovada: ReservaSafe | null = null;
  let resumo: PagamentoFakeResumo | null = null;

  await withTenant(schema_name, async (client) => {
    await _ensureReservaFluxoColumns(client);

    const { rows: pagRows } = await client.query<{
      id: number; reserva_id: number; status: string; expires_at: Date | null;
    }>(
      `SELECT id, reserva_id, status, expires_at
       FROM pagamento_reserva
       WHERE id = $1`,
      [pagamentoId],
    );
    if (!pagRows[0]) throw new Error('Pagamento não encontrado');

    const pagamento = pagRows[0];

    if (pagamento.status !== 'PENDENTE') throw new Error('Pagamento já processado');
    if (pagamento.expires_at && pagamento.expires_at < new Date())
      throw new Error('Link de pagamento expirado');

    const { rows: reservaRows } = await client.query<ReservaSafe>(
      `SELECT * FROM reserva WHERE id = $1 AND codigo_publico = $2`,
      [pagamento.reserva_id, codigoPublico],
    );
    if (!reservaRows[0]) throw new Error('Reserva não encontrada');

    const reserva = reservaRows[0];

    // Atualiza pagamento → APROVADO (guarda contra race condition)
    const { rows: upd } = await client.query<{ id: number; status: string; expires_at: Date | null; reserva_id: number }>(
      `UPDATE pagamento_reserva
       SET status = 'APROVADO', forma_pagamento = $1, data_pagamento = NOW()
       WHERE id = $2 AND status = 'PENDENTE'
       RETURNING id, status, expires_at, reserva_id`,
      [formaPagamento, pagamentoId],
    );
    if (!upd[0]) throw new Error('Pagamento já processado');

    await client.query(
      `UPDATE reserva SET status = 'APROVADA' WHERE id = $1`,
      [reserva.id],
    );

    reservaAprovada = { ...reserva, status: 'APROVADA' };
    resumo = _toResumo(upd[0], reserva.codigo_publico, reserva.valor_total);
  });

  // Efeitos colaterais NÃO podem derrubar a confirmação — o UPDATE do pagamento
  // e da reserva já foram commitados dentro do withTenant. Se FCM/email/historico
  // falharem, só loga warn e segue.
  if (reservaAprovada) {
    try {
      await _aplicarAprovacao(hotel_id, nome_hotel, reservaAprovada, formaPagamento, {
        capture_method: formaPagamento.toLowerCase(),
      });
    } catch (err) {
      console.warn('[confirmarPagamentoFake] _aplicarAprovacao falhou (não fatal):', err);
    }
  }

  if (!resumo) throw new Error('Pagamento não confirmado');
  return resumo;
}

async function _cancelarPagamentoFake(
  codigoPublico: string,
  pagamentoId:   number,
): Promise<PagamentoFakeResumo> {
  const { schema_name, hotel_id } = await _resolveTenantByCodigoPublico(codigoPublico);

  const resumo = await withTenant(schema_name, async (client) => {
    const { rows: pagRows } = await client.query<{
      id: number; reserva_id: number; status: string; expires_at: Date | null;
    }>(
      `UPDATE pagamento_reserva
       SET status = 'CANCELADO'
       WHERE id = $1 AND status = 'PENDENTE'
       RETURNING id, reserva_id, status, expires_at`,
      [pagamentoId],
    );
    if (!pagRows[0]) throw new Error('Pagamento não está pendente ou não existe');

    const { rows: reservaRows } = await client.query<ReservaSafe>(
      `UPDATE reserva SET status = 'CANCELADA'
       WHERE id = $1 AND codigo_publico = $2
       RETURNING *`,
      [pagRows[0].reserva_id, codigoPublico],
    );
    if (!reservaRows[0]) throw new Error('Reserva não encontrada');

    return _toResumo(pagRows[0], codigoPublico, reservaRows[0].valor_total);
  });

  // Notifica hotel — fire-and-forget
  Promise.all([
    getHotelTokens(hotel_id).then((tokens) =>
      sendPush(tokens, {
        title: 'Reserva cancelada',
        body:  `Reserva #${resumo.reserva_id} cancelada pelo hóspede.`,
        data:  { tipo: 'RESERVA_CANCELADA', reserva_id: String(resumo.reserva_id), codigo_publico: codigoPublico },
      }),
    ),
    insertNotificacao(hotel_id, {
      titulo:   'Reserva cancelada',
      mensagem: `Reserva #${resumo.reserva_id} foi cancelada pelo hóspede.`,
      tipo:     'RESERVA_CANCELADA',
      payload:  { reserva_id: resumo.reserva_id, codigo_publico: codigoPublico },
    }),
  ]).catch(() => {});

  return resumo;
}
