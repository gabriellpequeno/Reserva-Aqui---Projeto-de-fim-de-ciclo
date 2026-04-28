import { Router } from 'express';
import { handleSearchRooms } from '../controllers/searchRoom.controller';
import { handleGetRecommendedRooms } from '../controllers/recommendedRooms.controller';

const router = Router();

/**
 * GET /api/quartos/busca
 * Busca pública de quartos cross-tenant
 * Query params: q (obrigatório), checkin?, checkout?, hospedes?
 */
router.get('/busca', handleSearchRooms);

// Rota pública — GET /api/quartos/recomendados
router.get('/recomendados', handleGetRecommendedRooms);

export default router;
