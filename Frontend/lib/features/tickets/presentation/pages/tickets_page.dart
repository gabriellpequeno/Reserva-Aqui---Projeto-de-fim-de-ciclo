import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/ticket.dart';
import '../widgets/ticket_card.dart';

class TicketsPage extends ConsumerStatefulWidget {
  const TicketsPage({super.key});

  @override
  ConsumerState<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends ConsumerState<TicketsPage> {
  final _searchController = TextEditingController();
  TicketStatus? _activeFilter; // null = Todos
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Ticket> get _filtered {
    return mockTickets.where((t) {
      final matchesFilter =
          _activeFilter == null || t.status == _activeFilter;

      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          t.hotelName.toLowerCase().contains(q) ||
          t.roomType.toLowerCase().contains(q) ||
          t.id.contains(q) ||
          TicketStatusTheme.of(t.status).label.toLowerCase().contains(q);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearchBar(),
          _buildFilterTabs(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(27),
          bottomRight: Radius.circular(27),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 8, 17, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _headerButton(
                    icon: Icons.chevron_left,
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/profile/user'),
                  ),
                  SvgPicture.asset(
                    'lib/assets/icons/logo/logoDark.svg',
                    height: 28,
                  ),
                  _headerButton(
                    icon: Icons.notifications_none,
                    onTap: () => context.go('/notifications'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Minhas Reservas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Stack Sans Headline',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45.79,
        height: 45.79,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.37),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.17),
            width: 0.62,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  // ── Barra de busca ────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E6E6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontFamily: 'Stack Sans Text',
                ),
                decoration: const InputDecoration(
                  hintText: 'Buscar reserva...',
                  hintStyle: TextStyle(
                    color: Color(0xFF828282),
                    fontSize: 14,
                    fontFamily: 'Stack Sans Text',
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            Icon(Icons.search, color: AppColors.secondary, size: 22),
          ],
        ),
      ),
    );
  }

  // ── Filtro de status ──────────────────────────────────────────────────────
  Widget _buildFilterTabs() {
    final tabs = [
      (null, 'Todos'),
      (TicketStatus.aguardo, 'Aguardo'),
      (TicketStatus.aprovado, 'Aprovado'),
      (TicketStatus.hospedado, 'Hospedado'),
      (TicketStatus.cancelado, 'Cancelado'),
      (TicketStatus.finalizado, 'Finalizado'),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: tabs.map((tab) {
            final isActive = _activeFilter == tab.$1;
            return GestureDetector(
              onTap: () => setState(() => _activeFilter = tab.$1),
              child: Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? AppColors.secondary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab.$2,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.secondary
                        : const Color(0xFF828282),
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
    );
  }

  // ── Lista de tickets ──────────────────────────────────────────────────────
  Widget _buildList() {
    final tickets = _filtered;

    if (tickets.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma reserva encontrada',
          style: TextStyle(
            color: Color(0xFF828282),
            fontSize: 14,
            fontFamily: 'Stack Sans Text',
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => TicketCard(ticket: tickets[i]),
    );
  }
}
