/**
 * Entity: Avaliacao
 * Responsabilidade: validação pura das regras de negócio.
 * Nunca toca o banco de dados.
 * nota_total é sempre calculado pelo backend — nunca recebido no input.
 */

// ── Interfaces de Input ───────────────────────────────────────────────────────

export interface CreateAvaliacaoInput {
  codigo_publico:   string;
  nota_limpeza:     number;
  nota_atendimento: number;
  nota_conforto:    number;
  nota_organizacao: number;
  nota_localizacao: number;
  comentario?:      string | null;
}

/** Todos os campos opcionais — ao menos um deve estar presente. */
export interface UpdateAvaliacaoInput {
  nota_limpeza?:     number;
  nota_atendimento?: number;
  nota_conforto?:    number;
  nota_organizacao?: number;
  nota_localizacao?: number;
  comentario?:       string | null;
}

// ── Interface de Output ───────────────────────────────────────────────────────

export interface AvaliacaoSafe {
  id:               number;
  user_id:          string;
  reserva_id:       number;
  nota_limpeza:     number;
  nota_atendimento: number;
  nota_conforto:    number;
  nota_organizacao: number;
  nota_localizacao: number;
  nota_total:       number;
  comentario:       string | null;
  criado_em:        string;
}

// ── Classe de Validação ───────────────────────────────────────────────────────

export class Avaliacao {
  private static validateNota(valor: unknown, campo: string): number {
    const v = Number(valor);
    if (!Number.isInteger(v) || v < 1 || v > 5)
      throw new Error(`${campo} inválido: deve ser um inteiro entre 1 e 5`);
    return v;
  }

  private static validateCodigoPublico(valor: unknown): string {
    if (typeof valor !== 'string' || !/^[0-9a-f-]{36}$/.test(valor))
      throw new Error('codigo_publico inválido: deve ser um UUID');
    return valor;
  }

  private static validateComentario(valor: unknown): string | null {
    if (valor === null || valor === undefined) return null;
    if (typeof valor !== 'string') throw new Error('comentario inválido: deve ser texto');
    return valor.trim() || null;
  }

  /** Calcula nota_total como média arredondada das 5 notas. */
  static calcularTotal(
    limpeza:     number,
    atendimento: number,
    conforto:    number,
    organizacao: number,
    localizacao: number,
  ): number {
    return Math.round((limpeza + atendimento + conforto + organizacao + localizacao) / 5);
  }

  /** Valida input de criação — todas as 5 notas obrigatórias. */
  static validate(input: unknown): CreateAvaliacaoInput {
    const data = input as Record<string, unknown>;

    const result: CreateAvaliacaoInput = {
      codigo_publico:   this.validateCodigoPublico(data.codigo_publico),
      nota_limpeza:     this.validateNota(data.nota_limpeza,     'nota_limpeza'),
      nota_atendimento: this.validateNota(data.nota_atendimento, 'nota_atendimento'),
      nota_conforto:    this.validateNota(data.nota_conforto,    'nota_conforto'),
      nota_organizacao: this.validateNota(data.nota_organizacao, 'nota_organizacao'),
      nota_localizacao: this.validateNota(data.nota_localizacao, 'nota_localizacao'),
    };

    if (data.comentario !== undefined)
      result.comentario = this.validateComentario(data.comentario);

    return result;
  }

  /** Valida input de atualização parcial — ao menos um campo obrigatório. */
  static validatePartial(input: unknown): UpdateAvaliacaoInput {
    const data = input as Record<string, unknown>;
    const result: UpdateAvaliacaoInput = {};

    if (data.nota_limpeza     !== undefined) result.nota_limpeza     = this.validateNota(data.nota_limpeza,     'nota_limpeza');
    if (data.nota_atendimento !== undefined) result.nota_atendimento = this.validateNota(data.nota_atendimento, 'nota_atendimento');
    if (data.nota_conforto    !== undefined) result.nota_conforto    = this.validateNota(data.nota_conforto,    'nota_conforto');
    if (data.nota_organizacao !== undefined) result.nota_organizacao = this.validateNota(data.nota_organizacao, 'nota_organizacao');
    if (data.nota_localizacao !== undefined) result.nota_localizacao = this.validateNota(data.nota_localizacao, 'nota_localizacao');
    if (data.comentario       !== undefined) result.comentario       = this.validateComentario(data.comentario);

    if (!Object.keys(result).length)
      throw new Error('Nenhum campo para atualizar');

    return result;
  }
}
