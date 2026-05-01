import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/admin_account_status.dart';
import '../../domain/models/admin_hotel_model.dart';
import '../../domain/models/admin_user_model.dart';

/// Service para operações admin sobre contas (usuários e hotéis).
///
/// Consome os endpoints `/admin/*` entregues pela Fase 1 do backend.
/// Sem fallback mock: erros propagam como exceções para a camada de provider
/// converter em estado de erro na UI.
class AdminAccountsService {
  const AdminAccountsService(this._dio);

  final Dio _dio;

  Future<List<AdminUserModel>> getUsers({int? limit, int? offset}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/users',
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );
    final users = (response.data!['users'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return users.map(AdminUserModel.fromJson).toList();
  }

  Future<AdminUserModel> updateUserStatus(
    String userId,
    AdminAccountStatus status,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admin/users/$userId',
      data: {'status': status.toApiValue()},
    );
    return AdminUserModel.fromJson(
      response.data!['user'] as Map<String, dynamic>,
    );
  }

  Future<List<AdminHotelModel>> getHotels({int? limit, int? offset}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/hotels',
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );
    final hotels = (response.data!['hotels'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return hotels.map(AdminHotelModel.fromJson).toList();
  }

  Future<AdminHotelModel> updateHotelStatus(
    String hotelId,
    AdminAccountStatus status,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admin/hotels/$hotelId',
      data: {'status': status.toApiValue()},
    );
    return AdminHotelModel.fromJson(
      response.data!['hotel'] as Map<String, dynamic>,
    );
  }
}

final adminAccountsServiceProvider = Provider<AdminAccountsService>((ref) {
  return AdminAccountsService(ref.watch(dioProvider));
});
