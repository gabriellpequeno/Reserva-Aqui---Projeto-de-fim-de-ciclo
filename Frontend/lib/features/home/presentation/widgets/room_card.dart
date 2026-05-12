import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/smart_network_image.dart';
import 'package:go_router/go_router.dart';

class RoomCard extends StatelessWidget {
  final String roomId;
  final String hotelId;
  final String title;
  final String imageUrl;
  final String rating;
  final List<IconData> amenities;
  final double? price;
  final double? cardWidth;
  final double? cardHeight;
  final EdgeInsetsGeometry? cardMargin;
  final String? categoria;

  const RoomCard({
    super.key,
    required this.roomId,
    required this.hotelId,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.amenities,
    this.price,
    this.cardWidth,
    this.cardHeight,
    this.cardMargin,
    this.categoria,
  });

  String _formatRating(String raw) {
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) return raw;
    return parsed.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final width = cardWidth ?? 320.0;
    final margin = cardMargin ?? const EdgeInsets.only(right: 16);

    return GestureDetector(
      onTap: () => context.push('/room_details/$hotelId/$roomId'),
      child: Container(
        width: width,
        height: cardHeight,
        margin: margin,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SmartNetworkImage(
              url: imageUrl.isNotEmpty ? imageUrl : null,
              fallback: fallbackForHotel(hotelId),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // Gradient overlay
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
            // Info box na parte inferior
            Positioned(
              bottom: 20,
              left: 15,
              right: 15,
              child: Container(
                width: double.infinity,
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
                      title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.25,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: amenities.map((icon) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(icon, size: 18, color: AppColors.primary),
                            )).toList(),
                          ),
                        ),
                        if (double.tryParse(rating.replaceAll(',', '.')) != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 14, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  _formatRating(rating),
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
                    if (price != null && price! > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'R\$ ${price!.toStringAsFixed(2).replaceAll('.', ',')} / noite',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
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
