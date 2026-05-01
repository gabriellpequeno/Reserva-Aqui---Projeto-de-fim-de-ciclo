import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/admin_accounts_service.dart';
import '../../domain/models/admin_account_status.dart';
import '../../domain/models/admin_user_model.dart';

/// Lista de usuários (hóspedes) para o painel admin.
///
/// `updateStatus` aplica atualização otimista: o chip troca imediatamente,
/// e se o `PATCH` falhar, o estado anterior é restaurado e a exceção é
/// relançada para a UI exibir um snackbar.
class AdminUsersNotifier extends AsyncNotifier<List<AdminUserModel>> {
  @override
  Future<List<AdminUserModel>> build() async {
    return ref.read(adminAccountsServiceProvider).getUsers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminAccountsServiceProvider).getUsers(),
    );
  }

  Future<void> updateStatus(String userId, AdminAccountStatus newStatus) async {
    final current = state.value;
    if (current == null) return;

    // Otimista: atualiza local imediatamente.
    final optimistic = current
        .map((u) => u.id == userId ? u.copyWith(status: newStatus) : u)
        .toList();
    state = AsyncData(optimistic);

    try {
      final updated = await ref
          .read(adminAccountsServiceProvider)
          .updateUserStatus(userId, newStatus);

      // Substitui pelo retorno canônico do backend.
      final finalList = optimistic
          .map((u) => u.id == userId ? updated : u)
          .toList();
      state = AsyncData(finalList);
    } catch (err) {
      // Rollback para o estado anterior + relança para a UI tratar.
      state = AsyncData(current);
      rethrow;
    }
  }
}

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, List<AdminUserModel>>(
  AdminUsersNotifier.new,
);
