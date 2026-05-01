import { Router } from 'express';
import {
  listUsersController,
  updateUserStatusController,
  listHotelsController,
  updateHotelStatusController,
} from '../controllers/admin.controller';
import { adminGuard } from '../middlewares/adminGuard';
import { requireFields } from '../middlewares/validateBody';

const router = Router();

// ── Usuários ──────────────────────────────────────────────────────────────────

router.get('/users', adminGuard, listUsersController);
router.patch(
  '/users/:id',
  adminGuard,
  requireFields('status'),
  updateUserStatusController,
);

// ── Hotéis ────────────────────────────────────────────────────────────────────

router.get('/hotels', adminGuard, listHotelsController);
router.patch(
  '/hotels/:id',
  adminGuard,
  requireFields('status'),
  updateHotelStatusController,
);

export default router;
