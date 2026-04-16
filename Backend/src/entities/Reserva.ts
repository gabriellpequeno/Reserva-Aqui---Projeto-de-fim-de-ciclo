/**
 * Entity: Reserva
 * Responsabilidade: validação pura das regras de negócio.
 * Nunca toca o banco de dados.
 */

export type ReservaStatus = 'SOLICITADA' | 'AGUARDANDO_PAGAMENTO' | 'APROVADA' | 'CANCELADA' | 'CONCLUIDA';
export type CanalOrigem   = 'APP' | 'WHATSAPP' | 'BALCAO';

const STATUSES_VALIDOS: ReservaStatus[] = ['SOLICITADA', 'AGUARDANDO_PAGAMENTO', 'APROVADA', 'CANCELADA', 'CONCLUIDA'];

// ── Interfaces de Input ───────────────────────────────────────────────────────

/** Criação de reserva pelo usuário hóspede via app. */
export interface CreateReservaUsuarioInput {
  hotel_id:      string;
  quarto_id?:    number;
  tipo_quarto?:  string;
  num_hospedes:  number;
  data_checkin:  string; // ISO date: YYYY-MM-DD
  data_checkout: string;
  valor_total?:  number; // calculado automaticamente se quarto_id fornecido
  observacoes?:  string | null;
  p_turisticos?: unknown;
}

/** Criação de reserva walk-in pelo hotel (balcão). */
export interface CreateReservaWalkinInput {
  // Identificação do hóspede — user registrado OU dados manuais
  user_id?:          string;
  nome_hospede?:     string;
  cpf_hospede?:      string;
  telefone_contato?: string;
  // Quarto — id físico OU texto livre
  quarto_id?:        number;
  tipo_quarto?:      string;
  // Dados da estadia
  num_hospedes:      number;
  data_checkin:      string;
  data_checkout:     string;
  valor_total?:      number; // calculado automaticamente se quarto_id fornecido
  observacoes?:      string | null;
  sessao_chat_id?:   string | null;
}

/** Atualização de status pelo hotel. */
export interface UpdateStatusInput {
  status: ReservaStatus;
}

/** Atribuição de quarto a uma reserva. */
export interface AtribuirQuartoInput {
  quarto_id: number;
}

// ── Interface de Output ───────────────────────────────────────────────────────

export interface ReservaSafe {
  id:                  number;
  codigo_publico:      string;
  user_id:             string | null;
  nome_hospede:        string | null;
  cpf_hospede:         string | null;
  telefone_contato:    string | null;
  canal_origem:        CanalOrigem;
  sessao_chat_id:      string | null;
  quarto_id:           number | null;
  tipo_quarto:         string | null;
  num_hospedes:        number;
  data_checkin:        string;
  data_checkout:       string;
  hora_checkin_real:   string | null;
  hora_checkout_real:  string | null;
  valor_total:         string; // DECIMAL retorna como string pelo driver pg
  observacoes:         string | null;
  p_turisticos:        unknown;
  status:              ReservaStatus;
  criado_em:           string;
}

// ── Classe de Validação ───────────────────────────────────────────────────────

export class Reserva {
  private static validateHotelId(id: unknown): string {
    if (typeof id !== 'string' || !/^[0-9a-f-]{36}$/.test(id))
      throw new Error('hotel_id inválido: deve ser um UUID');
    return id;
  }

  private static validateUserId(id: unknown): string {
    if (typeof id !== 'string' || !/^[0-9a-f-]{36}$/.test(id))
      throw new Error('user_id inválido: deve ser um UUID');
    return id;
  }

  private static validateQuartoId(id: unknown): number {
    const v = Number(id);
    if (!Number.isInteger(v) || v <= 0)
      throw new Error('quarto_id inválido: deve ser um inteiro maior que zero');
    return v;
  }

  private static validateNumHospedes(n: unknown): number {
    const v = Number(n);
    if (!Number.isInteger(v) || v <= 0)
      throw new Error('num_hospedes inválido: deve ser um inteiro maior que zero');
    return v;
  }

  private static validateDate(value: unknown, campo: string): string {
    if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value))
      throw new Error(`${campo} inválido: use o formato YYYY-MM-DD`);
    const d = new Date(value);
    if (isNaN(d.getTime())) throw new Error(`${campo} inválido: data não reconhecida`);
    return value;
  }

  private static validateValorTotal(valor: unknown): number {
    const v = Number(valor);
    if (isNaN(v) || v <= 0)
      throw new Error('valor_total inválido: deve ser um número maior que zero');
    return v;
  }

  private static validateObservacoes(obs: unknown): string | null {
    if (obs === null || obs === undefined) return null;
    if (typeof obs !== 'string') throw new Error('observacoes inválidas: deve ser texto');
    return obs.trim() || null;
  }

  /** Valida criação de reserva pelo usuário hóspede (APP). */
  static validateUsuario(input: unknown): CreateReservaUsuarioInput {
    const data = input as Record<string, unknown>;

    const hotel_id       = this.validateHotelId(data.hotel_id);
    const num_hospedes   = this.validateNumHospedes(data.num_hospedes);
    const data_checkin   = this.validateDate(data.data_checkin, 'data_checkin');
    const data_checkout  = this.validateDate(data.data_checkout, 'data_checkout');
    const valor_total    = this.validateValorTotal(data.valor_total);

    if (data_checkout <= data_checkin)
      throw new Error('data_checkout deve ser posterior à data_checkin');

    if (data.quarto_id === undefined && !data.tipo_quarto)
      throw new Error('Informe quarto_id ou tipo_quarto');

    if (data.quarto_id === undefined && data.valor_total === undefined)
      throw new Error('Informe valor_total quando não há quarto_id');

    const result: CreateReservaUsuarioInput = {
      hotel_id,
      num_hospedes,
      data_checkin,
      data_checkout,
    };

    if (data.valor_total !== undefined) result.valor_total = valor_total;
    if (data.quarto_id  !== undefined) result.quarto_id  = this.validateQuartoId(data.quarto_id);
    if (data.tipo_quarto !== undefined) {
      if (typeof data.tipo_quarto !== 'string' || data.tipo_quarto.trim().length === 0)
        throw new Error('tipo_quarto inválido');
      result.tipo_quarto = data.tipo_quarto.trim();
    }
    if (data.observacoes  !== undefined) result.observacoes  = this.validateObservacoes(data.observacoes);
    if (data.p_turisticos !== undefined) result.p_turisticos = data.p_turisticos;

    return result;
  }

  /** Valida criação de reserva walk-in pelo hotel (BALCAO). */
  static validateWalkin(input: unknown): CreateReservaWalkinInput {
    const data = input as Record<string, unknown>;

    const num_hospedes   = this.validateNumHospedes(data.num_hospedes);
    const data_checkin   = this.validateDate(data.data_checkin, 'data_checkin');
    const data_checkout  = this.validateDate(data.data_checkout, 'data_checkout');
    const valor_total    = this.validateValorTotal(data.valor_total);

    if (data_checkout <= data_checkin)
      throw new Error('data_checkout deve ser posterior à data_checkin');

    // Identificação do hóspede: user_id registrado OU nome + (cpf ou telefone)
    const hasUserId     = data.user_id !== undefined && data.user_id !== null && data.user_id !== '';
    const hasNome       = typeof data.nome_hospede === 'string' && data.nome_hospede.trim().length > 0;
    const hasCpfOrFone  = (typeof data.cpf_hospede === 'string' && data.cpf_hospede.trim().length > 0)
                       || (typeof data.telefone_contato === 'string' && data.telefone_contato.trim().length > 0);

    if (!hasUserId && !(hasNome && hasCpfOrFone))
      throw new Error('Identifique o hóspede: informe user_id ou nome_hospede + (cpf_hospede ou telefone_contato)');

    // Quarto: id físico OU texto livre
    if (data.quarto_id === undefined && !data.tipo_quarto)
      throw new Error('Informe quarto_id ou tipo_quarto');

    if (data.quarto_id === undefined && data.valor_total === undefined)
      throw new Error('Informe valor_total quando não há quarto_id');

    const result: CreateReservaWalkinInput = { num_hospedes, data_checkin, data_checkout };

    if (data.valor_total !== undefined)    result.valor_total      = valor_total;
    if (hasUserId)                        result.user_id          = this.validateUserId(data.user_id);
    if (hasNome)                          result.nome_hospede     = (data.nome_hospede as string).trim();
    if (typeof data.cpf_hospede === 'string' && data.cpf_hospede.trim())
                                          result.cpf_hospede      = data.cpf_hospede.trim();
    if (typeof data.telefone_contato === 'string' && data.telefone_contato.trim())
                                          result.telefone_contato = data.telefone_contato.trim();
    if (data.quarto_id  !== undefined)    result.quarto_id        = this.validateQuartoId(data.quarto_id);
    if (data.tipo_quarto !== undefined) {
      if (typeof data.tipo_quarto !== 'string' || !data.tipo_quarto.trim())
        throw new Error('tipo_quarto inválido');
      result.tipo_quarto = data.tipo_quarto.trim();
    }
    if (data.observacoes !== undefined)   result.observacoes      = this.validateObservacoes(data.observacoes);
    if (typeof data.sessao_chat_id === 'string') result.sessao_chat_id = data.sessao_chat_id;

    return result;
  }

  /** Valida atualização de status pelo hotel. */
  static validateStatus(input: unknown): UpdateStatusInput {
    const data = input as Record<string, unknown>;
    if (!STATUSES_VALIDOS.includes(data.status as ReservaStatus))
      throw new Error(`status inválido: valores permitidos são ${STATUSES_VALIDOS.join(', ')}`);
    return { status: data.status as ReservaStatus };
  }

  /** Valida atribuição de quarto. */
  static validateAtribuirQuarto(input: unknown): AtribuirQuartoInput {
    const data = input as Record<string, unknown>;
    return { quarto_id: this.validateQuartoId(data.quarto_id) };
  }
}
