/**
 * Service: Recomendação de Quartos
 *
 * Lógica de recomendação:
 * 1. Busca todos os quartos com suas notas médias
 * 2. Agrupa por blocos de nota (desc) — empates ficam no mesmo bloco
 * 3. Bloco A (nota mais alta): garantidos no topo
 * 4. Bloco B (próxima nota): 2 slots sorteados aleatoriamente
 * 5. Limite: 5 resultados
 * 6. Fallback: se não houver avaliações, retorna 5 aleatórios
 */
import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';

const MAX_RESULTS = 5;

interface HotelMatch {
  hotel_id: string;
  nome_hotel: string;
  cidade: string;
  uf: string;
  schema_name: string;
}

interface RawRoom {
  quarto_id: number;
  hotel_id: string;
  numero: string;
  valor_diaria: string;
  nome_hotel: string;
  cidade: string;
  uf: string;
  nota_media: number | null;
}

interface RatingBlock {
  nota: number;
  quartos: RawRoom[];
}

export interface RecommendedRoom {
  roomId: string;
  title: string;
  imageUrl: string;
  rating: string;
  price: string;
  amenities: string[];
  hotelId: string;
  destination: string;
}

// Função principal: orquestra a lógica de recomendação e retorna 5 quartos
export async function getRecommendedRooms(): Promise<RecommendedRoom[]> {
  const startTime = Date.now();

  try {
    const roomsWithRatings = await fetchRoomsWithRatings();

    if (roomsWithRatings.length === 0) {
      console.warn('[recommendedRooms] Nenhum quarto encontrado');
      return [];
    }

    // Verifica se há avaliação — se não, usa fallback
    const hasRatings = roomsWithRatings.some(r => r.nota_media !== null);

    if (!hasRatings) {
      console.log('[recommendedRooms] Fallback: sem avaliações, retornando aleatórios');
      return getRandomFallback(roomsWithRatings, startTime);
    }

    const blocks = groupByRatingBlocks(roomsWithRatings);
    const result: RecommendedRoom[] = [];

    // Bloco A: garantidos no topo (primeira nota mais alta)
    if (blocks[0]) {
      const firstBlock = blocks[0].quartos.slice(0, 3);
      for (const room of firstBlock) {
        const hotel: HotelMatch = {
          hotel_id: room.hotel_id,
          nome_hotel: room.nome_hotel,
          cidade: room.cidade,
          uf: room.uf,
          schema_name: '',
        };
        result.push(enrichRoom(room, hotel));
      }
    }

    // Bloco B: 2 slots sorteados da segunda nota
    if (blocks[1] && result.length < MAX_RESULTS) {
      const secondBlock = blocks[1].quartos;
      const shuffled = shufflePick(secondBlock, 2);
      for (const room of shuffled) {
        if (result.length >= MAX_RESULTS) break;
        const hotel: HotelMatch = {
          hotel_id: room.hotel_id,
          nome_hotel: room.nome_hotel,
          cidade: room.cidade,
          uf: room.uf,
          schema_name: '',
        };
        result.push(enrichRoom(room, hotel));
      }
    }

    const elapsedMs = Date.now() - startTime;
    console.log(
      `[recommendedRooms] Retornados: tempo_total_ms=${elapsedMs}, quantidade=${result.length}`
    );

    return result.slice(0, MAX_RESULTS);
  } catch (error) {
    const elapsedMs = Date.now() - startTime;
    console.error(
      `[recommendedRooms] Erro crítico (tempo_total_ms=${elapsedMs}):`,
      error
    );
    throw error;
  }
}

// Busca cross-tenant: coleta todos os quartos com suas médias de avaliação
async function fetchRoomsWithRatings(): Promise<RawRoom[]> {
  const { rows: hoteis } = await masterPool.query<HotelMatch>(
    `SELECT hotel_id, nome_hotel, cidade, uf, schema_name
     FROM anfitriao WHERE ativo = TRUE`
  );

  if (!hoteis.length) return [];

  const results: RawRoom[] = [];

  await Promise.all(
    hoteis.map(async hotel => {
      try {
        const tenantRooms = await withTenant(hotel.schema_name, async client => {
          const { rows } = await client.query<{
            quarto_id: number;
            numero: string;
            valor_diaria: string;
            nota_media: number | null;
          }>(
            `SELECT
               q.id AS quarto_id,
               q.numero,
               COALESCE(q.valor_override, cq.preco_base::numeric) AS valor_diaria,
               ROUND(AVG(a.nota_total), 1) AS nota_media
             FROM quarto q
             LEFT JOIN categoria_quarto cq ON cq.id = q.categoria_quarto_id
             LEFT JOIN avaliacao a ON a.reserva_id IN (
               SELECT id FROM reserva WHERE quarto_id = q.id AND status = 'CONCLUIDA'
             )
             WHERE q.deleted_at IS NULL AND q.disponivel = TRUE
             GROUP BY q.id, q.numero, q.valor_override, cq.preco_base`
          );
          return rows;
        });

        for (const row of tenantRooms) {
          results.push({
            quarto_id: row.quarto_id,
            hotel_id: hotel.hotel_id,
            numero: row.numero,
            valor_diaria: row.valor_diaria,
            nome_hotel: hotel.nome_hotel,
            cidade: hotel.cidade,
            uf: hotel.uf,
            nota_media: row.nota_media,
          });
        }
      } catch (error) {
        console.warn(
          `[recommendedRooms] Erro ao buscar no tenant ${hotel.hotel_id}:`,
          error
        );
      }
    })
  );

  return results;
}

// Agrupa quartos por bloco de nota DESC para separar empates
function groupByRatingBlocks(rooms: RawRoom[]): RatingBlock[] {
  const withNotes = rooms.filter(r => r.nota_media !== null);
  const uniqueNotes = [...new Set(withNotes.map(r => r.nota_media as number))].sort((a, b) => b - a);

  return uniqueNotes.map(nota => ({
    nota,
    quartos: withNotes.filter(r => r.nota_media === nota),
  }));
}

// Sorteio: embaralha e retorna N itens aleatórios de um array
function shufflePick<T>(arr: T[], n: number): T[] {
  const shuffled = [...arr].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, n);
}

// Fallback: retorna 5 quartos aleatórios quando não há nenhuma avaliação
function getRandomFallback(rooms: RawRoom[], startTime: number): RecommendedRoom[] {
  const shuffled = shufflePick(rooms, MAX_RESULTS);

  const result = shuffled.map(room => {
    const hotel: HotelMatch = {
      hotel_id: room.hotel_id,
      nome_hotel: room.nome_hotel,
      cidade: room.cidade,
      uf: room.uf,
      schema_name: '',
    };
    return enrichRoom(room, hotel);
  });

  const elapsedMs = Date.now() - startTime;
  console.log(
    `[recommendedRooms] Fallback executado: tempo_total_ms=${elapsedMs}, quantidade=${result.length}`
  );

  return result;
}

// Enriquecimento: monta o shape final RecommendedRoom com imagem_url e comodidades
function enrichRoom(room: RawRoom, hotel: HotelMatch): RecommendedRoom {
  return {
    roomId: String(room.quarto_id),
    title: `${hotel.nome_hotel} - Quarto ${room.numero}`,
    imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80',
    rating: room.nota_media ? String(room.nota_media).replace('.', ',') : '0,0',
    price: room.valor_diaria,
    amenities: ['Wi-Fi', 'TV', 'Ar-condicionado'],
    hotelId: room.hotel_id,
    destination: `${hotel.cidade}, ${hotel.uf}`,
  };
}