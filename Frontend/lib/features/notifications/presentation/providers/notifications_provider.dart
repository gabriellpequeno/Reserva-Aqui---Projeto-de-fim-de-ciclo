import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../data/services/guest_notifications_storage.dart';
import '../../data/services/notificacoes_host_service.dart';
import '../../domain/models/app_notification.dart';

class NotificationsNotifier
    extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final auth = await ref.watch(authProvider.future);
    if (!auth.isAuthenticated) return [];

    if (auth.role == AuthRole.host) {
      return ref.read(notificacoesHostServiceProvider).fetchAll();
    }
    return ref.read(guestNotificationsStorageProvider).load();
  }

  void addNotification(AppNotification notification) {
    final current = state.asData?.value ?? [];
    final updated = [notification, ...current];
    state = AsyncData(updated);
    _persistIfGuest(updated);
  }

  Future<void> markAsRead(String id) async {
    final current = state.asData?.value ?? [];
    final updated =
        current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    state = AsyncData(updated);

    final auth = ref.read(authProvider).asData?.value;
    if (auth?.role == AuthRole.host) {
      await ref.read(notificacoesHostServiceProvider).markAsRead(id);
    } else {
      _persistIfGuest(updated);
    }
  }

  Future<void> clearAll() async {
    state = const AsyncData([]);

    final auth = ref.read(authProvider).asData?.value;
    if (auth?.role == AuthRole.host) {
      await ref.read(notificacoesHostServiceProvider).markAllAsRead();
    } else {
      await ref.read(guestNotificationsStorageProvider).clear();
    }
  }

  void _persistIfGuest(List<AppNotification> notifications) {
    final auth = ref.read(authProvider).asData?.value;
    if (auth?.role != AuthRole.host) {
      ref.read(guestNotificationsStorageProvider).save(notifications);
    }
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (list) => list.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});
