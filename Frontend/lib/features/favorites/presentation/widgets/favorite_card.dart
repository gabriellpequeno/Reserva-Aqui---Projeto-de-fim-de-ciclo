import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/favorite_hotel.dart';
import '../providers/favorites_provider.dart';

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
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(_heartController);
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  String? _buildCoverUrl() {
    if (widget.hotel.coverStoragePath == null) return null;
    final dio = ref.read(dioProvider);
    final baseUri = Uri.parse(dio.options.baseUrl);
    final serverRoot =
        '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
    return '$serverRoot/api/uploads/hotels/${widget.hotel.hotelId}/cover';
  }

  void _handleRemove() {
    _heartController.forward(from: 0).then((_) {
      ref.read(favoritesProvider.notifier).removeFavorite(widget.hotel.hotelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _buildCoverUrl();

    return Dismissible(
      key: Key('fav_${widget.hotel.hotelId}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref
            .read(favoritesProvider.notifier)
            .removeFavorite(widget.hotel.hotelId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.hotel.nomeHotel} removido dos favoritos'),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => context.push('/hotel_details/${widget.hotel.hotelId}'),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Image Section
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: coverUrl != null
                      ? Image.network(
                          coverUrl,
                          width: 120,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                // Details Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.hotel.nomeHotel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref
                                  .read(favoritesProvider.notifier)
                                  .removeFavorite(widget.hotel.hotelId),
                              icon: const Icon(Icons.cancel_outlined,
                                  size: 20, color: AppColors.greyText),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 12, color: AppColors.greyText),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${widget.hotel.bairro}, ${widget.hotel.cidade} - ${widget.hotel.uf}',
                                style: const TextStyle(
                                    color: AppColors.greyText, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox.shrink(),
                            ScaleTransition(
                              scale: _heartScale,
                              child: IconButton(
                                onPressed: _handleRemove,
                                icon: const Icon(Icons.favorite,
                                    color: Colors.red),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => context
                                .push('/hotel_details/${widget.hotel.hotelId}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('VER MAIS',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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

  Widget _buildPlaceholder() {
    return Container(
      width: 120,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.hotel, color: AppColors.greyText, size: 36),
    );
  }
}
