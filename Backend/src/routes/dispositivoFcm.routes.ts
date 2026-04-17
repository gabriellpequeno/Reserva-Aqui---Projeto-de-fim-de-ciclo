import { Router } from 'express';
import { authGuard }   from '../middlewares/authGuard';
import { hotelGuard }  from '../middlewares/hotelGuard';
import { requireFields } from '../middlewares/validateBody';
import {
  registerUserTokenController,
  registerHotelTokenController,
  removeTokenController,
} from '../controllers/dispositivoFcm.controller';

const router = Router();

// POST /api/dispositivos-fcm/usuario — app Flutter registra token após login do hóspede
router.post('/usuario', authGuard,  requireFields('fcm_token'), registerUserTokenController);

// POST /api/dispositivos-fcm/hotel — dashboard registra token após login do hotel
router.post('/hotel',   hotelGuard, requireFields('fcm_token'), registerHotelTokenController);

// DELETE /api/dispositivos-fcm/usuario — hóspede remove token no logout
router.delete('/usuario', authGuard,  requireFields('fcm_token'), removeTokenController);

// DELETE /api/dispositivos-fcm/hotel — hotel remove token no logout
router.delete('/hotel',   hotelGuard, requireFields('fcm_token'), removeTokenController);

export default router;
