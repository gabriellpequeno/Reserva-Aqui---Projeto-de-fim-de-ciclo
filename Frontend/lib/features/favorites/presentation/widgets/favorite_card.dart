import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/favorite_room.dart';
import '../providers/favorites_provider.dart';

class FavoriteCard extends ConsumerStatefulWidget {
  final FavoriteRoom room;

  const FavoriteCard({
    super.key,
    required this.room,
  });

  @override
  ConsumerState<FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends ConsumerState<FavoriteCard> with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  bool _isFavorite = true;

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

  void _handleToggleFavorite() {
    _heartController.forward(from: 0).then((_) {
      ref.read(favoritesProvider.notifier).removeFavorite(widget.room.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('fav_${widget.room.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        ref.read(favoritesProvider.notifier).removeFavorite(widget.room.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.room.title} removido dos favoritos'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                ref.read(favoritesProvider.notifier).toggleFavorite(widget.room);
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => context.push('/room_details/${widget.room.id}'),
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
                  child: Hero(
                    tag: 'room_img_${widget.room.id}',
                    child: Image.network(
                      widget.room.imageUrl,
                      width: 120,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
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
                                widget.room.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 'X' button
                            IconButton(
                              onPressed: () => ref.read(favoritesProvider.notifier).removeFavorite(widget.room.id),
                              icon: const Icon(Icons.cancel_outlined, size: 20, color: AppColors.greyText),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        Text(
                          widget.room.hotelName,
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppColors.greyText),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.room.destination,
                                style: const TextStyle(color: AppColors.greyText, fontSize: 11),
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
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  widget.room.rating,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            // Heart Animation Button
                            ScaleTransition(
                              scale: _heartScale,
                              child: IconButton(
                                onPressed: _handleToggleFavorite,
                                icon: Icon(
                                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: _isFavorite ? Colors.red : AppColors.greyText,
                                ),
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
                            onPressed: () => context.push('/room_details/${widget.room.id}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('VER MAIS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
}
