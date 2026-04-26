import { Router } from 'express';
import { handleSearchRooms } from '../controllers/searchRoom.controller';

const router = Router();

/**
 * GET /api/quartos/busca
 * Busca pública de quartos cross-tenant
 * Query params: q (obrigatório), checkin?, checkout?, hospedes?
 */
router.get('/busca', handleSearchRooms);

export default router;
