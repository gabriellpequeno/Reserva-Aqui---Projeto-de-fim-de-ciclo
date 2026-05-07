import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/tickets/data/services/tickets_service.dart';
import '../../../../features/tickets/domain/models/ticket.dart';

class AgendamentosNotifier extends AsyncNotifier<List<Ticket>> {
  TicketStatus? _statusFilter;
  DateTime? _dateFilter;

  @override
  Future<List<Ticket>> build() => _fetch();

  Future<List<Ticket>> _fetch() async {
    final service = ref.read(ticketsServiceProvider);
    List<Ticket> result = [];
    String? error;

    await service.fetchReservasHost(
      onSuccess: (list) => result = list,
      onError: (e) => error = e,
      status: _backendStatus(_statusFilter),
      dataCheckinFrom: _dateFilter != null ? _formatDate(_dateFilter!) : null,
      dataCheckinTo: _dateFilter != null ? _formatDate(_dateFilter!) : null,
    );

    if (error != null) throw Exception(error);
    return result;
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void setStatusFilter(TicketStatus? status) {
    _statusFilter = status;
    reload();
  }

  void setDateFilter(DateTime date) {
    _dateFilter = date;
    reload();
  }

  void clearDateFilter() {
    _dateFilter = null;
    reload();
  }

  DateTime? get activeDateFilter => _dateFilter;
  TicketStatus? get activeStatusFilter => _statusFilter;

  Future<String?> aprovarReserva(int reservaId) async {
    final service = ref.read(ticketsServiceProvider);
    String? err;
    await service.updateReservaStatus(
      reservaId: reservaId,
      novoStatus: 'APROVADA',
      onSuccess: () {},
      onError: (e) => err = e,
    );
    if (err == null) await reload();
    return err;
  }

  Future<String?> negarReserva(int reservaId) async {
    final service = ref.read(ticketsServiceProvider);
    String? err;
    await service.updateReservaStatus(
      reservaId: reservaId,
      novoStatus: 'CANCELADA',
      onSuccess: () {},
      onError: (e) => err = e,
    );
    if (err == null) await reload();
    return err;
  }

  static String? _backendStatus(TicketStatus? status) {
    if (status == null) return null;
    switch (status) {
      case TicketStatus.aguardo:
        return 'SOLICITADA';
      case TicketStatus.aprovado:
      case TicketStatus.hospedado:
        return 'APROVADA';
      case TicketStatus.cancelado:
        return 'CANCELADA';
      case TicketStatus.finalizado:
        return 'CONCLUIDA';
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final agendamentosNotifierProvider =
    AsyncNotifierProvider<AgendamentosNotifier, List<Ticket>>(
      AgendamentosNotifier.new,
    );
