import { masterPool } from '../database/masterDb';
import { WhatsAppService } from './whatsapp.service';

interface UsuarioRow {
  user_id: string;
}

interface SessaoChatRow {
  id: string;
  user_id: string | null;
  atualizado_em: string;
}

export interface IncomingMediaMetadata {
  mediaId?: string | null;
  mimeType?: string | null;
  caption?: string | null;
  filename?: string | null;
}

export interface ProcessIncomingWhatsAppMessageInput {
  fromNumber: string;
  messageType: 'text' | 'audio' | 'image' | 'document';
  metaMessageId?: string;
  textBody?: string;
  media?: IncomingMediaMetadata;
}

export interface ProcessStatusEventInput {
  id?: string;
  status?: string;
}

export interface SessionResolutionResult {
  sessionId: string;
  hasActiveCustomerWindow: boolean;
}

interface PersistChatMessageInput {
  sessionId: string;
  origem: string;
  conteudo: string;
  tipoMensagem: string;
  metaMessageId?: string | null;
  metaStatus?: string | null;
  metadata?: Record<string, unknown> | null;
}

const CANAL_WHATSAPP = 'WHATSAPP';
const STATUS_ABERTA = 'ABERTA';
const STATUS_FECHADA = 'FECHADA';
const STATUS_BOT_RESOLVIDO = 'BOT_RESOLVIDO';
const ORIGEM_CLIENTE = 'CLIENTE';
const ORIGEM_BOT = 'BOT_SISTEMA';

export function normalizePhoneNumber(input: string): string {
  return input.replace(/\D/g, '');
}

export function buildPhoneLookupCandidates(normalizedPhone: string): string[] {
  const candidates = new Set<string>();

  if (normalizedPhone) {
    candidates.add(normalizedPhone);
  }

  if (normalizedPhone.startsWith('55') && normalizedPhone.length > 11) {
    candidates.add(normalizedPhone.slice(2));
  }

  if (!normalizedPhone.startsWith('55') && normalizedPhone.length <= 11) {
    candidates.add(`55${normalizedPhone}`);
  }

  return Array.from(candidates);
}

export function buildProvisionalReply(incomingText: string): string {
  return `Ola! Recebemos sua mensagem "${incomingText}". Nosso assistente inteligente sera ativado em breve.`;
}

export function buildMediaAcknowledgementReply(messageType: ProcessIncomingWhatsAppMessageInput['messageType']): string {
  switch (messageType) {
    case 'audio':
      return 'Recebi seu audio. Ainda nao consigo processa-lo automaticamente, mas sua mensagem ja foi registrada.';
    case 'image':
      return 'Recebi sua imagem. Ainda nao consigo processa-la automaticamente, mas sua mensagem ja foi registrada.';
    case 'document':
      return 'Recebi seu documento. Ainda nao consigo processa-lo automaticamente, mas sua mensagem ja foi registrada.';
    default:
      return 'Recebi sua mensagem. Ainda nao consigo processa-la automaticamente, mas sua mensagem ja foi registrada.';
  }
}

export function logUnsupportedMessageType(messageType: string, fromNumber: string): void {
  console.log(`[WhatsApp] Mensagem recebida de ${fromNumber} com tipo ainda nao tratado: ${messageType}`);
}

function getSessionIdleHours(): number {
  const raw = Number(process.env.WHATSAPP_SESSION_IDLE_HOURS ?? '24');
  return Number.isFinite(raw) && raw > 0 ? raw : 24;
}

function isSessionActive(updatedAt: string): boolean {
  const updatedAtMs = new Date(updatedAt).getTime();
  const idleWindowMs = getSessionIdleHours() * 60 * 60 * 1000;
  return Date.now() - updatedAtMs <= idleWindowMs;
}

function toStoredMessageType(messageType: ProcessIncomingWhatsAppMessageInput['messageType'] | 'template'): string {
  return messageType.toUpperCase();
}

function buildIncomingContent(input: ProcessIncomingWhatsAppMessageInput): string {
  if (input.messageType === 'text') {
    return input.textBody?.trim() ?? '';
  }

  const caption = input.media?.caption?.trim();
  return caption ? `[${input.messageType}] ${caption}` : `[${input.messageType}]`;
}

export async function findExistingMessageByMetaId(metaMessageId?: string): Promise<boolean> {
  if (!metaMessageId) {
    return false;
  }

  const { rows } = await masterPool.query<{ id: string }>(
    `SELECT id
     FROM mensagem_chat
     WHERE meta_message_id = $1
     LIMIT 1`,
    [metaMessageId],
  );

  return Boolean(rows[0]);
}

export async function resolveUserIdByPhone(normalizedPhone: string): Promise<string | null> {
  const phoneCandidates = buildPhoneLookupCandidates(normalizedPhone);

  const { rows } = await masterPool.query<UsuarioRow>(
    `SELECT user_id
     FROM usuario
     WHERE ativo = TRUE
       AND numero_celular IS NOT NULL
       AND regexp_replace(numero_celular, '\\D', '', 'g') = ANY($1::text[])
     LIMIT 1`,
    [phoneCandidates],
  );

  return rows[0]?.user_id ?? null;
}

export async function getOrCreateOpenSession(
  normalizedPhone: string,
  userId: string | null,
): Promise<SessionResolutionResult> {
  const { rows } = await masterPool.query<SessaoChatRow>(
    `SELECT id, user_id, atualizado_em
     FROM sessao_chat
     WHERE canal = $1
       AND identificador_externo = $2
       AND status = $3
     ORDER BY criado_em DESC
     LIMIT 1`,
    [CANAL_WHATSAPP, normalizedPhone, STATUS_ABERTA],
  );

  if (rows[0]) {
    const activeCustomerWindow = isSessionActive(rows[0].atualizado_em);

    if (!activeCustomerWindow) {
      await masterPool.query(
        `UPDATE sessao_chat
         SET status = 'FECHADA', atualizado_em = NOW()
         WHERE id = $1`,
        [rows[0].id],
      );

      const { rows: newRows } = await masterPool.query<{ id: string }>(
        `INSERT INTO sessao_chat (canal, identificador_externo, user_id, status)
         VALUES ($1, $2, $3, $4)
         RETURNING id`,
        [CANAL_WHATSAPP, normalizedPhone, userId, STATUS_ABERTA],
      );

      return {
        sessionId: newRows[0].id,
        hasActiveCustomerWindow: false,
      };
    }

    if (userId && !rows[0].user_id) {
      await masterPool.query(
        `UPDATE sessao_chat
         SET user_id = $2, atualizado_em = NOW()
         WHERE id = $1`,
        [rows[0].id, userId],
      );
    } else {
      await masterPool.query(
        `UPDATE sessao_chat
         SET atualizado_em = NOW()
         WHERE id = $1`,
        [rows[0].id],
      );
    }

    return {
      sessionId: rows[0].id,
      hasActiveCustomerWindow: true,
    };
  }

  const { rows: newRows } = await masterPool.query<{ id: string }>(
    `INSERT INTO sessao_chat (canal, identificador_externo, user_id, status)
     VALUES ($1, $2, $3, $4)
     RETURNING id`,
    [CANAL_WHATSAPP, normalizedPhone, userId, STATUS_ABERTA],
  );

  return {
    sessionId: newRows[0].id,
    hasActiveCustomerWindow: false,
  };
}

export async function closeChatSession(
  sessionId: string,
  status: 'BOT_RESOLVIDO' | 'FECHADA' = STATUS_BOT_RESOLVIDO,
): Promise<void> {
  await masterPool.query(
    `UPDATE sessao_chat
     SET status = $2, atualizado_em = NOW()
     WHERE id = $1`,
    [sessionId, status],
  );
}

export async function persistChatMessage(input: PersistChatMessageInput): Promise<void> {
  await masterPool.query(
    `INSERT INTO mensagem_chat
       (sessao_chat_id, origem, conteudo, tipo_mensagem, meta_message_id, meta_status, metadata_json)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [
      input.sessionId,
      input.origem,
      input.conteudo,
      input.tipoMensagem,
      input.metaMessageId ?? null,
      input.metaStatus ?? null,
      input.metadata ?? null,
    ],
  );

  await masterPool.query(
    `UPDATE sessao_chat
     SET atualizado_em = NOW()
     WHERE id = $1`,
    [input.sessionId],
  );
}

export async function processIncomingWhatsAppMessage(input: ProcessIncomingWhatsAppMessageInput): Promise<void> {
  if (await findExistingMessageByMetaId(input.metaMessageId)) {
    return;
  }

  const normalizedPhone = normalizePhoneNumber(input.fromNumber);
  const userId = await resolveUserIdByPhone(normalizedPhone);
  const { sessionId } = await getOrCreateOpenSession(normalizedPhone, userId);

  const inboundContent = buildIncomingContent(input);
  const inboundMetadata =
    input.messageType === 'text'
      ? { source: 'whatsapp' }
      : {
          source: 'whatsapp',
          mediaId: input.media?.mediaId ?? null,
          mimeType: input.media?.mimeType ?? null,
          caption: input.media?.caption ?? null,
          filename: input.media?.filename ?? null,
        };

  await persistChatMessage({
    sessionId,
    origem: ORIGEM_CLIENTE,
    conteudo: inboundContent,
    tipoMensagem: toStoredMessageType(input.messageType),
    metaMessageId: input.metaMessageId ?? null,
    metaStatus: null,
    metadata: inboundMetadata,
  });

  const replyText =
    input.messageType === 'text'
      ? buildProvisionalReply(input.textBody?.trim() ?? '')
      : buildMediaAcknowledgementReply(input.messageType);

  const metaResponse = await WhatsAppService.sendText(normalizedPhone, replyText);
  const outboundMetaMessageId = metaResponse.messages?.[0]?.id ?? null;

  await persistChatMessage({
    sessionId,
    origem: ORIGEM_BOT,
    conteudo: replyText,
    tipoMensagem: 'TEXT',
    metaMessageId: outboundMetaMessageId,
    metaStatus: 'ACCEPTED',
    metadata: {
      deliveryChannel: 'WHATSAPP',
      usedTemplate: false,
    },
  });
}

export async function processStatusEvent(events: ProcessStatusEventInput[]): Promise<void> {
  for (const event of events) {
    if (!event.id || !event.status) {
      continue;
    }

    await masterPool.query(
      `UPDATE mensagem_chat
       SET meta_status = $2,
           metadata_json = COALESCE(metadata_json, '{}'::jsonb) || $3::jsonb
       WHERE meta_message_id = $1`,
      [event.id, event.status, { lastStatusSource: 'whatsapp-webhook' }],
    );
  }
}
