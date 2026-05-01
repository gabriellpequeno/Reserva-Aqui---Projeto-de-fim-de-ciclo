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
    final current = state.value;
    if (current == null) return;

    final optimistic = current
        .map((h) => h.id == hotelId ? h.copyWith(status: newStatus) : h)
        .toList();
    state = AsyncData(optimistic);

    try {
      final updated = await ref
          .read(adminAccountsServiceProvider)
          .updateHotelStatus(hotelId, newStatus);

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
