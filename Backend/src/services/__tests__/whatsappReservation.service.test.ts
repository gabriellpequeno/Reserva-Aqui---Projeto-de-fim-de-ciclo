jest.mock('../../database/masterDb', () => ({
  masterPool: {
    query: jest.fn(),
  },
}));

jest.mock('../../database/schemaWrapper', () => ({
  withTenant: jest.fn(),
}));

jest.mock('../whatsapp.service', () => ({
  WhatsAppService: {
    sendText: jest.fn(),
    sendTemplate: jest.fn(),
    sendDocument: jest.fn(),
  },
}));

import { masterPool } from '../../database/masterDb';
import { withTenant } from '../../database/schemaWrapper';
import { WhatsAppService } from '../whatsapp.service';
import {
  buildReservationConfirmationPdf,
  sendApprovedReservationConfirmation,
} from '../whatsappReservation.service';

const queryMock = masterPool.query as jest.Mock;
const withTenantMock = withTenant as jest.Mock;
const sendTemplateMock = WhatsAppService.sendTemplate as jest.Mock;
const sendDocumentMock = WhatsAppService.sendDocument as jest.Mock;

describe('whatsappReservation.service', () => {
  beforeEach(() => {
    process.env.WHATSAPP_DEFAULT_TEMPLATE_NAME = 'reservaqui_generico';
    process.env.WHATSAPP_DEFAULT_TEMPLATE_LANG = 'pt_BR';

    queryMock.mockReset();
    withTenantMock.mockReset();
    sendTemplateMock.mockReset();
    sendDocumentMock.mockReset();

    sendTemplateMock.mockResolvedValue({ messages: [{ id: 'meta-template-1' }] });
    sendDocumentMock.mockResolvedValue({ messages: [{ id: 'meta-doc-1' }] });
  });

  it('gera um PDF simples de confirmacao de reserva', () => {
    const buffer = buildReservationConfirmationPdf({
      nomeHotel: 'Hotel Vista',
      nomeHospede: 'Maria',
      codigoPublico: '11111111-1111-1111-1111-111111111111',
      tipoQuarto: 'Suite Master',
      dataCheckin: '2026-05-01',
      dataCheckout: '2026-05-03',
      valorTotal: '899.90',
      status: 'APROVADA',
    });

    expect(buffer.toString('latin1')).toContain('%PDF-1.4');
    expect(buffer.toString('latin1')).toContain('Hotel Vista');
    expect(buffer.toString('latin1')).toContain('Maria');
  });

  it('usa template generico fora da janela e envia o PDF da reserva aprovada', async () => {
    queryMock.mockImplementation(async (sql: string) => {
      if (sql.includes('FROM anfitriao')) {
        return { rows: [{ schema_name: 'hotel_123', nome_hotel: 'Hotel Vista' }] };
      }

      if (sql.includes('FROM usuario')) {
        return { rows: [{ nome_completo: 'Maria', numero_celular: '5581999991234' }] };
      }

      if (sql.includes('FROM sessao_chat')) {
        return { rows: [] };
      }

      if (sql.includes('INSERT INTO sessao_chat')) {
        return { rows: [{ id: 'session-approval' }] };
      }

      if (sql.includes('INSERT INTO mensagem_chat')) {
        return { rows: [] };
      }

      if (sql.includes('UPDATE sessao_chat')) {
        return { rows: [] };
      }

      return { rows: [] };
    });

    withTenantMock.mockImplementation(async (_schemaName: string, callback: (client: { query: jest.Mock }) => Promise<unknown>) => {
      const client = {
        query: jest.fn().mockResolvedValue({
          rows: [
            {
              id: 10,
              codigo_publico: '11111111-1111-1111-1111-111111111111',
              user_id: 'user-1',
              nome_hospede: null,
              telefone_contato: null,
              tipo_quarto: 'Suite Master',
              data_checkin: '2026-05-01',
              data_checkout: '2026-05-03',
              valor_total: '899.90',
              status: 'APROVADA',
            },
          ],
        }),
      };

      return callback(client);
    });

    await sendApprovedReservationConfirmation({
      hotelId: 'hotel-1',
      reservaId: 10,
    });

    expect(sendTemplateMock).toHaveBeenCalledWith(
      '5581999991234',
      'reservaqui_generico',
      'pt_BR',
    );
    expect(sendDocumentMock).toHaveBeenCalledWith(
      '5581999991234',
      expect.any(Buffer),
      'confirmacao-reserva-10.pdf',
      'Sua reserva foi aprovada. Segue o comprovante em PDF.',
    );
  });
});
