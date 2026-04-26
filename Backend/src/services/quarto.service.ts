import { PoolClient } from 'pg';
import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import {
  Quarto,
  QuartoSafe,
  QuartoItemInput,
  CreateQuartoInput,
  UpdateQuartoInput,
} from '../entities/Quarto';

// ── Funções Exportadas (Wrappers) ─────────────────────────────────────────────

export async function listQuartos(hotelId: string): Promise<QuartoSafe[]> {
  return _listQuartos(hotelId);
}

export async function getQuarto(hotelId: string, quartoId: number): Promise<QuartoSafe> {
  return _getQuarto(hotelId, quartoId);
}

export async function createQuarto(hotelId: string, input: CreateQuartoInput): Promise<QuartoSafe> {
  return _createQuarto(hotelId, input);
}

export async function updateQuarto(hotelId: string, quartoId: number, input: UpdateQuartoInput): Promise<QuartoSafe> {
  return _updateQuarto(hotelId, quartoId, input);
}

export async function deleteQuarto(hotelId: string, quartoId: number): Promise<void> {
  return _deleteQuarto(hotelId, quartoId);
}

/**
 * Atualiza a disponibilidade de um quarto.
 * Exportado para uso interno pelo service de reservas — quando uma reserva
 * é aprovada/checkin o quarto fica indisponível; no checkout/cancelamento, volta a ficar disponível.
 */
export async function setQuartoDisponivel(hotelId: string, quartoId: number, disponivel: boolean): Promise<void> {
  return _setQuartoDisponivel(hotelId, quartoId, disponivel);
}

// ── Helpers Privados ──────────────────────────────────────────────────────────

async function _getSchemaName(hotelId: string): Promise<string> {
  const { rows } = await masterPool.query<{ schema_name: string }>(
    `SELECT schema_name FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  if (!rows[0]) throw new Error('Hotel não encontrado');
  return rows[0].schema_name;
}

/**
 * Query reutilizada para buscar quartos com itens agregados em JSON.
 * Usa LEFT JOIN + json_agg para evitar N+1.
 */
export const SELECT_QUARTO_COM_ITENS = `
  SELECT
    q.id,
    q.numero,
    q.categoria_quarto_id,
    q.disponivel,
    q.descricao,
    COALESCE(q.valor_override, cq.preco_base) AS valor_diaria,
    COALESCE(
      json_agg(
        json_build_object(
          'catalogo_id', iq.catalogo_id,
          'nome',        c.nome,
          'categoria',   c.categoria,
          'quantidade',  iq.quantidade
        ) ORDER BY c.categoria, c.nome
      ) FILTER (WHERE iq.catalogo_id IS NOT NULL),
      '[]'
    ) AS itens
  FROM quarto q
  LEFT JOIN categoria_quarto cq ON cq.id = q.categoria_quarto_id
  LEFT JOIN itens_do_quarto iq ON iq.quarto_id = q.id
  LEFT JOIN catalogo c ON c.id = iq.catalogo_id AND c.deleted_at IS NULL
`;

/**
 * Sincroniza os itens de um quarto: deleta todos os existentes e reinsere os novos.
 * Operação atômica — chama dentro de um bloco withTenant existente.
 */
async function _syncItens(client: PoolClient, quartoId: number, itens: QuartoItemInput[]): Promise<void> {
  await client.query(`DELETE FROM itens_do_quarto WHERE quarto_id = $1`, [quartoId]);

  if (!itens.length) return;

  // Valida que todos os catalogo_ids existem e estão ativos antes de inserir
  const catalogoIds = itens.map(i => i.catalogo_id);
  const { rows: found } = await client.query(
    `SELECT id FROM catalogo WHERE id = ANY($1) AND deleted_at IS NULL`,
    [catalogoIds],
  );
  if (found.length !== catalogoIds.length) {
    throw new Error('Um ou mais itens de catálogo não foram encontrados ou estão inativos');
  }

  const values = itens.map((item, i) => `($1, $${i * 2 + 2}, $${i * 2 + 3})`).join(', ');
  const params: unknown[] = [quartoId];
  itens.forEach(item => params.push(item.catalogo_id, item.quantidade));

  await client.query(
    `INSERT INTO itens_do_quarto (quarto_id, catalogo_id, quantidade) VALUES ${values}`,
    params,
  );
}

// ── Funções Privadas (Regras de Negócio) ─────────────────────────────────────

/**
 * Lista todos os quartos ativos do hotel com seus itens.
 */
async function _listQuartos(hotelId: string): Promise<QuartoSafe[]> {
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const { rows } = await client.query<QuartoSafe>(
      `${SELECT_QUARTO_COM_ITENS}
       WHERE q.deleted_at IS NULL
       GROUP BY q.id, cq.id
       ORDER BY q.numero`,
    );
    return rows;
  });
}

/**
 * Retorna um quarto específico com seus itens.
 */
async function _getQuarto(hotelId: string, quartoId: number): Promise<QuartoSafe> {
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const { rows } = await client.query<QuartoSafe>(
      `${SELECT_QUARTO_COM_ITENS}
       WHERE q.id = $1 AND q.deleted_at IS NULL
       GROUP BY q.id, cq.id`,
      [quartoId],
    );
    if (!rows[0]) throw new Error('Quarto não encontrado');
    return rows[0];
  });
}

/**
 * Cria um novo quarto com itens opcionais.
 * Verifica unicidade do número e existência da categoria.
 */
async function _createQuarto(hotelId: string, input: CreateQuartoInput): Promise<QuartoSafe> {
  Quarto.validate(input);
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    // Unicidade do número
    const { rows: dup } = await client.query(
      `SELECT id FROM quarto WHERE numero = $1 AND deleted_at IS NULL`,
      [input.numero],
    );
    if (dup[0]) throw new Error('Já existe um quarto com este número');

    // Categoria deve existir e estar ativa
    const { rows: cat } = await client.query(
      `SELECT id FROM categoria_quarto WHERE id = $1 AND deleted_at IS NULL`,
      [input.categoria_quarto_id],
    );
    if (!cat[0]) throw new Error('Categoria de quarto não encontrada');

    const { rows } = await client.query<{ id: number }>(
      `INSERT INTO quarto (numero, categoria_quarto_id, descricao, valor_override, disponivel)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id`,
      [
        input.numero,
        input.categoria_quarto_id,
        input.descricao     ?? null,
        input.valor_diaria  ?? null,
        input.disponivel     ?? true,
      ],
    );

    const quartoId = rows[0].id;

    if (input.itens?.length) {
      await _syncItens(client, quartoId, input.itens);
    }

    const { rows: full } = await client.query<QuartoSafe>(
      `${SELECT_QUARTO_COM_ITENS}
       WHERE q.id = $1
       GROUP BY q.id, cq.id`,
      [quartoId],
    );
    return full[0];
  });
}

/**
 * Atualiza parcialmente um quarto.
 * Se `itens` estiver presente no body, substitui todos os itens existentes.
 * `valor_override: null` remove o override (quarto volta a usar preco_base da categoria).
 */
async function _updateQuarto(hotelId: string, quartoId: number, input: UpdateQuartoInput): Promise<QuartoSafe> {
  Quarto.validatePartial(input);
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    // Unicidade do número se estiver sendo alterado
    if (input.numero) {
      const { rows: dup } = await client.query(
        `SELECT id FROM quarto WHERE numero = $1 AND deleted_at IS NULL AND id != $2`,
        [input.numero, quartoId],
      );
      if (dup[0]) throw new Error('Já existe um quarto com este número');
    }

    // Categoria deve existir e estar ativa se estiver sendo alterada
    if (input.categoria_quarto_id) {
      const { rows: cat } = await client.query(
        `SELECT id FROM categoria_quarto WHERE id = $1 AND deleted_at IS NULL`,
        [input.categoria_quarto_id],
      );
      if (!cat[0]) throw new Error('Categoria de quarto não encontrada');
    }

    const fields: string[] = [];
    const values: unknown[] = [];
    let idx = 1;

    if (input.numero              !== undefined) { fields.push(`numero = $${idx++}`);              values.push(input.numero); }
    if (input.categoria_quarto_id !== undefined) { fields.push(`categoria_quarto_id = $${idx++}`); values.push(input.categoria_quarto_id); }
    if (input.descricao           !== undefined) { fields.push(`descricao = $${idx++}`);           values.push(input.descricao); }
    if (input.valor_diaria        !== undefined) { fields.push(`valor_override = $${idx++}`);      values.push(input.valor_diaria); }
    if (input.disponivel          !== undefined) { fields.push(`disponivel = $${idx++}`);          values.push(input.disponivel); }

    if (fields.length) {
      values.push(quartoId);
      const { rows } = await client.query<{ id: number }>(
        `UPDATE quarto SET ${fields.join(', ')} WHERE id = $${idx} AND deleted_at IS NULL RETURNING id`,
        values,
      );
      if (!rows[0]) throw new Error('Quarto não encontrado');
    }

    // Substitui itens apenas se o campo foi enviado
    if (input.itens !== undefined) {
      await _syncItens(client, quartoId, input.itens);
    }

    const { rows: full } = await client.query<QuartoSafe>(
      `${SELECT_QUARTO_COM_ITENS}
       WHERE q.id = $1 AND q.deleted_at IS NULL
       GROUP BY q.id, cq.id`,
      [quartoId],
    );
    if (!full[0]) throw new Error('Quarto não encontrado');
    return full[0];
  });
}

/**
 * Soft delete do quarto.
 * Itens (itens_do_quarto) e fotos (quarto_foto) são removidos em cascade pelo DB.
 */
async function _deleteQuarto(hotelId: string, quartoId: number): Promise<void> {
  const schemaName = await _getSchemaName(hotelId);

  await withTenant(schemaName, async (client) => {
    const { rowCount } = await client.query(
      `UPDATE quarto SET deleted_at = NOW() WHERE id = $1 AND deleted_at IS NULL`,
      [quartoId],
    );
    if (!rowCount) throw new Error('Quarto não encontrado');
  });
}

/**
 * Atualiza apenas a disponibilidade do quarto.
 * Chamado internamente pelo service de reservas ao aprovar/fazer checkin (false)
 * ou ao fazer checkout/cancelar (true) — sem passar pelo controller de PATCH.
 */
async function _setQuartoDisponivel(hotelId: string, quartoId: number, disponivel: boolean): Promise<void> {
  const schemaName = await _getSchemaName(hotelId);

  await withTenant(schemaName, async (client) => {
    const { rowCount } = await client.query(
      `UPDATE quarto SET disponivel = $1 WHERE id = $2 AND deleted_at IS NULL`,
      [disponivel, quartoId],
    );
    if (!rowCount) throw new Error('Quarto não encontrado');
  });
}
