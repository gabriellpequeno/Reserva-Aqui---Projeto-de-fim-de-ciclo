jest.mock('../../services/whatsappWebhook.service', () => ({
  processIncomingTextMessage: jest.fn().mockResolvedValue(undefined),
  logUnsupportedMessageType: jest.fn(),
}));

import express from 'express';
import request from 'supertest';
import whatsappRoutes from '../whatsapp.routes';
import {
  logUnsupportedMessageType,
  processIncomingTextMessage,
} from '../../services/whatsappWebhook.service';

const processIncomingTextMessageMock = processIncomingTextMessage as jest.Mock;
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
    processIncomingTextMessageMock.mockClear();
    logUnsupportedMessageTypeMock.mockClear();
  });

  it('retorna challenge quando o token da Meta está correto', async () => {
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

  it('retorna 403 quando o token da Meta está incorreto', async () => {
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

  it('retorna 200 em evento de status sem chamar o processamento do bot', async () => {
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
    expect(processIncomingTextMessageMock).not.toHaveBeenCalled();
  });

  it('retorna 200 para payload sem texto e não quebra o fluxo', async () => {
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
                      from: '5581999991234',
                      type: 'image',
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
    expect(processIncomingTextMessageMock).not.toHaveBeenCalled();
    expect(logUnsupportedMessageTypeMock).toHaveBeenCalledWith('image', '5581999991234');
  });

  it('encaminha mensagens de texto válidas para o serviço de processamento', async () => {
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
    expect(processIncomingTextMessageMock).toHaveBeenCalledWith({
      fromNumber: '5581999991234',
      incomingText: 'Tem estacionamento?',
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
                      from: '5581999991234',
                      type: 'text',
                      text: { body: 'Olá' },
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
    expect(processIncomingTextMessageMock).not.toHaveBeenCalled();
  });
});
