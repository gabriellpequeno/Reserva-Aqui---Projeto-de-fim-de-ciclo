// Validators compartilhados entre telas de signup e de reserva (guest / hóspede).
// Todos recebem o valor já digitado (com ou sem máscara) e retornam `null` se OK
// ou uma string com a mensagem de erro.

String? validateNomeCompleto(String? value) {
  if (value == null || value.trim().isEmpty) return 'Informe o nome completo';
  final words = value.trim().split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
  if (words.length < 2) return 'Informe nome e sobrenome';
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Informe o e-mail';
  final v = value.trim();
  if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v)) return 'E-mail inválido';
  return null;
}

/// Valida CPF: 11 dígitos + dígito verificador (aceita com ou sem máscara).
String? validateCpf(String? value) {
  if (value == null || value.isEmpty) return 'Informe o CPF';
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return 'CPF inválido';
  if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return 'CPF inválido';

  int calc(String base, int factor) {
    var sum = 0;
    for (var i = 0; i < base.length; i++) {
      sum += int.parse(base[i]) * (factor - i);
    }
    final mod = (sum * 10) % 11;
    return mod == 10 ? 0 : mod;
  }

  final d1 = calc(digits.substring(0, 9), 10);
  final d2 = calc(digits.substring(0, 10), 11);
  if (d1 != int.parse(digits[9]) || d2 != int.parse(digits[10])) return 'CPF inválido';
  return null;
}

/// Telefone brasileiro: 10 (fixo) ou 11 (celular) dígitos.
String? validateTelefoneBr(String? value) {
  if (value == null || value.isEmpty) return 'Informe o telefone';
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10 || digits.length > 11) return 'Telefone inválido (10 ou 11 dígitos com DDD)';
  return null;
}

/// Remove máscara e retorna só os dígitos (helpers de submit).
String onlyDigits(String v) => v.replaceAll(RegExp(r'\D'), '');
