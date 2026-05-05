import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../utils/breakpoints.dart';
import '../../features/landing/presentation/utils/auth_modals.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, this.showBackButton = true});

  final bool showBackButton;

  static const double _mobileHeight = 100;
  static const double _desktopHeight = 72;

  void _openProfileOrLogin(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider).asData?.value;
    if (auth?.isAuthenticated == true) {
      showProfileModalForRole(context, auth!.role ?? AuthRole.guest);
    } else {
      showLoginModal(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool canPop = context.canPop();
    final String location = GoRouterState.of(context).uri.path;
    final bool isHome = location == '/' || location == '/home';
    final bool isProfile = location.startsWith('/profile');
    final bool desktop = isDesktop(context);

    if (desktop) {
      return _DesktopAppBar(
        onProfileTap: () => _openProfileOrLogin(context, ref),
        preferredHeight: _desktopHeight,
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: _mobileHeight,
      leading: (showBackButton && (!isHome || canPop))
          ? Padding(
              padding: const EdgeInsets.only(top: 30.0, left: 8.0),
              child: IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.primary,
                  size: 32,
                ),
                onPressed: () {
                  if (canPop) {
                    context.pop();
                  } else if (isProfile) {
                    context.go('/home');
                  } else {
                    final auth = ref.read(authProvider).asData?.value;
                    if (auth?.role == AuthRole.host) {
                      context.go('/profile/host');
                    } else {
                      context.go('/profile/user');
                    }
                  }
                },
              ),
            )
          : null,
      title: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: SvgPicture.asset('lib/assets/icons/logo/logo.svg', height: 32),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_mobileHeight);
}

class _DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onProfileTap;
  final double preferredHeight;

  const _DesktopAppBar({
    required this.onProfileTap,
    required this.preferredHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          children: [
            SvgPicture.asset('lib/assets/icons/logo/logo.svg', height: 28),
            const Spacer(),
            _ProfileButton(onTap: onProfileTap),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(preferredHeight);
}

class _ProfileButton extends ConsumerWidget {
  final VoidCallback onTap;
  const _ProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).asData?.value;
    final isAuth = auth?.isAuthenticated == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAuth ? Icons.person_rounded : Icons.login_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              isAuth ? 'Perfil' : 'Entrar',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
