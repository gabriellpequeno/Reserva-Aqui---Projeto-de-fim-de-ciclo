/**
 * Entity: ConfiguracaoHotel
 * Responsabilidade: validação pura das regras de negócio.
 * Nunca toca o banco de dados.
 *
 * Nota: telefone_recepcao existe no schema mas não é exposto pela API.
 */

const TIME_REGEX = /^([01]\d|2[0-3]):([0-5]\d)$/;

export interface ConfiguracaoHotelInput {
  horario_checkin?:       string;   // HH:MM
  horario_checkout?:      string;   // HH:MM
  max_dias_reserva?:      number;
  politica_cancelamento?: string | null;
  aceita_animais?:        boolean;
  idiomas_atendimento?:   string;
}

export interface ConfiguracaoHotelSafe {
  hotel_id:               string;
  horario_checkin:        string;
  horario_checkout:       string;
  max_dias_reserva:       number;
  politica_cancelamento:  string | null;
  aceita_animais:         boolean;
  idiomas_atendimento:    string;
}

export class ConfiguracaoHotel {
  private static validateFields(data: Record<string, unknown>): ConfiguracaoHotelInput {
    const result: ConfiguracaoHotelInput = {};

    if (data.horario_checkin !== undefined) {
      if (typeof data.horario_checkin !== 'string' || !TIME_REGEX.test(data.horario_checkin))
        throw new Error('horario_checkin inválido: use o formato HH:MM (ex: 14:00)');
      result.horario_checkin = data.horario_checkin;
    }

    if (data.horario_checkout !== undefined) {
      if (typeof data.horario_checkout !== 'string' || !TIME_REGEX.test(data.horario_checkout))
        throw new Error('horario_checkout inválido: use o formato HH:MM (ex: 12:00)');
      result.horario_checkout = data.horario_checkout;
    }

    if (data.max_dias_reserva !== undefined) {
      const v = Number(data.max_dias_reserva);
      if (!Number.isInteger(v) || v <= 0)
        throw new Error('max_dias_reserva inválido: deve ser um inteiro maior que zero');
      result.max_dias_reserva = v;
    }

    if (data.aceita_animais !== undefined) {
      if (typeof data.aceita_animais !== 'boolean')
        throw new Error('aceita_animais inválido: deve ser true ou false');
      result.aceita_animais = data.aceita_animais;
    }

    if (data.idiomas_atendimento !== undefined) {
      if (typeof data.idiomas_atendimento !== 'string' || data.idiomas_atendimento.trim().length === 0 || data.idiomas_atendimento.length > 200)
        throw new Error('idiomas_atendimento inválido: deve ser uma string não vazia com até 200 caracteres');
      result.idiomas_atendimento = data.idiomas_atendimento.trim();
    }

    if (data.politica_cancelamento !== undefined) {
      if (data.politica_cancelamento !== null && typeof data.politica_cancelamento !== 'string')
        throw new Error('politica_cancelamento inválida: deve ser texto ou null');
      result.politica_cancelamento = data.politica_cancelamento as string | null;
    }

    return result;
  }

  /** Valida o body do POST — todos os campos são opcionais (DB tem defaults). */
  static validate(input: unknown): ConfiguracaoHotelInput {
    return this.validateFields(input as Record<string, unknown>);
  }

  /** Valida o body do PATCH — apenas campos presentes são validados. */
  static validatePartial(input: unknown): ConfiguracaoHotelInput {
    const data = input as Record<string, unknown>;
    if (!Object.keys(data).length)
      throw new Error('Nenhum campo para atualizar');
    return this.validateFields(data);
  }
}
