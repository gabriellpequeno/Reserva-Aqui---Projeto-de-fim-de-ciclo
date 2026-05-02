import { Router } from 'express';
import { sendMessageController } from '../controllers/chat.controller';

const router = Router();

// POST /api/v1/chat/message — endpoint público (sem authGuard)
// JWT opcional: se presente, enriquece a sessão com userId.
router.post('/message', sendMessageController);

export default router;
