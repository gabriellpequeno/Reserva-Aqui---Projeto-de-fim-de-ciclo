import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class RoomCard extends StatelessWidget {
  final String roomId;
  final String title;
  final String imageUrl;
  final String rating;
  final List<IconData> amenities;

  const RoomCard({
    super.key,
    required this.roomId,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.amenities,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/room_details/$roomId'),
      child: Container(
        width: 320,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 20,
              left: 15,
              right: 15,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Description Box
                  Container(
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
                        // Título e badge de nota em Row — texto colapsa antes do badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
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
                            ),
                            const SizedBox(width: 8),
                            // Badge de nota ao lado do título
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
                                    rating,
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
                        const SizedBox(height: 6),
                        Row(
                          children: amenities.map((icon) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(icon, size: 20, color: AppColors.primary),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
