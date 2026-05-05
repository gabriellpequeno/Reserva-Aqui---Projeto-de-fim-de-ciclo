import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class ChatFab extends StatelessWidget {
  const ChatFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.go('/chat'),
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.chat_bubble_outline),
      label: const Text(
        'Bene',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      tooltip: 'Conversar com o Bene',
    );
  }
}
