import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../notifiers/home_notifier.dart';
import '../notifiers/home_state.dart';
import '../widgets/room_card.dart';
import '../widgets/home_shimmer.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _desktopSearchController =
      TextEditingController();
  bool _hasLoadedRecommendations = false;
  bool _isFilterOpen = false;
  bool _introSeen = false;
  bool _prefLoaded = false;
  final Set<String> _selectedFilters = {};

  static const _introSeenKey = 'home_intro_seen';
  static const _filterOptions = [
    'Wi-Fi', 'Ar-condicionado', 'TV a cabo', 'Piscina', 'Academia',
    'Spa', 'Restaurante', 'Bar', 'Cama king-size', 'Cama queen-size',
    'Varanda', 'Banheira', 'Frigobar', 'Salão de eventos',
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_scrollListener);
    _loadIntroPref();
  }

  Future<void> _loadIntroPref() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_introSeenKey) ?? false;
    if (!mounted) return;
    setState(() {
      _introSeen = seen;
      _prefLoaded = true;
    });
    if (seen) {
      ref.read(navbarVisibleProvider.notifier).setVisible(true);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_scrollListener);
    _pageController.dispose();
    _searchController.dispose();
    _desktopSearchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedRecommendations) {
      _hasLoadedRecommendations = true;
      Future.microtask(() {
        ref.read(homeNotifierProvider.notifier).loadRecommended();
      });
    }
  }

  void _submitSearch(String query) {
    final trimmed = query.trim();
    if (_isFilterOpen) setState(() => _isFilterOpen = false);
    context.push('/search', extra: <String, dynamic>{
      'query': trimmed,
      'amenities': _selectedFilters.toList(),
    });
  }

  void _scrollListener() {
    if (_pageController.hasClients) {
      final double page = _pageController.page ?? 0;
      final bool isVisible = page > 0.3;
      if (ref.read(navbarVisibleProvider) != isVisible) {
        ref.read(navbarVisibleProvider.notifier).setVisible(isVisible);
      }
      if (!_introSeen && page > 0.8) {
        setState(() => _introSeen = true);
        SharedPreferences.getInstance().then(
          (prefs) => prefs.setBool(_introSeenKey, true),
        );
      }
    }
  }

  void _scrollToContent() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isDesktop(context)) {
      return _buildDesktopLanding();
    }

    final size = MediaQuery.of(context).size;
    final bool isWeb = size.width > 900;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String bgImage = isDark
        ? "lib/assets/images/home_dark.png"
        : "lib/assets/images/home_page.jpeg";

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            bgImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  "Erro ao carregar imagem",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),

        if (_prefLoaded) ...[
          if (_introSeen)
            _buildContentScreen(size, isWeb)
          else
            PageView(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              children: [
                _buildIntroScreen(size, isWeb),
                _buildContentScreen(size, isWeb),
              ],
            ),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DESKTOP — landing page
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildDesktopLanding() {
    final homeState = ref.watch(homeNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _DesktopHero(
            controller: _desktopSearchController,
            onSubmit: _submitSearch,
            onSecondaryTap: () => context.push('/search'),
          ),
          _DesktopRecommendedSection(
            state: homeState,
            onSeeAll: () => context.push('/search'),
          ),
          const _HowItWorksSection(),
          const _DesktopFooter(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MOBILE / TABLET — comportamento original
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildIntroScreen(Size size, bool isWeb) {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top + 104,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Column(
              children: [
                Text(
                  'SE VOCÊ QUER CONFORTO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 4.36,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -3),
                  child: SvgPicture.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? "lib/assets/icons/logo/logoDark.svg"
                        : "lib/assets/icons/logo/logo.svg",
                    width: 280,
                  ),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWeb) ...[
                const Text(
                  'BEM-VINDO AO RESERVA AQUI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 20),
              ]
            ],
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                'EXPLORAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isWeb ? 18 : 14,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: isWeb ? 60 : 40,
                ),
                onPressed: _scrollToContent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentScreen(Size size, bool isWeb) {
    final homeState = ref.watch(homeNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        children: [
          const SizedBox(height: 60),
          _buildSearchSection(),
          const SizedBox(height: 30),
          Text(
            'Quartos Recomendados',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (homeState.isLoading)
            const HomeShimmer()
          else if (homeState.rooms.isEmpty)
            _buildEmptyState()
          else
            _buildRoomCards(homeState),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRoomCards(HomeState homeState) {
    return SizedBox(
      height: 400,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeState.rooms.length,
        itemBuilder: (context, index) {
          final room = homeState.rooms[index];
          final roomId = room.id;
          final hotelId = room.hotelId;
          return RoomCard(
            roomId: roomId.isNotEmpty ? roomId : '0',
            hotelId: hotelId.isNotEmpty ? hotelId : '0',
            title: room.title,
            imageUrl: room.imageUrls.isNotEmpty ? room.imageUrls.first : '',
            rating: room.rating,
            amenities: room.amenities.map((a) => a.icon).toList(),
            price: room.price > 0 ? room.price : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Nenhum quarto disponível no momento',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final barRadius = _isFilterOpen
        ? const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          )
        : BorderRadius.circular(15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Descubra \nsua',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: ' estadia perfeita!',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: barRadius,
            border: Border.all(color: colorScheme.outline),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _submitSearch,
                  decoration: InputDecoration(
                    hintText: 'Para onde você vai?',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.tune,
                  color: _selectedFilters.isNotEmpty
                      ? AppColors.secondary
                      : colorScheme.primary,
                ),
                onPressed: () => setState(() => _isFilterOpen = !_isFilterOpen),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _isFilterOpen ? _buildFilterPanel() : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFilterPanel() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
        border: Border(
          left: BorderSide(color: colorScheme.outline),
          right: BorderSide(color: colorScheme.outline),
          bottom: BorderSide(color: colorScheme.outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            'Comodidades',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _filterOptions.map((option) {
              final isSelected = _selectedFilters.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedFilters.add(option);
                    } else {
                      _selectedFilters.remove(option);
                    }
                  });
                },
                selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                checkmarkColor: colorScheme.primary,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: colorScheme.surface,
                side: BorderSide(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
          if (_selectedFilters.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _selectedFilters.clear()),
              child: const Text(
                'Limpar filtros',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Desktop landing widgets
// ════════════════════════════════════════════════════════════════════════════

class _DesktopHero extends StatelessWidget {
  const _DesktopHero({
    required this.controller,
    required this.onSubmit,
    required this.onSecondaryTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final VoidCallback onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 56, 48, 80),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'RESERVAQUI',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Encontre seu hotel\n',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 56,
                                  height: 1.05,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                              const TextSpan(
                                text: 'perfeito.',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 56,
                                  height: 1.05,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                        _HeroSearchBar(
                          controller: controller,
                          onSubmit: onSubmit,
                        ),
                        const SizedBox(height: 20),
                        _HoverTextButton(
                          label: 'ou explore todos os destinos',
                          onTap: onSecondaryTap,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'lib/assets/images/landing_page.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSearchBar extends StatefulWidget {
  const _HeroSearchBar({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  State<_HeroSearchBar> createState() => _HeroSearchBarState();
}

class _HeroSearchBarState extends State<_HeroSearchBar> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hover
                ? AppColors.secondary.withValues(alpha: 0.6)
                : colorScheme.outline,
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            const SizedBox(width: 18),
            Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: widget.controller,
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.search,
                onSubmitted: widget.onSubmit,
                style:
                    TextStyle(color: colorScheme.onSurface, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Para onde você vai?',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
                onPressed: () => widget.onSubmit(widget.controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Buscar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverTextButton extends StatefulWidget {
  const _HoverTextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<_HoverTextButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration:
                    _hover ? TextDecoration.underline : TextDecoration.none,
                decorationColor: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward,
                color: AppColors.secondary, size: 16),
          ],
        ),
      ),
    );
  }
}

class _DesktopRecommendedSection extends StatelessWidget {
  const _DesktopRecommendedSection({
    required this.state,
    required this.onSeeAll,
  });

  final HomeState state;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 80, 48, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECOMENDADOS PARA VOCÊ',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Os quartos mais procurados da semana',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    _HoverTextButton(
                      label: 'Ver todos',
                      onTap: onSeeAll,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                if (state.isLoading)
                  const HomeShimmer()
                else if (state.rooms.isEmpty)
                  _emptyState(colorScheme)
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: state.rooms.length,
                    itemBuilder: (context, index) {
                      final room = state.rooms[index];
                      return RoomCard(
                        roomId: room.id.isNotEmpty ? room.id : '0',
                        hotelId: room.hotelId.isNotEmpty ? room.hotelId : '0',
                        title: room.title,
                        imageUrl: room.imageUrls.isNotEmpty
                            ? room.imageUrls.first
                            : '',
                        rating: room.rating,
                        amenities: room.amenities.map((a) => a.icon).toList(),
                        price: room.price > 0 ? room.price : null,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme colorScheme) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hotel, size: 48, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Nenhum quarto disponível no momento',
            style:
                TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final steps = const [
      _HowItWorksStep(
        index: '01',
        icon: Icons.search,
        title: 'Busque',
        body:
            'Encontre o quarto ideal pesquisando por destino, datas e comodidades.',
      ),
      _HowItWorksStep(
        index: '02',
        icon: Icons.event_available,
        title: 'Reserve',
        body:
            'Confirme em segundos. Pague depois pelo PIX, cartão ou boleto.',
      ),
      _HowItWorksStep(
        index: '03',
        icon: Icons.favorite,
        title: 'Aproveite',
        body:
            'Receba seu ticket digital e curta sua estadia sem complicação.',
      ),
    ];

    return Container(
      color: colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 80, 48, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMO FUNCIONA',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Três passos para a sua próxima viagem',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < steps.length; i++) ...[
                      Expanded(child: steps[i]),
                      if (i < steps.length - 1) const SizedBox(width: 32),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.index,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String index;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.secondary, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              index,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 15,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _DesktopFooter extends StatelessWidget {
  const _DesktopFooter();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: AppColors.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 48, 48, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            'lib/assets/icons/logo/logoDark.svg',
                            height: 32,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'A forma mais simples de reservar sua próxima estadia.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _footerColumn(context, 'Empresa', const [
                      ('Sobre', '/profile/about'),
                      ('Termos', '/profile/terms'),
                      ('Privacidade', '/profile/privacy'),
                    ])),
                    Expanded(
                        child:
                            _footerColumn(context, 'Conta', const [
                      ('Entrar', '/auth/login'),
                      ('Cadastrar', '/auth'),
                      ('Suporte', '/profile/support'),
                    ])),
                  ],
                ),
                const SizedBox(height: 40),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 20),
                Text(
                  '© ${DateTime.now().year} ReservAqui. Todos os direitos reservados.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerColumn(
      BuildContext context, String title, List<(String, String)> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HoverFooterLink(label: item.$1, route: item.$2),
          ),
      ],
    );
  }
}

class _HoverFooterLink extends StatefulWidget {
  const _HoverFooterLink({required this.label, required this.route});

  final String label;
  final String route;

  @override
  State<_HoverFooterLink> createState() => _HoverFooterLinkState();
}

class _HoverFooterLinkState extends State<_HoverFooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: Text(
          widget.label,
          style: TextStyle(
            color: _hover
                ? Colors.white
                : Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            decoration:
                _hover ? TextDecoration.underline : TextDecoration.none,
            decorationColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
