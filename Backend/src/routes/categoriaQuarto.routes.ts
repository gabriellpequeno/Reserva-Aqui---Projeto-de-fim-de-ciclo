import { Router } from 'express';
import {
  listCategoriasController,
  getCategoriaController,
  createCategoriaController,
  updateCategoriaController,
  deleteCategoriaController,
  addItemCategoriaController,
  removeItemCategoriaController,
  verificarDisponibilidadeController,
} from '../controllers/categoriaQuarto.controller';
import { hotelGuard }    from '../middlewares/hotelGuard';
import { requireFields } from '../middlewares/validateBody';

const router = Router();

// ── Rotas Públicas ────────────────────────────────────────────────────────────

// Deve vir antes de /:hotel_id/categorias/:id para não ser capturado como parâmetro
router.get('/:hotel_id/disponibilidade', verificarDisponibilidadeController);

router.get('/:hotel_id/categorias',     listCategoriasController);
router.get('/:hotel_id/categorias/:id', getCategoriaController);

// ── Rotas Protegidas (Requerem hotelGuard) ────────────────────────────────────

router.post(
  '/categorias',
  hotelGuard,
  requireFields('nome', 'preco_base', 'capacidade_pessoas'),
  createCategoriaController,
);

router.patch('/categorias/:id',  hotelGuard, updateCategoriaController);
router.delete('/categorias/:id', hotelGuard, deleteCategoriaController);

// ── Itens da Categoria ────────────────────────────────────────────────────────

router.post(
  '/categorias/:id/itens',
  hotelGuard,
  requireFields('catalogo_id'),
  addItemCategoriaController,
);

router.delete(
  '/categorias/:id/itens/:catalogo_id',
  hotelGuard,
  removeItemCategoriaController,
);

export default router;
