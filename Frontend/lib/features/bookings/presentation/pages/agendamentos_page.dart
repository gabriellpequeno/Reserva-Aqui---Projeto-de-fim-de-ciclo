import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../tickets/domain/models/ticket.dart';
import '../notifiers/agendamentos_notifier.dart';
import '../widgets/calendar_filter_widget.dart';

class AgendamentosPage extends ConsumerStatefulWidget {
  const AgendamentosPage({super.key});

  @override
  ConsumerState<AgendamentosPage> createState() => _AgendamentosPageState();
}

class _AgendamentosPageState extends ConsumerState<AgendamentosPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Ticket> _filtered(List<Ticket> tickets) {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return tickets;
    return tickets.where((t) {
      return (t.nomeHospede?.toLowerCase().contains(q) ?? false) ||
          t.id.contains(q) ||
          t.roomType.toLowerCase().contains(q);
    }).toList();
  }

  Set<DateTime> _datesWithReservas(List<Ticket> tickets) {
    return tickets.map((t) => DateTime(t.checkIn.year, t.checkIn.month, t.checkIn.day)).toSet();
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch registra a dependência de state — toda mudança de filtro chama
    // reload() que troca o estado, causando rebuild. activeDateFilter é lido
    // do notifier diretamente no rebuild, garantindo valor atualizado.
    final agendamentosAsync = ref.watch(agendamentosNotifierProvider);
    final notifier = ref.read(agendamentosNotifierProvider.notifier);
    final activeDate = notifier.activeDateFilter;

    final isDesktop = Breakpoints.isDesktop(context);
    return Scaffold(
      appBar: isDesktop
          ? null
          : const CustomAppBar(
              title: 'Agendamentos',
              showNotificationIcon: true,
              fallbackRoute: '/host/dashboard',
            ),
      body: Column(
        children: [
          Expanded(
            child: ResponsiveCenter(
              maxWidth: ContentMaxWidth.content,
              child: Column(
                children: [
                  _buildSearchAndCalendar(
                      context, agendamentosAsync, activeDate, notifier),
                  _buildFilterTabs(notifier),
                  if (activeDate != null)
                    _buildActiveDateChip(activeDate, notifier),
                  Expanded(
                    child: agendamentosAsync.when(
                      skipLoadingOnReload: true,
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          _buildErrorState(e.toString(), notifier),
                      data: (tickets) => RefreshIndicator(
                        onRefresh: notifier.reload,
                        child: _buildList(_filtered(tickets)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Barra de busca + botão calendário ──────────────────────────────────────
  Widget _buildSearchAndCalendar(
    BuildContext context,
    AsyncValue<List<Ticket>> agendamentosAsync,
    DateTime? activeDate,
    AgendamentosNotifier notifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final allTickets = agendamentosAsync.asData?.value ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontFamily: 'Stack Sans Text'),
                decoration: InputDecoration(
                  hintText: 'Buscar por hóspede ou código...',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontFamily: 'Stack Sans Text'),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => showCalendarFilter(
              context: context,
              datasComReserva: _datesWithReservas(allTickets),
              initialDate: activeDate,
              onDateSelected: (date) {
                if (date == null) {
                  notifier.clearDateFilter();
                } else {
                  notifier.setDateFilter(date);
                }
              },
            ),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: activeDate != null ? AppColors.primary : colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: activeDate != null ? AppColors.primary : colorScheme.outline,
                ),
              ),
              child: Icon(
                Icons.calendar_month,
                color: activeDate != null ? Colors.white : colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chips de filtro de status ───────────────────────────────────────────────
  Widget _buildFilterTabs(AgendamentosNotifier notifier) {
    final tabs = [
      (null, 'Todos'),
      (TicketStatus.aguardo, 'Aguardo'),
      (TicketStatus.aprovado, 'Em Andamento'),
      (TicketStatus.hospedado, 'Hospedado'),
      (TicketStatus.cancelado, 'Cancelado'),
      (TicketStatus.finalizado, 'Finalizado'),
    ];
    final currentFilter = notifier.activeStatusFilter;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.05, 0.95, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: tabs.map((tab) {
            final isActive = currentFilter == tab.$1;
            return GestureDetector(
              onTap: () => notifier.setStatusFilter(tab.$1),
              child: Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppColors.secondary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab.$2,
                  style: TextStyle(
                    color: isActive ? AppColors.secondary : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontFamily: 'Stack Sans Text',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Chip de data ativa ──────────────────────────────────────────────────────
  Widget _buildActiveDateChip(DateTime date, AgendamentosNotifier notifier) {
    final label = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontFamily: 'Stack Sans Text',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: notifier.clearDateFilter,
                  child: const Icon(Icons.close, size: 14, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Lista de agendamentos ───────────────────────────────────────────────────
  Widget _buildList(List<Ticket> tickets) {
    if (tickets.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              'Nenhum agendamento encontrado',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontFamily: 'Stack Sans Text',
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _AgendamentoCard(ticket: tickets[i]),
    );
  }

  Widget _buildErrorState(String message, AgendamentosNotifier notifier) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: notifier.reload,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card de agendamento (host) ────────────────────────────────────────────
class _AgendamentoCard extends StatelessWidget {
  const _AgendamentoCard({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = TicketStatusTheme.of(ticket.status);
    final nomeHospede = ticket.nomeHospede?.isNotEmpty == true
        ? ticket.nomeHospede!
        : 'Hóspede não identificado';

    return Column(
      children: [
        IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nomeHospede,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontFamily: 'Stack Sans Headline',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.badgeColor),
                        ),
                        child: Text(
                          theme.label,
                          style: TextStyle(
                            color: theme.badgeColor,
                            fontSize: 11,
                            fontFamily: 'Stack Sans Text',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (ticket.roomType.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      ticket.roomType,
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontFamily: 'Stack Sans Text',
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: theme.badgeColor),
                      const SizedBox(width: 6),
                      Text(
                        ticket.dateRange,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontFamily: 'Stack Sans Text',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.person_outline, size: 14, color: theme.badgeColor),
                      const SizedBox(width: 4),
                      Text(
                        '${ticket.guestCount}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontFamily: 'Stack Sans Text',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (ticket.id.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            height: 38,
            child: ElevatedButton(
              onPressed: () => context.push('/host/agendamentos/${ticket.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              child: const Text(
                'Detalhes',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Stack Sans Headline',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
