enum PaymentMethod { pix, cartaoCredito, cartaoDebito }

extension PaymentMethodApi on PaymentMethod {
  String get apiValue {
    switch (this) {
      case PaymentMethod.pix:            return 'PIX';
      case PaymentMethod.cartaoCredito:  return 'CARTAO_CREDITO';
      case PaymentMethod.cartaoDebito:   return 'CARTAO_DEBITO';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.pix:            return 'PIX';
      case PaymentMethod.cartaoCredito:  return 'Cartão de crédito';
      case PaymentMethod.cartaoDebito:   return 'Cartão de débito';
    }
  }
}

/// Pagamento fake retornado pelos endpoints públicos.
class PagamentoFakeModel {
  final int id;
  final int reservaId;
  final String codigoPublico;
  final String status;      // PENDENTE | APROVADO | CANCELADO
  final double valorTotal;
  final DateTime? expiresAt;

  const PagamentoFakeModel({
    required this.id,
    required this.reservaId,
    required this.codigoPublico,
    required this.status,
    required this.valorTotal,
    this.expiresAt,
  });

  factory PagamentoFakeModel.fromJson(Map<String, dynamic> json) {
    return PagamentoFakeModel(
      id:            json['pagamento_id'] as int,
      reservaId:     json['reserva_id']   as int,
      codigoPublico: json['codigo_publico'] as String,
      status:        json['status'] as String,
      valorTotal:    double.parse(json['valor_total'].toString()),
      expiresAt:     json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
    );
  }
}
