import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../layouts/main_layout.dart';
import '../utils/breakpoints.dart';
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
import '../../features/profile/presentation/pages/terms_page.dart';
import '../../features/profile/presentation/pages/privacy_page.dart';
import '../../features/profile/presentation/pages/about_page.dart';
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
import '../../features/bookings/presentation/pages/agendamentos_page.dart';
import '../../features/bookings/presentation/pages/agendamento_detail_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Page wrapper that uses fade transitions in desktop and the platform
/// default everywhere else. Avoids the slide-from-right that screams
/// "mobile portado" on web.
Page<dynamic> _adaptivePage(BuildContext context, GoRouterState state,
    Widget child) {
  if (Breakpoints.isDesktop(context)) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 120),
      reverseTransitionDuration: const Duration(milliseconds: 80),
      transitionsBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
  return MaterialPage<void>(key: state.pageKey, child: child);
}

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

      if (authAsync.isLoading) return null;

      final auth = authAsync.asData?.value;
      final isAuthenticated = auth?.isAuthenticated ?? false;
      final path = state.uri.path;

      if (path == '/') return '/home';

      final protectedRoutes = ['/profile', '/tickets', '/favorites'];
      final isProtected = protectedRoutes.any((r) => path.startsWith(r));

      if (!isAuthenticated && isProtected) return '/auth/login';

      final needsAdmin = path.startsWith('/admin/') ||
          path.startsWith('/profile/admin');
      if (needsAdmin) {
        if (!isAuthenticated) return '/auth/login';
        if (auth?.role != AuthRole.admin) return '/home';
      }

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
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return _adaptivePage(
                context,
                state,
                SearchPage(
                  initialQuery: extra['query'] as String?,
                  initialAmenities: (extra['amenities'] as List?)
                      ?.cast<String>()
                      .toSet(),
                ),
              );
            },
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) {
              final hotelId = state.uri.queryParameters['hotelId'];
              return _adaptivePage(
                  context, state, ChatPage(hotelId: hotelId));
            },
          ),
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const HomePage()),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const FavoritesPage()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const NotificationsPage()),
          ),
          GoRoute(
            path: '/tickets',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const TicketsPage()),
          ),
          GoRoute(
            path: '/auth',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const UserOrHostPage()),
            routes: [
              GoRoute(
                path: 'login',
                pageBuilder: (context, state) =>
                    _adaptivePage(context, state, const LoginPage()),
              ),
              GoRoute(
                path: 'signup/user',
                pageBuilder: (context, state) =>
                    _adaptivePage(context, state, const UserSignUpPage()),
              ),
              GoRoute(
                path: 'signup/host',
                pageBuilder: (context, state) =>
                    _adaptivePage(context, state, const HostSignUpPage()),
              ),
            ],
          ),
          GoRoute(
            path: '/profile/user',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const UserProfilePage()),
          ),
          GoRoute(
            path: '/profile/host',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const HostProfilePage()),
          ),
          GoRoute(
            path: '/profile/admin',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const AdminProfilePage()),
          ),
          GoRoute(
            path: '/profile/settings',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const SettingsPage()),
          ),
          GoRoute(
            path: '/profile/user/edit',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const EditUserProfilePage()),
          ),
          GoRoute(
            path: '/profile/host/edit',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const EditHostProfilePage()),
          ),
          GoRoute(
            path: '/profile/admin/edit',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const EditAdminProfilePage()),
          ),
          GoRoute(
            path: '/profile/terms',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const TermsPage()),
          ),
          GoRoute(
            path: '/profile/privacy',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const PrivacyPage()),
          ),
          GoRoute(
            path: '/profile/about',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const AboutPage()),
          ),
          GoRoute(
            path: '/room_details/:hotelId/:roomId',
            pageBuilder: (context, state) {
              final hotelId = state.pathParameters['hotelId'] ?? '';
              final roomId = state.pathParameters['roomId'] ?? '';
              return _adaptivePage(
                context,
                state,
                RoomDetailsPage(hotelId: hotelId, roomId: roomId),
              );
            },
          ),
          GoRoute(
            path: '/hotel_details/:hotelId',
            pageBuilder: (context, state) {
              final hotelId = state.pathParameters['hotelId'] ?? '';
              return _adaptivePage(
                  context, state, HotelDetailsPage(hotelId: hotelId));
            },
          ),
          GoRoute(
            path: '/add_room',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, AddRoomPage()),
          ),
          GoRoute(
            path: '/my_rooms',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, MyRoomsPage()),
          ),
          GoRoute(
            path: '/edit_room/:roomId',
            pageBuilder: (context, state) {
              final roomId = state.pathParameters['roomId'] ?? '';
              return _adaptivePage(
                  context, state, EditRoomPage(roomId: roomId));
            },
          ),
          GoRoute(
            path: '/tickets/details/:ticketId',
            pageBuilder: (context, state) {
              final ticketId = state.pathParameters['ticketId'] ?? '';
              return _adaptivePage(
                  context, state, TicketDetailsPage(ticketId: ticketId));
            },
          ),
          GoRoute(
            path: '/booking/checkout/:hotelId/:categoriaId/:quartoId',
            pageBuilder: (context, state) {
              final hotelId = state.pathParameters['hotelId'] ?? '';
              final categoriaId = int.tryParse(
                      state.pathParameters['categoriaId'] ?? '') ??
                  0;
              final quartoId =
                  int.tryParse(state.pathParameters['quartoId'] ?? '') ?? 0;
              final checkinRaw = state.uri.queryParameters['checkin'];
              final checkoutRaw = state.uri.queryParameters['checkout'];
              return _adaptivePage(
                context,
                state,
                CheckoutPage(
                  hotelId: hotelId,
                  categoriaId: categoriaId,
                  quartoId: quartoId,
                  initialCheckin: checkinRaw != null
                      ? DateTime.tryParse(checkinRaw)
                      : null,
                  initialCheckout: checkoutRaw != null
                      ? DateTime.tryParse(checkoutRaw)
                      : null,
                ),
              );
            },
          ),
          GoRoute(
            path: '/reservas/:codigoPublico',
            pageBuilder: (context, state) {
              final cp = state.pathParameters['codigoPublico'] ?? '';
              return _adaptivePage(
                  context, state, PublicTicketPage(codigoPublico: cp));
            },
          ),
          GoRoute(
            path: '/pagamento/:codigoPublico/:pagamentoId',
            pageBuilder: (context, state) {
              final cp = state.pathParameters['codigoPublico'] ?? '';
              final pid =
                  int.tryParse(state.pathParameters['pagamentoId'] ?? '') ?? 0;
              return _adaptivePage(
                context,
                state,
                WhatsappPaymentPage(codigoPublico: cp, pagamentoId: pid),
              );
            },
          ),
          GoRoute(
            path: '/booking/success',
            pageBuilder: (context, state) {
              final cp = state.uri.queryParameters['codigo'] ?? '';
              final mode = state.uri.queryParameters['mode'] ?? 'user';
              return _adaptivePage(
                context,
                state,
                ReservationSuccessPage(codigoPublico: cp, mode: mode),
              );
            },
          ),
          GoRoute(
            path: '/host/agendamentos',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const AgendamentosPage()),
          ),
          GoRoute(
            path: '/host/agendamentos/:reservaId',
            pageBuilder: (context, state) {
              final reservaId =
                  int.tryParse(state.pathParameters['reservaId'] ?? '') ?? 0;
              return _adaptivePage(
                context,
                state,
                AgendamentoDetailPage(reservaId: reservaId),
              );
            },
          ),
          GoRoute(
            path: '/host/dashboard',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const HostDashboardPage()),
          ),
          GoRoute(
            path: '/admin/dashboard',
            pageBuilder: (context, state) =>
                _adaptivePage(context, state, const AdminDashboardPage()),
          ),
          GoRoute(
            path: '/admin/accounts',
            pageBuilder: (context, state) => _adaptivePage(
                context, state, const AdminAccountManagementPage()),
          ),
        ],
      ),
    ],
  );
});
