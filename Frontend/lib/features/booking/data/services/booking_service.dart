import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/rooms/domain/models/hotel_details.dart';
import '../../domain/models/hospede_info.dart';
import '../../domain/models/pagamento_fake_model.dart';
import '../../domain/models/reserva_model.dart';

class BookingService {
  const BookingService(this._dio);

  final Dio _dio;

  Future<void> fetchCategoria({
    required String hotelId,
    required int categoriaId,
    required void Function(CategoriaHotelModel) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/hotel/$hotelId/categorias/$categoriaId',
      );
      final json = response.data!['data'] as Map<String, dynamic>;
      onSuccess(CategoriaHotelModel.fromJson(json));
    } on DioException catch (e) {
      onError(_handleError(e, {404: 'Categoria de quarto não encontrada.'}));
    } catch (_) {
      onError('Erro inesperado ao buscar dados do quarto.');
    }
  }

  Future<void> fetchConfiguracao({
    required String hotelId,
    required void Function(PoliticasHotelModel) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/hotel/$hotelId/configuracao',
      );
      final json = response.data!['data'] as Map<String, dynamic>;
      onSuccess(PoliticasHotelModel.fromJson(json));
    } on DioException catch (e) {
      onError(_handleError(e, {}));
    } catch (_) {
      onError('Erro inesperado ao buscar configuração do hotel.');
    }
  }

  Future<void> fetchQuartoPreco({
    required String hotelId,
    required int quartoId,
    required void Function(double valorDiaria) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/hotel/$hotelId/quartos/$quartoId',
      );
      final json = response.data!['data'] as Map<String, dynamic>;
      final raw = json['valor_diaria'];
      final valor = raw is num
          ? raw.toDouble()
          : double.tryParse(raw?.toString() ?? '') ?? 0.0;
      onSuccess(valor);
    } on DioException catch (e) {
      onError(_handleError(e, {404: 'Quarto não encontrado.'}));
    } catch (_) {
      onError('Erro inesperado ao buscar preço do quarto.');
    }
  }

  Future<void> fetchDisponibilidade({
    required String hotelId,
    required int categoriaId,
    required String dataCheckin,
    required String dataCheckout,
    required void Function(bool disponivel) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/hotel/$hotelId/disponibilidade',
        queryParameters: {
          'data_checkin': dataCheckin,
          'data_checkout': dataCheckout,
        },
      );
      final data = response.data!['data'] as List<dynamic>;
      final categoria = data.cast<Map<String, dynamic>>().firstWhere(
            (c) => c['id'] == categoriaId,
            orElse: () => {},
          );
      final disponivel =
          categoria.isNotEmpty ? (categoria['disponivel'] as bool? ?? false) : false;
      onSuccess(disponivel);
    } on DioException catch (e) {
      onError(_handleError(e, {}));
    } catch (_) {
      onError('Erro inesperado ao verificar disponibilidade.');
    }
  }

  Future<void> createReserva({
    required String hotelId,
    required int quartoId,
    required String tipoQuarto,
    required int numHospedes,
    required String dataCheckin,
    required String dataCheckout,
    required double valorTotal,
    HospedeInfoFormData? hospede,
    required void Function(ReservaModel) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final data = <String, dynamic>{
        'hotel_id':     hotelId,
        'quarto_id':    quartoId,
        'num_hospedes': numHospedes,
        'data_checkin': dataCheckin,
        'data_checkout': dataCheckout,
        'valor_total':  valorTotal,
      };
      if (hospede != null) {
        data['nome_hospede']     = hospede.nome;
        data['email_hospede']    = hospede.email;
        data['cpf_hospede']      = hospede.cpf;
        data['telefone_contato'] = hospede.telefone;
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/usuarios/reservas',
        data: data,
      );
      final json = response.data!['data'] as Map<String, dynamic>;
      onSuccess(ReservaModel.fromJson(json));
    } on DioException catch (e) {
      onError(_handleError(e, {
        400: 'Dados inválidos. Verifique os dados e tente novamente.',
        401: 'Sessão expirada. Faça login novamente.',
        409: 'Quarto indisponível nas datas selecionadas.',
      }));
    } catch (_) {
      onError('Erro inesperado ao criar reserva.');
    }
  }

  /// POST /api/reservas/guest — reserva sem JWT, com dados completos do hóspede.
  Future<void> createReservaGuest({
    required String hotelId,
    required int quartoId,
    required int categoriaId,
    required String tipoQuarto,
    required int numHospedes,
    required String dataCheckin,
    required String dataCheckout,
    required double valorTotal,
    required HospedeInfoFormData hospede,
    required void Function(ReservaModel) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/reservas/guest',
        data: {
          'hotel_id':        hotelId,
          'quarto_id':       quartoId,
          'categoria_id':    categoriaId,
          'tipo_quarto':     tipoQuarto,
          'num_hospedes':    numHospedes,
          'data_checkin':    dataCheckin,
          'data_checkout':   dataCheckout,
          'valor_total':     valorTotal,
          'nome_hospede':    hospede.nome,
          'email_hospede':   hospede.email,
          'cpf_hospede':     hospede.cpf,
          'telefone_contato': hospede.telefone,
        },
      );
      final json = response.data!['data'] as Map<String, dynamic>;
      onSuccess(ReservaModel.fromJson(json));
    } on DioException catch (e) {
      onError(_handleError(e, {
        400: 'Dados inválidos. Confira os campos e tente novamente.',
        409: 'Quarto indisponível nas datas selecionadas.',
        429: 'Muitas reservas em pouco tempo. Tente novamente em instantes.',
      }));
    } catch (_) {
      onError('Erro inesperado ao criar reserva.');
    }
  }

  /// POST /api/reservas/:codigo_publico/pagamentos — cria pagamento fake.
  Future<void> createPagamento({
    required String codigoPublico,
    String canal = 'APP',
    required void Function(PagamentoFakeModel) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/reservas/$codigoPublico/pagamentos',
        data: { 'canal': canal },
      );
      final json = response.data!['data'] as Map<String, dynamic>;
      onSuccess(PagamentoFakeModel.fromJson(json));
    } on DioException catch (e) {
      onError(_handleError(e, {
        404: 'Reserva não encontrada.',
        409: 'Já existe um pagamento em andamento para esta reserva.',
      }));
    } catch (_) {
      onError('Erro inesperado ao gerar pagamento.');
    }
  }

  /// GET /api/reservas/:codigo_publico/pagamentos/:id — polling de status.
  Future<void> fetchPagamento({
    required String codigoPublico,
    required int pagamentoId,
    required void Function(PagamentoFakeModel) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reservas/$codigoPublico/pagamentos/$pagamentoId',
      );
      final json = response.data!['data'] as Map<String, dynamic>;
      onSuccess(PagamentoFakeModel.fromJson(json));
    } on DioException catch (e) {
      onError(_handleError(e, { 404: 'Pagamento não encontrado.' }));
    } catch (_) {
      onError('Erro inesperado ao consultar pagamento.');
    }
  }

  /// POST /api/reservas/:codigo_publico/pagamentos/:id/confirmar — "paga" fake.
  Future<void> confirmarPagamento({
    required String codigoPublico,
    required int pagamentoId,
    required PaymentMethod metodo,
    required void Function(PagamentoFakeModel) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/reservas/$codigoPublico/pagamentos/$pagamentoId/confirmar',
        data: { 'forma_pagamento': metodo.apiValue },
      );
      final json = response.data!['data'] as Map<String, dynamic>;
      onSuccess(PagamentoFakeModel.fromJson(json));
    } on DioException catch (e) {
      onError(_handleError(e, {
        400: 'Forma de pagamento inválida.',
        409: 'Pagamento já processado.',
        410: 'Link de pagamento expirado.',
      }));
    } catch (_) {
      onError('Erro inesperado ao confirmar pagamento.');
    }
  }

  /// POST /api/reservas/:codigo_publico/pagamentos/:id/cancelar — cancela reserva.
  Future<void> cancelarPagamento({
    required String codigoPublico,
    required int pagamentoId,
    required void Function(PagamentoFakeModel) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/reservas/$codigoPublico/pagamentos/$pagamentoId/cancelar',
      );
      final json = response.data!['data'] as Map<String, dynamic>;
      onSuccess(PagamentoFakeModel.fromJson(json));
    } on DioException catch (e) {
      onError(_handleError(e, {
        400: 'Pagamento não está pendente.',
        404: 'Pagamento não encontrado.',
      }));
    } catch (_) {
      onError('Erro inesperado ao cancelar pagamento.');
    }
  }

  /// GET /api/reservas/:codigo_publico — ticket público (sem JWT).
  Future<void> fetchReservaPublica({
    required String codigoPublico,
    required void Function(Map<String, dynamic>) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/reservas/$codigoPublico');
      final json = response.data!['data'] as Map<String, dynamic>;
      onSuccess(json);
    } on DioException catch (e) {
      onError(_handleError(e, { 404: 'Reserva não encontrada.' }));
    } catch (_) {
      onError('Erro inesperado ao buscar reserva.');
    }
  }

  String _handleError(DioException e, Map<int, String> messages) {
    final status = e.response?.statusCode;
    if (status != null && messages.containsKey(status)) return messages[status]!;
    final body = e.response?.data;
    if (body is Map && body['error'] != null) return body['error'].toString();
    return 'Erro de conexão. Tente novamente.';
  }
}

final bookingServiceProvider = Provider<BookingService>(
  (ref) => BookingService(ref.read(dioProvider)),
);
