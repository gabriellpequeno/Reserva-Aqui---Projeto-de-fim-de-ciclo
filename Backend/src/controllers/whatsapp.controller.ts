import { Request, Response } from 'express';
import {
  logUnsupportedMessageType,
  processIncomingTextMessage,
} from '../services/whatsappWebhook.service';

export class WhatsAppController {
  
  /**
   * Endpoint passivo exigido pela Meta para cadastrar o Webhook.
   * Ele valida o token `hub.verify_token` que você definiu no painel e no .env
   */
  public static verifyWebhook(req: Request, res: Response): void {
    const VERIFY_TOKEN = process.env.WHATSAPP_WEBHOOK_VERIFY_TOKEN;

    const mode = req.query['hub.mode'];
    const token = req.query['hub.verify_token'];
    const challenge = req.query['hub.challenge'];

    if (mode && token) {
      if (mode === 'subscribe' && token === VERIFY_TOKEN) {
        console.log('✅ Webhook verificado com sucesso pela Meta!');
        res.status(200).send(challenge);
      } else {
        console.error('❌ Falha na verificação: Token ou Modo inválido.');
        res.sendStatus(403);
      }
    } else {
      res.sendStatus(400);
    }
  }

  /**
   * Endpoint ativo onde a Meta envia as mensagens novas do cliente (Eventos POST).
   */
  public static async receiveMessage(req: Request, res: Response): Promise<void> {
    const body = req.body;
    const changeValue = body?.entry?.[0]?.changes?.[0]?.value;

    // Log seguro: nunca expor payload completo em produção
    if (process.env.NODE_ENV === 'development') {
      console.log('[WEBHOOK] Payload recebido de:', changeValue?.messages?.[0]?.from ?? 'status-event');
    }

    // Verifica se é um evento da API do WhatsApp
    if (body.object) {
      const message = changeValue?.messages?.[0];

      if (!message) {
        // Evento de Status (entregue, lida, falha) e não de Mensagem Nova
        res.sendStatus(200);
        return;
      }

      const fromNumber = message.from;
      const messageType = message.type;
      const phoneNumberId = changeValue?.metadata?.phone_number_id;
      const configuredPhoneNumberId = process.env.WHATSAPP_PHONE_ID;

      // Responde 200 PRAZO CURTO para a Meta não achar que deu Timeout (Regra crítica)
      res.sendStatus(200);

      if (!fromNumber) {
        console.warn('[WhatsApp] Payload sem número de origem; evento ignorado.');
        return;
      }

      if (messageType !== 'text') {
        logUnsupportedMessageType(messageType, fromNumber);
        return;
      }

      const incomingText = typeof message.text?.body === 'string' ? message.text.body.trim() : '';
      if (!incomingText) {
        console.warn(`[WhatsApp] Mensagem de texto vazia recebida de ${fromNumber}; evento ignorado.`);
        return;
      }

      if (configuredPhoneNumberId && phoneNumberId && phoneNumberId !== configuredPhoneNumberId) {
        console.warn(`[WhatsApp] phone_number_id inesperado recebido: ${phoneNumberId}. Evento ignorado.`);
        return;
      }

      try {
        await processIncomingTextMessage({
          fromNumber,
          incomingText,
        });
      } catch (error) {
        console.error('❌ Erro no processamento do Banco ou Meta API:', error);
      }
    } else {
      res.sendStatus(404);
    }
  }
}
