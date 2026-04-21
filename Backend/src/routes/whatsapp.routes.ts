import { Router } from 'express';
import { WhatsAppController } from '../controllers/whatsapp.controller';

const router = Router();

// A Meta faz um GET requisição na hora de configurar o Webhook no painel
router.get('/webhook', WhatsAppController.verifyWebhook);

// A Meta faz requisições POST para cada mensagem nova do cliente
router.post('/webhook', WhatsAppController.receiveMessage);

export default router;
