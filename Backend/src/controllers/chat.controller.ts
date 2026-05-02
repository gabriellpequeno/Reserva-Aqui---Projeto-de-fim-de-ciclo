/**
 * Controller: Chat In-App
 *
 * Feature: P6-F — chat-rag-integration
 *
 * Expõe o AgentOrchestratorService via REST para o chat in-app do Flutter.
 * Endpoint público (sem authGuard obrigatório). Se JWT presente, enriquece
 * a sessão com userId. Gerencia sessões (canal APP) e persiste mensagens
 * em mensagem_chat para manter histórico do orquestrador.
 */
import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { masterPool } from '../database/masterDb';
import { AgentOrchestratorService } from '../services/ai/agentOrchestrator.service';
import { ContextResolverService, ChatContext } from '../services/ai/contextResolver.service';

const JWT_SECRET = process.env.JWT_SECRET!;

const CANAL_APP = 'APP';
const STATUS_ABERTA = 'ABERTA';
const ORIGEM_CLIENTE = 'CLIENTE';
const ORIGEM_BOT = 'BOT_SISTEMA';

// ── Helpers ───────────────────────────────────────────────────────────────────

function getSessionIdleHours(): number {
  const raw = Number(process.env.APP_CHAT_SESSION_IDLE_HOURS ?? '24');
  return Number.isFinite(raw) && raw > 0 ? raw : 24;
}

function isSessionActive(updatedAt: string): boolean {
  const updatedAtMs = new Date(updatedAt).getTime();
  const idleWindowMs = getSessionIdleHours() * 60 * 60 * 1000;
  return Date.now() - updatedAtMs <= idleWindowMs;
}

/**
 * Extrai userId do JWT sem bloquear a request.
 * Retorna null se token ausente, inválido ou expirado.
 */
function extractOptionalUserId(req: Request): string | null {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;

  const token = authHeader.split(' ')[1];
  try {
    const payload = jwt.verify(token, JWT_SECRET) as { user_id?: string };
    return payload.user_id ?? null;
  } catch {
    return null;
  }
}

interface SessionRow {
  id: string;
  user_id: string | null;
  hotel_id: string | null;
  atualizado_em: string;
}

/**
 * Busca ou cria sessão aberta para o canal APP.
 * Segue a mesma lógica de getOrCreateOpenSession do WhatsApp.
 */
async function getOrCreateAppSession(
  deviceId: string,
  userId: string | null,
): Promise<string> {
  const { rows } = await masterPool.query<SessionRow>(
    `SELECT id, user_id, hotel_id, atualizado_em
     FROM sessao_chat
     WHERE canal = $1
       AND identificador_externo = $2
       AND status = $3
     ORDER BY criado_em DESC
     LIMIT 1`,
    [CANAL_APP, deviceId, STATUS_ABERTA],
  );

  if (rows[0]) {
    if (!isSessionActive(rows[0].atualizado_em)) {
      // Sessão expirada: fechar e criar nova
      await masterPool.query(
        `UPDATE sessao_chat SET status = 'FECHADA', atualizado_em = NOW() WHERE id = $1`,
        [rows[0].id],
      );
    } else {
      // Sessão ativa: reutilizar. Enriquecer com userId se necessário.
      if (userId && !rows[0].user_id) {
        await masterPool.query(
          `UPDATE sessao_chat SET user_id = $2, atualizado_em = NOW() WHERE id = $1`,
          [rows[0].id, userId],
        );
      } else {
        await masterPool.query(
          `UPDATE sessao_chat SET atualizado_em = NOW() WHERE id = $1`,
          [rows[0].id],
        );
      }
      return rows[0].id;
    }
  }

  // Criar nova sessão
  const { rows: newRows } = await masterPool.query<{ id: string }>(
    `INSERT INTO sessao_chat (canal, identificador_externo, user_id, status)
     VALUES ($1, $2, $3, $4)
     RETURNING id`,
    [CANAL_APP, deviceId, userId, STATUS_ABERTA],
  );

  return newRows[0].id;
}

async function persistMessage(
  sessionId: string,
  origem: string,
  conteudo: string,
): Promise<void> {
  await masterPool.query(
    `INSERT INTO mensagem_chat (sessao_chat_id, origem, conteudo, tipo_mensagem, metadata_json)
     VALUES ($1, $2, $3, 'TEXT', $4)`,
    [sessionId, origem, conteudo, { deliveryChannel: 'APP' }],
  );

  await masterPool.query(
    `UPDATE sessao_chat SET atualizado_em = NOW() WHERE id = $1`,
    [sessionId],
  );
}

// ── Handler ───────────────────────────────────────────────────────────────────

/** POST /api/v1/chat/message */
export async function sendMessageController(req: Request, res: Response): Promise<void> {
  try {
    const { message, hotelId, deviceId } = req.body ?? {};

    // Validação
    if (!deviceId || typeof deviceId !== 'string' || !deviceId.trim()) {
      res.status(400).json({ error: 'deviceId é obrigatório' });
      return;
    }

    if (!message || typeof message !== 'string' || !message.trim()) {
      res.status(400).json({ error: 'Mensagem não pode ser vazia' });
      return;
    }

    const userMessage = message.trim();
    const userId = extractOptionalUserId(req);

    // 1. Buscar/criar sessão
    const sessionId = await getOrCreateAppSession(deviceId.trim(), userId);

    // 2. Se hotelId veio no body e a sessão não tem hotel, setar
    if (hotelId && typeof hotelId === 'string') {
      const { rows: sessionRows } = await masterPool.query<{ hotel_id: string | null }>(
        `SELECT hotel_id FROM sessao_chat WHERE id = $1`,
        [sessionId],
      );
      if (sessionRows[0] && !sessionRows[0].hotel_id) {
        await ContextResolverService.setHotelContext(sessionId, hotelId);
      }
    }

    // 3. Persistir mensagem do usuário
    await persistMessage(sessionId, ORIGEM_CLIENTE, userMessage);

    // 4. Resolver contexto
    let context = await ContextResolverService.getContext(sessionId);
    if (!context) {
      context = {
        sessionId,
        userId,
        hotelId: hotelId ?? null,
        schemaName: null,
      } as ChatContext;
    }

    // 5. Processar via AgentOrchestrator
    const reply = await AgentOrchestratorService.processMessage(sessionId, userMessage, context);

    // 6. Persistir resposta do bot
    await persistMessage(sessionId, ORIGEM_BOT, reply);

    // 7. Retornar
    res.json({ reply, sessionId });
  } catch (err) {
    console.error('[Chat Controller] Erro ao processar mensagem:', err);
    res.status(500).json({ error: 'Erro interno ao processar mensagem' });
  }
}
