import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/smart_network_image.dart';
import '../../domain/models/favorite_hotel.dart';
import '../providers/favorites_provider.dart';
import 'favorite_dialogs.dart';

class FavoriteCard extends ConsumerStatefulWidget {
  final FavoriteHotel hotel;

  const FavoriteCard({
    super.key,
    required this.hotel,
  });

  @override
  ConsumerState<FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends ConsumerState<FavoriteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_heartController);
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  String? _buildCoverUrl() {
    if (widget.hotel.firstCoverFotoId == null) return null;
    final dio = ref.read(dioProvider);
    final baseUri = Uri.parse(dio.options.baseUrl);
    final serverRoot =
        '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
    return '$serverRoot/api/v1/uploads/hotels/${widget.hotel.hotelId}/cover/${widget.hotel.firstCoverFotoId}';
  }

  Future<void> _handleRemove() async {
    final confirmed = await showUnfavoriteConfirmationDialog(context);
    if (!confirmed) return;
    await ref
        .read(favoritesProvider.notifier)
        .removeFavorite(widget.hotel.hotelId);
    _heartController.forward(from: 0);
    if (mounted) await showFavoriteRemovedDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _buildCoverUrl();

    return GestureDetector(
      onTap: () => context.push('/hotel_details/${widget.hotel.hotelId}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Imagem de fundo ─────────────────────────────────────────
            SmartNetworkImage(
              url: coverUrl,
              fallback: fallbackForHotel(widget.hotel.hotelId),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // ── Gradiente (cópia exata do RoomCard) ──────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.primary.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            // ── Coração (top-right) ──────────────────────────────────────
            Positioned(
              top: 10,
              right: 10,
              child: ScaleTransition(
                scale: _heartScale,
                child: GestureDetector(
                  onTap: _handleRemove,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite,
                        color: Colors.red, size: 17),
                  ),
                ),
              ),
            ),
            // ── Info box (cópia do RoomCard) ─────────────────────────────
            Positioned(
              bottom: 16,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.hotel.nomeHotel.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        height: 1.25,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 13, color: AppColors.secondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${widget.hotel.bairro}, ${widget.hotel.cidade} — ${widget.hotel.uf}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push(
                            '/hotel_details/${widget.hotel.hotelId}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Ver mais'),
                      ),
                    ),
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
