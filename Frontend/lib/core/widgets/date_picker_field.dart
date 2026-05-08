import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/auth/presentation/widgets/auth_text_field.dart';

/// Campo de data com máscara automática dd/mm/aaaa e ícone de calendário.
/// Digitação formata em tempo real; toque no ícone abre DatePicker nativo.
/// [lastDate] limita a data máxima selecionável no picker (ex: hoje - 18 anos).
class DatePickerField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final DateTime? lastDate;

  const DatePickerField({
    super.key,
    required this.controller,
    this.validator,
    this.lastDate,
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  Future<void> _openCalendar() async {
    final effectiveLastDate = widget.lastDate ?? DateTime.now();

    DateTime initial = effectiveLastDate;
    final text = widget.controller.text;
    if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(text)) {
      final parts = text.split('/');
      final parsed = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
      if (parsed != null) initial = parsed;
    }

    if (initial.isAfter(effectiveLastDate)) initial = effectiveLastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: effectiveLastDate,
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
    return AuthTextField(
      controller: widget.controller,
      validator: widget.validator,
      hintText: 'dd/mm/aaaa',
      label: 'Data de Nascimento',
      icon: Icons.calendar_today_outlined,
      keyboardType: TextInputType.number,
      inputFormatters: [_DateMaskFormatter()],
      suffixIcon: IconButton(
        icon: const Icon(Icons.edit_calendar_outlined, size: 20),
        onPressed: _openCalendar,
      ),
    );
  }
}

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
