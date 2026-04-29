// Status que contabilizam ocupação de unidades — CANCELADA e CONCLUIDA não bloqueiam vagas
const kStatusAtivos = {'SOLICITADA', 'AGUARDANDO_PAGAMENTO', 'APROVADA'};

class ReservaHotelModel {
  final int id;
  final int? quartoId;
  final String? tipoQuarto;
  final DateTime dataCheckin;
  final DateTime dataCheckout;
  final String status;

  const ReservaHotelModel({
    required this.id,
    this.quartoId,
    this.tipoQuarto,
    required this.dataCheckin,
    required this.dataCheckout,
    required this.status,
  });

  bool get ativa => kStatusAtivos.contains(status);

  factory ReservaHotelModel.fromJson(Map<String, dynamic> json) {
    return ReservaHotelModel(
      id: json['id'] as int? ?? 0,
      quartoId: json['quarto_id'] as int?,
      tipoQuarto: json['tipo_quarto'] as String?,
      dataCheckin: DateTime.parse(json['data_checkin'] as String),
      dataCheckout: DateTime.parse(json['data_checkout'] as String),
      status: json['status'] as String? ?? '',
    );
  }
}
