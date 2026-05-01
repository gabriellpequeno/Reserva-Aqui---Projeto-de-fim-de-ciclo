import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/admin_accounts_service.dart';
import '../../domain/models/admin_account_status.dart';
import '../../domain/models/admin_hotel_model.dart';

/// Lista de hotéis para o painel admin.
///
/// Mesmo padrão do `adminUsersProvider`: atualização otimista + rollback
/// em caso de erro.
class AdminHotelsNotifier extends AsyncNotifier<List<AdminHotelModel>> {
  @override
  Future<List<AdminHotelModel>> build() async {
    return ref.read(adminAccountsServiceProvider).getHotels();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminAccountsServiceProvider).getHotels(),
    );
  }

  Future<void> updateStatus(String hotelId, AdminAccountStatus newStatus) async {
    await _withOptimistic(
      hotelId,
      (h) => h.copyWith(status: newStatus),
      () => ref.read(adminAccountsServiceProvider).updateHotelStatus(hotelId, newStatus),
    );
  }

  /// Edita dados não-sensíveis de um hotel. `patch` usa as chaves do backend
  /// (`nome_hotel`, `email`, `telefone`, `descricao`, `cep`, `uf`, `cidade`,
  /// `bairro`, `rua`, `numero`, `complemento`) — só as presentes são enviadas.
  Future<void> updateData(String hotelId, Map<String, dynamic> patch) async {
    await _withOptimistic(
      hotelId,
      (h) => h.copyWith(
        nome: patch['nome_hotel'] as String?,
        emailResponsavel: patch['email'] as String?,
        telefone: patch['telefone'] as String?,
        descricao: patch['descricao'] as String?,
        cep: patch['cep'] as String?,
        uf: patch['uf'] as String?,
        cidade: patch['cidade'] as String?,
        bairro: patch['bairro'] as String?,
        rua: patch['rua'] as String?,
        numero: patch['numero'] as String?,
        complemento: patch['complemento'] as String?,
      ),
      () => ref.read(adminAccountsServiceProvider).updateHotel(hotelId, patch),
    );
  }

  Future<void> _withOptimistic(
    String hotelId,
    AdminHotelModel Function(AdminHotelModel) apply,
    Future<AdminHotelModel> Function() remote,
  ) async {
    final current = state.value;
    if (current == null) return;

    final optimistic = current
        .map((h) => h.id == hotelId ? apply(h) : h)
        .toList();
    state = AsyncData(optimistic);

    try {
      final updated = await remote();
      final finalList = optimistic
          .map((h) => h.id == hotelId ? updated : h)
          .toList();
      state = AsyncData(finalList);
    } catch (err) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final adminHotelsProvider =
    AsyncNotifierProvider<AdminHotelsNotifier, List<AdminHotelModel>>(
  AdminHotelsNotifier.new,
);
