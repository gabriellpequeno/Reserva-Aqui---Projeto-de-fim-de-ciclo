/**
 * FCM Service — Firebase Cloud Messaging
 *
 * Wrapper do Firebase Admin SDK para envio de push notifications.
 *
 * Configuração:
 *   Adicione ao .env:
 *     FIREBASE_SERVICE_ACCOUNT=<JSON da service account em uma única linha>
 *
 *   Para gerar o JSON:
 *     Firebase Console → Project Settings → Service accounts → Generate new private key
 *     Abra o arquivo .json, minifique e cole no .env como string.
 *
 * Comportamento sem credenciais:
 *   Se FIREBASE_SERVICE_ACCOUNT não estiver definido, sendPush() é no-op
 *   (loga aviso e retorna silenciosamente). O restante da aplicação não é afetado.
 */

import admin from 'firebase-admin';

// ── Inicialização lazy (apenas uma vez) ───────────────────────────────────────

let initialized = false;

function _init(): boolean {
  if (initialized) return true;

  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) {
    return false;
  }

  try {
    const serviceAccount = JSON.parse(raw) as admin.ServiceAccount;
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    initialized = true;
    return true;
  } catch {
    console.error('[FCM] Falha ao inicializar Firebase Admin SDK — verifique FIREBASE_SERVICE_ACCOUNT no .env');
    return false;
  }
}

// ── Tipos ─────────────────────────────────────────────────────────────────────

export interface FcmPayload {
  title: string;
  body:  string;
  data?: Record<string, string>; // campos extras (ex: reserva_id, checkout_url)
}

// ── Funções Exportadas ────────────────────────────────────────────────────────

/**
 * Envia push notification para uma lista de tokens FCM.
 * Tokens inválidos/expirados são ignorados silenciosamente.
 * No-op se Firebase não estiver configurado.
 */
export async function sendPush(tokens: string[], payload: FcmPayload): Promise<void> {
  if (!tokens.length) return;

  if (!_init()) {
    console.warn('[FCM] FIREBASE_SERVICE_ACCOUNT não configurado — push não enviado:', payload.title);
    return;
  }

  const message: admin.messaging.MulticastMessage = {
    tokens,
    notification: {
      title: payload.title,
      body:  payload.body,
    },
    data: payload.data,
    android: {
      priority: 'high',
    },
    apns: {
      payload: {
        aps: { sound: 'default' },
      },
    },
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);

    // Remove tokens inválidos do banco em background (fire-and-forget)
    if (response.failureCount > 0) {
      const invalidTokens = response.responses
        .map((r, i) => (!r.success ? tokens[i] : null))
        .filter((t): t is string => t !== null);

      _removeInvalidTokens(invalidTokens).catch(() => {
        // Falha silenciosa — não bloqueia o fluxo principal
      });
    }
  } catch (err) {
    // Falha no envio não deve quebrar o fluxo de negócio
    console.error('[FCM] Erro ao enviar push:', err);
  }
}

/**
 * Busca todos os tokens FCM ativos de um hotel.
 */
export async function getHotelTokens(hotelId: string): Promise<string[]> {
  const { masterPool } = await import('../database/masterDb');
  const { rows } = await masterPool.query<{ fcm_token: string }>(
    `SELECT fcm_token FROM dispositivo_fcm WHERE hotel_id = $1`,
    [hotelId],
  );
  return rows.map(r => r.fcm_token);
}

/**
 * Busca todos os tokens FCM ativos de um usuário.
 */
export async function getUserTokens(userId: string): Promise<string[]> {
  const { masterPool } = await import('../database/masterDb');
  const { rows } = await masterPool.query<{ fcm_token: string }>(
    `SELECT fcm_token FROM dispositivo_fcm WHERE user_id = $1`,
    [userId],
  );
  return rows.map(r => r.fcm_token);
}

// ── Helpers Privados ──────────────────────────────────────────────────────────

/**
 * Remove tokens inválidos/expirados do banco após falha de envio.
 * Chamado em fire-and-forget — não bloqueia o fluxo principal.
 */
async function _removeInvalidTokens(tokens: string[]): Promise<void> {
  if (!tokens.length) return;
  const { masterPool } = await import('../database/masterDb');
  await masterPool.query(
    `DELETE FROM dispositivo_fcm WHERE fcm_token = ANY($1)`,
    [tokens],
  );
}
