import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../rooms/domain/models/room.dart';
import '../providers/landing_provider.dart';

class FeaturedRoomsSection extends ConsumerStatefulWidget {
  const FeaturedRoomsSection({super.key});

  @override
  ConsumerState<FeaturedRoomsSection> createState() =>
      _FeaturedRoomsSectionState();
}

class _FeaturedRoomsSectionState extends ConsumerState<FeaturedRoomsSection> {
  late final PageController _pageCtrl;
  Timer? _timer;
  int _page = 0;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    // viewportFraction 0.72 → central card takes 72%, adjacent peek ~14% each
    _pageCtrl = PageController(viewportFraction: 0.72);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_paused && mounted) _advance();
    });
  }

  void _advance() {
    if (!_pageCtrl.hasClients) return;
    final next = _page + 1;
    _pageCtrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _page = next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(featuredRoomsProvider);
    final tablet = isTablet(context);

    return Container(
      color: AppColors.bgSecondary,
      padding: EdgeInsets.only(
        top: tablet ? 72 : 48,
        bottom: tablet ? 72 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: 'Quartos em ',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              children: const [
                TextSpan(
                  text: 'Destaque',
                  style: TextStyle(color: AppColors.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecionados com base nas melhores avaliações dos hóspedes.',
            style: TextStyle(color: AppColors.greyText, fontSize: 14),
          ),
          const SizedBox(height: 32),
          roomsAsync.when(
            loading: () => _buildShimmer(),
            error: (_, __) => const _ErrorState(),
            data: (rooms) =>
                rooms.isEmpty ? const _EmptyState() : _buildCarousel(rooms),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(List<Room> rooms) {
    const bgColor = AppColors.bgSecondary;
    const fadeWidth = 90.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _paused = true),
      onExit: (_) => setState(() => _paused = false),
      child: Stack(
        children: [
          SizedBox(
            height: 400,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: 9999,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final room = rooms[index % rooms.length];
                final isCurrent = index == _page;
                return AnimatedScale(
                  scale: isCurrent ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: _CarouselCard(room: room),
                  ),
                );
              },
            ),
          ),

          // Left fade
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: fadeWidth,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [bgColor, Color(0x00F5F5F5)],
                  ),
                ),
              ),
            ),
          ),

          // Right fade
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: fadeWidth,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [bgColor, Color(0x00F5F5F5)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return SizedBox(
      height: 400,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.72),
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Carousel card — fills its parent item ──────────────────────

class _CarouselCard extends StatelessWidget {
  final Room room;
  const _CarouselCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final roomId = room.id.isNotEmpty ? room.id : '0';
        final hotelId = room.hotelId.isNotEmpty ? room.hotelId : '0';
        context.push('/room_details/$hotelId/$roomId');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          image: room.imageUrls.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(room.imageUrls.first),
                  fit: BoxFit.cover,
                )
              : null,
          color: AppColors.bgSecondary,
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.primary.withValues(alpha: 0.82),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
            // Info box
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            room.title.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              height: 1.25,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  size: 14, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                room.rating,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (room.amenities.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: room.amenities
                            .take(4)
                            .map((a) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Icon(a.icon,
                                      size: 18, color: AppColors.primary),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Não foi possível carregar os quartos em destaque.',
              style: TextStyle(color: AppColors.greyText),
              textAlign: TextAlign.center),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Nenhum quarto disponível no momento.',
              style: TextStyle(color: AppColors.greyText),
              textAlign: TextAlign.center),
        ),
      );
}
