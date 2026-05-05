import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/dashboard/admin_dashboard_state.dart';

/// Row compacta com os dois contadores de "novos cadastros" (últimos 7 dias).
/// Usado no Admin Dashboard.
class NovosCadastrosRow extends StatelessWidget {
  final NovosCadastros novosCadastros;

  const NovosCadastrosRow({super.key, required this.novosCadastros});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Counter(
            icon: Icons.person_add_alt_1,
            label: 'Usuários',
            value: novosCadastros.usuarios,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Counter(
            icon: Icons.apartment,
            label: 'Hotéis',
            value: novosCadastros.hoteis,
          ),
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _Counter({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, novos cadastros: $value',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x3F182541)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.greyText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$value',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
