typedef PagamentoStatus = String;

class PagamentoModel {
  final int id;
  final int reservaId;
  final double valorPago;
  final String formaPagamento;
  final PagamentoStatus status;
  final String? checkoutUrl;
  final String? reciboUrl;
  final String? metodoCaptura;

  const PagamentoModel({
    required this.id,
    required this.reservaId,
    required this.valorPago,
    required this.formaPagamento,
    required this.status,
    this.checkoutUrl,
    this.reciboUrl,
    this.metodoCaptura,
  });

  factory PagamentoModel.fromJson(Map<String, dynamic> json) {
    return PagamentoModel(
      id: json['id'] as int,
      reservaId: json['reserva_id'] as int,
      valorPago: double.parse(json['valor_pago'].toString()),
      formaPagamento: json['forma_pagamento'] as String,
      status: json['status'] as String,
      checkoutUrl: json['checkout_url'] as String?,
      reciboUrl: json['recibo_url'] as String?,
      metodoCaptura: json['metodo_captura'] as String?,
    );
  }
}
