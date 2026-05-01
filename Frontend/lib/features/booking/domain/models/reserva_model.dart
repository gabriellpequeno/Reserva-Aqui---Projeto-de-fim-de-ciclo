typedef ReservaStatus = String;

class ReservaModel {
  final int id;
  final String codigoPublico;
  final String? userId;
  final String? nomeHospede;
  final int? quartoId;
  final String? tipoQuarto;
  final int numHospedes;
  final DateTime dataCheckin;
  final DateTime dataCheckout;
  final double valorTotal;
  final String? observacoes;
  final ReservaStatus status;
  final DateTime criadoEm;

  const ReservaModel({
    required this.id,
    required this.codigoPublico,
    this.userId,
    this.nomeHospede,
    this.quartoId,
    this.tipoQuarto,
    required this.numHospedes,
    required this.dataCheckin,
    required this.dataCheckout,
    required this.valorTotal,
    this.observacoes,
    required this.status,
    required this.criadoEm,
  });

  factory ReservaModel.fromJson(Map<String, dynamic> json) {
    return ReservaModel(
      id: json['id'] as int,
      codigoPublico: json['codigo_publico'] as String,
      userId: json['user_id'] as String?,
      nomeHospede: json['nome_hospede'] as String?,
      quartoId: json['quarto_id'] as int?,
      tipoQuarto: json['tipo_quarto'] as String?,
      numHospedes: json['num_hospedes'] as int,
      dataCheckin: DateTime.parse(json['data_checkin'] as String),
      dataCheckout: DateTime.parse(json['data_checkout'] as String),
      valorTotal: double.parse(json['valor_total'].toString()),
      observacoes: json['observacoes'] as String?,
      status: json['status'] as String,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }
}
