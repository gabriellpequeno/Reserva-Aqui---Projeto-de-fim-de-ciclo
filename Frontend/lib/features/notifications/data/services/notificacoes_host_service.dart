import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/app_notification.dart';

class NotificacoesHostService {
  NotificacoesHostService(this._dio);
  final Dio _dio;

  Future<List<AppNotification>> fetchAll() async {
    final response = await _dio.get<Map<String, dynamic>>('/hotel/notificacoes');
    final list = (response.data?['data'] as List<dynamic>?) ?? [];
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch<void>('/hotel/notificacoes/$id/lida');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch<void>('/hotel/notificacoes/lida-todas');
  }
}

final notificacoesHostServiceProvider = Provider<NotificacoesHostService>((ref) {
  return NotificacoesHostService(ref.watch(dioProvider));
});
