import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/dashboard_service.dart';
import '../../domain/models/dashboard/admin_dashboard_state.dart';
import '../../domain/models/dashboard/dashboard_period.dart';

/// Estado do dashboard global do Admin.
///
/// Pareado com `DashboardPeriod` — trocar o período dispara refetch automático
/// via `setPeriod`. `refresh` força um novo fetch com o período atual.
class AdminDashboardNotifier extends AsyncNotifier<AdminDashboardState> {
  DashboardPeriod _period = DashboardPeriod.today;

  DashboardPeriod get period => _period;

  @override
  Future<AdminDashboardState> build() async {
    return ref.read(dashboardServiceProvider).getAdminDashboard(_period);
  }

  Future<void> setPeriod(DashboardPeriod newPeriod) async {
    if (newPeriod == _period) return;
    _period = newPeriod;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardServiceProvider).getAdminDashboard(_period),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardServiceProvider).getAdminDashboard(_period),
    );
  }
}

final adminDashboardProvider =
    AsyncNotifierProvider<AdminDashboardNotifier, AdminDashboardState>(
  AdminDashboardNotifier.new,
);
