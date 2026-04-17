import { Router } from 'express';
import { authGuard } from '../middlewares/authGuard';
import { requireFields } from '../middlewares/validateBody';
import {
  createAvaliacaoController,
  updateAvaliacaoController,
  listAvaliacoesController,
} from '../controllers/avaliacao.controller';

// ── Router Usuário (/api/usuarios/avaliacoes) ─────────────────────────────────
export const usuarioAvaliacaoRouter = Router();

usuarioAvaliacaoRouter.post(
  '/',
  authGuard,
  requireFields(
    'codigo_publico',
    'nota_limpeza',
    'nota_atendimento',
    'nota_conforto',
    'nota_organizacao',
    'nota_localizacao',
  ),
  createAvaliacaoController,
);

usuarioAvaliacaoRouter.patch('/:codigo_publico', authGuard, updateAvaliacaoController);

// ── Router Público (/api/hotel/:hotel_id/avaliacoes) ──────────────────────────
export const publicAvaliacaoRouter = Router({ mergeParams: true });

publicAvaliacaoRouter.get('/', listAvaliacoesController);
