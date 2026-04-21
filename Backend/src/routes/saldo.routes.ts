import { Router } from 'express';
import { hotelGuard } from '../middlewares/hotelGuard';
import { getSaldoController, sacarSaldoController } from '../controllers/saldo.controller';

const router = Router();

router.get('/saldo',       hotelGuard, getSaldoController);
router.post('/saldo/saque', hotelGuard, sacarSaldoController);

export default router;
