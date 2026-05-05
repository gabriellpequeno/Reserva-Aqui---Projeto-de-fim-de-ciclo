import 'package:flutter/foundation.dart';

/// Status canônicos de reserva, alinhados ao backend (valor cru em SCREAMING_SNAKE).
/// Tradução para labels UI-friendly é feita via [toLabel].
enum ReservaStatus {
  solicitada,
  aguardandoPagamento,
  aprovada,
  cancelada,
  concluida;

  /// Reconstrói a enum a partir do valor cru do backend.
  /// Em valor desconhecido, retorna [solicitada] e emite `debugPrint` para investigação.
  static ReservaStatus fromString(String? value) {
    switch (value) {
      case 'SOLICITADA':
        return ReservaStatus.solicitada;
      case 'AGUARDANDO_PAGAMENTO':
        return ReservaStatus.aguardandoPagamento;
      case 'APROVADA':
        return ReservaStatus.aprovada;
      case 'CANCELADA':
        return ReservaStatus.cancelada;
      case 'CONCLUIDA':
        return ReservaStatus.concluida;
      default:
        debugPrint('[ReservaStatus.fromString] valor desconhecido: $value — defaulting to solicitada');
        return ReservaStatus.solicitada;
    }
  }

  /// Label apresentado na UI.
  String toLabel() {
    switch (this) {
      case ReservaStatus.solicitada:
        return 'Pendente';
      case ReservaStatus.aguardandoPagamento:
        return 'Aguardando pagamento';
      case ReservaStatus.aprovada:
        return 'Confirmada';
      case ReservaStatus.cancelada:
        return 'Cancelada';
      case ReservaStatus.concluida:
        return 'Finalizada';
    }
  }
}
