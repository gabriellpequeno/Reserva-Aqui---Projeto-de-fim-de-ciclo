import { Router } from 'express';
import {
  listUsersController,
  updateUserController,
  listHotelsController,
  updateHotelController,
} from '../controllers/admin.controller';
import { adminGuard } from '../middlewares/adminGuard';

const router = Router();

// ── Usuários ──────────────────────────────────────────────────────────────────
// PATCH aceita `status` e/ou campos de dados (nome, email, telefone).
// A validação do body é feita no controller, porque o shape é dinâmico.

router.get('/users',      adminGuard, listUsersController);
router.patch('/users/:id', adminGuard, updateUserController);

// ── Hotéis ────────────────────────────────────────────────────────────────────

router.get('/hotels',      adminGuard, listHotelsController);
router.patch('/hotels/:id', adminGuard, updateHotelController);

export default router;
