import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de data com máscara automática dd/mm/aaaa e ícone de calendário.
/// Digitação formata em tempo real; toque no ícone abre DatePicker nativo.
class DatePickerField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const DatePickerField({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  Future<void> _openCalendar() async {
    final now = DateTime.now();

    DateTime initial = now;
    final text = widget.controller.text;
    if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(text)) {
      final parts = text.split('/');
      final parsed = DateTime.tryParse(
        '${parts[2]}-${parts[1]}-${parts[0]}',
      );
      if (parsed != null) initial = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      final d = picked.day.toString().padLeft(2, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final y = picked.year.toString();
      widget.controller.text = '$d/$m/$y';
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: TextInputType.number,
      inputFormatters: [_DateMaskFormatter()],
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: 'dd/mm/aaaa',
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today_outlined, size: 20),
          color: colorScheme.onSurfaceVariant,
          onPressed: _openCalendar,
        ),
      ),
    );
  }
}

/// Formata a entrada numérica inserindo '/' nas posições corretas.
class _DateMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
