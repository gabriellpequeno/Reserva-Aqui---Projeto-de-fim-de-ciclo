import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth/auth_notifier.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/widgets/auth_dialogs.dart';

class DesktopTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const DesktopTopBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final void Function(int) onTap;

  static const double _height = 96;
  static const int _homeIndex = 2;

  static const _labels = <String>[
    'Buscar',
    'Curtidas',
    'Início',
    'Mensagens',
    'Perfil',
  ];

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider).asData?.value;
    final isAuth = auth?.isAuthenticated ?? false;

    return Material(
      elevation: 0,
      color: colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: _height,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: _Logo(onTap: () => onTap(_homeIndex)),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < _labels.length; i++) ...[
                          _DesktopNavItem(
                            label: _labels[i],
                            selected: currentIndex == i,
                            onTap: () => onTap(i),
                            isFirst: i == 0,
                          ),
                          if (i < _labels.length - 1)
                            const SizedBox(width: 4),
                        ],
                        const Spacer(),
                        if (!isAuth)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LoginButton(
                              onTap: () => showLoginDialog(context),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'lib/assets/icons/logo/logoDark.svg'
        : 'lib/assets/icons/logo/logo.svg';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: SvgPicture.asset(asset, height: 28),
      ),
    );
  }
}

class _DesktopNavItem extends StatefulWidget {
  const _DesktopNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isFirst = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;

  @override
  State<_DesktopNavItem> createState() => _DesktopNavItemState();
}

class _DesktopNavItemState extends State<_DesktopNavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final colorScheme = Theme.of(context).colorScheme;

    final Color indicatorColor =
        selected ? AppColors.secondary : Colors.transparent;

    final Color textColor;
    if (selected) {
      textColor = AppColors.secondary;
    } else if (_hover) {
      textColor = colorScheme.onSurface;
    } else {
      textColor = colorScheme.onSurfaceVariant;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(widget.isFirst ? 0 : 16, 0, 16, 0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: indicatorColor, width: 2),
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.2,
              fontFamily: 'Stack Sans Headline',
              height: 2.4,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatefulWidget {
  const _LoginButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _hover ? AppColors.primary : AppColors.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Entrar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              fontFamily: 'Stack Sans Headline',
            ),
          ),
        ),
      ),
    );
  }
}
