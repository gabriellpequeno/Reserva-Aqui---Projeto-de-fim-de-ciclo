import 'package:flutter/services.dart';

/// Formata número de telefone brasileiro em tempo real.
/// Suporta celular (11 dígitos): (xx) xxxxx-xxxx
/// e fixo (10 dígitos):          (xx) xxxx-xxxx
class PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    final newDigits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Se o usuário apagou um caractere de máscara (ex: ")" ou "-"), a contagem
    // de dígitos não muda — removemos o último dígito para não travar o cursor.
    String d = newDigits;
    if (newValue.text.length < oldValue.text.length &&
        newDigits == oldDigits &&
        d.isNotEmpty) {
      d = d.substring(0, d.length - 1);
    }
    if (d.length > 11) d = d.substring(0, 11);

    final buffer = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(d[i]);
      if (i == 1) buffer.write(') ');
      // celular (11 dígitos): traço após o 7º dígito (índice 6)
      // fixo   (10 dígitos): traço após o 6º dígito (índice 5)
      if (d.length == 11 && i == 6) buffer.write('-');
      if (d.length <= 10 && i == 5) buffer.write('-');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
