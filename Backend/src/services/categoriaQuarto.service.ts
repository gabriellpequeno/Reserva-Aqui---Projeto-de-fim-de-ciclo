import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import {
  CategoriaQuarto,
  CategoriaQuartoSafe,
  CreateCategoriaQuartoInput,
  UpdateCategoriaQuartoInput,
  AddCategoriaItemInput,
  CategoriaItemSafe,
} from '../entities/CategoriaQuarto';

// ── Funções Exportadas (Wrappers) ─────────────────────────────────────────────

export async function listCategoriasQuarto(hotelId: string): Promise<CategoriaQuartoSafe[]> {
  return _listCategoriasQuarto(hotelId);
}

export async function getCategoriaQuarto(hotelId: string, categoriaId: number): Promise<CategoriaQuartoSafe> {
  return _getCategoriaQuarto(hotelId, categoriaId);
}

export async function createCategoriaQuarto(hotelId: string, input: CreateCategoriaQuartoInput): Promise<CategoriaQuartoSafe> {
  return _createCategoriaQuarto(hotelId, input);
}

export async function updateCategoriaQuarto(hotelId: string, categoriaId: number, input: UpdateCategoriaQuartoInput): Promise<CategoriaQuartoSafe> {
  return _updateCategoriaQuarto(hotelId, categoriaId, input);
}

export async function deleteCategoriaQuarto(hotelId: string, categoriaId: number): Promise<void> {
  return _deleteCategoriaQuarto(hotelId, categoriaId);
}

export async function addItemToCategoria(hotelId: string, categoriaId: number, input: AddCategoriaItemInput): Promise<CategoriaItemSafe> {
  return _addItemToCategoria(hotelId, categoriaId, input);
}

export async function removeItemFromCategoria(hotelId: string, categoriaId: number, catalogoId: number): Promise<void> {
  return _removeItemFromCategoria(hotelId, categoriaId, catalogoId);
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

/**
 * Query reutilizada para buscar categorias com itens agregados em JSON.
 * Usa json_agg para evitar N+1 — retorna tudo em uma única consulta.
 */
const SELECT_CATEGORIA_COM_ITENS = `
  SELECT
    cq.id,
    cq.nome,
    cq.preco_base,
    cq.capacidade_pessoas,
    COALESCE(
      json_agg(
        json_build_object(
          'catalogo_id', ci.catalogo_id,
          'nome',        c.nome,
          'categoria',   c.categoria,
          'quantidade',  ci.quantidade
        ) ORDER BY c.categoria, c.nome
      ) FILTER (WHERE ci.catalogo_id IS NOT NULL),
      '[]'
    ) AS itens
  FROM categoria_quarto cq
  LEFT JOIN categoria_item ci ON ci.categoria_quarto_id = cq.id
  LEFT JOIN catalogo c ON c.id = ci.catalogo_id AND c.deleted_at IS NULL
`;

// ── Funções Privadas (Regras de Negócio) ─────────────────────────────────────

/**
 * Lista todas as categorias ativas do hotel com seus itens de catálogo.
 * Usa agregação JSON — uma única query retorna tudo ordenado por nome.
 */
async function _listCategoriasQuarto(hotelId: string): Promise<CategoriaQuartoSafe[]> {
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const { rows } = await client.query<CategoriaQuartoSafe>(
      `${SELECT_CATEGORIA_COM_ITENS}
       WHERE cq.deleted_at IS NULL
       GROUP BY cq.id
       ORDER BY cq.nome`,
    );
    return rows;
  });
}

/**
 * Retorna uma categoria específica com seus itens.
 * Lança erro se não encontrada ou já deletada.
 */
async function _getCategoriaQuarto(hotelId: string, categoriaId: number): Promise<CategoriaQuartoSafe> {
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const { rows } = await client.query<CategoriaQuartoSafe>(
      `${SELECT_CATEGORIA_COM_ITENS}
       WHERE cq.id = $1 AND cq.deleted_at IS NULL
       GROUP BY cq.id`,
      [categoriaId],
    );
    if (!rows[0]) throw new Error('Categoria de quarto não encontrada');
    return rows[0];
  });
}

/**
 * Cria uma nova categoria de quarto.
 * Nome deve ser único dentro do hotel (sem distinção por deleted_at — evita confusão).
 */
async function _createCategoriaQuarto(
  hotelId: string,
  input:   CreateCategoriaQuartoInput,
): Promise<CategoriaQuartoSafe> {
  CategoriaQuarto.validate(input);
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const { rows: existing } = await client.query(
      `SELECT id FROM categoria_quarto WHERE nome = $1 AND deleted_at IS NULL`,
      [input.nome],
    );
    if (existing[0]) throw new Error('Já existe uma categoria com este nome');

    const { rows } = await client.query<{ id: number }>(
      `INSERT INTO categoria_quarto (nome, preco_base, capacidade_pessoas)
       VALUES ($1, $2, $3)
       RETURNING id`,
      [input.nome, input.preco_base, input.capacidade_pessoas],
    );

    // Busca com itens para retornar o formato padrão (itens = [] na criação)
    const { rows: full } = await client.query<CategoriaQuartoSafe>(
      `${SELECT_CATEGORIA_COM_ITENS}
       WHERE cq.id = $1
       GROUP BY cq.id`,
      [rows[0].id],
    );
    return full[0];
  });
}

/**
 * Atualiza parcialmente uma categoria de quarto.
 * Verifica unicidade do novo nome se fornecido.
 */
async function _updateCategoriaQuarto(
  hotelId:     string,
  categoriaId: number,
  input:       UpdateCategoriaQuartoInput,
): Promise<CategoriaQuartoSafe> {
  CategoriaQuarto.validatePartial(input);
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    if (input.nome) {
      const { rows: dup } = await client.query(
        `SELECT id FROM categoria_quarto WHERE nome = $1 AND deleted_at IS NULL AND id != $2`,
        [input.nome, categoriaId],
      );
      if (dup[0]) throw new Error('Já existe uma categoria com este nome');
    }

    const fields: string[] = [];
    const values: unknown[] = [];
    let idx = 1;

    if (input.nome               != null) { fields.push(`nome = $${idx++}`);               values.push(input.nome); }
    if (input.preco_base         != null) { fields.push(`preco_base = $${idx++}`);         values.push(input.preco_base); }
    if (input.capacidade_pessoas != null) { fields.push(`capacidade_pessoas = $${idx++}`); values.push(input.capacidade_pessoas); }

    values.push(categoriaId);

    const { rows } = await client.query<{ id: number }>(
      `UPDATE categoria_quarto
       SET ${fields.join(', ')}
       WHERE id = $${idx} AND deleted_at IS NULL
       RETURNING id`,
      values,
    );
    if (!rows[0]) throw new Error('Categoria de quarto não encontrada');

    const { rows: full } = await client.query<CategoriaQuartoSafe>(
      `${SELECT_CATEGORIA_COM_ITENS}
       WHERE cq.id = $1
       GROUP BY cq.id`,
      [rows[0].id],
    );
    return full[0];
  });
}

/**
 * Soft delete de uma categoria.
 * Bloqueado se existirem quartos físicos ativos vinculados a ela.
 */
async function _deleteCategoriaQuarto(hotelId: string, categoriaId: number): Promise<void> {
  const schemaName = await _getSchemaName(hotelId);

  await withTenant(schemaName, async (client) => {
    const { rows: quartos } = await client.query(
      `SELECT id FROM quarto WHERE categoria_quarto_id = $1 AND deleted_at IS NULL LIMIT 1`,
      [categoriaId],
    );
    if (quartos[0]) throw new Error('Categoria possui quartos ativos vinculados — desvincule ou remova os quartos antes');

    const { rowCount } = await client.query(
      `UPDATE categoria_quarto SET deleted_at = NOW()
       WHERE id = $1 AND deleted_at IS NULL`,
      [categoriaId],
    );
    if (!rowCount) throw new Error('Categoria de quarto não encontrada');
  });
}

/**
 * Adiciona um item de catálogo à categoria.
 * Verifica se o item de catálogo existe e está ativo.
 * Lança erro se o item já estiver associado.
 */
async function _addItemToCategoria(
  hotelId:     string,
  categoriaId: number,
  input:       AddCategoriaItemInput,
): Promise<CategoriaItemSafe> {
  CategoriaQuarto.validateItem(input);
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    // Garante que a categoria existe
    const { rows: cat } = await client.query(
      `SELECT id FROM categoria_quarto WHERE id = $1 AND deleted_at IS NULL`,
      [categoriaId],
    );
    if (!cat[0]) throw new Error('Categoria de quarto não encontrada');

    // Garante que o item de catálogo existe e está ativo
    const { rows: catalogo } = await client.query(
      `SELECT id FROM catalogo WHERE id = $1 AND deleted_at IS NULL`,
      [input.catalogo_id],
    );
    if (!catalogo[0]) throw new Error('Item de catálogo não encontrado');

    // Verifica duplicata
    const { rows: existing } = await client.query(
      `SELECT categoria_quarto_id FROM categoria_item
       WHERE categoria_quarto_id = $1 AND catalogo_id = $2`,
      [categoriaId, input.catalogo_id],
    );
    if (existing[0]) throw new Error('Item já associado a esta categoria');

    await client.query(
      `INSERT INTO categoria_item (categoria_quarto_id, catalogo_id, quantidade)
       VALUES ($1, $2, $3)`,
      [categoriaId, input.catalogo_id, input.quantidade],
    );

    const { rows } = await client.query<CategoriaItemSafe>(
      `SELECT ci.catalogo_id, c.nome, c.categoria, ci.quantidade
       FROM categoria_item ci
       JOIN catalogo c ON c.id = ci.catalogo_id
       WHERE ci.categoria_quarto_id = $1 AND ci.catalogo_id = $2`,
      [categoriaId, input.catalogo_id],
    );
    return rows[0];
  });
}

/**
 * Remove um item de catálogo da categoria.
 */
async function _removeItemFromCategoria(
  hotelId:    string,
  categoriaId: number,
  catalogoId:  number,
): Promise<void> {
  const schemaName = await _getSchemaName(hotelId);

  await withTenant(schemaName, async (client) => {
    const { rowCount } = await client.query(
      `DELETE FROM categoria_item
       WHERE categoria_quarto_id = $1 AND catalogo_id = $2`,
      [categoriaId, catalogoId],
    );
    if (!rowCount) throw new Error('Item não encontrado nesta categoria');
  });
}
