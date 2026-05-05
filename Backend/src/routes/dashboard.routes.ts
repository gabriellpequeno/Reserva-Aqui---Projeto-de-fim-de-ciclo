import { Router } from 'express';
import { hotelGuard } from '../middlewares/hotelGuard';
import { adminGuard } from '../middlewares/adminGuard';
import {
  getHostDashboardController,
  getAdminDashboardController,
} from '../controllers/dashboard.controller';

// ── Host Dashboard ────────────────────────────────────────────────────────────
// Montado em `${API_PREFIX}/host/dashboard` → expõe GET /

export const hostDashboardRouter = Router();
hostDashboardRouter.get('/', hotelGuard, getHostDashboardController);

// ── Admin Dashboard ───────────────────────────────────────────────────────────
// Montado em `${API_PREFIX}/admin/dashboard` → expõe GET /

export const adminDashboardRouter = Router();
adminDashboardRouter.get('/', adminGuard, getAdminDashboardController);
