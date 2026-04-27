import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import { SELECT_QUARTO_COM_ITENS } from './quarto.service';

/**
 * Status de reserva que bloqueiam a disponibilidade de um quarto em um intervalo.
 * Centralizado aqui para facilitar futuras mudanças de política de disponibilidade.
 */
export const BLOCKING_RESERVATION_STATUSES = ['SOLICITADA', 'AGUARDANDO_PAGAMENTO', 'APROVADA'] as const;

interface SearchRoomRefinos {
  checkin?: string;
  checkout?: string;
  hospedes?: number;
  amenidadeIds?: number[];
}

interface QuartoItem {
  catalogo_id: number;
  nome: string;
  categoria: string;
  quantidade: number;
}

export interface SearchRoomResult {
  quarto_id: number;
  hotel_id: string;
  numero: string;
  descricao: string | null;
  valor_diaria: string;
  itens: QuartoItem[];
  nome_hotel: string;
  cidade: string;
  uf: string;
}

interface HotelMatch {
  hotel_id: string;
  nome_hotel: string;
  cidade: string;
  uf: string;
  schema_name: string;
}

/**
 * Escapa wildcards SQL (%, _, \) para tratamento literal em ILIKE.
 * Padrão: escapar \ primeiro, depois % e _.
 */
function escapeLikePattern(q: string): string {
  return q.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
}

/**
 * Busca quartos cross-tenant:
 * 1. Query master para descobrir hotéis ativos que casam com q (nome_hotel, cidade, uf)
 * 2. Fan-out com Promise.all nos schemas tenant para coletar quartos não deletados
 * 3. Enrich em memória com dados do hotel
 */
export async function searchRooms(
  q: string,
  refinos?: SearchRoomRefinos,
): Promise<SearchRoomResult[]> {
  const startTime = Date.now();

  try {
    const trimmedQ = q.trim();

    // Escapa wildcards antes de montar o padrão de busca
    const escapedQ = escapeLikePattern(trimmedQ);
    const pattern = `%${escapedQ}%`;

    // 1. Descobre hotéis ativos na master DB
    const { rows: hotels } = await masterPool.query<HotelMatch>(
      `
      SELECT
        hotel_id,
        nome_hotel,
        cidade,
        uf,
        schema_name
      FROM anfitriao
      WHERE ativo = TRUE
        AND (
          unaccent(nome_hotel) ILIKE unaccent($1)
          OR unaccent(cidade) ILIKE unaccent($2)
          OR unaccent(uf) ILIKE unaccent($3)
        )
      ORDER BY
        CASE
          WHEN unaccent(nome_hotel) ILIKE unaccent($1) THEN 0
          WHEN unaccent(nome_hotel) ILIKE unaccent(concat(substring($1, 1, 1), '%')) THEN 1
          ELSE 2
        END,
        nome_hotel ASC
      LIMIT 20
      `,
      [pattern, pattern, pattern],
    );

    // 2. Map hotéis para busca rápida por hotel_id
    const hotelMap = new Map<string, HotelMatch>(
      hotels.map(h => [h.hotel_id, h]),
    );

    // 3. Fan-out paralelo: busca quartos em cada tenant
    const results: SearchRoomResult[] = [];

    await Promise.all(
      hotels.map(async hotel => {
        try {
          await withTenant(hotel.schema_name, async client => {
            // Monta WHERE com filtros condicionais
            let whereConditions = [
              'q.deleted_at IS NULL',
              'cq.deleted_at IS NULL',
              'c.deleted_at IS NULL',
            ];
            const queryParams: any[] = [];

            // Filtro de capacidade (hospedes)
            if (refinos?.hospedes) {
              whereConditions.push('cq.capacidade_pessoas >= $' + (queryParams.length + 1));
              queryParams.push(refinos.hospedes);
            }

            // Filtro de disponibilidade por data
            if (refinos?.checkin && refinos?.checkout) {
              whereConditions.push(`
                NOT EXISTS (
                  SELECT 1 FROM reserva r
                  WHERE r.quarto_id = q.id
                    AND r.status = ANY($${queryParams.length + 1}::text[])
                    AND r.data_checkin < $${queryParams.length + 2}::date
                    AND r.data_checkout > $${queryParams.length + 3}::date
                )
              `);
              queryParams.push(
                Array.from(BLOCKING_RESERVATION_STATUSES),
                refinos.checkout,
                refinos.checkin,
              );
            }

            // Filtro de amenidades (AND lógico)
            if (refinos?.amenidadeIds && refinos.amenidadeIds.length > 0) {
              whereConditions.push(`
                q.id IN (
                  SELECT quarto_id FROM itens_do_quarto
                  WHERE catalogo_id = ANY($${queryParams.length + 1}::int[])
                  GROUP BY quarto_id
                  HAVING COUNT(DISTINCT catalogo_id) = $${queryParams.length + 2}::int
                )
              `);
              queryParams.push(refinos.amenidadeIds, refinos.amenidadeIds.length);
            }

            const whereClause = whereConditions.join(' AND ');

            // Reusa SELECT_QUARTO_COM_ITENS com JOINs para JOIN categoria_quarto
            const quartoQuery = `
              ${SELECT_QUARTO_COM_ITENS}
              WHERE ${whereClause}
              GROUP BY q.id, q.numero, cq.preco_base, q.valor_override, q.categoria_quarto_id, q.disponivel, q.descricao
            `;

            const { rows } = await client.query<{
              id: number;
              numero: string;
              descricao: string | null;
              valor_diaria: string;
              itens: QuartoItem[];
            }>(quartoQuery, queryParams);

            // Enrich com dados do hotel
            for (const row of rows) {
              results.push({
                quarto_id: row.id,
                hotel_id: hotel.hotel_id,
                numero: row.numero,
                descricao: row.descricao,
                valor_diaria: row.valor_diaria,
                itens: row.itens || [],
                nome_hotel: hotel.nome_hotel,
                cidade: hotel.cidade,
                uf: hotel.uf,
              });
            }
          });
        } catch (error) {
          console.warn(
            `[searchRoom] Erro ao buscar quartos no tenant ${hotel.hotel_id} (${hotel.schema_name}):`,
            error,
          );
          // Tenant com erro é omitido do resultado, não derruba a busca
        }
      }),
    );

    const elapsedMs = Date.now() - startTime;
    console.log(
      `[searchRoom] Busca concluída: tempo_total_ms=${elapsedMs}, hoteis_iterados=${hotels.length}`,
    );

    return results;
  } catch (error) {
    const elapsedMs = Date.now() - startTime;
    console.error(
      `[searchRoom] Erro crítico em searchRooms (q="${q}", tempo_total_ms=${elapsedMs}):`,
      error,
    );
    throw error;
  }
}
