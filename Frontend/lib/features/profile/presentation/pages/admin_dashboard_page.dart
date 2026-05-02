import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/models/dashboard/admin_dashboard_state.dart';
import '../providers/admin_dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/metric_card.dart';
import '../widgets/novos_cadastros_row.dart';
import '../widgets/period_selector.dart';
import '../widgets/reserva_status_breakdown.dart';
import '../widgets/top_hotel_tile.dart';

/// Dashboard agregado da plataforma (Admin).
///
/// Consome `adminDashboardProvider` e exibe métricas globais:
/// 4 MetricCard (usuários, hotéis, reservas hoje, receita),
/// Top 3 hotéis, breakdown de reservas por status e novos cadastros.
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(adminDashboardProvider);
    final notifier = ref.read(adminDashboardProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          DashboardHeader(
            title: 'Dashboard',
            onBack: () => context.canPop() ? context.pop() : context.go('/profile/admin'),
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

  Widget _buildBody(BuildContext context, AdminDashboardState data, AdminDashboardNotifier notifier) {
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
            if (data.melhorAvaliado != null) ...[
              _SectionTitle(title: 'Hotel mais bem avaliado'),
              const SizedBox(height: 12),
              _MelhorAvaliadoCard(hotel: data.melhorAvaliado!),
              const SizedBox(height: 24),
            ],
            _SectionTitle(title: 'Top hotéis'),
            const SizedBox(height: 12),
            _TopHoteisSection(topHoteis: data.topHoteis),
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
            const SizedBox(height: 24),
            _SectionTitle(title: 'Novos cadastros (últimos 7 dias)'),
            const SizedBox(height: 12),
            NovosCadastrosRow(novosCadastros: data.novosCadastros),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final AdminDashboardMetrics metrics;
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
              title: 'Total de usuários',
              value: _formatInt(metrics.totalUsuarios),
              icon: Icons.people_outline,
            ),
            MetricCard(
              title: 'Total de hotéis',
              value: _formatInt(metrics.totalHoteis),
              icon: Icons.apartment,
            ),
            MetricCard(
              title: 'Reservas hoje',
              value: _formatInt(metrics.reservasHoje),
              icon: Icons.event_available,
            ),
            MetricCard(
              title: 'Receita no período',
              value: _formatCurrency(metrics.receitaPeriodo),
              icon: Icons.attach_money,
            ),
            MetricCard(
              title: 'Receita média/hotel',
              value: _formatCurrency(metrics.receitaMediaHotel),
              icon: Icons.trending_up,
            ),
          ],
        );
      },
    );
  }
}

class _TopHoteisSection extends StatelessWidget {
  final List topHoteis;
  const _TopHoteisSection({required this.topHoteis});

  @override
  Widget build(BuildContext context) {
    if (topHoteis.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x3F182541)),
        ),
        child: const Text(
          'Sem hotéis com reservas ativas no período',
          style: TextStyle(color: AppColors.greyText, fontSize: 13),
        ),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < topHoteis.length; i++)
          TopHotelTile(position: i + 1, hotel: topHoteis[i]),
      ],
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

class _MelhorAvaliadoCard extends StatelessWidget {
  final MelhorAvaliadoModel hotel;
  const _MelhorAvaliadoCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0x3F182541)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppColors.secondary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel.nomeHotel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.secondary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      hotel.avaliacaoMedia.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· ${hotel.totalAvaliacoes} ${hotel.totalAvaliacoes == 1 ? "avaliação" : "avaliações"}',
                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

String _formatCurrency(double v) {
  final rounded = v.toStringAsFixed(2);
  final parts = rounded.split('.');
  final int intPart = int.parse(parts[0]);
  return 'R\$ ${_formatInt(intPart)},${parts[1]}';
}
