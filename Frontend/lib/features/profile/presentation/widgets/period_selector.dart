import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/dashboard/dashboard_period.dart';

/// Seletor horizontal dos 4 presets de período dos dashboards.
///
/// Chip selecionado: fundo `AppColors.secondary` + texto branco.
/// Demais: fundo branco + borda `AppColors.strokeLight` + texto `AppColors.primary`.
class PeriodSelector extends StatelessWidget {
  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onChanged;

  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: DashboardPeriod.values.map((p) {
          final isSelected = p == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: _chip(p, isSelected),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chip(DashboardPeriod p, bool selected) {
    return Semantics(
      label: '${p.toLabel()}${selected ? ', selecionado' : ''}',
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.strokeLight,
            ),
          ),
          child: Text(
            p.toLabel(),
            style: TextStyle(
              color: selected ? Colors.white : AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
