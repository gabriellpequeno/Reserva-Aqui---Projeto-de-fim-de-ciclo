import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/models/dashboard/host_dashboard_state.dart';
import '../../domain/models/dashboard/next_checkin_model.dart';
import '../providers/host_dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/metric_card.dart';
import '../widgets/next_checkin_tile.dart';
import '../widgets/period_selector.dart';
import '../widgets/reserva_status_breakdown.dart';

/// Dashboard operacional do Host (anfitrião).
///
/// Consome `hostDashboardProvider` e exibe métricas do hotel autenticado:
/// 4 MetricCard (reservas hoje, ocupação, receita, avaliação média),
/// lista de próximos check-ins e breakdown de reservas por status.
class HostDashboardPage extends ConsumerWidget {
  const HostDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(hostDashboardProvider);
    final notifier = ref.read(hostDashboardProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          DashboardHeader(
            title: 'Dashboard',
            onBack: () => context.canPop() ? context.pop() : context.go('/profile/host'),
            onRefresh: notifier.refresh,
          ),
          const SizedBox(height: 12),
          PeriodSelector(
            selected: notifier.period,
            onChanged: notifier.setPeriod,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: asyncState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
              error: (err, _) => _buildError(context, err.toString(), notifier.refresh),
              data: (data) => _buildBody(context, data, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message, Future<void> Function() onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar o dashboard:\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            PrimaryButton(text: 'Tentar novamente', onPressed: onRetry),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HostDashboardState data, HostDashboardNotifier notifier) {
    return RefreshIndicator(
      color: AppColors.secondary,
      onRefresh: notifier.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsGrid(metrics: data.metrics),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Próximos check-ins'),
            const SizedBox(height: 12),
            _NextCheckinsSection(checkins: data.proximosCheckins),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Reservas por status'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0x3F182541)),
              ),
              child: ReservaStatusBreakdown(items: data.reservasPorStatus),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final HostDashboardMetrics metrics;
  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxis = _crossAxisFor(constraints.maxWidth);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxis,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: crossAxis == 1 ? 2.6 : 1.35,
          children: [
            MetricCard(
              title: 'Reservas hoje',
              value: _formatInt(metrics.reservasHoje),
              icon: Icons.event_available,
            ),
            MetricCard(
              title: 'Ocupação atual',
              value: _formatPercent(metrics.ocupacaoPercentual),
              icon: Icons.meeting_room,
            ),
            MetricCard(
              title: 'Receita no período',
              value: _formatCurrency(metrics.receitaPeriodo),
              icon: Icons.attach_money,
            ),
            MetricCard(
              title: 'Avaliação média',
              value: metrics.avaliacaoMedia == null
                  ? '—'
                  : '${metrics.avaliacaoMedia!.toStringAsFixed(1)} ★',
              icon: Icons.star_rate,
            ),
            MetricCard(
              title: 'Taxa de cancelamento',
              value: '${metrics.taxaCancelamento.toStringAsFixed(1)}%',
              icon: Icons.cancel_outlined,
            ),
            MetricCard(
              title: 'Estadia média',
              value: metrics.estadiaMediaDias == null
                  ? '—'
                  : '${metrics.estadiaMediaDias!.toStringAsFixed(1)} dias',
              icon: Icons.hotel_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _NextCheckinsSection extends StatelessWidget {
  final List<NextCheckinModel> checkins;
  const _NextCheckinsSection({required this.checkins});

  @override
  Widget build(BuildContext context) {
    if (checkins.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x3F182541)),
        ),
        child: const Text(
          'Sem check-ins próximos',
          style: TextStyle(color: AppColors.greyText, fontSize: 13),
        ),
      );
    }
    return Column(
      children: checkins.map((c) => NextCheckinTile(checkin: c)).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

int _crossAxisFor(double width) {
  if (width < 600) return 2;
  if (width < 900) return 2;
  if (width < 1200) return 3;
  return 4;
}

String _formatInt(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _formatPercent(double v) => '${v.toStringAsFixed(1)}%';

String _formatCurrency(double v) {
  final rounded = v.toStringAsFixed(2);
  final parts = rounded.split('.');
  final int intPart = int.parse(parts[0]);
  return 'R\$ ${_formatInt(intPart)},${parts[1]}';
}
