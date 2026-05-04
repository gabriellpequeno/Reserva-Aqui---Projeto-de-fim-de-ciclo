import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/ticket.dart';

class TicketsService {
  const TicketsService(this._dio);

  final Dio _dio;

  Future<void> fetchReservas({
    required void Function(List<Ticket>) onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/usuarios/reservas');
      final data = response.data!['data'] as List<dynamic>;
      final tickets = data
          .cast<Map<String, dynamic>>()
          .map(Ticket.fromJson)
          .toList();
      onSuccess(tickets);
    } on DioException catch (e) {
      onError(_handleError(e, {401: 'Sessão expirada. Faça login novamente.'}));
    } catch (_) {
      onError('Erro inesperado ao buscar reservas.');
    }
  }

  Future<String?> fetchFotoQuarto({
    required String hotelId,
    required int quartoId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/hotel/$hotelId/quartos/$quartoId/fotos',
      );
      final data = response.data!['data'];
      if (data is List && data.isNotEmpty) {
        final fotos = data.cast<Map<String, dynamic>>();
        fotos.sort((a, b) => (a['ordem'] as int? ?? 0).compareTo(b['ordem'] as int? ?? 0));
        return fotos.first['url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchReservaByCodigoPublico(String codigoPublico) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/reservas/$codigoPublico');
      return response.data!['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_handleError(e, {404: 'Reserva não encontrada.'}));
    }
  }

  Future<Map<String, dynamic>?> fetchCategoriaByNome(String hotelId, String tipoQuarto) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/$hotelId/categorias');
      final list = (response.data!['data'] as List).cast<Map<String, dynamic>>();
      final lower = tipoQuarto.toLowerCase();
      for (final c in list) {
        if ((c['nome'] as String? ?? '').toLowerCase() == lower) return c;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchConfiguracaoHotel(String hotelId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/$hotelId/configuracao');
      return response.data!['data'] as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelarReserva(String codigoPublico) async {
    try {
      await _dio.patch<void>('/usuarios/reservas/$codigoPublico/cancelar');
    } on DioException catch (e) {
      throw Exception(_handleError(e, {
        401: 'Sessão expirada. Faça login novamente.',
        403: 'Você não tem permissão para cancelar esta reserva.',
        404: 'Reserva não encontrada.',
      }));
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

final ticketsServiceProvider = Provider<TicketsService>(
  (ref) => TicketsService(ref.read(dioProvider)),
);
