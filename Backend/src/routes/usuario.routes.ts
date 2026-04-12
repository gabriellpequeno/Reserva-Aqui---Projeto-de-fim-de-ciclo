import { Router } from 'express';
import {
  registerUsuarioController,
  loginUsuarioController,
  refreshUsuarioTokenController,
  logoutUsuarioController,
  getMeController,
  updateMeController,
  changePasswordController,
  deleteMeController,
} from '../controllers/usuario.controller';
import { loginRateLimiter } from '../middlewares/rateLimiter';
import { authGuard } from '../middlewares/authGuard';
import { requireFields } from '../middlewares/validateBody';

const router = Router();

// ── Rotas Públicas ────────────────────────────────────────────────────────────

// Registro requer os campos base
router.post(
  '/register',
  requireFields('nome_completo', 'email', 'senha', 'cpf', 'data_nascimento'),
  registerUsuarioController
);

// Login usa o rate limiter
router.post(
  '/login',
  loginRateLimiter,
  requireFields('email', 'senha'),
  loginUsuarioController
);

// Refresh do token usa apenas o refreshToken enviado no body
router.post(
  '/refresh',
  requireFields('refreshToken'),
  refreshUsuarioTokenController
);

// ── Rotas Protegidas (Requerem authGuard) ─────────────────────────────────────

// Logout requer apenas o refreshToken para revogação do DB (token de acesso já está no header para validação)
router.post(
  '/logout',
  authGuard,
  requireFields('refreshToken'),
  logoutUsuarioController
);

// CRUD perfil
router.get('/me', authGuard, getMeController);
router.patch('/me', authGuard, updateMeController);
router.delete('/me', authGuard, deleteMeController);

// Troca de senha
router.post(
  '/change-password',
  authGuard,
  requireFields('senhaAtual', 'novaSenha'),
  changePasswordController
);

export default router;
