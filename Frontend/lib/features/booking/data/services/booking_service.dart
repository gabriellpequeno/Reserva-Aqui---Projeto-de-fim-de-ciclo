import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/rooms/domain/models/hotel_details.dart';
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
    required void Function(ReservaModel) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/usuarios/reservas',
        data: {
          'hotel_id': hotelId,
          'quarto_id': quartoId,
          'num_hospedes': numHospedes,
          'data_checkin': dataCheckin,
          'data_checkout': dataCheckout,
          'valor_total': valorTotal,
        },
      );
      final json = response.data!['data'] as Map<String, dynamic>;
      onSuccess(ReservaModel.fromJson(json));
    } on DioException catch (e) {
      onError(_handleError(e, {
        400: 'Dados inválidos. Verifique as datas e tente novamente.',
        401: 'Sessão expirada. Faça login novamente.',
        409: 'Quarto indisponível nas datas selecionadas.',
      }));
    } catch (_) {
      onError('Erro inesperado ao criar reserva.');
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
