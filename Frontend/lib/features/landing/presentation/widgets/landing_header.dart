import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/utils/breakpoints.dart';
import '../utils/auth_modals.dart';

class LandingHeader extends ConsumerWidget {
  final VoidCallback? onHomeTap;
  const LandingHeader({super.key, this.onHomeTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authValue = ref.watch(authProvider).asData?.value;
    final isAuth = authValue?.isAuthenticated ?? false;
    final desktop = isDesktop(context);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(top: 14, left: 24, right: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 940),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1B35),
                  Color(0xFF182541),
                  Color(0xFF1E3A5F),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Logo
                GestureDetector(
                  onTap: onHomeTap,
                  child: SvgPicture.asset(
                    'lib/assets/icons/logo/logoDark.svg',
                    height: 26,
                    colorFilter: const ColorFilter.mode(
                        Colors.white, BlendMode.srcIn),
                  ),
                ),
                const Spacer(),
                if (desktop)
                  _DesktopLinks(
                    isAuth: isAuth,
                    authRole: authValue?.role,
                    onHomeTap: onHomeTap,
                  )
                else
                  _HamburgerMenu(isAuth: isAuth, onHomeTap: onHomeTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Desktop nav links ──────────────────────────────────────────

class _DesktopLinks extends StatelessWidget {
  final bool isAuth;
  final AuthRole? authRole;
  final VoidCallback? onHomeTap;
  const _DesktopLinks({required this.isAuth, this.authRole, this.onHomeTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavLink('Home', onHomeTap ?? () {}),
        _NavLink('Busca', () => context.go('/search')),
        if (isAuth)
          _NavLink('Perfil', () => showProfileModalForRole(context, authRole ?? AuthRole.guest))
        else
          _NavLink('Entrar', () => showLoginModal(context)),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}

// ── Hamburger menu (mobile/tablet) ────────────────────────────

class _HamburgerMenu extends ConsumerWidget {
  final bool isAuth;
  final VoidCallback? onHomeTap;
  const _HamburgerMenu({required this.isAuth, this.onHomeTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.menu, color: Colors.white, size: 22),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () => _openMenu(context),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF182541),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _MenuItem(Icons.home_outlined, 'Home', () {
                Navigator.pop(ctx);
                if (onHomeTap != null) onHomeTap!();
              }),
              _MenuItem(Icons.search, 'Busca', () {
                Navigator.pop(ctx);
                context.go('/search');
              }),
              if (isAuth)
                _MenuItem(Icons.person_outline, 'Perfil', () {
                  Navigator.pop(ctx);
                  context.go('/profile/user');
                })
              else
                _MenuItem(Icons.login, 'Entrar', () {
                  Navigator.pop(ctx);
                  showLoginModal(context);
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: onTap,
    );
  }
}
