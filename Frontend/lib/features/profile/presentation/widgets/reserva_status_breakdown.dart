import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/dashboard/reserva_status.dart';
import '../../domain/models/dashboard/reserva_status_count.dart';

/// Mini-barras horizontais com distribuição de reservas por status.
/// Cor de cada barra varia por status (amarelo/laranja/verde/vermelho/cinza).
/// Largura proporcional ao maior count da lista; se total = 0, mostra empty state.
class ReservaStatusBreakdown extends StatelessWidget {
  final List<ReservaStatusCount> items;

  const ReservaStatusBreakdown({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, i) => sum + i.count);

    if (items.isEmpty || total == 0) {
      return _EmptyState();
    }

    final maxCount = items.map((i) => i.count).reduce((a, b) => a > b ? a : b);

    return Column(
      children: items.map((item) {
        final fraction = maxCount == 0 ? 0.0 : item.count / maxCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.status.toLabel(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: AppColors.strokeLight,
                  valueColor: AlwaysStoppedAnimation(_colorFor(item.status)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static Color _colorFor(ReservaStatus status) {
    switch (status) {
      case ReservaStatus.solicitada:
        return const Color(0xFFF4C542); // amarelo
      case ReservaStatus.aguardandoPagamento:
        return AppColors.secondary; // laranja
      case ReservaStatus.aprovada:
        return const Color(0xFF3AAA64); // verde
      case ReservaStatus.cancelada:
        return const Color(0xFFC53939); // vermelho
      case ReservaStatus.concluida:
        return AppColors.greyText; // cinza
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: const Text(
        'Sem reservas no período',
        style: TextStyle(color: AppColors.greyText, fontSize: 13),
      ),
    );
  }
}
