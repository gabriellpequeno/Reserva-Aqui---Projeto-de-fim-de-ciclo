jest.mock('../../database/masterDb', () => ({
  masterPool: {
    query: jest.fn(),
  },
}));

jest.mock('../whatsapp.service', () => ({
  WhatsAppService: {
    sendText: jest.fn(),
  },
}));

import { masterPool } from '../../database/masterDb';
import { WhatsAppService } from '../whatsapp.service';
import { processIncomingTextMessage } from '../whatsappWebhook.service';

type QueryCall = [string, unknown[]?];

const queryMock = masterPool.query as jest.Mock;
const sendTextMock = WhatsAppService.sendText as jest.Mock;

function normalizeSql(sql: string): string {
  return sql.replace(/\s+/g, ' ').trim();
}

describe('whatsappWebhook.service', () => {
  beforeEach(() => {
    queryMock.mockReset();
    sendTextMock.mockReset();
    sendTextMock.mockResolvedValue({ messages: [{ id: 'meta-msg-1' }] });
  });

  it('cria sessão global do WhatsApp, vincula usuário por telefone e persiste resposta provisória', async () => {
    queryMock.mockImplementation(async (sql: string) => {
      const normalizedSql = normalizeSql(sql);

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

    await processIncomingTextMessage({
      fromNumber: '+55 (81) 99999-1234',
      incomingText: 'tem piscina?',
    });

    expect(sendTextMock).toHaveBeenCalledWith(
      '5581999991234',
      'Olá! Recebemos sua mensagem "tem piscina?". Nosso assistente inteligente será ativado em breve.',
    );

    const calls = queryMock.mock.calls as QueryCall[];

    const sessionInsert = calls.find(([sql]) => normalizeSql(sql).includes('INSERT INTO sessao_chat'));
    expect(sessionInsert?.[1]).toEqual(['WHATSAPP', '5581999991234', 'user-1', 'ABERTA']);

    const messageInserts = calls.filter(([sql]) => normalizeSql(sql).includes('INSERT INTO mensagem_chat'));
    expect(messageInserts).toHaveLength(2);
    expect(messageInserts[0][1]).toEqual(['session-1', 'CLIENTE', 'tem piscina?']);
    expect(messageInserts[1][1]).toEqual([
      'session-1',
      'BOT_SISTEMA',
      'Olá! Recebemos sua mensagem "tem piscina?". Nosso assistente inteligente será ativado em breve.',
    ]);
  });

  it('reutiliza a sessão aberta para o mesmo número', async () => {
    queryMock.mockImplementation(async (sql: string) => {
      const normalizedSql = normalizeSql(sql);

      if (normalizedSql.includes('FROM usuario')) {
        return { rows: [] };
      }

      if (normalizedSql.includes('FROM sessao_chat')) {
        return { rows: [{ id: 'session-1', user_id: null, hotel_id: null }] };
      }

      return { rows: [] };
    });

    await processIncomingTextMessage({
      fromNumber: '5581999991234',
      incomingText: 'qual o horário do café?',
    });

    const calls = queryMock.mock.calls as QueryCall[];
    const sessionInsert = calls.find(([sql]) => normalizeSql(sql).includes('INSERT INTO sessao_chat'));

    expect(sessionInsert).toBeUndefined();

    const clientInsert = calls.find(
      ([sql, params]) =>
        normalizeSql(sql).includes('INSERT INTO mensagem_chat') &&
        params?.[1] === 'CLIENTE',
    );

    expect(clientInsert?.[1]).toEqual(['session-1', 'CLIENTE', 'qual o horário do café?']);
  });

  it('mantém guest quando não encontra usuário pelo telefone', async () => {
    queryMock.mockImplementation(async (sql: string) => {
      const normalizedSql = normalizeSql(sql);

      if (normalizedSql.includes('FROM usuario')) {
        return { rows: [] };
      }

      if (normalizedSql.includes('FROM sessao_chat')) {
        return { rows: [] };
      }

      if (normalizedSql.includes('INSERT INTO sessao_chat')) {
        return { rows: [{ id: 'session-guest' }] };
      }

      return { rows: [] };
    });

    await processIncomingTextMessage({
      fromNumber: '5581999991234',
      incomingText: 'oi',
    });

    const calls = queryMock.mock.calls as QueryCall[];
    const sessionInsert = calls.find(([sql]) => normalizeSql(sql).includes('INSERT INTO sessao_chat'));

    expect(sessionInsert?.[1]).toEqual(['WHATSAPP', '5581999991234', null, 'ABERTA']);
  });
});
