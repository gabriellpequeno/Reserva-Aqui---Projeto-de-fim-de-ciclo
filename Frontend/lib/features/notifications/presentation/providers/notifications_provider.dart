import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_notification.dart';

class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    // Mock data based on the prototype
    return [
      AppNotification(
        id: '1',
        title: 'Reserva Aprovada',
        subtitle: 'Grand Hotel Budapest',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: '2',
        title: 'Nova Mensagem',
        subtitle: 'Bo turista',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      AppNotification(
        id: '3',
        title: 'Reserva cancelada',
        subtitle: 'Copacabana Palace',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  void markAsRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  void clearAll() {
    state = [];
  }

  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<AppNotification>>(NotificationsNotifier.new);
