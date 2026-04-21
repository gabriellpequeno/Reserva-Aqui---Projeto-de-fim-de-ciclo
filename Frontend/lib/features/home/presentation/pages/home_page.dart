import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/room_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _pageController.removeListener(_scrollListener);
    _pageController.dispose();
    super.dispose();
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
              SizedBox(
                height: 400,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    RoomCard(
                      roomId: '1',
                      title: 'Copacabana Palace',
                      imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?q=80&w=2070',
                      rating: '5,0',
                      amenities: [Icons.wifi, Icons.ac_unit, Icons.pool],
                    ),
                    RoomCard(
                      roomId: '2',
                      title: 'Fasano Rio',
                      imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?q=80&w=2000',
                      rating: '4,9',
                      amenities: [Icons.wifi, Icons.restaurant, Icons.spa],
                    ),
                    RoomCard(
                      roomId: '3',
                      title: 'Hotel Unique SP',
                      imageUrl: 'https://images.unsplash.com/photo-1541971802814-ced3bbff94a5?q=80&w=2070',
                      rating: '4,8',
                      amenities: [Icons.wifi, Icons.pool, Icons.fitness_center],
                    ),
                    RoomCard(
                      roomId: '4',
                      title: 'Belmond Cataratas',
                      imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?q=80&w=2070',
                      rating: '5,0',
                      amenities: [Icons.wifi, Icons.nature, Icons.park],
                    ),
                  ],
                ),
              ),
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

  Widget _buildSearchSection() {
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
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black12),
            ),
            child: const TextField(
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'Para onde você vai?',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
      ],
    );
  }
}
