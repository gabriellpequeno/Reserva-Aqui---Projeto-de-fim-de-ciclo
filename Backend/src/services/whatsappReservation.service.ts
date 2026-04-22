import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import { WhatsAppService } from './whatsapp.service';
import {
  closeChatSession,
  getOrCreateOpenSession,
  normalizePhoneNumber,
  persistChatMessage,
} from './whatsappWebhook.service';

interface HotelInfo {
  schema_name: string;
  nome_hotel: string;
}

interface ReservationRow {
  id: number;
  codigo_publico: string;
  user_id: string | null;
  nome_hospede: string | null;
  telefone_contato: string | null;
  tipo_quarto: string | null;
  data_checkin: string;
  data_checkout: string;
  valor_total: string;
  status: string;
}

interface UserContactRow {
  nome_completo: string;
  numero_celular: string | null;
}

interface ReservationPdfInput {
  nomeHotel: string;
  nomeHospede: string;
  codigoPublico: string;
  tipoQuarto: string;
  dataCheckin: string;
  dataCheckout: string;
  valorTotal: string;
  status: string;
}

function toPdfAscii(input: string): string {
  return input
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[()\\]/g, '\\$&');
}

function buildSimplePdf(lines: string[]): Buffer {
  const stream = lines
    .map((line, index) => `BT /F1 12 Tf 50 ${780 - (index * 18)} Td (${toPdfAscii(line)}) Tj ET`)
    .join('\n');

  const objects = [
    '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj',
    '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj',
    '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj',
    '4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj',
    `5 0 obj << /Length ${Buffer.byteLength(stream, 'latin1')} >> stream\n${stream}\nendstream\nendobj`,
  ];

  let pdf = '%PDF-1.4\n';
  const offsets: number[] = [];

  for (const object of objects) {
    offsets.push(Buffer.byteLength(pdf, 'latin1'));
    pdf += `${object}\n`;
  }

  const xrefOffset = Buffer.byteLength(pdf, 'latin1');
  pdf += `xref\n0 ${objects.length + 1}\n`;
  pdf += '0000000000 65535 f \n';

  for (const offset of offsets) {
    pdf += `${String(offset).padStart(10, '0')} 00000 n \n`;
  }

  pdf += `trailer << /Size ${objects.length + 1} /Root 1 0 R >>\n`;
  pdf += `startxref\n${xrefOffset}\n%%EOF`;

  return Buffer.from(pdf, 'latin1');
}

export function buildReservationConfirmationPdf(input: ReservationPdfInput): Buffer {
  return buildSimplePdf([
    'Confirmacao de reserva',
    '',
    `Hotel: ${input.nomeHotel}`,
    `Hospede: ${input.nomeHospede}`,
    `Codigo da reserva: ${input.codigoPublico}`,
    `Quarto: ${input.tipoQuarto}`,
    `Check-in: ${input.dataCheckin}`,
    `Check-out: ${input.dataCheckout}`,
    `Valor total: R$ ${input.valorTotal}`,
    `Status: ${input.status}`,
    '',
    'ReservAqui',
  ]);
}

async function getHotelInfo(hotelId: string): Promise<HotelInfo> {
  const { rows } = await masterPool.query<HotelInfo>(
    `SELECT schema_name, nome_hotel
     FROM anfitriao
     WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );

  if (!rows[0]) {
    throw new Error('Hotel nao encontrado');
  }

  return rows[0];
}

async function getReservationForConfirmation(hotelId: string, reservaId: number): Promise<ReservationRow & { nome_hotel: string }> {
  const hotel = await getHotelInfo(hotelId);

  return withTenant(hotel.schema_name, async (client) => {
    const { rows } = await client.query<ReservationRow>(
      `SELECT id, codigo_publico, user_id, nome_hospede, telefone_contato, tipo_quarto,
              data_checkin, data_checkout, valor_total, status
       FROM reserva
       WHERE id = $1`,
      [reservaId],
    );

    if (!rows[0]) {
      throw new Error('Reserva nao encontrada');
    }

    return {
      ...rows[0],
      nome_hotel: hotel.nome_hotel,
    };
  });
}

async function getUserContact(userId: string): Promise<UserContactRow | null> {
  const { rows } = await masterPool.query<UserContactRow>(
    `SELECT nome_completo, numero_celular
     FROM usuario
     WHERE user_id = $1`,
    [userId],
  );

  return rows[0] ?? null;
}

export async function sendApprovedReservationConfirmation(input: {
  hotelId: string;
  reservaId: number;
}): Promise<void> {
  const reservation = await getReservationForConfirmation(input.hotelId, input.reservaId);

  if (reservation.status !== 'APROVADA') {
    return;
  }

  const userContact = reservation.user_id ? await getUserContact(reservation.user_id) : null;
  const rawPhone = userContact?.numero_celular ?? reservation.telefone_contato ?? null;

  if (!rawPhone) {
    return;
  }

  const normalizedPhone = normalizePhoneNumber(rawPhone);
  const session = await getOrCreateOpenSession(normalizedPhone, reservation.user_id);

  if (session.hasActiveCustomerWindow) {
    const textResponse = await WhatsAppService.sendText(
      normalizedPhone,
      'Sua reserva foi aprovada. Segue o comprovante em PDF.',
    );

    await persistChatMessage({
      sessionId: session.sessionId,
      origem: 'BOT_SISTEMA',
      conteudo: 'Sua reserva foi aprovada. Segue o comprovante em PDF.',
      tipoMensagem: 'TEXT',
      metaMessageId: textResponse.messages?.[0]?.id ?? null,
      metaStatus: 'ACCEPTED',
      metadata: {
        deliveryChannel: 'WHATSAPP',
        usedTemplate: false,
      },
    });
  } else {
    const templateName = process.env.WHATSAPP_DEFAULT_TEMPLATE_NAME;
    const templateLang = process.env.WHATSAPP_DEFAULT_TEMPLATE_LANG ?? 'pt_BR';

    if (!templateName) {
      throw new Error('WHATSAPP_DEFAULT_TEMPLATE_NAME nao configurado.');
    }

    const templateResponse = await WhatsAppService.sendTemplate(normalizedPhone, templateName, templateLang);

    await persistChatMessage({
      sessionId: session.sessionId,
      origem: 'BOT_SISTEMA',
      conteudo: 'Mensagem de retomada enviada por template.',
      tipoMensagem: 'TEMPLATE',
      metaMessageId: templateResponse.messages?.[0]?.id ?? null,
      metaStatus: 'ACCEPTED',
      metadata: {
        deliveryChannel: 'WHATSAPP',
        usedTemplate: true,
        templateName,
        templateLang,
      },
    });
  }

  const pdfBuffer = buildReservationConfirmationPdf({
    nomeHotel: reservation.nome_hotel,
    nomeHospede: userContact?.nome_completo ?? reservation.nome_hospede ?? 'Hospede',
    codigoPublico: reservation.codigo_publico,
    tipoQuarto: reservation.tipo_quarto ?? 'Quarto',
    dataCheckin: reservation.data_checkin,
    dataCheckout: reservation.data_checkout,
    valorTotal: reservation.valor_total,
    status: reservation.status,
  });

  const documentResponse = await WhatsAppService.sendDocument(
    normalizedPhone,
    pdfBuffer,
    `confirmacao-reserva-${reservation.id}.pdf`,
    'Sua reserva foi aprovada. Segue o comprovante em PDF.',
  );

  await persistChatMessage({
    sessionId: session.sessionId,
    origem: 'BOT_SISTEMA',
    conteudo: 'PDF de confirmacao da reserva enviado.',
    tipoMensagem: 'DOCUMENT',
    metaMessageId: documentResponse.messages?.[0]?.id ?? null,
    metaStatus: 'ACCEPTED',
    metadata: {
      deliveryChannel: 'WHATSAPP',
      filename: `confirmacao-reserva-${reservation.id}.pdf`,
      codigoPublico: reservation.codigo_publico,
    },
  });

  await closeChatSession(session.sessionId);
}
