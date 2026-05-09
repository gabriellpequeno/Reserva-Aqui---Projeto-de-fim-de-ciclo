import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String? name;
  final double size;
  final Uint8List? localImageBytes;

  const UserAvatarWidget({
    super.key,
    this.photoUrl,
    this.name,
    this.size = 96,
    this.localImageBytes,
  });

  String _initials() {
    if (name == null || name!.trim().isEmpty) return '';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String? _resolveUrl(String? url) {
    if (url == null) return null;
    if (url.startsWith('http')) return url;
    return '$backendHost$url';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _initials();
    final resolvedUrl = _resolveUrl(photoUrl);

    if (localImageBytes != null) {
      return ClipOval(
        child: Image.memory(
          localImageBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: resolvedUrl != null
            ? null
            : AppColors.secondary.withValues(alpha: 0.2),
        image: resolvedUrl != null
            ? DecorationImage(
                image: NetworkImage(resolvedUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: resolvedUrl != null
          ? null
          : Center(
              child: initials.isNotEmpty
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: size * 0.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: size * 0.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
    );
  }
}
