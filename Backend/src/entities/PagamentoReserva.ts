/**
 * Entity: PagamentoReserva
 * Responsabilidade: validação pura — nunca toca o banco.
 */

export type PagamentoStatus  = 'PENDENTE' | 'APROVADO' | 'ESTORNADO' | 'CANCELADO';
export type FormaPagamento   = 'PIX' | 'CARTAO_CREDITO' | 'CARTAO_DEBITO';
export type CanalPagamento   = 'APP' | 'WHATSAPP';

// ── Interfaces de Output ──────────────────────────────────────────────────────

export interface PagamentoReservaSafe {
  id:                    number;
  reserva_id:            number;
  valor_pago:            string;       // DECIMAL → string via driver pg
  forma_pagamento:       string;
  status:                PagamentoStatus;
  checkout_url:          string | null;
  infinite_invoice_slug: string | null;
  transaction_nsu:       string | null;
  metodo_captura:        string | null;
  recibo_url:            string | null;
  data_pagamento:        string;
  expires_at:            string | null;
}

// ── Interface do Webhook InfinitePay ─────────────────────────────────────────

/**
 * Corpo que a InfinitePay envia ao webhook quando o pagamento é aprovado.
 * Campos conforme documentação oficial.
 */
export interface InfinitePayWebhookPayload {
  invoice_slug:    string;
  amount:          number;   // valor em centavos
  paid_amount:     number;   // valor efetivamente pago (pode incluir juros)
  installments:    number;
  capture_method:  string;   // 'credit_card' | 'pix'
  transaction_nsu: string;
  order_nsu:       string;   // codigo_publico da reserva (que enviamos na criação)
  receipt_url:     string;
  items:           unknown[];
}

// ── Classe de Validação ───────────────────────────────────────────────────────

export class PagamentoReserva {
  /** Valida o corpo do webhook recebido da InfinitePay. */
  static validateWebhook(input: unknown): InfinitePayWebhookPayload {
    const data = input as Record<string, unknown>;

    const required = ['invoice_slug', 'amount', 'capture_method', 'transaction_nsu', 'order_nsu'];
    for (const field of required) {
      if (data[field] === undefined || data[field] === null || data[field] === '')
        throw new Error(`Campo obrigatório ausente no webhook: ${field}`);
    }

    if (typeof data.invoice_slug !== 'string' || !data.invoice_slug.trim())
      throw new Error('invoice_slug inválido');
    if (typeof data.transaction_nsu !== 'string' || !data.transaction_nsu.trim())
      throw new Error('transaction_nsu inválido');
    if (typeof data.order_nsu !== 'string' || !data.order_nsu.trim())
      throw new Error('order_nsu inválido');
    if (typeof data.capture_method !== 'string')
      throw new Error('capture_method inválido');
    if (typeof data.amount !== 'number' || data.amount <= 0)
      throw new Error('amount inválido');

    return {
      invoice_slug:    (data.invoice_slug    as string).trim(),
      amount:          data.amount           as number,
      paid_amount:     (data.paid_amount     as number)  ?? data.amount,
      installments:    (data.installments    as number)  ?? 1,
      capture_method:  (data.capture_method  as string).trim(),
      transaction_nsu: (data.transaction_nsu as string).trim(),
      order_nsu:       (data.order_nsu       as string).trim(),
      receipt_url:     (data.receipt_url     as string)  ?? '',
      items:           (data.items           as unknown[]) ?? [],
    };
  }
}
