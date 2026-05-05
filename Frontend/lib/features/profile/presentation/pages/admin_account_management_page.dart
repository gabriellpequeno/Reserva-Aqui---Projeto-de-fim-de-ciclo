import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/admin_accounts_service.dart';
import '../../domain/models/admin_hotel_model.dart';
import '../../domain/models/admin_user_model.dart';
import '../providers/admin_hotels_provider.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/admin_edit_account_sheet.dart';
import '../widgets/admin_hotel_card.dart';
import '../widgets/admin_user_card.dart';

/// Tela de gerenciamento de contas pelo admin.
///
/// Layout inspirado em `my_rooms_page.dart`: header com busca no topo + abas
/// (Usuários / Hotéis) + lista de cards com status e ação de editar.
///
/// - Busca in-memory por nome/email, com debounce de 300ms;
///   termo persiste entre as abas (requisito #16 do PRD).
/// - Atualização de status é otimista (ver providers); se o PATCH falhar,
///   o estado original é restaurado e um SnackBar informa o erro.
class AdminAccountManagementPage extends ConsumerStatefulWidget {
  const AdminAccountManagementPage({super.key});

  @override
  ConsumerState<AdminAccountManagementPage> createState() =>
      _AdminAccountManagementPageState();
}

class _AdminAccountManagementPageState
    extends ConsumerState<AdminAccountManagementPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  bool _matchesUser(AdminUserModel u) {
    if (_query.isEmpty) return true;
    return u.nome.toLowerCase().contains(_query) ||
        u.email.toLowerCase().contains(_query);
  }

  bool _matchesHotel(AdminHotelModel h) {
    if (_query.isEmpty) return true;
    return h.nome.toLowerCase().contains(_query) ||
        h.emailResponsavel.toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildHotelsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(27),
          bottomRight: Radius.circular(27),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Semantics(
                  label: 'Voltar',
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/profile/admin'),
                  ),
                ),
              ),
              Column(
                children: [
                  SvgPicture.asset(
                    'lib/assets/icons/logo/logo.svg',
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    semanticsLabel: 'ReservaQui',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gerenciamento de Contas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Semantics(
              label: 'Pesquisar por nome ou e-mail',
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Pesquisar por nome ou e-mail...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  suffixIcon: const Icon(
                    Icons.search,
                    color: AppColors.secondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: AppColors.secondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        tabs: const [
          Tab(text: 'Usuários'),
          Tab(text: 'Hotéis'),
        ],
      ),
    );
  }

  // ── Users tab ─────────────────────────────────────────────────────────────

  Widget _buildUsersTab() {
    final asyncUsers = ref.watch(adminUsersProvider);

    return asyncUsers.when(
      loading: _buildLoading,
      error: (err, _) => _buildError(
        message: err.toString(),
        onRetry: () => ref.read(adminUsersProvider.notifier).refresh(),
      ),
      data: (users) {
        final filtered = users.where(_matchesUser).toList();
        if (users.isEmpty) {
          return _buildEmpty(
            icon: Icons.people_outline,
            title: 'Nenhum usuário cadastrado',
            subtitle: 'Aguarde o primeiro cadastro de hóspede.',
          );
        }
        if (filtered.isEmpty) {
          return _buildEmpty(
            icon: Icons.search_off,
            title: 'Nenhum resultado',
            subtitle: 'Tente outro termo de busca.',
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(adminUsersProvider.notifier).refresh(),
          color: AppColors.secondary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final user = filtered[i];
              return AdminUserCard(
                user: user,
                onEdit: () => _editUser(user),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _editUser(AdminUserModel user) async {
    final result = await AdminEditAccountSheet.showForUser(
      context: context,
      user: user,
    );
    if (result == null || result.isEmpty) return;

    final notifier = ref.read(adminUsersProvider.notifier);
    try {
      if (result.status != null) {
        await notifier.updateStatus(user.id, result.status!);
      }
      if (result.dataPatch != null) {
        await notifier.updateData(user.id, result.dataPatch!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Usuário atualizado.'),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageFor(err)),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  String _messageFor(Object err) {
    if (err is AdminDuplicateEmailException) {
      return 'Email já em uso por outra conta.';
    }
    return 'Não foi possível atualizar: $err';
  }

  // ── Hotels tab ────────────────────────────────────────────────────────────

  Widget _buildHotelsTab() {
    final asyncHotels = ref.watch(adminHotelsProvider);

    return asyncHotels.when(
      loading: _buildLoading,
      error: (err, _) => _buildError(
        message: err.toString(),
        onRetry: () => ref.read(adminHotelsProvider.notifier).refresh(),
      ),
      data: (hotels) {
        final filtered = hotels.where(_matchesHotel).toList();
        if (hotels.isEmpty) {
          return _buildEmpty(
            icon: Icons.hotel_outlined,
            title: 'Nenhum hotel cadastrado',
            subtitle: 'Aguarde o primeiro cadastro de hotel.',
          );
        }
        if (filtered.isEmpty) {
          return _buildEmpty(
            icon: Icons.search_off,
            title: 'Nenhum resultado',
            subtitle: 'Tente outro termo de busca.',
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(adminHotelsProvider.notifier).refresh(),
          color: AppColors.secondary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final hotel = filtered[i];
              return AdminHotelCard(
                hotel: hotel,
                onEdit: () => _editHotel(hotel),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _editHotel(AdminHotelModel hotel) async {
    final result = await AdminEditAccountSheet.showForHotel(
      context: context,
      hotel: hotel,
    );
    if (result == null || result.isEmpty) return;

    final notifier = ref.read(adminHotelsProvider.notifier);
    try {
      if (result.status != null) {
        await notifier.updateStatus(hotel.id, result.status!);
      }
      if (result.dataPatch != null) {
        await notifier.updateData(hotel.id, result.dataPatch!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hotel atualizado.'),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageFor(err)),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  // ── Shared states ─────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.secondary),
    );
  }

  Widget _buildError({required String message, required VoidCallback onRetry}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
