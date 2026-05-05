import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ui_providers.dart';
import '../utils/breakpoints.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/custom_app_bar.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../../features/landing/presentation/utils/auth_modals.dart';

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
        location.startsWith('/auth')) {
      return 4;
    }
    return 0;
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
        _openProfile(context, ref);
    }
  }

  void _openProfile(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider).asData?.value;
    if (isDesktop(context)) {
      if (auth?.isAuthenticated == true) {
        showProfileModalForRole(context, auth!.role ?? AuthRole.guest);
      } else {
        showLoginModal(context);
      }
    } else {
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
      } else {
        context.go('/auth/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.path;
    final currentIndex = _calculateSelectedIndex(location);
    final isNavbarVisible = ref.watch(navbarVisibleProvider);

    // After desktop login, the login modal sets this provider.
    // We detect it here and open the matching profile modal.
    ref.listen(postLoginProfileProvider, (_, role) {
      if (role == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ref.read(postLoginProfileProvider.notifier).clear();
          showProfileModalForRole(context, role);
        }
      });
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        final desktop = !isMobile;

        // On mobile, hide the app bar for content pages that have their own header.
        // On desktop, always show the app bar (it becomes the top nav).
        final bool hideAppBar = isMobile &&
            (location == '/' ||
                location == '/home' ||
                location == '/chat' ||
                location == '/favorites' ||
                location == '/notifications' ||
                location == '/search' ||
                location.startsWith('/tickets') ||
                location.startsWith('/room_details'));

        final bool hideBottomNav = location.startsWith('/room_details');

        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: desktop ? false : true,
          appBar: hideAppBar ? null : const CustomAppBar(),
          body: child,
          bottomNavigationBar: hideBottomNav
              ? null
              : isMobile
                  ? AnimatedSlide(
                      offset: (isNavbarVisible ||
                              hideAppBar &&
                                  location != '/home' &&
                                  location != '/')
                          ? Offset.zero
                          : const Offset(0, 1),
                      duration: const Duration(milliseconds: 300),
                      child: CustomBottomNavBar(
                        currentIndex: currentIndex,
                        onTap: (index) => _onItemTapped(index, context, ref),
                      ),
                    )
                  : null,
        );
      },
    );
  }
}
