import { masterPool } from '../database/masterDb';
import { WhatsAppService } from './whatsapp.service';

interface UsuarioRow {
  user_id: string;
}

interface SessaoChatRow {
  id: string;
  user_id: string | null;
}

export interface ProcessIncomingTextMessageInput {
  fromNumber: string;
  incomingText: string;
}

const CANAL_WHATSAPP = 'WHATSAPP';
const STATUS_ABERTA = 'ABERTA';
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
  return `Olá! Recebemos sua mensagem "${incomingText}". Nosso assistente inteligente será ativado em breve.`;
}

export function logUnsupportedMessageType(messageType: string, fromNumber: string): void {
  console.log(`[WhatsApp] Mensagem recebida de ${fromNumber} com tipo ainda não tratado: ${messageType}`);
}

async function resolveUserIdByPhone(normalizedPhone: string): Promise<string | null> {
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

async function getOrCreateOpenSession(
  normalizedPhone: string,
  userId: string | null,
): Promise<string> {
  const { rows } = await masterPool.query<SessaoChatRow>(
    `SELECT id, user_id
     FROM sessao_chat
     WHERE canal = $1
       AND identificador_externo = $2
       AND status = $3
     ORDER BY criado_em DESC
     LIMIT 1`,
    [CANAL_WHATSAPP, normalizedPhone, STATUS_ABERTA],
  );

  if (rows[0]) {
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

    return rows[0].id;
  }

  const { rows: newRows } = await masterPool.query<{ id: string }>(
    `INSERT INTO sessao_chat (canal, identificador_externo, user_id, status)
     VALUES ($1, $2, $3, $4)
     RETURNING id`,
    [CANAL_WHATSAPP, normalizedPhone, userId, STATUS_ABERTA],
  );

  return newRows[0].id;
}

async function persistChatMessage(sessionId: string, origem: string, conteudo: string): Promise<void> {
  await masterPool.query(
    `INSERT INTO mensagem_chat (sessao_chat_id, origem, conteudo)
     VALUES ($1, $2, $3)`,
    [sessionId, origem, conteudo],
  );

  await masterPool.query(
    `UPDATE sessao_chat
     SET atualizado_em = NOW()
     WHERE id = $1`,
    [sessionId],
  );
}

export async function processIncomingTextMessage(input: ProcessIncomingTextMessageInput): Promise<void> {
  const normalizedPhone = normalizePhoneNumber(input.fromNumber);
  const userId = await resolveUserIdByPhone(normalizedPhone);
  const sessionId = await getOrCreateOpenSession(normalizedPhone, userId);

  await persistChatMessage(sessionId, ORIGEM_CLIENTE, input.incomingText);

  const provisionalReply = buildProvisionalReply(input.incomingText);
  await WhatsAppService.sendText(normalizedPhone, provisionalReply);
  await persistChatMessage(sessionId, ORIGEM_BOT, provisionalReply);
}
