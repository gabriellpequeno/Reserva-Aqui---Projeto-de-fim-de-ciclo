/**
 * Entity: DispositivoFcm
 * Responsabilidade: validação pura — nunca toca o banco.
 */

export type FcmOrigem = 'DASHBOARD_WEB' | 'APP_IOS' | 'APP_ANDROID';

const ORIGENS_VALIDAS: FcmOrigem[] = ['DASHBOARD_WEB', 'APP_IOS', 'APP_ANDROID'];

export interface RegisterFcmInput {
  fcm_token: string;
  origem?:   FcmOrigem;
}

export class DispositivoFcm {
  static validate(input: unknown): RegisterFcmInput {
    const data = input as Record<string, unknown>;

    if (typeof data.fcm_token !== 'string' || data.fcm_token.trim().length === 0)
      throw new Error('fcm_token obrigatório');

    const result: RegisterFcmInput = { fcm_token: data.fcm_token.trim() };

    if (data.origem !== undefined) {
      if (!ORIGENS_VALIDAS.includes(data.origem as FcmOrigem))
        throw new Error(`origem inválida: valores permitidos são ${ORIGENS_VALIDAS.join(', ')}`);
      result.origem = data.origem as FcmOrigem;
    }

    return result;
  }
}
