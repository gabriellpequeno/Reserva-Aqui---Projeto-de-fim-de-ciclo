import { Router } from 'express';
import {
  listQuartosController,
  getQuartoController,
  createQuartoController,
  updateQuartoController,
  deleteQuartoController,
} from '../controllers/quarto.controller';
import { hotelGuard }    from '../middlewares/hotelGuard';
import { requireFields } from '../middlewares/validateBody';

const router = Router();

// Todos os endpoints de quartos exigem hotelGuard — gerenciamento interno do hotel
router.get('/quartos',     hotelGuard, listQuartosController);
router.get('/quartos/:id', hotelGuard, getQuartoController);

router.post(
  '/quartos',
  hotelGuard,
  requireFields('numero', 'categoria_quarto_id'),
  createQuartoController,
);

router.patch('/quartos/:id',  hotelGuard, updateQuartoController);
router.delete('/quartos/:id', hotelGuard, deleteQuartoController);

export default router;
