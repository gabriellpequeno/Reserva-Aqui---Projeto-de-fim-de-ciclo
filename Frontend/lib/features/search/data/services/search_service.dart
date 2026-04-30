import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/search_room_result.dart';

class SearchService {
  SearchService(this._dio);
  final Dio _dio;

  Future<List<SearchRoomResult>> searchRooms({
    required String q,
    String? checkin,
    String? checkout,
    int? hospedes,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (q.isNotEmpty) {
      queryParams['q'] = q;
    }
    if (checkin != null) queryParams['checkin'] = checkin;
    if (checkout != null) queryParams['checkout'] = checkout;
    if (hospedes != null) queryParams['hospedes'] = hospedes;

    final response = await _dio.get<List<dynamic>>(
      '/quartos/busca',
      queryParameters: queryParams,
    );

    final data = response.data ?? [];
    return data
        .map((e) => SearchRoomResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(ref.watch(dioProvider));
});
