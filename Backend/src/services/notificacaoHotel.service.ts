import { masterPool } from '../database/masterDb';
import { withTenant }  from '../database/schemaWrapper';

// ── Tipos ─────────────────────────────────────────────────────────────────────

export type NotificacaoTipo =
  | 'NOVA_RESERVA'
  | 'APROVACAO_RESERVA'
  | 'PAGAMENTO_CONFIRMADO'
  | 'RESERVA_CANCELADA'
  | 'MENSAGEM_CHAT';

export interface NotificacaoHotelSafe {
  id:             number;
  titulo:         string;
  mensagem:       string;
  tipo:           string;
  lida_em:        string | null;
  acao_requerida: string | null;
  acao_concluida: boolean;
  payload:        unknown;
  criado_em:      string;
}

export interface CreateNotificacaoInput {
  titulo:          string;
  mensagem:        string;
  tipo:            NotificacaoTipo;
  acao_requerida?: string | null;
  payload?:        unknown;
}

// ── Funções Exportadas (Wrappers) ─────────────────────────────────────────────

export async function listNotificacoes(
  hotelId:     string,
  apenasNaoLidas: boolean,
): Promise<NotificacaoHotelSafe[]> {
  return _listNotificacoes(hotelId, apenasNaoLidas);
}

export async function marcarLida(hotelId: string, notificacaoId: number): Promise<NotificacaoHotelSafe> {
  return _marcarLida(hotelId, notificacaoId);
}

export async function marcarTodasLidas(hotelId: string): Promise<void> {
  return _marcarTodasLidas(hotelId);
}

/**
 * Cria uma notificação no inbox do hotel.
 * Chamado internamente pelos services de reserva nos 4 pontos de evento.
 * Fire-and-forget: falhas não propagam para o fluxo principal.
 */
export async function insertNotificacao(
  hotelId: string,
  input:   CreateNotificacaoInput,
): Promise<void> {
  return _insertNotificacao(hotelId, input);
}

// ── Helper ────────────────────────────────────────────────────────────────────

async function _getSchemaName(hotelId: string): Promise<string> {
  const { rows } = await masterPool.query<{ schema_name: string }>(
    `SELECT schema_name FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  if (!rows[0]) throw new Error('Hotel não encontrado');
  return rows[0].schema_name;
}

// ── Funções Privadas ──────────────────────────────────────────────────────────

async function _listNotificacoes(
  hotelId:        string,
  apenasNaoLidas: boolean,
): Promise<NotificacaoHotelSafe[]> {
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const where = apenasNaoLidas ? 'WHERE lida_em IS NULL' : '';
    const { rows } = await client.query<NotificacaoHotelSafe>(
      `SELECT *
       FROM notificacao_hotel
       ${where}
       ORDER BY criado_em DESC
       LIMIT 100`,
    );
    return rows;
  });
}

async function _marcarLida(
  hotelId:        string,
  notificacaoId:  number,
): Promise<NotificacaoHotelSafe> {
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const { rows } = await client.query<NotificacaoHotelSafe>(
      `UPDATE notificacao_hotel
       SET lida_em = NOW()
       WHERE id = $1 AND lida_em IS NULL
       RETURNING *`,
      [notificacaoId],
    );
    // Se lida_em já estava preenchido, busca o registro sem alterar
    if (!rows[0]) {
      const { rows: existing } = await client.query<NotificacaoHotelSafe>(
        `SELECT * FROM notificacao_hotel WHERE id = $1`,
        [notificacaoId],
      );
      if (!existing[0]) throw new Error('Notificação não encontrada');
      return existing[0];
    }
    return rows[0];
  });
}

async function _marcarTodasLidas(hotelId: string): Promise<void> {
  const schemaName = await _getSchemaName(hotelId);

  await withTenant(schemaName, async (client) => {
    await client.query(
      `UPDATE notificacao_hotel SET lida_em = NOW() WHERE lida_em IS NULL`,
    );
  });
}

async function _insertNotificacao(
  hotelId: string,
  input:   CreateNotificacaoInput,
): Promise<void> {
  try {
    const schemaName = await _getSchemaName(hotelId);

    await withTenant(schemaName, async (client) => {
      await client.query(
        `INSERT INTO notificacao_hotel (titulo, mensagem, tipo, acao_requerida, payload)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          input.titulo,
          input.mensagem,
          input.tipo,
          input.acao_requerida ?? null,
          input.payload ? JSON.stringify(input.payload) : null,
        ],
      );
    });
  } catch (err) {
    // Falha na notificação não deve interromper o fluxo de negócio
    console.error('[NotificacaoHotel] Erro ao inserir notificação:', err);
  }
}
