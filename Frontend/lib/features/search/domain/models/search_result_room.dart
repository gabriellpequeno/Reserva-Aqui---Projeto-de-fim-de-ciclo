import 'amenity.dart';
import '../../data/dtos/search_room_result_dto.dart';

class SearchResultRoom {
  final int roomId;
  final String hotelId;
  final String numero;
  final String? descricao;
  final String precoDiaria;
  final List<Amenity> amenities;
  final String nomeHotel;
  final String cidade;
  final String uf;
  final String? imageUrl;
  final double? rating;
  final int reviewCount;

  SearchResultRoom({
    required this.roomId,
    required this.hotelId,
    required this.numero,
    this.descricao,
    required this.precoDiaria,
    required this.amenities,
    required this.nomeHotel,
    required this.cidade,
    required this.uf,
    this.imageUrl,
    this.rating,
    required this.reviewCount,
  });

  factory SearchResultRoom.fromDto(SearchRoomResultDto dto) {
    return SearchResultRoom(
      roomId: dto.quartoId,
      hotelId: dto.hotelId,
      numero: dto.numero,
      descricao: dto.descricao,
      precoDiaria: dto.valorDiaria,
      amenities: dto.itens
          .map((itemDto) => Amenity(
            catalogoId: itemDto.catalogoId,
            nome: itemDto.nome,
            categoria: itemDto.categoria,
            quantidade: itemDto.quantidade,
          ))
          .toList(),
      nomeHotel: dto.nomeHotel,
      cidade: dto.cidade,
      uf: dto.uf,
      imageUrl: null,
      rating: null,
      reviewCount: 0,
    );
  }

  SearchResultRoom copyWith({
    String? imageUrl,
    double? rating,
    int? reviewCount,
  }) {
    return SearchResultRoom(
      roomId: roomId,
      hotelId: hotelId,
      numero: numero,
      descricao: descricao,
      precoDiaria: precoDiaria,
      amenities: amenities,
      nomeHotel: nomeHotel,
      cidade: cidade,
      uf: uf,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
