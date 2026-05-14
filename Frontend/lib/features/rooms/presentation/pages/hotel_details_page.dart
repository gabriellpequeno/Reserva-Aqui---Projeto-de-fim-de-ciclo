import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/smart_network_image.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../favorites/presentation/widgets/favorite_dialogs.dart';
import '../../domain/models/hotel_details.dart';
import '../notifiers/hotel_details_notifier.dart';
import '../notifiers/hotel_details_state.dart';

class HotelDetailsPage extends ConsumerStatefulWidget {
  final String hotelId;

  const HotelDetailsPage({
    super.key,
    required this.hotelId,
  });

  @override
  ConsumerState<HotelDetailsPage> createState() => _HotelDetailsPageState();
}

class _HotelDetailsPageState extends ConsumerState<HotelDetailsPage> {
  late Set<int> _selectedCapacidades;

  @override
  void initState() {
    super.initState();
    _selectedCapacidades = {};
    Future.microtask(() {
      ref.read(hotelDetailsNotifierProvider.notifier).loadHotel(widget.hotelId);
    });
  }

  Future<void> _handleFavoriteTap() async {
    final isAuth =
        ref.read(authProvider).asData?.value.isAuthenticated ?? false;
    if (!isAuth) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Funcionalidade Exclusiva'),
          content: const Text(
              'Faça login para favoritar hotéis e acompanhar suas escolhas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () => context.push('/auth/login'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary),
              child: const Text('Fazer Login'),
            ),
          ],
        ),
      );
      return;
    }

    final isFav = ref
            .read(favoritesProvider)
            .value
            ?.any((h) => h.hotelId == widget.hotelId) ??
        false;

    if (isFav) {
      final confirmed = await showUnfavoriteConfirmationDialog(context);
      if (!confirmed || !mounted) return;
      await ref.read(favoritesProvider.notifier).removeFavorite(widget.hotelId);
      if (mounted) await showFavoriteRemovedDialog(context);
    } else {
      await ref.read(favoritesProvider.notifier).addFavorite(widget.hotelId);
      if (mounted) await showFavoriteAddedDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hotelDetailsNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isFavorited = ref.watch(favoritesProvider).value
            ?.any((h) => h.hotelId == widget.hotelId) ??
        false;

    final isDesktop = Breakpoints.isDesktop(context);

    return Scaffold(
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error,
                          size: 48, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        'Erro ao carregar detalhes do hotel',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(hotelDetailsNotifierProvider.notifier)
                            .loadHotel(widget.hotelId),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : isDesktop
                  ? _buildDesktopLayout(context, state, isFavorited)
                  : _buildMobileLayout(context, state, isFavorited),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DESKTOP — 2-col: imagem à esquerda, info à direita
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
      BuildContext context, HotelDetailsState state, bool isFavorited) {
    final colorScheme = Theme.of(context).colorScheme;
    final coverUrl =
        state.coverUrls.isNotEmpty ? state.coverUrls[0] : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 32, 48, 48),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // — Coluna esquerda: imagem + avatar —
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: SmartNetworkImage(
                              url: coverUrl,
                              fallback:
                                  fallbackForHotel(widget.hotelId),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Avatar sobreposto no canto inf-esquerdo
                        if (state.avatarUrl != null)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: colorScheme.surface, width: 3),
                              ),
                              child: ClipOval(
                                child: SmartNetworkImage(
                                  url: state.avatarUrl,
                                  fallback:
                                      fallbackForHotel(widget.hotelId),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Cover images extras
                    if (state.coverUrls.length > 1) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.coverUrls.length.clamp(0, 6),
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (ctx, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SmartNetworkImage(
                              url: state.coverUrls[i],
                              fallback: fallbackForHotel(widget.hotelId),
                              width: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // — Coluna direita: info —
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome + localização + favoritar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.nome ?? 'Hotel',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 15,
                                        color: colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${state.cidade ?? ''}, ${state.uf ?? ''}',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Botão favoritar
                          IconButton(
                            onPressed: _handleFavoriteTap,
                            icon: Icon(
                              isFavorited
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorited
                                  ? Colors.red
                                  : colorScheme.onSurfaceVariant,
                              size: 26,
                            ),
                            tooltip: isFavorited
                                ? 'Remover dos favoritos'
                                : 'Adicionar aos favoritos',
                          ),
                        ],
                      ),
                      // Rating
                      if (state.notaMedia > 0) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < state.notaMedia.toInt()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: AppColors.secondary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.notaMedia.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      Divider(height: 1, color: colorScheme.outline),
                      const SizedBox(height: 24),
                      // Descrição
                      _desktopSectionTitle('Sobre o hotel'),
                      const SizedBox(height: 10),
                      Text(
                        state.descricao ?? 'Sem descrição disponível',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      if (state.politicas != null) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showPoliticasModal(context, state.politicas!),
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Text(
                              'Ver políticas do hotel →',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (state.comodidades.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Divider(height: 1, color: colorScheme.outline),
                        const SizedBox(height: 24),
                        _desktopSectionTitle('Comodidades'),
                        const SizedBox(height: 14),
                        _buildComodidades(state.comodidades),
                      ],
                      const SizedBox(height: 28),
                      Divider(height: 1, color: colorScheme.outline),
                      const SizedBox(height: 24),
                      Text.rich(
                        TextSpan(
                          text: 'Quartos ',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Disponíveis',
                              style: TextStyle(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildBedFilter(state.categorias),
                      const SizedBox(height: 14),
                      _buildCategorias(
                          state.categorias, _selectedCapacidades),
                      if (state.avaliacoes.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Divider(height: 1, color: colorScheme.outline),
                        const SizedBox(height: 24),
                        _desktopSectionTitle('Avaliações'),
                        const SizedBox(height: 14),
                        _buildAvaliacoes(state.avaliacoes),
                      ],
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MOBILE — layout original com SliverAppBar
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
      BuildContext context, HotelDetailsState state, bool isFavorited) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, state, isFavorited),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: colorScheme.surface, width: 4),
                      ),
                      child: ClipOval(
                        child: SmartNetworkImage(
                          url: state.avatarUrl,
                          fallback: fallbackForHotel(widget.hotelId),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(state),
                        Divider(height: 48, color: colorScheme.outline),
                        Center(child: _buildSectionTitle('Descrição')),
                        const SizedBox(height: 12),
                        Text(
                          state.descricao ?? 'Sem descrição disponível',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        if (state.politicas != null) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: GestureDetector(
                              onTap: () => _showPoliticasModal(
                                  context, state.politicas!),
                              child: const Text(
                                'Ver políticas do hotel',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.secondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (state.comodidades.isNotEmpty) ...[
                          Divider(height: 48, color: colorScheme.outline),
                          _buildSectionTitle('Comodidades'),
                          const SizedBox(height: 16),
                          _buildComodidades(state.comodidades),
                        ],
                        Divider(height: 48, color: colorScheme.outline),
                        _buildRichSectionTitle('Quartos ', 'Disponíveis'),
                        const SizedBox(height: 16),
                        _buildBedFilter(state.categorias),
                        const SizedBox(height: 16),
                        _buildCategorias(
                            state.categorias, _selectedCapacidades),
                        Divider(height: 48, color: colorScheme.outline),
                        _buildSectionTitle('Avaliações'),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            state.notaMedia.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < state.notaMedia.toInt()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (state.avaliacoes.isNotEmpty)
                          _buildAvaliacoes(state.avaliacoes)
                        else
                          Center(
                            child: Text(
                              'Nenhuma avaliação ainda',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPoliticasModal(BuildContext context, PoliticasHotelModel politicas) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Políticas do Hotel',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildPoliticaRow('Check-in', politicas.horarioCheckin),
              _buildPoliticaRow('Check-out', politicas.horarioCheckout),
              if (politicas.politicaCancelamento != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Cancelamento',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  politicas.politicaCancelamento!,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, HotelDetailsState state, bool isFavorited) {
    final imageUrl = state.coverUrls.isNotEmpty ? state.coverUrls[0] : null;

    return SliverAppBar(
      expandedHeight: 260.0,
      pinned: false,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            SmartNetworkImage(
              url: imageUrl,
              fallback: fallbackForHotel(widget.hotelId),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 24, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: isFavorited ? Colors.red : Colors.white,
              ),
              onPressed: _handleFavoriteTap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(HotelDetailsState state) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          state.nome ?? 'Hotel',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: colorScheme.onSurfaceVariant, size: 16),
            const SizedBox(width: 4),
            Text(
              '${state.cidade ?? ''}, ${state.uf ?? ''}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRichSectionTitle(String primary, String secondary) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        text: primary,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: secondary,
            style: const TextStyle(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliticaRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForItem(String nome) {
    final n = nome.toLowerCase();
    if (n.contains('wi-fi') || n.contains('wifi') || n.contains('internet')) return Icons.wifi;
    if (n.contains('ar-condicionado') || n.contains('ar condicionado') || n.contains('ac')) return Icons.ac_unit;
    if (n.contains('tv') || n.contains('televisão') || n.contains('cabo')) return Icons.tv;
    if (n.contains('frigobar') || n.contains('geladeira') || n.contains('minibar')) return Icons.kitchen;
    if (n.contains('cofre')) return Icons.lock;
    if (n.contains('piscina')) return Icons.pool;
    if (n.contains('academia') || n.contains('gym') || n.contains('ginásio')) return Icons.fitness_center;
    if (n.contains('spa')) return Icons.spa;
    if (n.contains('restaurante') || n.contains('café da manhã') || n.contains('refeição')) return Icons.restaurant;
    if (n.contains('estacionamento') || n.contains('garagem')) return Icons.local_parking;
    if (n.contains('banheiro') || n.contains('ducha') || n.contains('chuveiro')) return Icons.shower;
    if (n.contains('varanda') || n.contains('sacada') || n.contains('terraço')) return Icons.balcony;
    if (n.contains('king')) return Icons.king_bed;
    if (n.contains('queen') || n.contains('casal')) return Icons.bed;
    if (n.contains('solteiro') || n.contains('single')) return Icons.single_bed;
    return Icons.check_circle_outline;
  }

  Widget _buildComodidades(List<ComodidadeHotelModel> comodidades) {
    final colorScheme = Theme.of(context).colorScheme;
    final itens = comodidades
        .where((c) => c.categoria != 'COMODO')
        .toList();

    if (itens.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: itens.map((com) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconForItem(com.nome), size: 14, color: colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(
                com.nome,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBedFilter(List<CategoriaHotelModel> categorias) {
    final colorScheme = Theme.of(context).colorScheme;
    final capacidades = <int>{};
    for (final cat in categorias) {
      capacidades.add(cat.capacidadePessoas);
    }
    final capacidadesSorted = capacidades.toList()..sort();

    if (capacidadesSorted.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: capacidadesSorted.map((cap) {
        final isSelected = _selectedCapacidades.contains(cap);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCapacidades.remove(cap);
              } else {
                _selectedCapacidades.add(cap);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondary : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.king_bed_outlined,
                  size: 20,
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  '$cap pessoa${cap > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
      ),
    );
  }

  Widget _buildCategorias(
    List<CategoriaHotelModel> categorias,
    Set<int> selectedCapacidades,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoriasFiltradas = selectedCapacidades.isEmpty
        ? categorias
        : categorias.where((c) => selectedCapacidades.contains(c.capacidadePessoas)).toList();

    if (categoriasFiltradas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Nenhum quarto disponível para o filtro selecionado',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: categoriasFiltradas.map((cat) {
        final itensVisiveis = cat.itens.where((i) => i.categoria != 'COMODO').toList();
        final podeNavegar = cat.primeiroQuartoId != null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: podeNavegar
                ? () => context.push(
                      '/room_details/${widget.hotelId}/${cat.primeiroQuartoId}',
                    )
                : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.nome,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Capacidade: ${cat.capacidadePessoas} pessoa${cat.capacidadePessoas > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'R\$ ${cat.preco.toStringAsFixed(0)}/dia',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (podeNavegar) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (itensVisiveis.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: itensVisiveis.map((item) {
                        return Chip(
                          avatar: Icon(
                            _iconForItem(item.nome),
                            size: 14,
                            color: colorScheme.onSurface,
                          ),
                          label: Text(
                            item.nome,
                            style: const TextStyle(fontSize: 11),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvaliacoes(List<AvaliacaoHotelModel> avaliacoes) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: avaliacoes.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Divider(height: 1, color: colorScheme.outline),
      ),
      itemBuilder: (context, index) {
        final review = avaliacoes[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.surfaceContainerHigh,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.nomeUsuario,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < review.notaTotal.toInt()
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.secondary,
                            size: 14,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Text(
                  review.timeAgo,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (review.comentario != null && review.comentario!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Text(
                  review.comentario!,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
