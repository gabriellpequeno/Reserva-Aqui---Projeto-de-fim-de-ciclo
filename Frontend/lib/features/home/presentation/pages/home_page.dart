import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../notifiers/home_notifier.dart';
import '../notifiers/home_state.dart';
import '../widgets/room_card.dart';
import '../widgets/home_shimmer.dart';
import '../../../search/presentation/providers/search_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  bool _hasLoadedRecommendations = false;
  bool _isFilterOpen = false;
  final Set<String> _selectedFilters = {};

  static const _filterOptions = [
    'Wi-Fi', 'Piscina', 'Ar-condicionado',
    'Estacionamento', 'Restaurante', 'Spa', 'Fitness',
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _pageController.removeListener(_scrollListener);
    _pageController.dispose();
    _searchController.dispose();
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

  // Submete a busca: atualiza destination no provider e navega para search_page
  void _submitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      context.push('/search');
      return;
    }
    ref.read(searchProvider.notifier).updateDestination(trimmed);
    if (_isFilterOpen) setState(() => _isFilterOpen = false);
    context.push('/search');
  }

  void _scrollListener() {
    if (_pageController.hasClients) {
      final double page = _pageController.page ?? 0;
      final bool isVisible = page > 0.3; // Threshold to show navbar
      if (ref.read(navbarVisibleProvider) != isVisible) {
        ref.read(navbarVisibleProvider.notifier).setVisible(isVisible);
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
    final size = MediaQuery.of(context).size;
    final bool isWeb = size.width > 900;

    return Stack(
      children: [
        // Background Header Image 
        Positioned.fill(
          child: Image.asset(
            "lib/assets/images/home_page.jpeg",
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

        // Main vertical navigation
        PageView(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          children: [
            // Screen 1: Splash/Intro
            _buildIntroScreen(size, isWeb),

            // Screen 2: Main Content
            _buildContentScreen(size, isWeb),
          ],
        ),
      ],
    );
  }

  Widget _buildIntroScreen(Size size, bool isWeb) {
    return Stack(
      children: [
        // FIXED TEXT - Only visible here
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Column(
              children: [
                const Text(
                  'SE VOCÊ QUER CONFORTO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 4.34,
                  ),
                ),
                const SizedBox(height: 15),
                SvgPicture.asset(
                  "lib/assets/icons/logo/logo.svg",
                  width: 260, // Aumentado para coincidir com a largura do texto acima
                ),
              ],
            ),
          ),
        ),
        // Content Area for Intro
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
        // Chevron Button at bottom
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
          const SizedBox(height: 40),
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
          Stack(
            children: [
              if (homeState.isLoading)
                const HomeShimmer()
              else if (homeState.rooms.isEmpty)
                _buildEmptyState()
              else
                _buildRoomCards(homeState),
              Positioned(
                right: 0,
                top: 180,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chevron_right, color: colorScheme.primary, size: 30),
                  ),
                ),
              ),
            ],
          ),
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
        // Dropdown de filtros: abre abaixo da barra com mesma largura
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
                  debugPrint('[home] Filtros ativos: $_selectedFilters');
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
