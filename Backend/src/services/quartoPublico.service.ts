import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';

// Busca dados públicos de um quarto físico com join em categoria e itens de catálogo
export interface QuartoPublicoDetails {
  quarto_id: number;
  numero: string;
  descricao: string | null;
  valor_diaria: string;
  hotel_id: string;
  nome_hotel: string;
  cidade: string;
  uf: string;
  categoria: {
    id: number;
    nome: string;
    capacidade_pessoas: number;
    itens: Array<{
      catalogo_id: number;
      nome: string;
      categoria: string;
      quantidade: number;
    }>;
  };
}

// Busca dados públicos de um quarto físico com join em categoria e itens de catálogo
export async function getRoomPublicDetails(
  hotelId: string,
  quartoId: number,
): Promise<QuartoPublicoDetails> {
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const { rows } = await client.query<QuartoPublicoDetails>(
      `SELECT
         q.id AS quarto_id,
         q.numero,
         q.descricao,
         COALESCE(q.valor_override, cq.preco_base::numeric) AS valor_diaria,
         json_build_object(
           'id', cq.id,
           'nome', cq.nome,
           'capacidade_pessoas', cq.capacidade_pessoas,
           'itens', COALESCE(
             json_agg(
               json_build_object(
                 'catalogo_id', ci.catalogo_id,
                 'nome', c.nome,
                 'categoria', c.categoria,
                 'quantidade', ci.quantidade
               ) ORDER BY c.categoria, c.nome
             ) FILTER (WHERE ci.catalogo_id IS NOT NULL),
             '[]'::json
           )
         ) AS categoria
       FROM quarto q
       LEFT JOIN categoria_quarto cq ON cq.id = q.categoria_quarto_id
       LEFT JOIN categoria_item ci ON ci.categoria_quarto_id = cq.id
       LEFT JOIN catalogo c ON c.id = ci.catalogo_id AND c.deleted_at IS NULL
       WHERE q.id = $1 AND q.deleted_at IS NULL
       GROUP BY q.id, q.numero, q.descricao, q.valor_override, cq.id, cq.nome, cq.preco_base, cq.capacidade_pessoas`,
      [quartoId],
    );

    if (!rows[0]) throw new Error('Quarto não encontrado');

    // Enriquecer com dados do hotel
    const { rows: hotel } = await masterPool.query<{
      hotel_id: string;
      nome_hotel: string;
      cidade: string;
      uf: string;
    }>(
      `SELECT hotel_id, nome_hotel, cidade, uf FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
      [hotelId],
    );

    if (!hotel[0]) throw new Error('Hotel não encontrado');

    return {
      ...rows[0],
      hotel_id: hotel[0].hotel_id,
      nome_hotel: hotel[0].nome_hotel,
      cidade: hotel[0].cidade,
      uf: hotel[0].uf,
    };
  });
}

// Helper privado: busca schema_name do hotel no master
async function _getSchemaName(hotelId: string): Promise<string> {
  const { rows } = await masterPool.query<{ schema_name: string }>(
    `SELECT schema_name FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  if (!rows[0]) throw new Error('Hotel não encontrado');
  return rows[0].schema_name;
}
