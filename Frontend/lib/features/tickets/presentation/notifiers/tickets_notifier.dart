import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../data/services/tickets_service.dart';
import '../../domain/models/ticket.dart';

// ── Notifier ──────────────────────────────────────────────────────────────────

class TicketsNotifier extends AsyncNotifier<List<Ticket>> {
  @override
  Future<List<Ticket>> build() async {
    final auth = await ref.watch(authProvider.future);
    if (!auth.isAuthenticated) return [];
    return _fetch(auth.role ?? AuthRole.guest);
  }

  Future<List<Ticket>> _fetch(AuthRole role) async {
    final service = ref.read(ticketsServiceProvider);
    List<Ticket> result = [];
    String? error;

    await service.fetchReservas(
      role: role,
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
    final auth = ref.read(authProvider).asData?.value;
    final role = auth?.role ?? AuthRole.guest;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(role));
  }

  /// Muda status de uma reserva (apenas para host). Recarrega a lista em sucesso.
  /// Retorna `null` em sucesso; mensagem de erro em falha.
  Future<String?> mudarStatusReserva(int reservaId, String novoStatus) async {
    final service = ref.read(ticketsServiceProvider);
    String? err;
    await service.updateReservaStatus(
      reservaId: reservaId,
      novoStatus: novoStatus,
      onSuccess: () {},
      onError: (e) => err = e,
    );
    if (err == null) await reload();
    return err;
  }

  /// Atalho: aprovar reserva (status → APROVADA).
  Future<String?> aprovarReserva(int reservaId) =>
      mudarStatusReserva(reservaId, 'APROVADA');

  /// Atalho: negar/cancelar reserva (status → CANCELADA).
  Future<String?> negarReserva(int reservaId) =>
      mudarStatusReserva(reservaId, 'CANCELADA');
  Future<void> cancelarReserva(String codigoPublico) async {
    await ref.read(ticketsServiceProvider).cancelarReserva(codigoPublico);
    state = state.whenData(
      (tickets) => tickets
          .map((t) => t.codigoPublico == codigoPublico ? t.copyWith(status: TicketStatus.cancelado) : t)
          .toList(),
    );
  }
}

final ticketsNotifierProvider =
    AsyncNotifierProvider<TicketsNotifier, List<Ticket>>(TicketsNotifier.new);
