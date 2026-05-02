import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/dashboard_service.dart';
import '../../domain/models/dashboard/dashboard_period.dart';
import '../../domain/models/dashboard/host_dashboard_state.dart';

/// Estado do dashboard do Host.
///
/// Pareado com `DashboardPeriod` — trocar o período dispara refetch automático
/// via `setPeriod`. `refresh` força um novo fetch com o período atual.
class HostDashboardNotifier extends AsyncNotifier<HostDashboardState> {
  DashboardPeriod _period = DashboardPeriod.today;

  DashboardPeriod get period => _period;

  @override
  Future<HostDashboardState> build() async {
    return ref.read(dashboardServiceProvider).getHostDashboard(_period);
  }

  Future<void> setPeriod(DashboardPeriod newPeriod) async {
    if (newPeriod == _period) return;
    _period = newPeriod;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardServiceProvider).getHostDashboard(_period),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardServiceProvider).getHostDashboard(_period),
    );
  }
}

final hostDashboardProvider =
    AsyncNotifierProvider<HostDashboardNotifier, HostDashboardState>(
  HostDashboardNotifier.new,
);
