import 'package:flutter_test/flutter_test.dart';
import 'package:reservaqui/features/auth/utils/validators.dart';

void main() {
  group('validateNomeCompleto', () {
    test('rejeita null', () {
      expect(validateNomeCompleto(null), 'Informe o nome completo');
    });

    test('rejeita string vazia', () {
      expect(validateNomeCompleto(''), 'Informe o nome completo');
    });

    test('rejeita string só com espaços', () {
      expect(validateNomeCompleto('   '), 'Informe o nome completo');
    });

    test('rejeita um único nome', () {
      expect(validateNomeCompleto('Maria'), 'Informe nome e sobrenome');
    });

    test('rejeita nome + sobrenome com 1 letra (filtrado)', () {
      // 'Maria S' — 'S' tem length 1, fica abaixo do mínimo (2).
      expect(validateNomeCompleto('Maria S'), 'Informe nome e sobrenome');
    });

    test('aceita nome + sobrenome', () {
      expect(validateNomeCompleto('Maria Silva'), isNull);
    });

    test('aceita nome composto com acentos', () {
      expect(validateNomeCompleto('João Antônio Pereira'), isNull);
    });

    test('aceita com espaços extras', () {
      expect(validateNomeCompleto('  Maria   Silva  '), isNull);
    });
  });

  group('validateEmail', () {
    test('rejeita null e vazio', () {
      expect(validateEmail(null), 'Informe o e-mail');
      expect(validateEmail(''), 'Informe o e-mail');
      expect(validateEmail('   '), 'Informe o e-mail');
    });

    test('rejeita formato sem @', () {
      expect(validateEmail('mariaexample.com'), 'E-mail inválido');
    });

    test('rejeita TLD com 1 letra', () {
      expect(validateEmail('maria@example.c'), 'E-mail inválido');
    });

    test('rejeita sem domínio', () {
      expect(validateEmail('maria@'), 'E-mail inválido');
    });

    test('aceita formato simples', () {
      expect(validateEmail('maria@example.com'), isNull);
    });

    test('aceita com dot, plus e dash no local-part', () {
      expect(validateEmail('maria.silva+work-2@example.com'), isNull);
    });

    test('aceita com dash no domínio', () {
      expect(validateEmail('a@my-domain.co'), isNull);
    });

    test('faz trim antes de validar', () {
      expect(validateEmail('  maria@example.com  '), isNull);
    });
  });

  group('validateCpf', () {
    test('rejeita null e vazio', () {
      expect(validateCpf(null), 'Informe o CPF');
      expect(validateCpf(''), 'Informe o CPF');
    });

    test('rejeita menos de 11 dígitos', () {
      expect(validateCpf('1234567890'), 'CPF inválido');
    });

    test('rejeita mais de 11 dígitos', () {
      expect(validateCpf('123456789012'), 'CPF inválido');
    });

    test('rejeita todos os dígitos iguais (111.111.111-11)', () {
      expect(validateCpf('111.111.111-11'), 'CPF inválido');
      expect(validateCpf('00000000000'), 'CPF inválido');
    });

    test('rejeita dígito verificador errado', () {
      expect(validateCpf('123.456.789-00'), 'CPF inválido');
    });

    test('aceita CPF válido sem máscara', () {
      // CPF sintético com dígitos verificadores corretos.
      expect(validateCpf('52998224725'), isNull);
    });

    test('aceita CPF válido com máscara', () {
      expect(validateCpf('529.982.247-25'), isNull);
    });

    test('aceita com caracteres não numéricos misturados se os 11 dígitos forem válidos', () {
      expect(validateCpf('CPF: 529.982.247-25'), isNull);
    });
  });

  group('validateTelefoneBr', () {
    test('rejeita null e vazio', () {
      expect(validateTelefoneBr(null), 'Informe o telefone');
      expect(validateTelefoneBr(''), 'Informe o telefone');
    });

    test('rejeita menos de 10 dígitos', () {
      expect(validateTelefoneBr('999999999'), 'Telefone inválido (10 ou 11 dígitos com DDD)');
    });

    test('rejeita mais de 11 dígitos', () {
      expect(validateTelefoneBr('999999999999'), 'Telefone inválido (10 ou 11 dígitos com DDD)');
    });

    test('aceita 10 dígitos (fixo)', () {
      expect(validateTelefoneBr('1133224455'), isNull);
    });

    test('aceita 11 dígitos (celular)', () {
      expect(validateTelefoneBr('11999887766'), isNull);
    });

    test('aceita com máscara', () {
      expect(validateTelefoneBr('(11) 99988-7766'), isNull);
    });
  });

  group('onlyDigits', () {
    test('remove tudo que não é dígito', () {
      expect(onlyDigits('(11) 99988-7766'), '11999887766');
      expect(onlyDigits('CPF 529.982.247-25'), '52998224725');
    });

    test('retorna string vazia quando não há dígitos', () {
      expect(onlyDigits('abc def'), '');
    });

    test('preserva string já só com dígitos', () {
      expect(onlyDigits('12345'), '12345');
    });
  });
}
