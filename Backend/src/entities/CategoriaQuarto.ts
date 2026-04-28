/**
 * Entity: CategoriaQuarto
 * Responsabilidade: validação pura das regras de negócio.
 * Nunca toca o banco de dados.
 */

export interface CreateCategoriaQuartoInput {
  nome:               string;
  valor_diaria:       number;
  capacidade_pessoas: number;
}

export interface UpdateCategoriaQuartoInput {
  nome?:               string;
  valor_diaria?:       number;
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
  id:                  number;
  nome:                string;
  valor_diaria:        string;   // DECIMAL retorna como string pelo driver pg
  capacidade_pessoas:  number;
  itens:               CategoriaItemSafe[];
  primeiro_quarto_id:  number | null;
}

export class CategoriaQuarto {
  private static validateNome(nome: unknown): string {
    if (typeof nome !== 'string' || nome.trim().length === 0 || nome.trim().length > 50)
      throw new Error('Nome inválido: deve ter entre 1 e 50 caracteres');
    return nome.trim();
  }

  private static validateValorDiaria(preco: unknown): number {
    const v = Number(preco);
    if (isNaN(v) || v <= 0)
      throw new Error('valor_diaria inválido: deve ser um número maior que zero');
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
      valor_diaria:       this.validateValorDiaria(data.valor_diaria),
      capacidade_pessoas: this.validateCapacidade(data.capacidade_pessoas),
    };
  }

  /** Valida campos presentes para atualização parcial. */
  static validatePartial(input: unknown): UpdateCategoriaQuartoInput {
    const data = input as Record<string, unknown>;
    const result: UpdateCategoriaQuartoInput = {};

    if (data.nome               !== undefined) result.nome               = this.validateNome(data.nome);
    if (data.valor_diaria       !== undefined) result.valor_diaria       = this.validateValorDiaria(data.valor_diaria);
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
