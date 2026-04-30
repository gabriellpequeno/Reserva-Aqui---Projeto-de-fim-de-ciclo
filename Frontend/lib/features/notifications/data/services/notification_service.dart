import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/app_notification.dart';
import '../../presentation/providers/notifications_provider.dart';

// Runs in a separate isolate — cannot use Riverpod here.
// Host notifications are fetched on next app open; guest ones are handled inline.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService(this._ref);
  final Ref _ref;

  final _messaging = FirebaseMessaging.instance;

  // Returns the FCM token, or null if permission was denied or Firebase não configurado.
  Future<String?> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }

      FirebaseMessaging.onMessage.listen(_handleForeground);

      // VAPID key is required for Web — replace after `flutterfire configure`.
      if (kIsWeb) {
        return _messaging.getToken(
          vapidKey: 'REPLACE_WITH_YOUR_VAPID_KEY',
        );
      }
      return _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  void setupInteractionHandlers(GoRouter router) {
    // App opened from terminated state via notification tap.
    _messaging.getInitialMessage().then((message) {
      if (message != null) _navigateFromData(router, message.data);
    });

    // App in background, user taps notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateFromData(router, message.data);
    });
  }

  void _handleForeground(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    final appNotification = AppNotification(
      id: message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? _titleFromTipo(data['tipo'] ?? ''),
      subtitle: notification?.body ?? '',
      timestamp: DateTime.now(),
      tipo: data['tipo'] ?? '',
      payload: data,
    );

    _ref.read(notificationsProvider.notifier).addNotification(appNotification);
  }

  static void _navigateFromData(
    GoRouter router,
    Map<String, dynamic> data,
  ) {
    final tipo = data['tipo'] as String? ?? '';
    final codigoPublico = data['codigo_publico'] as String?;
    final checkoutUrl = data['checkout_url'] as String?;

    switch (tipo) {
      case 'APROVACAO_RESERVA':
      case 'PAGAMENTO_CONFIRMADO':
        if (checkoutUrl != null) {
          launchUrl(Uri.parse(checkoutUrl),
              mode: LaunchMode.externalApplication);
        } else if (codigoPublico != null) {
          router.push('/tickets/details/$codigoPublico');
        }
      case 'RESERVA_CANCELADA':
        if (codigoPublico != null) {
          router.push('/tickets/details/$codigoPublico');
        }
      case 'NOVA_RESERVA':
        router.push('/tickets');
      case 'MENSAGEM_CHAT':
        router.go('/chat');
    }
  }

  static String _titleFromTipo(String tipo) {
    return switch (tipo) {
      'NOVA_RESERVA' => 'Nova Reserva',
      'APROVACAO_RESERVA' => 'Reserva Aprovada',
      'PAGAMENTO_CONFIRMADO' => 'Pagamento Confirmado',
      'RESERVA_CANCELADA' => 'Reserva Cancelada',
      'MENSAGEM_CHAT' => 'Nova Mensagem',
      _ => 'Notificação',
    };
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
