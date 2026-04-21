import { masterPool } from '../database/masterDb';
import { DispositivoFcm, RegisterFcmInput } from '../entities/DispositivoFcm';

// ── Funções Exportadas (Wrappers) ─────────────────────────────────────────────

export async function registerUserToken(userId: string, input: RegisterFcmInput): Promise<void> {
  return _registerUserToken(userId, input);
}

export async function registerHotelToken(hotelId: string, input: RegisterFcmInput): Promise<void> {
  return _registerHotelToken(hotelId, input);
}

export async function removeToken(fcmToken: string): Promise<void> {
  return _removeToken(fcmToken);
}

// ── Funções Privadas ──────────────────────────────────────────────────────────

async function _registerUserToken(userId: string, input: RegisterFcmInput): Promise<void> {
  DispositivoFcm.validate(input);

  // UPSERT: se o token já existe (mesmo dispositivo, novo login), apenas atualiza atualizado_em
  // Se o token pertencia a outro usuário, a unique constraint garante que não há duplicata
  await masterPool.query(
    `INSERT INTO dispositivo_fcm (user_id, fcm_token, origem)
     VALUES ($1, $2, $3)
     ON CONFLICT (fcm_token)
     DO UPDATE SET
       user_id       = EXCLUDED.user_id,
       hotel_id      = NULL,
       origem        = COALESCE(EXCLUDED.origem, dispositivo_fcm.origem),
       atualizado_em = NOW()`,
    [userId, input.fcm_token, input.origem ?? null],
  );
}

async function _registerHotelToken(hotelId: string, input: RegisterFcmInput): Promise<void> {
  DispositivoFcm.validate(input);

  await masterPool.query(
    `INSERT INTO dispositivo_fcm (hotel_id, fcm_token, origem)
     VALUES ($1, $2, $3)
     ON CONFLICT (fcm_token)
     DO UPDATE SET
       hotel_id      = EXCLUDED.hotel_id,
       user_id       = NULL,
       origem        = COALESCE(EXCLUDED.origem, dispositivo_fcm.origem),
       atualizado_em = NOW()`,
    [hotelId, input.fcm_token, input.origem ?? null],
  );
}

async function _removeToken(fcmToken: string): Promise<void> {
  await masterPool.query(
    `DELETE FROM dispositivo_fcm WHERE fcm_token = $1`,
    [fcmToken],
  );
}
