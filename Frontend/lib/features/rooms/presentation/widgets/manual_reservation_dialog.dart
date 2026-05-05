import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ManualReservationDialog extends StatefulWidget {
  final String nomeCategoria;
  final double? valorBase;
  final Set<DateTime> diasIndisponiveis;
  final Future<String?> Function({
    required DateTime checkin,
    required DateTime checkout,
    required double valorTotal,
  }) onConfirm;

  const ManualReservationDialog({
    super.key,
    required this.nomeCategoria,
    required this.diasIndisponiveis,
    required this.onConfirm,
    this.valorBase,
  });

  @override
  State<ManualReservationDialog> createState() => _ManualReservationDialogState();
}

class _ManualReservationDialogState extends State<ManualReservationDialog> {
  DateTimeRange? _intervalo;
  bool _loading = false;
  String? _erro;

  int get _noites {
    if (_intervalo == null) return 0;
    return _intervalo!.end.difference(_intervalo!.start).inDays;
  }

  double get _valorTotal =>
      (_noites > 0 ? (widget.valorBase ?? 1.0) * _noites : 0.0);

  bool _isDiaIndisponivel(DateTime dia) {
    final d = DateTime(dia.year, dia.month, dia.day);
    return widget.diasIndisponiveis
        .any((x) => x.year == d.year && x.month == d.month && x.day == d.day);
  }

  Future<void> _selecionarIntervalo() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      currentDate: DateTime.now(),
      selectableDayPredicate: (day, s, e) => !_isDiaIndisponivel(day),
      helpText: 'Selecionar período de bloqueio',
      saveText: 'Confirmar',
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogThemeData(
              insetPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.10,
                vertical: 24,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child!,
          ),
        );
      },
    );

    if (result != null) setState(() => _intervalo = result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reserva manual',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.nomeCategoria,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Fechar',
                ),
              ],
            ),

            const SizedBox(height: 20),

            Semantics(
              label: 'Selecionar período de reserva',
              child: GestureDetector(
                onTap: _selecionarIntervalo,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: _intervalo != null
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: _intervalo != null
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _intervalo == null
                            ? Text(
                                'Selecionar datas',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_fmtData(_intervalo!.start)}  →  ${_fmtData(_intervalo!.end)}',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$_noites noite${_noites != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_erro != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _erro!,
                  style: TextStyle(color: Colors.red[400], fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    label: 'Confirmar reserva manual',
                    child: ElevatedButton(
                      onPressed: _intervalo != null && !_loading ? _confirmar : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        disabledBackgroundColor: colorScheme.surfaceContainerHigh,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Confirmar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    final erro = await widget.onConfirm(
      checkin: _intervalo!.start,
      checkout: _intervalo!.end,
      valorTotal: _valorTotal > 0 ? _valorTotal : 1.0,
    );

    if (!mounted) return;

    if (erro != null) {
      setState(() {
        _loading = false;
        _erro = erro;
      });
    } else {
      Navigator.of(context).pop(true);
    }
  }

  String _fmtData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
