import 'package:dio/dio.dart';

class ViaCepResult {
  final String uf;
  final String cidade;
  final String bairro;
  final String rua;

  const ViaCepResult({
    required this.uf,
    required this.cidade,
    required this.bairro,
    required this.rua,
  });
}

Future<ViaCepResult?> fetchViaCep(String cep) async {
  final clean = cep.replaceAll(RegExp(r'\D'), '');
  if (clean.length != 8) return null;

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  try {
    final response = await dio.get<dynamic>(
      'https://viacep.com.br/ws/$clean/json/',
    );
    final raw = response.data;
    Map<String, dynamic>? data;
    if (raw is Map<String, dynamic>) {
      data = raw;
    } else if (raw is Map) {
      data = Map<String, dynamic>.from(raw);
    } else {
      return null;
    }

    final erro = data['erro'];
    if (erro == true || erro == 'true') return null;

    final uf = (data['uf'] ?? '').toString();
    final cidade = (data['localidade'] ?? '').toString();
    if (uf.isEmpty || cidade.isEmpty) return null;

    return ViaCepResult(
      uf: uf,
      cidade: cidade,
      bairro: (data['bairro'] ?? '').toString(),
      rua: (data['logradouro'] ?? '').toString(),
    );
  } catch (_) {
    return null;
  }
}
