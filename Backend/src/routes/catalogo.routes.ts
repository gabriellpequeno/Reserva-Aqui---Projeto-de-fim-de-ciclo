import { Router } from 'express';
import {
  listCatalogoController,
  createCatalogoController,
  updateCatalogoController,
  deleteCatalogoController,
} from '../controllers/catalogo.controller';
import { hotelGuard }    from '../middlewares/hotelGuard';
import { requireFields } from '../middlewares/validateBody';

const router = Router();

// ── Rota Pública ──────────────────────────────────────────────────────────────

// Lista todos os itens ativos do catálogo de um hotel
// Usado pelo app do hóspede para exibir comodidades/cômodos/lazer do hotel
router.get('/:hotel_id/catalogo', listCatalogoController);

// ── Rotas Protegidas (Requerem hotelGuard) ────────────────────────────────────

// Cria um novo item no catálogo do hotel autenticado
router.post(
  '/catalogo',
  hotelGuard,
  requireFields('nome', 'categoria'),
  createCatalogoController,
);

// Edita o nome de um item (categoria imutável após criação)
router.patch(
  '/catalogo/:id',
  hotelGuard,
  requireFields('nome'),
  updateCatalogoController,
);

// Soft delete de um item (deleted_at = NOW())
router.delete(
  '/catalogo/:id',
  hotelGuard,
  deleteCatalogoController,
);

export default router;
