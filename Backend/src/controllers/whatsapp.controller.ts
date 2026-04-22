import { Request, Response } from 'express';
import {
  IncomingMediaMetadata,
  logUnsupportedMessageType,
  processIncomingWhatsAppMessage,
  processStatusEvent,
} from '../services/whatsappWebhook.service';

export class WhatsAppController {
  public static verifyWebhook(req: Request, res: Response): void {
    const verifyToken = process.env.WHATSAPP_WEBHOOK_VERIFY_TOKEN;

    const mode = req.query['hub.mode'];
    const token = req.query['hub.verify_token'];
    const challenge = req.query['hub.challenge'];

    if (mode && token) {
      if (mode === 'subscribe' && token === verifyToken) {
        console.log('Webhook verificado com sucesso pela Meta!');
        res.status(200).send(challenge);
      } else {
        console.error('Falha na verificacao: token ou modo invalido.');
        res.sendStatus(403);
      }
    } else {
      res.sendStatus(400);
    }
  }

  public static async receiveMessage(req: Request, res: Response): Promise<void> {
    const body = req.body;
    const changeValue = body?.entry?.[0]?.changes?.[0]?.value;

    if (!body.object) {
      res.sendStatus(404);
      return;
    }

    const message = changeValue?.messages?.[0];
    const statuses = Array.isArray(changeValue?.statuses) ? changeValue.statuses : [];

    if (!message) {
      res.sendStatus(200);

      if (statuses.length) {
        try {
          await processStatusEvent(statuses);
        } catch (error) {
          console.error('Erro ao atualizar status do WhatsApp:', error);
        }
      }

      return;
    }

    const fromNumber = message.from;
    const messageType = message.type;
    const phoneNumberId = changeValue?.metadata?.phone_number_id;
    const configuredPhoneNumberId = process.env.WHATSAPP_PHONE_ID;

    res.sendStatus(200);

    if (!fromNumber) {
      console.warn('[WhatsApp] Payload sem numero de origem; evento ignorado.');
      return;
    }

    if (configuredPhoneNumberId && phoneNumberId && phoneNumberId !== configuredPhoneNumberId) {
      console.warn(`[WhatsApp] phone_number_id inesperado recebido: ${phoneNumberId}. Evento ignorado.`);
      return;
    }

    if (messageType !== 'text' && messageType !== 'audio' && messageType !== 'image' && messageType !== 'document') {
      logUnsupportedMessageType(messageType, fromNumber);
      return;
    }

    const mediaMetadata: IncomingMediaMetadata | undefined =
      messageType === 'audio'
        ? {
            mediaId: message.audio?.id ?? null,
            mimeType: message.audio?.mime_type ?? null,
            caption: null,
            filename: null,
          }
        : messageType === 'image'
          ? {
              mediaId: message.image?.id ?? null,
              mimeType: message.image?.mime_type ?? null,
              caption: message.image?.caption ?? null,
              filename: null,
            }
          : messageType === 'document'
            ? {
                mediaId: message.document?.id ?? null,
                mimeType: message.document?.mime_type ?? null,
                caption: message.document?.caption ?? null,
                filename: message.document?.filename ?? null,
              }
            : undefined;

    if (messageType === 'text') {
      const textBody = typeof message.text?.body === 'string' ? message.text.body.trim() : '';
      if (!textBody) {
        console.warn(`[WhatsApp] Mensagem de texto vazia recebida de ${fromNumber}; evento ignorado.`);
        return;
      }

      try {
        await processIncomingWhatsAppMessage({
          fromNumber,
          messageType: 'text',
          metaMessageId: message.id,
          textBody,
        });
      } catch (error) {
        console.error('Erro no processamento do Banco ou Meta API:', error);
      }

      return;
    }

    try {
      await processIncomingWhatsAppMessage({
        fromNumber,
        messageType,
        metaMessageId: message.id,
        media: mediaMetadata,
      });
    } catch (error) {
      console.error('Erro no processamento do Banco ou Meta API:', error);
    }
  }
}
