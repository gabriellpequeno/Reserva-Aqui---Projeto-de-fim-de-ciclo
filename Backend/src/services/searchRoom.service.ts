import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import { SELECT_QUARTO_COM_ITENS } from './quarto.service';

interface SearchRoomRefinos {
  checkin?: string;
  checkout?: string;
  hospedes?: number;
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
    const hasQuery = trimmedQ.length >= 2;

    // 1. Descobre hotéis ativos na master DB
    let hotels: HotelMatch[];
    if (hasQuery) {
      const escapedQ = escapeLikePattern(trimmedQ);
      const pattern = `%${escapedQ}%`;
      const { rows } = await masterPool.query<HotelMatch>(
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
      hotels = rows;
    } else {
      // Sem query — retorna todos os hotéis ativos
      const { rows } = await masterPool.query<HotelMatch>(
        `
        SELECT
          hotel_id,
          nome_hotel,
          cidade,
          uf,
          schema_name
        FROM anfitriao
        WHERE ativo = TRUE
        ORDER BY nome_hotel ASC
        LIMIT 20
        `,
      );
      hotels = rows;
    }

    // 2. Fan-out paralelo: busca quartos em cada tenant com filtros aplicados
    const results: SearchRoomResult[] = [];
    const hasCheckin = typeof refinos?.checkin === 'string';
    const hasCheckout = typeof refinos?.checkout === 'string';
    const hasDateFilter = hasCheckin || hasCheckout;
    const hasGuestsFilter = refinos?.hospedes && refinos!.hospedes! > 0;

    await Promise.all(
      hotels.map(async hotel => {
        try {
          const params: unknown[] = [];
          let whereClause = 'WHERE q.deleted_at IS NULL';

          if (hasDateFilter) {
            if (hasCheckin && hasCheckout) {
              whereClause += `
                AND NOT EXISTS (
                  SELECT 1 FROM reserva r
                  WHERE r.quarto_id = q.id
                    AND r.status NOT IN ('CANCELADA', 'CANCELADO', 'REJEITADA', 'REJEITADO')
                    AND r.data_checkin < $1
                    AND r.data_checkout > $2
                )
              `;
              params.push(refinos!.checkout, refinos!.checkin);
            } else if (hasCheckin) {
              whereClause += `
                AND NOT EXISTS (
                  SELECT 1 FROM reserva r
                  WHERE r.quarto_id = q.id
                    AND r.status NOT IN ('CANCELADA', 'CANCELADO', 'REJEITADA', 'REJEITADO')
                    AND r.data_checkin <= $1
                )
              `;
              params.push(refinos!.checkin);
            } else if (hasCheckout) {
              whereClause += `
                AND NOT EXISTS (
                  SELECT 1 FROM reserva r
                  WHERE r.quarto_id = q.id
                    AND r.status NOT IN ('CANCELADA', 'CANCELADO', 'REJEITADA', 'REJEITADO')
                    AND r.data_checkout >= $1
                )
              `;
              params.push(refinos!.checkout);
            }
          }

          if (hasGuestsFilter) {
            whereClause += ' AND cq.capacidade_pessoas >= $' + (params.length + 1);
            params.push(refinos!.hospedes);
          }

          const quartoQuery = `
            ${SELECT_QUARTO_COM_ITENS}
            ${whereClause}
            GROUP BY q.id, q.numero, cq.preco_base, q.valor_override, q.categoria_quarto_id, q.disponivel, q.descricao
          `;

          const tenantResults = await withTenant(hotel.schema_name, async client => {
            const { rows } = await client.query<{
              id: number;
              numero: string;
              descricao: string | null;
              valor_diaria: string;
              itens: QuartoItem[];
            }>(quartoQuery, params);
            return rows;
          });

          for (const row of tenantResults) {
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
        } catch (error) {
          console.warn(
            `[searchRoom] Erro ao buscar quartos no tenant ${hotel.hotel_id} (${hotel.schema_name}):`,
            error,
          );
        }
      }),
    );

    const elapsedMs = Date.now() - startTime;
    const filterInfo = [
      refinos?.checkin && refinos?.checkout ? `checkin=${refinos.checkin}` : null,
      refinos?.checkin && refinos?.checkout ? `checkout=${refinos.checkout}` : null,
      refinos?.hospedes ? `hospedes=${refinos.hospedes}` : null,
    ].filter(Boolean).join(', ');
    console.log(
      `[searchRoom] Busca concluída: tempo_total_ms=${elapsedMs}, hoteis_iterados=${hotels.length}, resultados=${results.length}${filterInfo ? `, filtros={${filterInfo}}` : ''}`,
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
