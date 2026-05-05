import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import 'landing_theme_bg.dart';

class AiAssistantSection extends StatefulWidget {
  const AiAssistantSection({super.key});

  @override
  State<AiAssistantSection> createState() => _AiAssistantSectionState();
}

class _AiAssistantSectionState extends State<AiAssistantSection>
    with TickerProviderStateMixin {
  static const _messages = [
    _Message('Olá! Preciso de um quarto em São Paulo para o fim de semana.', true),
    _Message('Encontrei 3 ótimas opções disponíveis para você! 🏨\nQuer que eu filtre por piscina ou academia?', false),
    _Message('Com piscina, por favor!', true),
    _Message('Perfeito! O Grand Palace Hotel tem piscina e está disponível por R\$ 280/noite. Posso fazer a reserva agora? ✅', false),
  ];

  late final List<AnimationController> _bubbleControllers;
  late final List<Animation<double>> _bubbleAnims;

  @override
  void initState() {
    super.initState();
    _bubbleControllers = List.generate(
      _messages.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      ),
    );
    _bubbleAnims = _bubbleControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutBack))
        .toList();

    for (int i = 0; i < _messages.length; i++) {
      Future.delayed(Duration(milliseconds: 600 + i * 1100), () {
        if (mounted) _bubbleControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _bubbleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);

    return LandingThemedBox(
      child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 32,
              vertical: tablet ? 72 : 48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: tablet
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _TextContent(context)),
                          const SizedBox(width: 48),
                          Expanded(
                            child: _MockupCard(
                              messages: _messages,
                              animations: _bubbleAnims,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TextContent(context),
                          const SizedBox(height: 32),
                          _MockupCard(
                            messages: _messages,
                            animations: _bubbleAnims,
                          ),
                        ],
                      ),
              ),
            ),
      ),
    );
  }
}

// ── Text content ───────────────────────────────────────────────

class _TextContent extends StatelessWidget {
  final BuildContext parentContext;
  const _TextContent(this.parentContext);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome,
                  color: AppColors.secondary, size: 14),
              const SizedBox(width: 6),
              const Text(
                'Assistente de IA',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Conheça o Bene,\nseu assistente no WhatsApp',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'O Bene é o assistente inteligente do Reserva Aqui. Pelo WhatsApp, ele responde dúvidas, busca quartos disponíveis e te ajuda a fazer reservas — tudo em linguagem natural, sem precisar abrir o app.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.access_time, color: AppColors.secondary, size: 14),
            const SizedBox(width: 6),
            Text(
              'Disponível 24h por dia, 7 dias por semana.',
              style: TextStyle(
                color: AppColors.secondary.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.hotel, color: AppColors.secondary, size: 14),
            const SizedBox(width: 6),
            Text(
              'Integrado com o inventário de hotéis em tempo real.',
              style: TextStyle(
                color: AppColors.secondary.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => parentContext.go('/chat'),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Conversar com o Bene'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ── Chat mockup ─────────────────────────────────────────────────

class _Message {
  final String text;
  final bool isUser;
  const _Message(this.text, this.isUser);
}

class _MockupCard extends StatelessWidget {
  final List<_Message> messages;
  final List<Animation<double>> animations;

  const _MockupCard({
    required this.messages,
    required this.animations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chat header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    const AssetImage('lib/assets/images/Bene.jpeg'),
                onBackgroundImageError: (_, __) {},
                backgroundColor: AppColors.secondary,
                child: Image.asset('lib/assets/images/Bene.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Text('B',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bene',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('Assistente Reserva Aqui',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 7),
                    SizedBox(width: 4),
                    Text('Online',
                        style:
                            TextStyle(color: Colors.green, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 8),
          // Animated chat bubbles
          ...messages.asMap().entries.map(
                (e) => ScaleTransition(
                  scale: animations[e.key],
                  alignment: e.value.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: FadeTransition(
                    opacity: animations[e.key],
                    child: _ChatBubble(e.value.text, isUser: e.value.isUser),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _ChatBubble(this.text, {required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.secondary.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, height: 1.4),
        ),
      ),
    );
  }
}
