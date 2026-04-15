/**
 * Entity: Quarto
 * Responsabilidade: validação pura das regras de negócio.
 * Nunca toca o banco de dados.
 */

export interface QuartoItemInput {
  catalogo_id: number;
  quantidade:  number;
}

export interface CreateQuartoInput {
  numero:              string;
  categoria_quarto_id: number;
  descricao?:          string | null;
  valor_override?:     number | null;
  disponivel?:         boolean;
  itens?:              QuartoItemInput[];
}

export interface UpdateQuartoInput {
  numero?:              string;
  categoria_quarto_id?: number;
  descricao?:           string | null;
  valor_override?:      number | null;
  disponivel?:          boolean;
  itens?:               QuartoItemInput[];
}

export interface QuartoItemSafe {
  catalogo_id: number;
  nome:        string;
  categoria:   string;
  quantidade:  number;
}

export interface QuartoSafe {
  id:                  number;
  numero:              string;
  categoria_quarto_id: number;
  disponivel:          boolean;
  descricao:           string | null;
  valor_override:      string | null;  // DECIMAL retorna como string pelo driver pg
  itens:               QuartoItemSafe[];
}

export class Quarto {
  private static validateNumero(numero: unknown): string {
    if (typeof numero !== 'string' || numero.trim().length === 0 || numero.trim().length > 10)
      throw new Error('numero inválido: deve ter entre 1 e 10 caracteres');
    return numero.trim();
  }

  private static validateCategoriaId(id: unknown): number {
    const v = Number(id);
    if (!Number.isInteger(v) || v <= 0)
      throw new Error('categoria_quarto_id inválido: deve ser um inteiro maior que zero');
    return v;
  }

  private static validateDescricao(desc: unknown): string | null {
    if (desc === null || desc === undefined) return null;
    if (typeof desc !== 'string' || desc.length > 500)
      throw new Error('descricao inválida: deve ter no máximo 500 caracteres');
    return desc.trim() || null;
  }

  private static validateValorOverride(valor: unknown): number | null {
    if (valor === null || valor === undefined) return null;
    const v = Number(valor);
    if (isNaN(v) || v <= 0)
      throw new Error('valor_override inválido: deve ser um número maior que zero');
    return v;
  }

  private static validateItens(itens: unknown): QuartoItemInput[] {
    if (!Array.isArray(itens)) throw new Error('itens deve ser um array');
    return itens.map((item, i) => {
      const catalogoId = Number((item as any).catalogo_id);
      if (!Number.isInteger(catalogoId) || catalogoId <= 0)
        throw new Error(`itens[${i}].catalogo_id inválido: deve ser um inteiro maior que zero`);

      const quantidade = (item as any).quantidade !== undefined ? Number((item as any).quantidade) : 1;
      if (!Number.isInteger(quantidade) || quantidade <= 0)
        throw new Error(`itens[${i}].quantidade inválida: deve ser um inteiro maior que zero`);

      return { catalogo_id: catalogoId, quantidade };
    });
  }

  /** Valida campos obrigatórios para criação. */
  static validate(input: unknown): CreateQuartoInput {
    const data = input as Record<string, unknown>;

    const result: CreateQuartoInput = {
      numero:              this.validateNumero(data.numero),
      categoria_quarto_id: this.validateCategoriaId(data.categoria_quarto_id),
    };

    if (data.descricao      !== undefined) result.descricao      = this.validateDescricao(data.descricao);
    if (data.valor_override !== undefined) result.valor_override = this.validateValorOverride(data.valor_override);
    if (data.disponivel     !== undefined) {
      if (typeof data.disponivel !== 'boolean') throw new Error('disponivel deve ser true ou false');
      result.disponivel = data.disponivel;
    }
    if (data.itens !== undefined) result.itens = this.validateItens(data.itens);

    return result;
  }

  /** Valida campos presentes para atualização parcial. */
  static validatePartial(input: unknown): UpdateQuartoInput {
    const data = input as Record<string, unknown>;
    const result: UpdateQuartoInput = {};

    if (data.numero              !== undefined) result.numero              = this.validateNumero(data.numero);
    if (data.categoria_quarto_id !== undefined) result.categoria_quarto_id = this.validateCategoriaId(data.categoria_quarto_id);
    if (data.descricao           !== undefined) result.descricao           = this.validateDescricao(data.descricao);
    if (data.valor_override      !== undefined) result.valor_override      = this.validateValorOverride(data.valor_override);
    if (data.disponivel          !== undefined) {
      if (typeof data.disponivel !== 'boolean') throw new Error('disponivel deve ser true ou false');
      result.disponivel = data.disponivel;
    }
    if (data.itens !== undefined) result.itens = this.validateItens(data.itens);

    if (!Object.keys(result).length) throw new Error('Nenhum campo para atualizar');
    return result;
  }
}
