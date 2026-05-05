class TopHotelModel {
  final String hotelId;
  final String nomeHotel;
  final int reservasAtivas;

  const TopHotelModel({
    required this.hotelId,
    required this.nomeHotel,
    required this.reservasAtivas,
  });

  factory TopHotelModel.fromJson(Map<String, dynamic> json) {
    return TopHotelModel(
      hotelId: (json['hotelId'] as String?) ?? '',
      nomeHotel: (json['nomeHotel'] as String?) ?? '',
      reservasAtivas: (json['reservasAtivas'] as num?)?.toInt() ?? 0,
    );
  }
}
