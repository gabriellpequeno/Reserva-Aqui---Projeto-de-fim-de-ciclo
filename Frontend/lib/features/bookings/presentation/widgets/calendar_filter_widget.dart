import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CalendarFilterWidget extends StatefulWidget {
  const CalendarFilterWidget({
    super.key,
    required this.datasComReserva,
    required this.onDateSelected,
    this.initialDate,
  });

  final Set<DateTime> datasComReserva;
  final ValueChanged<DateTime?> onDateSelected;
  final DateTime? initialDate;

  @override
  State<CalendarFilterWidget> createState() => _CalendarFilterWidgetState();
}

class _CalendarFilterWidgetState extends State<CalendarFilterWidget> {
  late DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
  }

  bool _hasReserva(DateTime day) {
    return widget.datasComReserva.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtrar por data',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Stack Sans Headline',
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (_selected != null)
                TextButton(
                  onPressed: () {
                    setState(() => _selected = null);
                    widget.onDateSelected(null);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Limpar filtro'),
                ),
            ],
          ),
        ),
        CalendarDatePicker(
          initialDate: _selected ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          onDateChanged: (date) {
            setState(() => _selected = date);
          },
        ),
        // Legenda de dot para dias com reservas
        if (widget.datasComReserva.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Dia com reserva',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Stack Sans Text',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _selected == null
                  ? null
                  : () {
                      widget.onDateSelected(_selected);
                      Navigator.of(context).pop();
                    },
              child: const Text(
                'Aplicar',
                style: TextStyle(
                  fontFamily: 'Stack Sans Text',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void showCalendarFilter({
  required BuildContext context,
  required Set<DateTime> datasComReserva,
  required ValueChanged<DateTime?> onDateSelected,
  DateTime? initialDate,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => CalendarFilterWidget(
      datasComReserva: datasComReserva,
      onDateSelected: onDateSelected,
      initialDate: initialDate,
    ),
  );
}
