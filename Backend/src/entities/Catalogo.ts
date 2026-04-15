/**
 * Entity: Catalogo
 * Responsabilidade: validação pura das regras de negócio.
 * Nunca toca o banco de dados.
 */

export type CategoriaItem = 'COMODO' | 'COMODIDADE' | 'LAZER';

export interface CreateCatalogoInput {
  nome:      string;
  categoria: CategoriaItem;
}

export interface UpdateCatalogoInput {
  nome: string;
}

export interface CatalogoSafe {
  id:        number;
  nome:      string;
  categoria: CategoriaItem;
}

export class Catalogo {
  private static validateNome(nome: unknown): string {
    if (typeof nome !== 'string' || nome.trim().length === 0 || nome.trim().length > 100)
      throw new Error('Nome inválido: deve ter entre 1 e 100 caracteres');
    return nome.trim();
  }

  private static validateCategoria(categoria: unknown): CategoriaItem {
    const valid: CategoriaItem[] = ['COMODO', 'COMODIDADE', 'LAZER'];
    if (!valid.includes(categoria as CategoriaItem))
      throw new Error('Categoria inválida: deve ser COMODO, COMODIDADE ou LAZER');
    return categoria as CategoriaItem;
  }

  /** Valida os campos obrigatórios para criação de um item. */
  static validate(input: unknown): CreateCatalogoInput {
    const data = input as Record<string, unknown>;
    return {
      nome:      this.validateNome(data.nome),
      categoria: this.validateCategoria(data.categoria),
    };
  }

  /** Valida o único campo editável — nome. Categoria é imutável após criação. */
  static validatePartial(input: unknown): UpdateCatalogoInput {
    const data = input as Record<string, unknown>;
    return { nome: this.validateNome(data.nome) };
  }
}
