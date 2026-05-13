import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'user_avatar_widget.dart';

/// Hero card horizontal: avatar à esquerda, nome+email no meio, botões à direita.
/// Usado em user/host/admin profile pages no layout desktop.
class DesktopProfileHero extends StatelessWidget {
  const DesktopProfileHero({
    super.key,
    required this.name,
    required this.email,
    required this.onEdit,
    required this.onLogout,
    this.avatarUrl,
    this.subtitle,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final String? subtitle;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatarWidget(photoUrl: avatarUrl, name: name, size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          OutlinedHoverButton(
            label: 'Editar perfil',
            icon: Icons.edit_outlined,
            onTap: onEdit,
          ),
          const SizedBox(width: 12),
          OutlinedHoverButton(
            label: 'Sair',
            icon: Icons.logout,
            onTap: onLogout,
            destructive: true,
          ),
        ],
      ),
    );
  }
}

/// Eyebrow estilo "ATIVIDADE", "SISTEMA" — laranja, letter-spacing alto.
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
      ),
    );
  }
}

class DesktopActionItem {
  const DesktopActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

/// Wrap responsive de cards de ação (320px cada). Hover state e arrow indicator.
class DesktopActionGrid extends StatelessWidget {
  const DesktopActionGrid({super.key, required this.items});

  final List<DesktopActionItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items
          .map((item) => SizedBox(
                width: 320,
                child: _DesktopActionCard(item: item),
              ))
          .toList(),
    );
  }
}

class _DesktopActionCard extends StatefulWidget {
  const _DesktopActionCard({required this.item});

  final DesktopActionItem item;

  @override
  State<_DesktopActionCard> createState() => _DesktopActionCardState();
}

class _DesktopActionCardState extends State<_DesktopActionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: _hover
                ? colorScheme.surfaceContainerLow
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hover
                  ? AppColors.secondary.withValues(alpha: 0.5)
                  : colorScheme.outline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 20, color: AppColors.secondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: _hover
                    ? AppColors.secondary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão outlined com hover state — usado no hero card pra Editar/Sair.
class OutlinedHoverButton extends StatefulWidget {
  const OutlinedHoverButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  State<OutlinedHoverButton> createState() => _OutlinedHoverButtonState();
}

class _OutlinedHoverButtonState extends State<OutlinedHoverButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent =
        widget.destructive ? colorScheme.error : AppColors.secondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hover ? accent.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover ? accent : colorScheme.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: 16, color: _hover ? accent : colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: _hover ? accent : colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Container padrão de página de perfil em desktop — maxWidth 1100, padding 40/48.
class DesktopProfileScaffold extends StatelessWidget {
  const DesktopProfileScaffold({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 28, 40, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}
