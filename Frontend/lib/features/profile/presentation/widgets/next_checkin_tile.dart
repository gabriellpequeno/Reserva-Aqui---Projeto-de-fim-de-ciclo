import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/dashboard/next_checkin_model.dart';

/// Tile compacto para a seção "Próximos check-ins" do Host Dashboard.
/// Visual alinhado aos cards existentes (radius 11, borda 0x3F182541).
class NextCheckinTile extends StatelessWidget {
  final NextCheckinModel checkin;

  const NextCheckinTile({super.key, required this.checkin});

  @override
  Widget build(BuildContext context) {
    final quartoLabel = checkin.quartoNumero != null
        ? 'Quarto ${checkin.quartoNumero}'
        : (checkin.tipoQuarto ?? 'Quarto não atribuído');
    final dataLabel = _formatDate(checkin.dataCheckin);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0x3F182541)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkin.nomeHospede,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$quartoLabel · $dataLabel',
                  style: const TextStyle(
                    color: AppColors.greyText,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }
}
