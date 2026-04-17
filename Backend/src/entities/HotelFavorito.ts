/**
 * Entity: HotelFavorito
 * Responsabilidade: validação pura das regras de negócio.
 * Nunca toca o banco de dados.
 */

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export interface AddFavoritoInput {
  hotel_id: string;
}

/** Dados do favorito com informações do hotel para exibição no app. */
export interface FavoritoComHotel {
  hotel_id:           string;
  nome_hotel:         string;
  cidade:             string;
  uf:                 string;
  bairro:             string;
  descricao:          string | null;
  cover_storage_path: string | null;
  favoritado_em:      Date;
}

export class HotelFavorito {
  /** Valida e retorna um hotel_id limpo para adicionar aos favoritos. */
  static validate(input: unknown): AddFavoritoInput {
    const data = input as Record<string, unknown>;

    if (typeof data.hotel_id !== 'string' || !UUID_REGEX.test(data.hotel_id))
      throw new Error('hotel_id inválido: deve ser um UUID');

    return { hotel_id: data.hotel_id };
  }

  /** Valida um hotel_id vindo de route param (:hotel_id). */
  static validateId(hotel_id: unknown): string {
    if (typeof hotel_id !== 'string' || !UUID_REGEX.test(hotel_id))
      throw new Error('hotel_id inválido: deve ser um UUID');
    return hotel_id;
  }
}
