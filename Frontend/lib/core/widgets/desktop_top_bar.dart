import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class DesktopTopBar extends StatelessWidget implements PreferredSizeWidget {
  const DesktopTopBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final void Function(int) onTap;

  static const double _height = 104;
  static const int _homeIndex = 2;

  static const _items = <_NavItem>[
    _NavItem(Icons.search, Icons.search, 'Buscar'),
    _NavItem(Icons.favorite_border, Icons.favorite, 'Curtidas'),
    _NavItem(Icons.home_outlined, Icons.home, 'Início'),
    _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Mensagens'),
    _NavItem(Icons.person_outline, Icons.person, 'Perfil'),
  ];

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _height,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.only(left: 28, right: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _Logo(onTap: () => onTap(_homeIndex)),
                    const Spacer(),
                    Row(
                      children: [
                        for (int i = 0; i < _items.length; i++) ...[
                          _DesktopNavItem(
                            item: _items[i],
                            selected: currentIndex == i,
                            onTap: () => onTap(i),
                          ),
                          if (i < _items.length - 1)
                            const SizedBox(width: 10),
                        ],
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: SvgPicture.asset(
          'lib/assets/icons/logo/logoDark.svg',
          height: 30,
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _DesktopNavItem extends StatefulWidget {
  const _DesktopNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_DesktopNavItem> createState() => _DesktopNavItemState();
}

class _DesktopNavItemState extends State<_DesktopNavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    final Color indicatorColor = selected
        ? AppColors.secondary
        : (_hover
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.transparent);

    final Color contentColor = selected
        ? AppColors.secondary
        : Colors.white.withValues(alpha: _hover ? 1.0 : 0.7);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: indicatorColor, width: 3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? widget.item.activeIcon : widget.item.icon,
                size: 19,
                color: contentColor,
              ),
              const SizedBox(width: 8),
              Text(
                widget.item.label,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                  fontFamily: 'Stack Sans Headline',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
