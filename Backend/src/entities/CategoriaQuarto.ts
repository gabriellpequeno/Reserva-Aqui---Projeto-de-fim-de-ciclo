/**
 * Entity: CategoriaQuarto
 * Responsabilidade: validação pura das regras de negócio.
 * Nunca toca o banco de dados.
 */

export interface CreateCategoriaQuartoInput {
  nome:               string;
  preco_base:         number;
  capacidade_pessoas: number;
}

export interface UpdateCategoriaQuartoInput {
  nome?:               string;
  preco_base?:         number;
  capacidade_pessoas?: number;
}

export interface AddCategoriaItemInput {
  catalogo_id: number;
  quantidade:  number;
}

export interface CategoriaItemSafe {
  catalogo_id: number;
  nome:        string;
  categoria:   string;
  quantidade:  number;
}

export interface CategoriaQuartoSafe {
  id:                 number;
  nome:               string;
  preco_base:         string;   // DECIMAL retorna como string pelo driver pg
  capacidade_pessoas: number;
  itens:              CategoriaItemSafe[];
}

export class CategoriaQuarto {
  private static validateNome(nome: unknown): string {
    if (typeof nome !== 'string' || nome.trim().length === 0 || nome.trim().length > 50)
      throw new Error('Nome inválido: deve ter entre 1 e 50 caracteres');
    return nome.trim();
  }

  private static validatePrecoBase(preco: unknown): number {
    const v = Number(preco);
    if (isNaN(v) || v <= 0)
      throw new Error('preco_base inválido: deve ser um número maior que zero');
    return v;
  }

  private static validateCapacidade(cap: unknown): number {
    const v = Number(cap);
    if (!Number.isInteger(v) || v <= 0)
      throw new Error('capacidade_pessoas inválida: deve ser um inteiro maior que zero');
    return v;
  }

  /** Valida os campos obrigatórios para criação de uma categoria. */
  static validate(input: unknown): CreateCategoriaQuartoInput {
    const data = input as Record<string, unknown>;
    return {
      nome:               this.validateNome(data.nome),
      preco_base:         this.validatePrecoBase(data.preco_base),
      capacidade_pessoas: this.validateCapacidade(data.capacidade_pessoas),
    };
  }

  /** Valida campos presentes para atualização parcial. */
  static validatePartial(input: unknown): UpdateCategoriaQuartoInput {
    const data = input as Record<string, unknown>;
    const result: UpdateCategoriaQuartoInput = {};

    if (data.nome               !== undefined) result.nome               = this.validateNome(data.nome);
    if (data.preco_base         !== undefined) result.preco_base         = this.validatePrecoBase(data.preco_base);
    if (data.capacidade_pessoas !== undefined) result.capacidade_pessoas = this.validateCapacidade(data.capacidade_pessoas);

    if (!Object.keys(result).length)
      throw new Error('Nenhum campo para atualizar');

    return result;
  }

  /** Valida o body para adicionar um item de catálogo à categoria. */
  static validateItem(input: unknown): AddCategoriaItemInput {
    const data = input as Record<string, unknown>;

    const catalogoId = Number(data.catalogo_id);
    if (!Number.isInteger(catalogoId) || catalogoId <= 0)
      throw new Error('catalogo_id inválido: deve ser um inteiro maior que zero');

    const quantidade = data.quantidade !== undefined ? Number(data.quantidade) : 1;
    if (!Number.isInteger(quantidade) || quantidade <= 0)
      throw new Error('quantidade inválida: deve ser um inteiro maior que zero');

    return { catalogo_id: catalogoId, quantidade };
  }
}
