import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
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
    final bool isWeb = isDesktop(context);

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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
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
          const Text(
            'Quartos Recomendados',
            style: TextStyle(
              color: AppColors.primary,
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
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right, color: AppColors.primary, size: 30),
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
    if (isTablet(context)) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: homeState.rooms.length,
        itemBuilder: (context, index) => _buildRoomCardItem(homeState.rooms[index]),
      );
    }

    return SizedBox(
      height: 400,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeState.rooms.length,
        itemBuilder: (context, index) => _buildRoomCardItem(homeState.rooms[index]),
      ),
    );
  }

  Widget _buildRoomCardItem(dynamic room) {
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
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Nenhum quarto disponível no momento',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    // Ajusta o border radius da barra quando o dropdown está aberto para parecer conectado
    final barRadius = _isFilterOpen
        ? const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          )
        : BorderRadius.circular(15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Descubra \nsua',
                style: TextStyle(
                  color: AppColors.primary,
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
        // Barra de busca: toque no campo navega para search_page
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: barRadius,
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              // Campo de busca: digitável, submeter navega para search_page com query
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _submitSearch,
                  decoration: const InputDecoration(
                    hintText: 'Para onde você vai?',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColors.primary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              // Ícone de filtro: abre dropdown de comodidades sem sair da home
              IconButton(
                icon: Icon(
                  Icons.tune,
                  // Indica visualmente que há filtros ativos
                  color: _selectedFilters.isNotEmpty
                      ? AppColors.secondary
                      : AppColors.primary,
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

  // Painel de filtros com chips de seleção múltipla
  Widget _buildFilterPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
        border: const Border(
          left: BorderSide(color: Colors.black12),
          right: BorderSide(color: Colors.black12),
          bottom: BorderSide(color: Colors.black12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 8),
          const Text(
            'Comodidades',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
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
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: isSelected ? AppColors.primary : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.black12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
          if (_selectedFilters.isNotEmpty) ...[
            const SizedBox(height: 8),
            // Botão para limpar todos os filtros selecionados
            GestureDetector(
              onTap: () => setState(() => _selectedFilters.clear()),
              child: Text(
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
