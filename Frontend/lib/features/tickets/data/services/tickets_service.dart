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
