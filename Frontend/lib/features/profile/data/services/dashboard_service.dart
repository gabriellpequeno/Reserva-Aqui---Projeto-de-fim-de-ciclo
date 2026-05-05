import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/dashboard/admin_dashboard_state.dart';
import '../../domain/models/dashboard/dashboard_period.dart';
import '../../domain/models/dashboard/host_dashboard_state.dart';

/// Service para os endpoints de dashboard.
///
/// Consome `GET /host/dashboard` (token de anfitrião via `hotelGuard` no
/// backend) e `GET /admin/dashboard` (token de admin via `adminGuard`).
/// Sem fallback mock — erros propagam como exceções para a camada de provider
/// converter em estado de erro na UI.
class DashboardService {
  const DashboardService(this._dio);

  final Dio _dio;

  Future<HostDashboardState> getHostDashboard(DashboardPeriod period) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/host/dashboard',
      queryParameters: {'period': period.toQueryValue()},
    );
    final data = (response.data!['data'] as Map).cast<String, dynamic>();
    return HostDashboardState.fromJson(data);
  }

  Future<AdminDashboardState> getAdminDashboard(DashboardPeriod period) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/dashboard',
      queryParameters: {'period': period.toQueryValue()},
    );
    final data = (response.data!['data'] as Map).cast<String, dynamic>();
    return AdminDashboardState.fromJson(data);
  }
}

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.watch(dioProvider));
});
