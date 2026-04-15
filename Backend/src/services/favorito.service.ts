import { masterPool } from '../database/masterDb';
import { FavoritoComHotel } from '../entities/HotelFavorito';

// ── Funções Exportadas (Wrappers) ─────────────────────────────────────────────

export async function listFavoritos(userId: string): Promise<FavoritoComHotel[]> {
  return _listFavoritos(userId);
}

export async function addFavorito(userId: string, hotelId: string): Promise<FavoritoComHotel> {
  return _addFavorito(userId, hotelId);
}

export async function removeFavorito(userId: string, hotelId: string): Promise<void> {
  return _removeFavorito(userId, hotelId);
}

// ── Funções Privadas (Regras de Negócio) ─────────────────────────────────────

/**
 * Lista todos os hotéis favoritados pelo usuário com dados do hotel para exibição no app.
 * Ignora hotéis inativos — se o hotel foi desativado, some da lista sem erro.
 */
async function _listFavoritos(userId: string): Promise<FavoritoComHotel[]> {
  const { rows } = await masterPool.query<FavoritoComHotel>(
    `SELECT
       a.hotel_id,
       a.nome_hotel,
       a.cidade,
       a.uf,
       a.bairro,
       a.descricao,
       a.cover_storage_path,
       f.criado_em AS favoritado_em
     FROM hotel_favorito f
     JOIN anfitriao a ON a.hotel_id = f.hotel_id AND a.ativo = TRUE
     WHERE f.user_id = $1
     ORDER BY f.criado_em DESC`,
    [userId],
  );
  return rows;
}

/**
 * Adiciona um hotel aos favoritos do usuário.
 * Verifica se o hotel existe e está ativo antes de inserir.
 * Lança erro 'já favoritado' se a relação já existe.
 */
async function _addFavorito(userId: string, hotelId: string): Promise<FavoritoComHotel> {
  // Verifica se o hotel existe e está ativo
  const { rows: hotel } = await masterPool.query<{ hotel_id: string }>(
    `SELECT hotel_id FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  if (!hotel[0]) throw new Error('Hotel não encontrado');

  // Verifica duplicata antes do INSERT para mensagem de erro clara
  const { rows: existing } = await masterPool.query(
    `SELECT id FROM hotel_favorito WHERE user_id = $1 AND hotel_id = $2`,
    [userId, hotelId],
  );
  if (existing[0]) throw new Error('Hotel já favoritado');

  await masterPool.query(
    `INSERT INTO hotel_favorito (user_id, hotel_id) VALUES ($1, $2)`,
    [userId, hotelId],
  );

  // Retorna os dados completos do favorito recém-criado
  const { rows } = await masterPool.query<FavoritoComHotel>(
    `SELECT
       a.hotel_id,
       a.nome_hotel,
       a.cidade,
       a.uf,
       a.bairro,
       a.descricao,
       a.cover_storage_path,
       f.criado_em AS favoritado_em
     FROM hotel_favorito f
     JOIN anfitriao a ON a.hotel_id = f.hotel_id
     WHERE f.user_id = $1 AND f.hotel_id = $2`,
    [userId, hotelId],
  );
  return rows[0];
}

/**
 * Remove um hotel dos favoritos do usuário (hard delete).
 * Lança erro se o favorito não existia.
 */
async function _removeFavorito(userId: string, hotelId: string): Promise<void> {
  const { rowCount } = await masterPool.query(
    `DELETE FROM hotel_favorito WHERE user_id = $1 AND hotel_id = $2`,
    [userId, hotelId],
  );
  if (!rowCount) throw new Error('Favorito não encontrado');
}
