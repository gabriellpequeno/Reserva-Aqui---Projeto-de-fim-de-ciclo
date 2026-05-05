import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../layouts/main_layout.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/user_signup_page.dart';
import '../../features/auth/presentation/pages/host_signup_page.dart';
import '../../features/auth/presentation/pages/user_or_host_page.dart';
import '../../features/profile/presentation/pages/user_profile_page.dart';
import '../../features/profile/presentation/pages/host_profile_page.dart';
import '../../features/profile/presentation/pages/admin_profile_page.dart';
import '../../features/profile/presentation/pages/admin_account_management_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/edit_user_profile_page.dart';
import '../../features/profile/presentation/pages/edit_host_profile_page.dart';
import '../../features/profile/presentation/pages/edit_admin_profile_page.dart';
import '../../features/profile/presentation/pages/host_dashboard_page.dart';
import '../../features/profile/presentation/pages/admin_dashboard_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/rooms/presentation/pages/room_details_page.dart';
import '../../features/rooms/presentation/pages/hotel_details_page.dart';
import '../../features/rooms/presentation/pages/add_room_page.dart';
import '../../features/rooms/presentation/pages/my_rooms_page.dart';
import '../../features/rooms/presentation/pages/edit_room_page.dart';
import '../../features/booking/presentation/pages/checkout_page.dart';
import '../../features/booking/presentation/pages/public_ticket_page.dart';
import '../../features/booking/presentation/pages/reservation_success_page.dart';
import '../../features/booking/presentation/pages/whatsapp_payment_page.dart';
import '../../features/tickets/presentation/pages/tickets_page.dart';
import '../../features/tickets/presentation/pages/ticket_details_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Um Notifier que limpa o estado de reconstrução do RouterNotifier 
/// e permite que o GoRouter escute mudanças no authProvider.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authProvider);
      
      // Se ainda estiver carregando (estado inicial do storage), não tome decisões de roteamento.
      if (authAsync.isLoading) return null;

      final auth = authAsync.asData?.value;
      final isAuthenticated = auth?.isAuthenticated ?? false;
      final path = state.uri.path;

      if (path == '/') return '/home';

      final protectedRoutes = ['/profile', '/tickets', '/favorites'];
      final isProtected = protectedRoutes.any((r) => path.startsWith(r));

      if (!isAuthenticated && isProtected) return '/auth/login';

      // Rotas admin — exigem papel 'admin'. Autoridade real fica no backend
      // (adminGuard retorna 403 em /api/v1/admin/* para outros papéis); o guard
      // de frontend previne que usuários errados vejam a UI admin via deep-link.
      final needsAdmin = path.startsWith('/admin/') ||
          path.startsWith('/profile/admin');
      if (needsAdmin) {
        if (!isAuthenticated) return '/auth/login';
        if (auth?.role != AuthRole.admin) return '/home';
      }

      // Rotas host — exigem papel 'host'. Mesmo raciocínio: autoridade real é o
      // hotelGuard do backend (403 em /api/v1/host/*); esta camada é só UX.
      final needsHost = path.startsWith('/host/');
      if (needsHost) {
        if (!isAuthenticated) return '/auth/login';
        if (auth?.role != AuthRole.host) return '/home';
      }

      return null;
    },
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) {
              final hotelId = state.uri.queryParameters['hotelId'];
              return ChatPage(hotelId: hotelId);
            },
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
            path: '/tickets',
            builder: (context, state) => const TicketsPage(),
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
          GoRoute(
            path: '/profile/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/profile/user/edit',
            builder: (context, state) => const EditUserProfilePage(),
          ),
          GoRoute(
            path: '/profile/host/edit',
            builder: (context, state) => const EditHostProfilePage(),
          ),
          GoRoute(
            path: '/profile/admin/edit',
            builder: (context, state) => const EditAdminProfilePage(),
          ),
        ],
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/room_details/:hotelId/:roomId',
        builder: (context, state) {
          final hotelId = state.pathParameters['hotelId'] ?? '';
          final roomId = state.pathParameters['roomId'] ?? '';
          return RoomDetailsPage(hotelId: hotelId, roomId: roomId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/hotel_details/:hotelId',
        builder: (context, state) {
          final hotelId = state.pathParameters['hotelId'] ?? '';
          return HotelDetailsPage(hotelId: hotelId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/add_room',
        builder: (context, state) => AddRoomPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/my_rooms',
        builder: (context, state) => MyRoomsPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/edit_room/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return EditRoomPage(roomId: roomId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tickets/details/:ticketId',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId'] ?? '';
          return TicketDetailsPage(ticketId: ticketId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/booking/checkout/:hotelId/:categoriaId/:quartoId',
        builder: (context, state) {
          final hotelId = state.pathParameters['hotelId'] ?? '';
          final categoriaId = int.tryParse(state.pathParameters['categoriaId'] ?? '') ?? 0;
          final quartoId = int.tryParse(state.pathParameters['quartoId'] ?? '') ?? 0;
          final checkinRaw  = state.uri.queryParameters['checkin'];
          final checkoutRaw = state.uri.queryParameters['checkout'];
          return CheckoutPage(
            hotelId: hotelId,
            categoriaId: categoriaId,
            quartoId: quartoId,
            initialCheckin:  checkinRaw  != null ? DateTime.tryParse(checkinRaw)  : null,
            initialCheckout: checkoutRaw != null ? DateTime.tryParse(checkoutRaw) : null,
          );
        },
      ),
      // Rotas públicas do fluxo de reserva (nunca protegidas, fora do ShellRoute)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reservas/:codigoPublico',
        builder: (context, state) {
          final cp = state.pathParameters['codigoPublico'] ?? '';
          return PublicTicketPage(codigoPublico: cp);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/pagamento/:codigoPublico/:pagamentoId',
        builder: (context, state) {
          final cp = state.pathParameters['codigoPublico'] ?? '';
          final pid = int.tryParse(state.pathParameters['pagamentoId'] ?? '') ?? 0;
          return WhatsappPaymentPage(codigoPublico: cp, pagamentoId: pid);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/booking/success',
        builder: (context, state) {
          final cp = state.uri.queryParameters['codigo'] ?? '';
          final mode = state.uri.queryParameters['mode'] ?? 'user';
          return ReservationSuccessPage(codigoPublico: cp, mode: mode);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/host/dashboard',
        builder: (context, state) => const HostDashboardPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/accounts',
        builder: (context, state) => const AdminAccountManagementPage(),
      ),
    ],
  );
});
