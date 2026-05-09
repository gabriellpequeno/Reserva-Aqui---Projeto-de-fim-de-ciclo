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
import fs from 'fs';
import path from 'path';
import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import { UPLOAD_DIR } from './storage.service';

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
  descricao: string | null;
  nome_categoria: string | null;
  valor_diaria: string;
  nome_hotel: string;
  cidade: string;
  uf: string;
  nota_media: number | null;
  foto_id: string | null;
  foto_storage_path: string | null;
  itens: string[];
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

    return numberDuplicateTitles(result.slice(0, MAX_RESULTS));
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
            descricao: string | null;
            nome_categoria: string | null;
            valor_diaria: string;
            nota_media: number | null;
            foto_id: string | null;
            foto_storage_path: string | null;
            itens: string[];
          }>(
            `SELECT
               q.id AS quarto_id,
               q.numero,
               q.descricao,
               cq.nome AS nome_categoria,
               COALESCE(q.valor_override, cq.preco_base::numeric) AS valor_diaria,
               ROUND(AVG(a.nota_total), 1) AS nota_media,
               (SELECT id::text FROM quarto_foto WHERE quarto_id = q.id ORDER BY ordem ASC, criado_em ASC LIMIT 1) AS foto_id,
               (SELECT storage_path FROM quarto_foto WHERE quarto_id = q.id ORDER BY ordem ASC, criado_em ASC LIMIT 1) AS foto_storage_path,
               COALESCE(
                 (SELECT json_agg(c.nome ORDER BY c.nome)
                  FROM itens_do_quarto iq
                  JOIN catalogo c ON c.id = iq.catalogo_id AND c.deleted_at IS NULL
                  WHERE iq.quarto_id = q.id),
                 (SELECT json_agg(c.nome ORDER BY c.nome)
                  FROM categoria_item ci
                  JOIN catalogo c ON c.id = ci.catalogo_id AND c.deleted_at IS NULL
                  WHERE ci.categoria_quarto_id = q.categoria_quarto_id),
                 '[]'::json
               ) AS itens
             FROM quarto q
             LEFT JOIN categoria_quarto cq ON cq.id = q.categoria_quarto_id
             LEFT JOIN avaliacao a ON a.reserva_id IN (
               SELECT id FROM reserva WHERE quarto_id = q.id AND status = 'CONCLUIDA'
             )
             WHERE q.deleted_at IS NULL AND q.disponivel = TRUE
             GROUP BY q.id, q.numero, q.descricao, q.valor_override, cq.preco_base, cq.nome`
          );
          return rows;
        });

        for (const row of tenantRooms) {
          results.push({
            quarto_id: row.quarto_id,
            hotel_id: hotel.hotel_id,
            numero: row.numero,
            descricao: row.descricao ?? null,
            nome_categoria: row.nome_categoria ?? null,
            valor_diaria: row.valor_diaria,
            nome_hotel: hotel.nome_hotel,
            cidade: hotel.cidade,
            uf: hotel.uf,
            nota_media: row.nota_media,
            foto_id: row.foto_id ?? null,
            foto_storage_path: row.foto_storage_path ?? null,
            itens: row.itens ?? [],
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

  return numberDuplicateTitles(result);
}

function photoFileExists(storagePath: string | null): boolean {
  if (!storagePath) return false;
  return fs.existsSync(path.resolve(UPLOAD_DIR, storagePath));
}

// Enriquecimento: monta o shape final RecommendedRoom com imagem_url e comodidades
function enrichRoom(room: RawRoom, hotel: HotelMatch): RecommendedRoom {
  const imageUrl = room.foto_id && photoFileExists(room.foto_storage_path)
    ? `/api/v1/uploads/hotels/${room.hotel_id}/rooms/${room.quarto_id}/${room.foto_id}`
    : '';
  const roomName = room.nome_categoria?.trim() || room.descricao?.trim() || `Quarto ${room.numero}`;
  return {
    roomId: String(room.quarto_id),
    title: `${roomName} - ${hotel.nome_hotel}`,
    imageUrl,
    rating: room.nota_media ? String(room.nota_media).replace('.', ',') : '0,0',
    price: room.valor_diaria,
    amenities: room.itens,
    hotelId: room.hotel_id,
    destination: `${hotel.cidade}, ${hotel.uf}`,
  };
}

// Numera quartos com mesmo nome dentro do mesmo hotel: "Suite - Hotel X" → "Suite #1 - Hotel X"
function numberDuplicateTitles(rooms: RecommendedRoom[]): RecommendedRoom[] {
  const counts: Record<string, number> = {};
  for (const room of rooms) {
    const key = `${room.hotelId}:${room.title}`;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  const indices: Record<string, number> = {};
  return rooms.map(room => {
    const key = `${room.hotelId}:${room.title}`;
    if ((counts[key] ?? 0) <= 1) return room;
    indices[key] = (indices[key] ?? 0) + 1;
    const sepIdx = room.title.indexOf(' - ');
    const roomPart = sepIdx >= 0 ? room.title.slice(0, sepIdx) : room.title;
    const hotelPart = sepIdx >= 0 ? room.title.slice(sepIdx) : '';
    return { ...room, title: `${roomPart} #${indices[key]}${hotelPart}` };
  });
}