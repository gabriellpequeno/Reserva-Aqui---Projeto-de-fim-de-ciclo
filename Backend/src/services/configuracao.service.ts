import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import {
  ConfiguracaoHotel,
  ConfiguracaoHotelInput,
  ConfiguracaoHotelSafe,
} from '../entities/ConfiguracaoHotel';

// ── Funções Exportadas (Wrappers) ─────────────────────────────────────────────

export async function getConfiguracaoHotel(hotelId: string): Promise<ConfiguracaoHotelSafe> {
  return _getConfiguracaoHotel(hotelId);
}

export async function createConfiguracaoHotel(hotelId: string, input: ConfiguracaoHotelInput): Promise<ConfiguracaoHotelSafe> {
  return _createConfiguracaoHotel(hotelId, input);
}

export async function updateConfiguracaoHotel(hotelId: string, input: ConfiguracaoHotelInput): Promise<ConfiguracaoHotelSafe> {
  return _updateConfiguracaoHotel(hotelId, input);
}

// ── Helper Privado ────────────────────────────────────────────────────────────

async function _getSchemaName(hotelId: string): Promise<string> {
  const { rows } = await masterPool.query<{ schema_name: string }>(
    `SELECT schema_name FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  if (!rows[0]) throw new Error('Hotel não encontrado');
  return rows[0].schema_name;
}

// ── Funções Privadas (Regras de Negócio) ─────────────────────────────────────

/**
 * Retorna a configuração operacional do hotel.
 * Lança erro se ainda não foi criada (hotel precisa chamar POST primeiro).
 */
async function _getConfiguracaoHotel(hotelId: string): Promise<ConfiguracaoHotelSafe> {
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const { rows } = await client.query<ConfiguracaoHotelSafe>(
      `SELECT hotel_id, horario_checkin, horario_checkout, max_dias_reserva,
              politica_cancelamento, aceita_animais, idiomas_atendimento
       FROM configuracao_hotel
       WHERE hotel_id = $1`,
      [hotelId],
    );
    if (!rows[0]) throw new Error('Configuração do hotel não encontrada');
    return rows[0];
  });
}

/**
 * Cria a configuração do hotel com os valores fornecidos.
 * Campos não informados usam os defaults definidos no banco:
 *   checkin=14:00, checkout=12:00, max_dias=30, aceita_animais=false, idiomas=Português
 * Lança erro 'já existe' se o hotel já possui configuração.
 */
async function _createConfiguracaoHotel(
  hotelId: string,
  input:   ConfiguracaoHotelInput,
): Promise<ConfiguracaoHotelSafe> {
  ConfiguracaoHotel.validate(input);
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const { rows: existing } = await client.query(
      `SELECT hotel_id FROM configuracao_hotel WHERE hotel_id = $1`,
      [hotelId],
    );
    if (existing[0]) throw new Error('Configuração já existe para este hotel');

    // Insere com defaults da aplicação para campos não informados
    const { rows } = await client.query<ConfiguracaoHotelSafe>(
      `INSERT INTO configuracao_hotel
         (hotel_id, horario_checkin, horario_checkout, max_dias_reserva,
          politica_cancelamento, aceita_animais, idiomas_atendimento)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING hotel_id, horario_checkin, horario_checkout, max_dias_reserva,
                 politica_cancelamento, aceita_animais, idiomas_atendimento`,
      [
        hotelId,
        input.horario_checkin       ?? '14:00',
        input.horario_checkout      ?? '12:00',
        input.max_dias_reserva      ?? 30,
        input.politica_cancelamento ?? null,
        input.aceita_animais        ?? false,
        input.idiomas_atendimento   ?? 'Português',
      ],
    );
    return rows[0];
  });
}

/**
 * Atualiza parcialmente a configuração do hotel.
 * Apenas os campos presentes no body são modificados.
 */
async function _updateConfiguracaoHotel(
  hotelId: string,
  input:   ConfiguracaoHotelInput,
): Promise<ConfiguracaoHotelSafe> {
  ConfiguracaoHotel.validatePartial(input);
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const fields: string[] = [];
    const values: unknown[] = [];
    let idx = 1;

    if (input.horario_checkin       != null) { fields.push(`horario_checkin = $${idx++}`);       values.push(input.horario_checkin); }
    if (input.horario_checkout      != null) { fields.push(`horario_checkout = $${idx++}`);      values.push(input.horario_checkout); }
    if (input.max_dias_reserva      != null) { fields.push(`max_dias_reserva = $${idx++}`);      values.push(input.max_dias_reserva); }
    if (input.aceita_animais        != null) { fields.push(`aceita_animais = $${idx++}`);        values.push(input.aceita_animais); }
    if (input.idiomas_atendimento   != null) { fields.push(`idiomas_atendimento = $${idx++}`);   values.push(input.idiomas_atendimento); }
    // politica_cancelamento permite null explícito (remover política)
    if (input.politica_cancelamento !== undefined) { fields.push(`politica_cancelamento = $${idx++}`); values.push(input.politica_cancelamento); }

    values.push(hotelId);

    const { rows } = await client.query<ConfiguracaoHotelSafe>(
      `UPDATE configuracao_hotel
       SET ${fields.join(', ')}
       WHERE hotel_id = $${idx}
       RETURNING hotel_id, horario_checkin, horario_checkout, max_dias_reserva,
                 politica_cancelamento, aceita_animais, idiomas_atendimento`,
      values,
    );
    if (!rows[0]) throw new Error('Configuração do hotel não encontrada');
    return rows[0];
  });
}
