import { Router } from 'express';
import { hotelGuard } from '../middlewares/hotelGuard';
import { pagamentoPublicLimiter } from '../middlewares/rateLimiter';
import {
  createPagamentoController,
  listPagamentosController,
  infinitePayWebhookController,
  createPagamentoPublicoController,
  getPagamentoPublicoController,
  confirmarPagamentoController,
  cancelarPagamentoController,
} from '../controllers/pagamentoReserva.controller';

// ── Router Hotel (/api/hotel/reservas/:reserva_id/pagamentos) ─────────────────
export const hotelPagamentoRouter = Router({ mergeParams: true });

// POST /api/hotel/reservas/:reserva_id/pagamentos — gera link InfinitePay
hotelPagamentoRouter.post('/', hotelGuard, createPagamentoController);

// GET  /api/hotel/reservas/:reserva_id/pagamentos — lista pagamentos da reserva
hotelPagamentoRouter.get('/',  hotelGuard, listPagamentosController);

// ── Router Webhook (/api/pagamentos/webhook) ──────────────────────────────────
export const webhookPagamentoRouter = Router();

// POST /api/pagamentos/webhook/infinitepay — recebe confirmação da InfinitePay
// Sem auth — InfinitePay não envia token. Idempotência garantida via invoice_slug.
webhookPagamentoRouter.post('/infinitepay', infinitePayWebhookController);

// ── Router Público (/api/reservas/:codigo_publico/pagamentos) ────────────────
// Fluxo fake: criar/consultar/confirmar/cancelar pagamento sem PSP real.
// Chaveado pelo codigo_publico da reserva (opaco) em vez do ID numérico.
export const publicPagamentoRouter = Router({ mergeParams: true });

publicPagamentoRouter.post('/',              pagamentoPublicLimiter, createPagamentoPublicoController);
publicPagamentoRouter.get ('/:id',           pagamentoPublicLimiter, getPagamentoPublicoController);
publicPagamentoRouter.post('/:id/confirmar', pagamentoPublicLimiter, confirmarPagamentoController);
publicPagamentoRouter.post('/:id/cancelar',  pagamentoPublicLimiter, cancelarPagamentoController);
