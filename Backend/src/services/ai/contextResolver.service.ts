import { masterPool } from '../../database/masterDb';

export interface ChatContext {
  sessionId: string;
  userId: string | null;
  hotelId: string | null;
  schemaName: string | null; // Necessário para acessar o banco de dados do Tenant (ex: quartos, disponibilidade)
}

export class ContextResolverService {
  /**
   * Recupera o contexto atual de uma sessão de chat, incluindo o hotel ativo e seu schema.
   */
  static async getContext(sessionId: string): Promise<ChatContext | null> {
    const { rows } = await masterPool.query(`
      SELECT 
        s.id as "sessionId",
        s.user_id as "userId",
        s.hotel_id as "hotelId",
        a.schema_name as "schemaName"
      FROM sessao_chat s
      LEFT JOIN anfitriao a ON s.hotel_id = a.hotel_id
      WHERE s.id = $1
    `, [sessionId]);

    if (!rows[0]) {
      return null;
    }

    return {
      sessionId: rows[0].sessionId,
      userId: rows[0].userId,
      hotelId: rows[0].hotelId,
      schemaName: rows[0].schemaName,
    };
  }

  /**
   * Trava a sessão atual em um hotel específico.
   * Útil quando o usuário inicia o fluxo de reserva ou dúvidas específicas de um hotel.
   */
  static async setHotelContext(sessionId: string, hotelId: string): Promise<void> {
    await masterPool.query(`
      UPDATE sessao_chat
      SET hotel_id = $2, atualizado_em = NOW()
      WHERE id = $1
    `, [sessionId, hotelId]);
  }

  /**
   * Limpa o contexto do hotel atual.
   * Útil se o usuário quiser voltar à "página inicial" e buscar outros hotéis.
   */
  static async clearHotelContext(sessionId: string): Promise<void> {
    await masterPool.query(`
      UPDATE sessao_chat
      SET hotel_id = NULL, atualizado_em = NOW()
      WHERE id = $1
    `, [sessionId]);
  }
}
