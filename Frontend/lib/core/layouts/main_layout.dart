import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ui_providers.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/custom_app_bar.dart';
import '../mocks/mock_auth.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  // Ordem das abas: 0=buscar 1=curtidas 2=início(home) 3=mensagens 4=perfil
  int _calculateSelectedIndex(BuildContext context, String location) {
    if (location.startsWith('/search')) return 0;                        // buscar
    if (location == '/' || location.startsWith('/home')) return 2;       // início
    if (location.startsWith('/favorites')) return 1;                      // curtidas
    if (location.startsWith('/chat')) return 3;                           // mensagens/tickets
    if (location.startsWith('/admin') || location.startsWith('/host') ||
        location.startsWith('/profile') || location.startsWith('/auth')) return 4; // perfil
    return 0;
  }

  // Ação de clique de navegação
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/search'); // buscar
        break;
      case 1:
        context.go('/favorites'); // curtidas
        break;
      case 2:
        context.go('/home'); // início (home)
        break;
      case 3:
        context.go('/chat'); // mensagens/tickets
        break;
      case 4:
        if (MockAuth.isLoggedIn) {
          final role = MockAuth.currentUserRole;
          if (role == UserRole.admin) {
            context.go('/profile/admin');
          } else if (role == UserRole.host) {
            context.go('/profile/host');
          } else {
            context.go('/profile/user');
          }
        } else {
          context.go('/auth');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.path;
    final currentIndex = _calculateSelectedIndex(context, location);
    final isNavbarVisible = ref.watch(navbarVisibleProvider);
    final bool hideAppBar = location == '/' || location == '/home' || location == '/chat' || location == '/favorites' || location == '/notifications' || location == '/search' || location.startsWith('/room_details');
    final bool hideBottomNav = location.startsWith('/room_details');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: hideAppBar ? null : const CustomAppBar(),
          drawer: isMobile ? null : _buildDrawer(context),
          body: child,
          bottomNavigationBar: hideBottomNav ? null : (isMobile 
            ? AnimatedSlide(
                offset: (isNavbarVisible || hideAppBar && location != '/home' && location != '/') ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 300),
                child: CustomBottomNavBar(
                  currentIndex: currentIndex, 
                  onTap: (index) => _onItemTapped(index, context)
                ),
              ) 
            : null),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
              if (MockAuth.isLoggedIn) {
                final role = MockAuth.currentUserRole;
                if (role == UserRole.admin) {
                  context.go('/profile/admin');
                } else if (role == UserRole.host) {
                  context.go('/profile/host');
                } else {
                  context.go('/profile/user');
                }
              } else {
                context.go('/auth');
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

