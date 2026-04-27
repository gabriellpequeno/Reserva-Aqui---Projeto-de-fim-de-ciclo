import 'amenity_dto.dart';

class SearchRoomResultDto {
  final int quartoId;
  final String hotelId;
  final String numero;
  final String? descricao;
  final String valorDiaria;
  final List<AmenityDto> itens;
  final String nomeHotel;
  final String cidade;
  final String uf;

  SearchRoomResultDto({
    required this.quartoId,
    required this.hotelId,
    required this.numero,
    this.descricao,
    required this.valorDiaria,
    required this.itens,
    required this.nomeHotel,
    required this.cidade,
    required this.uf,
  });

  factory SearchRoomResultDto.fromJson(Map<String, dynamic> json) {
    return SearchRoomResultDto(
      quartoId: json['quarto_id'] as int,
      hotelId: json['hotel_id'] as String,
      numero: json['numero'] as String,
      descricao: json['descricao'] as String?,
      valorDiaria: json['valor_diaria'] as String,
      itens: (json['itens'] as List<dynamic>?)
          ?.map((item) => AmenityDto.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      nomeHotel: json['nome_hotel'] as String,
      cidade: json['cidade'] as String,
      uf: json['uf'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'quarto_id': quartoId,
    'hotel_id': hotelId,
    'numero': numero,
    'descricao': descricao,
    'valor_diaria': valorDiaria,
    'itens': itens.map((e) => e.toJson()).toList(),
    'nome_hotel': nomeHotel,
    'cidade': cidade,
    'uf': uf,
  };
}
