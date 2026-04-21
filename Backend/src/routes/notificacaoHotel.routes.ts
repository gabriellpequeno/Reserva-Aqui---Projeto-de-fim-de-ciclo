import { Router } from 'express';
import { hotelGuard } from '../middlewares/hotelGuard';
import {
  listNotificacoesController,
  marcarLidaController,
  marcarTodasLidasController,
} from '../controllers/notificacaoHotel.controller';

const router = Router();

// GET  /api/hotel/notificacoes?nao_lidas=true — lista notificações (todas ou só não lidas)
router.get('/',               hotelGuard, listNotificacoesController);

// PATCH /api/hotel/notificacoes/lida-todas — marca todas como lidas
// (deve vir antes de /:id para não ser capturado como id="lida-todas")
router.patch('/lida-todas',   hotelGuard, marcarTodasLidasController);

// PATCH /api/hotel/notificacoes/:id/lida — marca uma como lida
router.patch('/:id/lida',     hotelGuard, marcarLidaController);

export default router;
