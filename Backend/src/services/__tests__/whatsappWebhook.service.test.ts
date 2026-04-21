jest.mock('../../database/masterDb', () => ({
  masterPool: {
    query: jest.fn(),
  },
}));

jest.mock('../whatsapp.service', () => ({
  WhatsAppService: {
    sendText: jest.fn(),
    sendTemplate: jest.fn(),
    sendDocument: jest.fn(),
  },
}));

import { masterPool } from '../../database/masterDb';
import { WhatsAppService } from '../whatsapp.service';
import {
  processIncomingWhatsAppMessage,
  processStatusEvent,
} from '../whatsappWebhook.service';

type QueryCall = [string, unknown[]?];

const queryMock = masterPool.query as jest.Mock;
const sendTextMock = WhatsAppService.sendText as jest.Mock;

function normalizeSql(sql: string): string {
  return sql.replace(/\s+/g, ' ').trim();
}

describe('whatsappWebhook.service', () => {
  beforeEach(() => {
    process.env.WHATSAPP_SESSION_IDLE_HOURS = '24';
    queryMock.mockReset();
    sendTextMock.mockReset();
    sendTextMock.mockResolvedValue({ messages: [{ id: 'meta-msg-1' }] });
  });

  it('deduplica inbound por wamid e nao reprocesa a mesma mensagem', async () => {
    queryMock.mockImplementation(async (sql: string) => {
      const normalizedSql = normalizeSql(sql);

      if (normalizedSql.includes('FROM mensagem_chat') && normalizedSql.includes('meta_message_id = $1')) {
        return { rows: [{ id: 'existing-msg-1' }] };
      }

      return { rows: [] };
    });

    await processIncomingWhatsAppMessage({
      fromNumber: '5581999991234',
      messageType: 'text',
      metaMessageId: 'wamid.text.dup',
      textBody: 'oi',
    });

    expect(sendTextMock).not.toHaveBeenCalled();
    expect(queryMock.mock.calls).toHaveLength(1);
  });

  it('cria sessao global, vincula usuario, persiste inbound com wamid e outbound com meta id e status inicial', async () => {
    queryMock.mockImplementation(async (sql: string) => {
      const normalizedSql = normalizeSql(sql);

      if (normalizedSql.includes('FROM mensagem_chat') && normalizedSql.includes('meta_message_id = $1')) {
        return { rows: [] };
      }

      if (normalizedSql.includes('FROM usuario')) {
        return { rows: [{ user_id: 'user-1' }] };
      }

      if (normalizedSql.includes('FROM sessao_chat')) {
        return { rows: [] };
      }

      if (normalizedSql.includes('INSERT INTO sessao_chat')) {
        return { rows: [{ id: 'session-1' }] };
      }

      return { rows: [] };
    });

    await processIncomingWhatsAppMessage({
      fromNumber: '+55 (81) 99999-1234',
      messageType: 'text',
      metaMessageId: 'wamid.text.1',
      textBody: 'tem piscina?',
    });

    expect(sendTextMock).toHaveBeenCalledWith(
      '5581999991234',
      'Ola! Recebemos sua mensagem "tem piscina?". Nosso assistente inteligente sera ativado em breve.',
    );

    const calls = queryMock.mock.calls as QueryCall[];
    const messageInserts = calls.filter(([sql]) => normalizeSql(sql).includes('INSERT INTO mensagem_chat'));

    expect(messageInserts).toHaveLength(2);
    expect(messageInserts[0][1]).toEqual([
      'session-1',
      'CLIENTE',
      'tem piscina?',
      'TEXT',
      'wamid.text.1',
      null,
      { source: 'whatsapp' },
    ]);
    expect(messageInserts[1][1]).toEqual([
      'session-1',
      'BOT_SISTEMA',
      'Ola! Recebemos sua mensagem "tem piscina?". Nosso assistente inteligente sera ativado em breve.',
      'TEXT',
      'meta-msg-1',
      'ACCEPTED',
      { deliveryChannel: 'WHATSAPP', usedTemplate: false },
    ]);
  });

  it('fecha a sessao antiga por inatividade e cria uma nova sessao aberta', async () => {
    queryMock.mockImplementation(async (sql: string) => {
      const normalizedSql = normalizeSql(sql);

      if (normalizedSql.includes('FROM mensagem_chat') && normalizedSql.includes('meta_message_id = $1')) {
        return { rows: [] };
      }

      if (normalizedSql.includes('FROM usuario')) {
        return { rows: [] };
      }

      if (normalizedSql.includes('FROM sessao_chat')) {
        return {
          rows: [
            {
              id: 'session-old',
              user_id: null,
              atualizado_em: '2024-01-01T00:00:00.000Z',
            },
          ],
        };
      }

      if (normalizedSql.includes('UPDATE sessao_chat') && normalizedSql.includes("status = 'FECHADA'")) {
        return { rows: [] };
      }

      if (normalizedSql.includes('INSERT INTO sessao_chat')) {
        return { rows: [{ id: 'session-new' }] };
      }

      return { rows: [] };
    });

    await processIncomingWhatsAppMessage({
      fromNumber: '5581999991234',
      messageType: 'text',
      metaMessageId: 'wamid.text.2',
      textBody: 'ola',
    });

    const calls = queryMock.mock.calls as QueryCall[];
    const closeOldSession = calls.find(
      ([sql]) =>
        normalizeSql(sql).includes('UPDATE sessao_chat') &&
        normalizeSql(sql).includes("status = 'FECHADA'"),
    );

    expect(closeOldSession?.[1]).toEqual(['session-old']);

    const sessionInsert = calls.find(([sql]) => normalizeSql(sql).includes('INSERT INTO sessao_chat'));
    expect(sessionInsert?.[1]).toEqual(['WHATSAPP', '5581999991234', null, 'ABERTA']);
  });

  it('persiste metadados de imagem e responde com mensagem amigavel simples', async () => {
    queryMock.mockImplementation(async (sql: string) => {
      const normalizedSql = normalizeSql(sql);

      if (normalizedSql.includes('FROM mensagem_chat') && normalizedSql.includes('meta_message_id = $1')) {
        return { rows: [] };
      }

      if (normalizedSql.includes('FROM usuario')) {
        return { rows: [] };
      }

      if (normalizedSql.includes('FROM sessao_chat')) {
        return { rows: [] };
      }

      if (normalizedSql.includes('INSERT INTO sessao_chat')) {
        return { rows: [{ id: 'session-media' }] };
      }

      return { rows: [] };
    });

    await processIncomingWhatsAppMessage({
      fromNumber: '5581999991234',
      messageType: 'image',
      metaMessageId: 'wamid.image.1',
      media: {
        mediaId: 'media-1',
        mimeType: 'image/jpeg',
        caption: 'fachada',
        filename: null,
      },
    });

    expect(sendTextMock).toHaveBeenCalledWith(
      '5581999991234',
      'Recebi sua imagem. Ainda nao consigo processa-la automaticamente, mas sua mensagem ja foi registrada.',
    );

    const calls = queryMock.mock.calls as QueryCall[];
    const messageInserts = calls.filter(([sql]) => normalizeSql(sql).includes('INSERT INTO mensagem_chat'));

    expect(messageInserts[0][1]).toEqual([
      'session-media',
      'CLIENTE',
      '[image] fachada',
      'IMAGE',
      'wamid.image.1',
      null,
      {
        source: 'whatsapp',
        mediaId: 'media-1',
        mimeType: 'image/jpeg',
        caption: 'fachada',
        filename: null,
      },
    ]);
  });

  it('atualiza apenas o ultimo status conhecido da mensagem outbound', async () => {
    await processStatusEvent([
      { id: 'meta-msg-1', status: 'delivered' },
    ]);

    expect(queryMock).toHaveBeenCalledWith(
      expect.stringContaining('UPDATE mensagem_chat'),
      ['meta-msg-1', 'delivered', { lastStatusSource: 'whatsapp-webhook' }],
    );
  });
});
