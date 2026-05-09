class FavoriteHotel {
  final String hotelId;
  final String nomeHotel;
  final String cidade;
  final String uf;
  final String bairro;
  final String? descricao;
  final String? firstCoverFotoId;
  final DateTime favoritadoEm;

  const FavoriteHotel({
    required this.hotelId,
    required this.nomeHotel,
    required this.cidade,
    required this.uf,
    required this.bairro,
    this.descricao,
    this.firstCoverFotoId,
    required this.favoritadoEm,
  });

  factory FavoriteHotel.fromJson(Map<String, dynamic> json) {
    return FavoriteHotel(
      hotelId: json['hotel_id'] as String,
      nomeHotel: json['nome_hotel'] as String,
      cidade: json['cidade'] as String,
      uf: json['uf'] as String,
      bairro: json['bairro'] as String,
      descricao: json['descricao'] as String?,
      firstCoverFotoId: json['first_cover_foto_id'] as String?,
      favoritadoEm: DateTime.parse(json['favoritado_em'] as String),
    );
  }
}
