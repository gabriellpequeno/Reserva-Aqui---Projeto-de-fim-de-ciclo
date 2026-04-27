import 'package:dio/dio.dart';
import '../dtos/search_room_result_dto.dart';

class SearchException implements Exception {
  final String message;
  final int? statusCode;

  SearchException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class SearchService {
  final Dio dio;

  SearchService({required this.dio});

  Future<List<SearchRoomResultDto>> searchRooms({
    required String q,
    DateTime? checkin,
    DateTime? checkout,
    int? hospedes,
    List<int>? amenidadeIds,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': q.trim(),
      };

      if (checkin != null && checkout != null) {
        queryParams['checkin'] = checkin.toIso8601String().split('T').first;
        queryParams['checkout'] = checkout.toIso8601String().split('T').first;
      }

      if (hospedes != null) {
        queryParams['hospedes'] = hospedes;
      }

      if (amenidadeIds != null && amenidadeIds.isNotEmpty) {
        queryParams['amenidades'] = amenidadeIds.join(',');
      }

      final response = await dio.get<List<dynamic>>(
        '/quartos/busca',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return (response.data as List<dynamic>)
            .map((item) => SearchRoomResultDto.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw SearchException('Resposta inesperada do servidor', statusCode: response.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorBody = e.response?.data as Map<String, dynamic>?;
        final errorMessage = errorBody?['error'] as String? ?? 'Parâmetro inválido';
        throw SearchException(errorMessage, statusCode: 400);
      } else if (e.response?.statusCode == 500) {
        throw SearchException('Erro interno do servidor', statusCode: 500);
      }
      throw SearchException('Erro ao buscar quartos: ${e.message}');
    } catch (e) {
      throw SearchException('Erro inesperado: $e');
    }
  }
}
