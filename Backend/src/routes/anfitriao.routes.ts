import { Router } from 'express';
import {
  registerAnfitriaoController,
  loginAnfitriaoController,
  refreshAnfitriaoTokenController,
  logoutAnfitriaoController,
  getHotelMeController,
  updateHotelMeController,
  changeHotelPasswordController,
  deleteHotelMeController,
} from '../controllers/anfitriao.controller';
import { loginRateLimiter } from '../middlewares/rateLimiter';
import { hotelGuard } from '../middlewares/hotelGuard';
import { requireFields } from '../middlewares/validateBody';

const router = Router();

// ── Rotas Públicas ────────────────────────────────────────────────────────────

// Cadastro requer dados obrigatórios do hotel
router.post(
  '/register',
  requireFields('nome_hotel', 'cnpj', 'telefone', 'email', 'senha', 'cep', 'uf', 'cidade', 'bairro', 'rua', 'numero'),
  registerAnfitriaoController,
);

// Login usa o rate limiter (compartilhado com usuario)
router.post(
  '/login',
  loginRateLimiter,
  requireFields('email', 'senha'),
  loginAnfitriaoController,
);

// Refresh usa o refreshToken enviado no body
router.post(
  '/refresh',
  requireFields('refreshToken'),
  refreshAnfitriaoTokenController,
);

// ── Rotas Protegidas (Requerem hotelGuard) ────────────────────────────────────

// Logout revoga o refresh token via DB
router.post(
  '/logout',
  hotelGuard,
  requireFields('refreshToken'),
  logoutAnfitriaoController,
);

// CRUD perfil do hotel
router.get('/me',    hotelGuard, getHotelMeController);
router.patch('/me',  hotelGuard, updateHotelMeController);
router.delete('/me', hotelGuard, deleteHotelMeController);

// Troca de senha
router.post(
  '/change-password',
  hotelGuard,
  requireFields('senhaAtual', 'novaSenha'),
  changeHotelPasswordController,
);

export default router;
