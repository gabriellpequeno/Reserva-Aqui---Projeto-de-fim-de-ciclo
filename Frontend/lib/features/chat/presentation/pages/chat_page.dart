import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/chat_bubble.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom Chat Header
          _buildHeader(context),
          
          // Chat Messages
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Nov 30, 2023, 9:41 AM',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
                ChatBubble(
                  message: 'This is the main chat template',
                  isMe: true,
                ),
                ChatBubble(
                  message: 'Oh?',
                  isMe: false,
                  isLastInGroup: false,
                ),
                ChatBubble(
                  message: 'Cool',
                  isMe: false,
                  isFirstInGroup: false,
                  isLastInGroup: false,
                ),
                ChatBubble(
                  message: 'How does it work?',
                  isMe: false,
                  isFirstInGroup: false,
                ),
                ChatBubble(
                  message: 'You just edit any text to type in the conversation you want to show, and delete any bubbles you don’t want to use',
                  isMe: true,
                  isLastInGroup: false,
                ),
                ChatBubble(
                  message: 'Boom!',
                  isMe: true,
                  isFirstInGroup: false,
                ),
                ChatBubble(
                  message: 'Hmmm',
                  isMe: false,
                  isLastInGroup: false,
                ),
                ChatBubble(
                  message: 'I think I get it',
                  isMe: false,
                  isFirstInGroup: false,
                  isLastInGroup: false,
                ),
                ChatBubble(
                  message: 'Will head to the Help Center if I have more questions tho',
                  isMe: false,
                  isFirstInGroup: false,
                ),
              ],
            ),
          ),
          
          // Chat Input
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(27),
          bottomRight: Radius.circular(27),
        ),
      ),
      child: Column(
        children: [
          // Logo and Circular Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button (Circular)
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                ),
              ),
              
              // Logo
              SvgPicture.asset(
                'lib/assets/icons/logo/logoDark.svg',
                height: 32,
              ),
              
              // Notification/Bell Button (Circular)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // User Info Row
          Row(
            children: [
              const SizedBox(width: 48), // Align with the content above if needed
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFA3A3A3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bo Turista',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Ativo 11m atrás',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Mensagem...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: AppColors.secondary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
