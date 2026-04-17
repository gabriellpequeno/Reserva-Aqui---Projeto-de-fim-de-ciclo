import { Router } from 'express';
import { hotelGuard } from '../middlewares/hotelGuard';
import {
  createPagamentoController,
  listPagamentosController,
  infinitePayWebhookController,
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
