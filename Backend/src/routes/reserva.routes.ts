import { Router } from 'express';
import { hotelGuard }  from '../middlewares/hotelGuard';
import { authGuard }   from '../middlewares/authGuard';
import { requireFields } from '../middlewares/validateBody';
import { guestReservaLimiter } from '../middlewares/rateLimiter';
import {
  // Hotel
  createReservaWalkinController,
  listReservasController,
  getReservaByIdController,
  updateStatusController,
  atribuirQuartoController,
  registrarCheckinController,
  registrarCheckoutController,
  // Usuário
  createReservaUsuarioController,
  listReservasUsuarioController,
  cancelarReservaUsuarioController,
  // Público
  createReservaGuestController,
  getReservaPublicaController,
} from '../controllers/reserva.controller';

// ── Router Hotel (/api/hotel/reservas) ────────────────────────────────────────
export const hotelReservaRouter = Router();

hotelReservaRouter.get('/',    hotelGuard, listReservasController);
hotelReservaRouter.get('/:id', hotelGuard, getReservaByIdController);

hotelReservaRouter.post(
  '/',
  hotelGuard,
  requireFields('num_hospedes', 'data_checkin', 'data_checkout', 'valor_total'),
  createReservaWalkinController,
);

hotelReservaRouter.patch('/:id/status',   hotelGuard, requireFields('status'),    updateStatusController);
hotelReservaRouter.patch('/:id/quarto',   hotelGuard, requireFields('quarto_id'), atribuirQuartoController);
hotelReservaRouter.patch('/:id/checkin',  hotelGuard, registrarCheckinController);
hotelReservaRouter.patch('/:id/checkout', hotelGuard, registrarCheckoutController);

// ── Router Usuário (/api/usuarios/reservas) ───────────────────────────────────
export const usuarioReservaRouter = Router();

usuarioReservaRouter.get('/', authGuard, listReservasUsuarioController);

usuarioReservaRouter.post(
  '/',
  authGuard,
  requireFields('hotel_id', 'num_hospedes', 'data_checkin', 'data_checkout', 'valor_total'),
  createReservaUsuarioController,
);

usuarioReservaRouter.patch('/:codigo_publico/cancelar', authGuard, cancelarReservaUsuarioController);

// ── Router Público (/api/reservas) ────────────────────────────────────────────
export const publicReservaRouter = Router();

// Reserva de guest (sem JWT) — rate-limit por IP
publicReservaRouter.post(
  '/guest',
  guestReservaLimiter,
  requireFields(
    'hotel_id', 'num_hospedes', 'data_checkin', 'data_checkout', 'valor_total',
    'nome_hospede', 'email_hospede', 'cpf_hospede', 'telefone_contato',
  ),
  createReservaGuestController,
);

publicReservaRouter.get('/:codigo_publico', getReservaPublicaController);
