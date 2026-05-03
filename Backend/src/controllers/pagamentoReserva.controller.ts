import { Request, Response } from 'express';
import { HotelRequest } from '../middlewares/hotelGuard';
import {
  createPagamento,
  listPagamentos,
  handleWebhook,
  createPagamentoFake,
  getPagamentoPublic,
  confirmarPagamentoFake,
  cancelarPagamentoFake,
} from '../services/pagamentoReserva.service';
import { PagamentoReserva, FormaPagamento } from '../entities/PagamentoReserva';

function mapError(message: string): number {
  if (message.includes('Já existe')   || message.includes('já processado')
   || message.includes('Já existe um pagamento'))                              return 409;
  if (message.includes('expirado'))                                            return 410;
  if (message.includes('não encontrad'))                                       return 404;
  if (message.includes('obrigatório') || message.includes('inválid')
   || message.includes('Não é possível') || message.includes('pendente ou'))   return 400;
  if (message.includes('não configurad'))                                      return 503;
  return 500;
}

// ── Hotel (hotelGuard) ────────────────────────────────────────────────────────

export async function createPagamentoController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const reservaId = Number(req.params.reserva_id);
    if (!Number.isInteger(reservaId) || reservaId <= 0) {
      res.status(400).json({ error: 'ID de reserva inválido' });
      return;
    }
    const result = await createPagamento(req.hotelId!, reservaId);
    res.status(201).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function listPagamentosController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const reservaId = Number(req.params.reserva_id);
    if (!Number.isInteger(reservaId) || reservaId <= 0) {
      res.status(400).json({ error: 'ID de reserva inválido' });
      return;
    }
    const result = await listPagamentos(req.hotelId!, reservaId);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

// ── Público — Pagamento fake (sem JWT) ────────────────────────────────────────

function parsePagamentoId(raw: unknown): number | null {
  const n = Number(raw);
  if (!Number.isInteger(n) || n <= 0) return null;
  return n;
}

export async function createPagamentoPublicoController(
  req: Request,
  res: Response,
): Promise<void> {
  try {
    const codigoPublico = req.params.codigo_publico;
    const canal = (req.body?.canal === 'WHATSAPP' ? 'WHATSAPP' : 'APP') as 'APP' | 'WHATSAPP';
    const result = await createPagamentoFake({ codigoPublico, canal });
    res.status(201).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function getPagamentoPublicoController(
  req: Request,
  res: Response,
): Promise<void> {
  try {
    const codigoPublico = req.params.codigo_publico;
    const pagamentoId   = parsePagamentoId(req.params.id);
    if (pagamentoId === null) {
      res.status(400).json({ error: 'ID de pagamento inválido' });
      return;
    }
    const result = await getPagamentoPublic(codigoPublico, pagamentoId);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

const FORMAS_VALIDAS: FormaPagamento[] = ['PIX', 'CARTAO_CREDITO', 'CARTAO_DEBITO'];

export async function confirmarPagamentoController(
  req: Request,
  res: Response,
): Promise<void> {
  try {
    const codigoPublico = req.params.codigo_publico;
    const pagamentoId   = parsePagamentoId(req.params.id);
    if (pagamentoId === null) {
      res.status(400).json({ error: 'ID de pagamento inválido' });
      return;
    }
    const forma = req.body?.forma_pagamento;
    if (!FORMAS_VALIDAS.includes(forma)) {
      res.status(400).json({ error: 'forma_pagamento inválida' });
      return;
    }
    const result = await confirmarPagamentoFake(codigoPublico, pagamentoId, forma);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function cancelarPagamentoController(
  req: Request,
  res: Response,
): Promise<void> {
  try {
    const codigoPublico = req.params.codigo_publico;
    const pagamentoId   = parsePagamentoId(req.params.id);
    if (pagamentoId === null) {
      res.status(400).json({ error: 'ID de pagamento inválido' });
      return;
    }
    const result = await cancelarPagamentoFake(codigoPublico, pagamentoId);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

// ── Webhook InfinitePay (público) ─────────────────────────────────────────────

export async function infinitePayWebhookController(
  req: Request,
  res: Response,
): Promise<void> {
  // InfinitePay exige resposta em <1s e retenta se receber 400.
  // Respondemos 200 imediatamente e processamos em background.
  // Erros de negócio (ex: order_nsu não encontrado) são logados mas não retornam 400
  // para evitar reenvios infinitos de webhooks de outros sistemas.
  res.status(200).json({ received: true });

  try {
    const payload = PagamentoReserva.validateWebhook(req.body);
    await handleWebhook(payload);
  } catch (err) {
    console.error('[Webhook InfinitePay] Erro ao processar:', err instanceof Error ? err.message : err);
  }
}
