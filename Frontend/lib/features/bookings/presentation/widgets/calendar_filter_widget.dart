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
  late DateTime _focusedMonth;
  late DateTime? _selected;

  static const _weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  static const _months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _focusedMonth = DateTime(
      (_selected ?? DateTime.now()).year,
      (_selected ?? DateTime.now()).month,
    );
  }

  bool _hasReserva(DateTime day) => widget.datasComReserva.any(
        (d) => d.year == day.year && d.month == day.month && d.day == day.day,
      );

  bool _isSelected(DateTime day) =>
      _selected != null &&
      _selected!.year == day.year &&
      _selected!.month == day.month &&
      _selected!.day == day.day;

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  List<DateTime?> _buildDays() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final last = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final days = <DateTime?>[];
    // leading nulls for weekday offset (0=Sun)
    for (var i = 0; i < first.weekday % 7; i++) {
      days.add(null);
    }
    for (var d = 1; d <= last.day; d++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final days = _buildDays();
    final minDate = DateTime(2024);
    final maxDate = DateTime.now().add(const Duration(days: 365));

    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    final nextMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    final canGoPrev = !prevMonth.isBefore(DateTime(minDate.year, minDate.month));
    final canGoNext = !nextMonth.isAfter(DateTime(maxDate.year, maxDate.month));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtrar por data',
                style: TextStyle(
                  fontSize: 16,
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

        // ── Navegação de mês ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: canGoPrev ? colorScheme.onSurface : colorScheme.outlineVariant),
                onPressed: canGoPrev
                    ? () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1))
                    : null,
              ),
              Text(
                '${_months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: canGoNext ? colorScheme.onSurface : colorScheme.outlineVariant),
                onPressed: canGoNext
                    ? () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1))
                    : null,
              ),
            ],
          ),
        ),

        // ── Cabeçalho dos dias da semana ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _weekdays.map((d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 4),

        // ── Grid de dias ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              if (day == null) return const SizedBox();

              final isPast = day.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
              final isFutureBeyond = day.isAfter(maxDate);
              final isDisabled = isPast || isFutureBeyond;
              final isSel = _isSelected(day);
              final hasRes = _hasReserva(day);
              final isNow = _isToday(day);

              return GestureDetector(
                onTap: isDisabled ? null : () => setState(() => _selected = day),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSel ? AppColors.primary : Colors.transparent,
                        border: isNow && !isSel
                            ? Border.all(color: AppColors.secondary, width: 1.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSel || isNow ? FontWeight.w700 : FontWeight.w400,
                          color: isSel
                              ? Colors.white
                              : isDisabled
                                  ? colorScheme.outlineVariant
                                  : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    // dot de reserva
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasRes ? AppColors.secondary : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // ── Legenda ───────────────────────────────────────────────────────────
        if (widget.datasComReserva.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

        // ── Botão Aplicar ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _selected == null
                  ? null
                  : () {
                      widget.onDateSelected(_selected);
                      Navigator.of(context).pop();
                    },
              child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.w600)),
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
