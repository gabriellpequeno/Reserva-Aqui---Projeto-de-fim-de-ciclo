import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/register_request.dart';
import '../models/register_host_request.dart';
import '../models/auth_response.dart';

class AuthService {
  AuthService(this._dio);
  final Dio _dio;

  Future<void> register(RegisterRequest request) async {
    await _dio.post<Map<String, dynamic>>(
      '/usuarios/register',
      data: request.toJson(),
    );
  }

  Future<AuthResponse> login(String email, String senha) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/usuarios/login',
      data: {'email': email, 'senha': senha},
    );
    return AuthResponse.fromJson(response.data!);
  }

  Future<void> registerHotel(Map<String, dynamic> hotelData) async {
    await _dio.post<Map<String, dynamic>>(
      '/hotel/register',
      data: hotelData,
    );
  }

  Future<AuthResponse> loginHotel(String email, String senha) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/hotel/login',
      data: {'email': email, 'senha': senha},
    );
    return AuthResponse.fromJson(response.data!);
  }

  Future<void> registerHotel(RegisterHostRequest request) async {
    await _dio.post(
      '/hotel/register',
      data: request.toJson(),
    );
  }

  Future<AuthResponse> loginHotel(String email, String senha) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/hotel/login',
      data: {'email': email, 'senha': senha},
    );
    return AuthResponse.fromJson(response.data!);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider));
});
