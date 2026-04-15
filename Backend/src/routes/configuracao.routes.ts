import { Router } from 'express';
import {
  getConfiguracaoHotelController,
  createConfiguracaoHotelController,
  updateConfiguracaoHotelController,
} from '../controllers/configuracao.controller';
import { hotelGuard } from '../middlewares/hotelGuard';

const router = Router();

// ── Rota Pública ──────────────────────────────────────────────────────────────

// Retorna as políticas operacionais do hotel (horários, animais, cancelamento)
// Usado pelo app do hóspede na tela de detalhes do hotel
router.get('/:hotel_id/configuracao', getConfiguracaoHotelController);

// ── Rotas Protegidas (Requerem hotelGuard) ────────────────────────────────────

// Cria a configuração inicial do hotel (necessário antes do primeiro uso)
router.post('/configuracao', hotelGuard, createConfiguracaoHotelController);

// Atualiza parcialmente a configuração do hotel
router.patch('/configuracao', hotelGuard, updateConfiguracaoHotelController);

export default router;
