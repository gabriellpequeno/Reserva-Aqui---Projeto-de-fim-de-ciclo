import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mocks/mock_auth.dart';
import '../layouts/main_layout.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/user_signup_page.dart';
import '../../features/auth/presentation/pages/host_signup_page.dart';
import '../../features/auth/presentation/pages/user_or_host_page.dart';
import '../../features/profile/presentation/pages/user_profile_page.dart';
import '../../features/profile/presentation/pages/host_profile_page.dart';
import '../../features/profile/presentation/pages/admin_profile_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/rooms/presentation/pages/room_details_page.dart';

// O Navigator base
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final role = MockAuth.currentUserRole;
      final path = state.uri.path;

      if (path == '/') {
        if (role == UserRole.guest || role == UserRole.user) {
          return '/home';
        } else if (role == UserRole.host) {
          return '/host/dashboard';
        } else if (role == UserRole.admin) {
          return '/admin/dashboard';
        }
      }

      final isLogged = MockAuth.isLoggedIn;
      final protectedRoutes = ['/host', '/admin', '/profile'];
      final isProtected = protectedRoutes.any((r) => path.startsWith(r));

      if (!isLogged && isProtected) {
        return '/auth';
      }

      return null;
    },
    routes: [
      // Rotas com Casco (BottomNavBar / Drawer)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatPage(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesPage(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/auth',
            builder: (context, state) => const UserOrHostPage(),
            routes: [
              GoRoute(
                path: 'login',
                builder: (context, state) => const LoginPage(),
              ),
              GoRoute(
                path: 'signup/user',
                builder: (context, state) => const UserSignUpPage(),
              ),
              GoRoute(
                path: 'signup/host',
                builder: (context, state) => const HostSignUpPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile/user',
            builder: (context, state) => const UserProfilePage(),
          ),
          GoRoute(
            path: '/profile/host',
            builder: (context, state) => const HostProfilePage(),
          ),
          GoRoute(
            path: '/profile/admin',
            builder: (context, state) => const AdminProfilePage(),
          ),
        ],
      ),

      // ROTAS FORA DO CASCO (Sem Bottom Bar global) - Ex: Tela de Detalhes
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey, 
        path: '/room_details/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return RoomDetailsPage(roomId: roomId);
        },
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/host/dashboard',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Página: Host Dashboard (My Rooms)')),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/dashboard',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Página: Admin Dashboard')),
        ),
      ),
    ],
  );
});
