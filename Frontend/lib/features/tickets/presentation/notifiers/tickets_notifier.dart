import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../data/services/tickets_service.dart';
import '../../domain/models/ticket.dart';

// ── Notifier ──────────────────────────────────────────────────────────────────

class TicketsNotifier extends AsyncNotifier<List<Ticket>> {
  @override
  Future<List<Ticket>> build() async {
    final auth = await ref.watch(authProvider.future);
    if (!auth.isAuthenticated) return [];
    return _fetch();
  }

  Future<List<Ticket>> _fetch() async {
    final service = ref.read(ticketsServiceProvider);
    List<Ticket> result = [];
    String? error;

    await service.fetchReservas(
      onSuccess: (list) => result = list,
      onError: (e) => error = e,
    );

    if (error != null) throw Exception(error);

    final enriched = await Future.wait(
      result.map((t) async {
        if (t.quartoId == null) return t;
        final url = await service.fetchFotoQuarto(
          hotelId: t.hotelId,
          quartoId: t.quartoId!,
        );
        return url != null ? t.copyWith(imageUrl: url) : t;
      }),
    );

    return enriched;
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final ticketsNotifierProvider =
    AsyncNotifierProvider<TicketsNotifier, List<Ticket>>(TicketsNotifier.new);
