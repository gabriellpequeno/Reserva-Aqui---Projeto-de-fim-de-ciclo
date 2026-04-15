import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import {
  Catalogo,
  CatalogoSafe,
  CreateCatalogoInput,
  UpdateCatalogoInput,
} from '../entities/Catalogo';

// ── Funções Exportadas (Wrappers) ─────────────────────────────────────────────

export async function listCatalogo(hotelId: string): Promise<CatalogoSafe[]> {
  return _listCatalogo(hotelId);
}

export async function createCatalogo(hotelId: string, input: CreateCatalogoInput): Promise<CatalogoSafe> {
  return _createCatalogo(hotelId, input);
}

export async function updateCatalogo(hotelId: string, catalogoId: number, input: UpdateCatalogoInput): Promise<CatalogoSafe> {
  return _updateCatalogo(hotelId, catalogoId, input);
}

export async function deleteCatalogo(hotelId: string, catalogoId: number): Promise<void> {
  return _deleteCatalogo(hotelId, catalogoId);
}

// ── Helper Privado ────────────────────────────────────────────────────────────

/**
 * Busca o schema_name do hotel no master DB.
 * Centraliza o lookup para evitar repetição nas funções privadas.
 */
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
 * Lista todos os itens ativos do catálogo de um hotel.
 * Ordenados por categoria e nome para facilitar exibição no app.
 */
async function _listCatalogo(hotelId: string): Promise<CatalogoSafe[]> {
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const { rows } = await client.query<CatalogoSafe>(
      `SELECT id, nome, categoria
       FROM catalogo
       WHERE deleted_at IS NULL
       ORDER BY categoria, nome`,
    );
    return rows;
  });
}

/**
 * Cria um novo item no catálogo do hotel.
 * Respeita a unique constraint (nome, categoria) — lança 'já existe' se duplicado.
 */
async function _createCatalogo(hotelId: string, input: CreateCatalogoInput): Promise<CatalogoSafe> {
  Catalogo.validate(input);
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const { rows: existing } = await client.query(
      `SELECT id FROM catalogo WHERE nome = $1 AND categoria = $2 AND deleted_at IS NULL`,
      [input.nome, input.categoria],
    );
    if (existing[0]) throw new Error('Item já existe nesta categoria');

    const { rows } = await client.query<CatalogoSafe>(
      `INSERT INTO catalogo (nome, categoria)
       VALUES ($1, $2)
       RETURNING id, nome, categoria`,
      [input.nome, input.categoria],
    );
    return rows[0];
  });
}

/**
 * Atualiza o nome de um item do catálogo.
 * Categoria é imutável — qualquer valor de categoria no input é ignorado.
 * Garante que o novo nome não conflite com outro item da mesma categoria.
 */
async function _updateCatalogo(
  hotelId:    string,
  catalogoId: number,
  input:      UpdateCatalogoInput,
): Promise<CatalogoSafe> {
  Catalogo.validatePartial(input);
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    // Busca o item atual para obter a categoria (necessária para a unique check)
    const { rows: current } = await client.query<{ categoria: string }>(
      `SELECT categoria FROM catalogo WHERE id = $1 AND deleted_at IS NULL`,
      [catalogoId],
    );
    if (!current[0]) throw new Error('Item do catálogo não encontrado');

    const { categoria } = current[0];

    // Verifica unicidade do novo nome dentro da mesma categoria
    const { rows: duplicate } = await client.query(
      `SELECT id FROM catalogo
       WHERE nome = $1 AND categoria = $2 AND deleted_at IS NULL AND id != $3`,
      [input.nome, categoria, catalogoId],
    );
    if (duplicate[0]) throw new Error('Já existe um item com esse nome nesta categoria');

    const { rows } = await client.query<CatalogoSafe>(
      `UPDATE catalogo SET nome = $1
       WHERE id = $2 AND deleted_at IS NULL
       RETURNING id, nome, categoria`,
      [input.nome, catalogoId],
    );
    return rows[0];
  });
}

/**
 * Soft delete de um item do catálogo.
 * Marca deleted_at independente de referências em categoria_item/itens_do_quarto.
 * O item some da UI mas o registro físico permanece (integridade referencial preservada).
 */
async function _deleteCatalogo(hotelId: string, catalogoId: number): Promise<void> {
  const schemaName = await _getSchemaName(hotelId);

  await withTenant(schemaName, async (client) => {
    const { rowCount } = await client.query(
      `UPDATE catalogo SET deleted_at = NOW()
       WHERE id = $1 AND deleted_at IS NULL`,
      [catalogoId],
    );
    if (!rowCount) throw new Error('Item do catálogo não encontrado');
  });
}
