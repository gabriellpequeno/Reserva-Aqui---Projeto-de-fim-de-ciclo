import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/admin_account_status.dart';
import '../../domain/models/admin_hotel_model.dart';
import '../../domain/models/admin_user_model.dart';

/// Exception usada quando o backend sinaliza 409 (email duplicado) nos
/// endpoints admin de update. Permite a UI exibir uma mensagem específica
/// sem inspecionar o status HTTP.
class AdminDuplicateEmailException implements Exception {
  const AdminDuplicateEmailException([
    this.message = 'Email já cadastrado em outra conta',
  ]);
  final String message;

  @override
  String toString() => message;
}

/// Service para operações admin sobre contas (usuários e hotéis).
///
/// Consome os endpoints `/admin/*`. Sem fallback mock: erros propagam como
/// exceções para a camada de provider converter em estado de erro na UI.
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
    return _patchUser(userId, {'status': status.toApiValue()});
  }

  /// Atualiza campos não-sensíveis de um usuário.
  /// `patch` deve conter apenas as chaves `nome_completo`, `email`, `numero_celular`.
  Future<AdminUserModel> updateUser(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    return _patchUser(userId, patch);
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
    return _patchHotel(hotelId, {'status': status.toApiValue()});
  }

  /// Atualiza campos não-sensíveis de um hotel.
  /// `patch` pode conter `nome_hotel`, `email`, `telefone`, `descricao`,
  /// `cep`, `uf`, `cidade`, `bairro`, `rua`, `numero`, `complemento`.
  Future<AdminHotelModel> updateHotel(
    String hotelId,
    Map<String, dynamic> patch,
  ) async {
    return _patchHotel(hotelId, patch);
  }

  // ── Internals ────────────────────────────────────────────────────────────

  Future<AdminUserModel> _patchUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/admin/users/$userId',
        data: data,
      );
      return AdminUserModel.fromJson(
        response.data!['user'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const AdminDuplicateEmailException();
      }
      rethrow;
    }
  }

  Future<AdminHotelModel> _patchHotel(
    String hotelId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/admin/hotels/$hotelId',
        data: data,
      );
      return AdminHotelModel.fromJson(
        response.data!['hotel'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const AdminDuplicateEmailException();
      }
      rethrow;
    }
  }
}

final adminAccountsServiceProvider = Provider<AdminAccountsService>((ref) {
  return AdminAccountsService(ref.watch(dioProvider));
});
