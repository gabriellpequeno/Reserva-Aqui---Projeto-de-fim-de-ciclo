import { Router } from 'express';
import {
  listCategoriasController,
  getCategoriaController,
  createCategoriaController,
  updateCategoriaController,
  deleteCategoriaController,
  addItemCategoriaController,
  removeItemCategoriaController,
} from '../controllers/categoriaQuarto.controller';
import { hotelGuard }    from '../middlewares/hotelGuard';
import { requireFields } from '../middlewares/validateBody';

const router = Router();

// ── Rotas Públicas ────────────────────────────────────────────────────────────

// Lista todos os tipos de quarto ativos com itens de catálogo incluídos
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
