import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ui_providers.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/custom_app_bar.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.path;
    final currentIndex = _calculateSelectedIndex(location);
    final isNavbarVisible = ref.watch(navbarVisibleProvider);
    final bool hideAppBar = location == '/' ||
        location == '/home' ||
        location == '/chat' ||
        location == '/favorites' ||
        location == '/notifications' ||
        location == '/search' ||
        location.startsWith('/room_details');
    final bool hideBottomNav = location.startsWith('/room_details');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: hideAppBar ? null : const CustomAppBar(),
          drawer: isMobile ? null : _buildDrawer(context, ref),
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

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Início'),
            onTap: () {
              context.go('/');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Buscar Quartos'),
            onTap: () {
              context.go('/home');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favoritos'),
            onTap: () {
              context.go('/favorites');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number),
            title: const Text('Meus Tickets'),
            onTap: () {
              context.go('/chat');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () {
              _navigateToProfile(context, ref);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
