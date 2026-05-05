import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../widgets/chat_bubble.dart';
import '../providers/chat_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String? hotelId;
  /// Quando fornecido, o botão de voltar fecha o painel em vez de navegar.
  final VoidCallback? onClose;

  const ChatPage({super.key, this.hotelId, this.onClose});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasSetHotelId = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    // Set hotelId once
    if (!_hasSetHotelId) {
      ref.read(chatProvider.notifier).setHotelId(widget.hotelId);
      _hasSetHotelId = true;
    }

    final chatState = ref.watch(chatProvider);

    // Show error snackbar
    if (chatState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatState.error!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () => ref.read(chatProvider.notifier).clearError(),
            ),
          ),
        );
        ref.read(chatProvider.notifier).clearError();
      });
    }

    // Auto-scroll when messages change
    if (chatState.messages.isNotEmpty || chatState.isLoading) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: chatState.messages.isEmpty && !chatState.isLoading
                ? _buildEmptyState()
                : _buildMessageList(chatState),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Assistente ReservAqui',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Posso te ajudar a buscar hotéis, verificar disponibilidade, fazer reservas e tirar dúvidas.\n\nDigite uma mensagem para começar!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatState chatState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator
        if (index == chatState.messages.length && chatState.isLoading) {
          return _buildTypingIndicator();
        }

        final message = chatState.messages[index];

        // Group detection for bubble styling
        final isFirstInGroup = index == 0 ||
            chatState.messages[index - 1].isMe != message.isMe;
        final isLastInGroup = index == chatState.messages.length - 1 ||
            chatState.messages[index + 1].isMe != message.isMe;

        return ChatBubble(
          message: message.text,
          isMe: message.isMe,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.3,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.3 + (0.7 * ((1 + (value * 3.14 * 2).toInt() % 2) / 2)),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
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
              // Back Button (Circular) — hidden on desktop
              if (!isDesktop(context))
                GestureDetector(
                  onTap: widget.onClose ?? () => context.go('/home'),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                  ),
                )
              else
                const SizedBox(width: 48),
              
              // Logo
              SvgPicture.asset(
                'lib/assets/icons/logo/logoDark.svg',
                height: 32,
              ),
              
              // Spacer to balance layout
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 24),
          // Bot Info Row
          Row(
            children: [
              const SizedBox(width: 48),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assistente ReservAqui',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Online agora',
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
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: const InputDecoration(
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
                onPressed: _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
