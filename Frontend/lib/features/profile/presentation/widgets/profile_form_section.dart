import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileFormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ProfileFormSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.strokeLight),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
