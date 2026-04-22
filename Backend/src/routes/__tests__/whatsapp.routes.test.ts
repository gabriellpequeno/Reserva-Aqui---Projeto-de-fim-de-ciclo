jest.mock('../../services/whatsappWebhook.service', () => ({
  processIncomingWhatsAppMessage: jest.fn().mockResolvedValue(undefined),
  processStatusEvent: jest.fn().mockResolvedValue(undefined),
  logUnsupportedMessageType: jest.fn(),
}));

import express from 'express';
import request from 'supertest';
import whatsappRoutes from '../whatsapp.routes';
import {
  logUnsupportedMessageType,
  processIncomingWhatsAppMessage,
  processStatusEvent,
} from '../../services/whatsappWebhook.service';

const processIncomingWhatsAppMessageMock = processIncomingWhatsAppMessage as jest.Mock;
const processStatusEventMock = processStatusEvent as jest.Mock;
const logUnsupportedMessageTypeMock = logUnsupportedMessageType as jest.Mock;

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/v1/whatsapp', whatsappRoutes);
  return app;
}

function flushPromises(): Promise<void> {
  return new Promise((resolve) => setImmediate(resolve));
}

describe('whatsapp.routes', () => {
  beforeEach(() => {
    process.env.WHATSAPP_WEBHOOK_VERIFY_TOKEN = 'verify-token';
    process.env.WHATSAPP_PHONE_ID = '1042015812332979';
    processIncomingWhatsAppMessageMock.mockClear();
    processStatusEventMock.mockClear();
    logUnsupportedMessageTypeMock.mockClear();
  });

  it('retorna challenge quando o token da Meta esta correto', async () => {
    const app = createApp();

    const response = await request(app)
      .get('/api/v1/whatsapp/webhook')
      .query({
        'hub.mode': 'subscribe',
        'hub.verify_token': 'verify-token',
        'hub.challenge': '123456',
      });

    expect(response.status).toBe(200);
    expect(response.text).toBe('123456');
  });

  it('retorna 403 quando o token da Meta esta incorreto', async () => {
    const app = createApp();

    await request(app)
      .get('/api/v1/whatsapp/webhook')
      .query({
        'hub.mode': 'subscribe',
        'hub.verify_token': 'invalid-token',
        'hub.challenge': '123456',
      })
      .expect(403);
  });

  it('encaminha evento de status para atualizacao do ultimo status outbound', async () => {
    const app = createApp();

    await request(app)
      .post('/api/v1/whatsapp/webhook')
      .send({
        object: 'whatsapp_business_account',
        entry: [
          {
            changes: [
              {
                value: {
                  statuses: [{ id: 'wamid.status.1', status: 'delivered' }],
                },
              },
            ],
          },
        ],
      })
      .expect(200);

    await flushPromises();
    expect(processStatusEventMock).toHaveBeenCalledWith([
      { id: 'wamid.status.1', status: 'delivered' },
    ]);
    expect(processIncomingWhatsAppMessageMock).not.toHaveBeenCalled();
  });

  it('encaminha mensagens de texto validas com wamid para o servico de processamento', async () => {
    const app = createApp();

    await request(app)
      .post('/api/v1/whatsapp/webhook')
      .send({
        object: 'whatsapp_business_account',
        entry: [
          {
            changes: [
              {
                value: {
                  metadata: { phone_number_id: '1042015812332979' },
                  messages: [
                    {
                      id: 'wamid.text.1',
                      from: '5581999991234',
                      type: 'text',
                      text: { body: 'Tem estacionamento?' },
                    },
                  ],
                },
              },
            ],
          },
        ],
      })
      .expect(200);

    await flushPromises();
    expect(processIncomingWhatsAppMessageMock).toHaveBeenCalledWith({
      fromNumber: '5581999991234',
      messageType: 'text',
      metaMessageId: 'wamid.text.1',
      textBody: 'Tem estacionamento?',
    });
  });

  it('encaminha imagem com metadados para o servico de processamento', async () => {
    const app = createApp();

    await request(app)
      .post('/api/v1/whatsapp/webhook')
      .send({
        object: 'whatsapp_business_account',
        entry: [
          {
            changes: [
              {
                value: {
                  metadata: { phone_number_id: '1042015812332979' },
                  messages: [
                    {
                      id: 'wamid.image.1',
                      from: '5581999991234',
                      type: 'image',
                      image: {
                        id: 'media-1',
                        mime_type: 'image/jpeg',
                        caption: 'foto da fachada',
                      },
                    },
                  ],
                },
              },
            ],
          },
        ],
      })
      .expect(200);

    await flushPromises();
    expect(processIncomingWhatsAppMessageMock).toHaveBeenCalledWith({
      fromNumber: '5581999991234',
      messageType: 'image',
      metaMessageId: 'wamid.image.1',
      media: {
        mediaId: 'media-1',
        mimeType: 'image/jpeg',
        caption: 'foto da fachada',
        filename: null,
      },
    });
  });

  it('ignora payload com phone_number_id diferente do canal configurado', async () => {
    const app = createApp();

    await request(app)
      .post('/api/v1/whatsapp/webhook')
      .send({
        object: 'whatsapp_business_account',
        entry: [
          {
            changes: [
              {
                value: {
                  metadata: { phone_number_id: '9999999999999999' },
                  messages: [
                    {
                      id: 'wamid.text.2',
                      from: '5581999991234',
                      type: 'text',
                      text: { body: 'Ola' },
                    },
                  ],
                },
              },
            ],
          },
        ],
      })
      .expect(200);

    await flushPromises();
    expect(processIncomingWhatsAppMessageMock).not.toHaveBeenCalled();
    expect(processStatusEventMock).not.toHaveBeenCalled();
  });

  it('mantem log para tipos ainda nao suportados pelo fluxo', async () => {
    const app = createApp();

    await request(app)
      .post('/api/v1/whatsapp/webhook')
      .send({
        object: 'whatsapp_business_account',
        entry: [
          {
            changes: [
              {
                value: {
                  metadata: { phone_number_id: '1042015812332979' },
                  messages: [
                    {
                      id: 'wamid.location.1',
                      from: '5581999991234',
                      type: 'location',
                    },
                  ],
                },
              },
            ],
          },
        ],
      })
      .expect(200);

    await flushPromises();
    expect(processIncomingWhatsAppMessageMock).not.toHaveBeenCalled();
    expect(logUnsupportedMessageTypeMock).toHaveBeenCalledWith('location', '5581999991234');
  });
});
