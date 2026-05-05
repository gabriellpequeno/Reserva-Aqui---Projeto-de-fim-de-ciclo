import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Header curvo reutilizado pelos dashboards Host e Admin.
///
/// Replica o padrão visual de `my_rooms_page.dart` e `admin_account_management_page.dart`
/// — primary com cantos arredondados na base, row de 3 colunas com botões
/// circulares translúcidos em volta do título central.
class DashboardHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const DashboardHeader({
    super.key,
    required this.title,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(27),
          bottomRight: Radius.circular(27),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleButton(
            label: 'Voltar',
            icon: Icons.arrow_back_ios_new,
            iconSize: 18,
            onPressed: onBack,
          ),
          Column(
            children: [
              const Text(
                'RESERVAQUI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          _CircleButton(
            label: 'Atualizar',
            icon: Icons.refresh,
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconSize;
  final VoidCallback onPressed;

  const _CircleButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Semantics(
        label: label,
        button: true,
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: iconSize),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
