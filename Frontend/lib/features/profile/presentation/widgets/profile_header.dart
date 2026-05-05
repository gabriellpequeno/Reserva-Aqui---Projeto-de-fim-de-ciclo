import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'user_avatar_widget.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback onEditTap;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        UserAvatarWidget(photoUrl: avatarUrl, name: name),
        const SizedBox(height: 12),
        Text(
          name,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          email,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onEditTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.secondary),
            ),
            child: Text(
              'Editar perfil',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
