import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ui_providers.dart';
import '../utils/breakpoints.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/desktop_top_bar.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../../features/auth/presentation/widgets/auth_dialogs.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key, required this.child});

  final Widget child;

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/search')) return 0;
    if (location == '/' || location.startsWith('/home')) return 2;
    if (location.startsWith('/favorites')) return 1;
    if (location.startsWith('/chat')) return 3;
    if (location.startsWith('/admin') ||
        location.startsWith('/host') ||
        location.startsWith('/profile') ||
        location.startsWith('/tickets') ||
        location.startsWith('/auth')) return 4;
    return 0;
  }

  void _navigateToProfile(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider).asData?.value;
    if (auth?.isAuthenticated == true) {
      switch (auth!.role) {
        case AuthRole.host:
          context.go('/profile/host');
        case AuthRole.admin:
          context.go('/profile/admin');
        case AuthRole.guest:
        case null:
          context.go('/profile/user');
      }
    } else if (Breakpoints.isDesktop(context)) {
      showLoginDialog(context);
    } else {
      context.go('/auth/login');
    }
  }

  void _onItemTapped(int index, BuildContext context, WidgetRef ref) {
    switch (index) {
      case 0:
        context.go('/search');
      case 1:
        context.go('/favorites');
      case 2:
        context.go('/home');
      case 3:
        context.go('/chat');
      case 4:
        _navigateToProfile(context, ref);
    }
  }

  bool _wasOutsideShellOriginally(String location) {
    return location.startsWith('/room_details') ||
        location.startsWith('/hotel_details') ||
        location == '/add_room' ||
        location == '/my_rooms' ||
        location.startsWith('/edit_room') ||
        location.startsWith('/tickets/details') ||
        location.startsWith('/booking/') ||
        location.startsWith('/reservas/') ||
        location.startsWith('/pagamento/') ||
        location == '/profile/terms' ||
        location == '/profile/privacy' ||
        location == '/profile/about' ||
        location.startsWith('/host/') ||
        location.startsWith('/admin/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.path;
    final currentIndex = _calculateSelectedIndex(location);
    final isNavbarVisible = ref.watch(navbarVisibleProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final bool isDesktop = w >= Breakpoints.desktop;
        final bool wasOutside = _wasOutsideShellOriginally(location);

        if (wasOutside) {
          if (!isDesktop) return child;

          return Scaffold(
            appBar: DesktopTopBar(
              currentIndex: currentIndex,
              onTap: (i) => _onItemTapped(i, context, ref),
            ),
            body: child,
          );
        }

        final bool isRoot = location == '/' ||
            location == '/home' ||
            location == '/chat' ||
            location == '/favorites' ||
            location == '/notifications' ||
            location == '/search' ||
            location.startsWith('/tickets') ||
            location.startsWith('/auth/login');
        final bool hideBottomNav = false;

        final PreferredSizeWidget? appBar = isDesktop
            ? DesktopTopBar(
                currentIndex: currentIndex,
                onTap: (i) => _onItemTapped(i, context, ref),
              )
            : (isRoot
                ? null
                : CustomAppBar(
                    fallbackRoute:
                        location.startsWith('/profile') ? '/home' : null,
                  ));

        final Widget? bottomNav = (isDesktop || hideBottomNav)
            ? null
            : AnimatedSlide(
                offset: (isNavbarVisible ||
                        (isRoot && location != '/home' && location != '/'))
                    ? Offset.zero
                    : const Offset(0, 1),
                duration: const Duration(milliseconds: 300),
                child: CustomBottomNavBar(
                  currentIndex: currentIndex,
                  onTap: (index) => _onItemTapped(index, context, ref),
                ),
              );

        return Scaffold(
          extendBody: !isDesktop,
          extendBodyBehindAppBar: !isDesktop,
          appBar: appBar,
          body: child,
          bottomNavigationBar: bottomNav,
        );
      },
    );
  }
}
