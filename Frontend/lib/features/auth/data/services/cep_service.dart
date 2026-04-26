import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cep_response.dart';

final cepServiceProvider = Provider<CepService>((ref) => CepService());

class CepService {
  late final Dio _dio;

  CepService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://viacep.com.br/ws/',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
  }

  Future<CepResponse> lookup(String cep) async {
    try {
      final response = await _dio.get('$cep/json/');
      return CepResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      // Falha de rede expira com erro, tratamos como erro de CEP não encontrado
      // para evitar exceptions que quebrem o formulário
      return CepResponse(erro: true);
    }
  }
}
