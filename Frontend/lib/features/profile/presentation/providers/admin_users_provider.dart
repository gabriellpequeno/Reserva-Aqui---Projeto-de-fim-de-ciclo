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
    await _withOptimistic(
      userId,
      (u) => u.copyWith(status: newStatus),
      () => ref.read(adminAccountsServiceProvider).updateUserStatus(userId, newStatus),
    );
  }

  /// Edita dados não-sensíveis de um usuário. `patch` usa as chaves do backend
  /// (`nome_completo`, `email`, `numero_celular`) — só as presentes são enviadas.
  Future<void> updateData(String userId, Map<String, dynamic> patch) async {
    await _withOptimistic(
      userId,
      (u) => u.copyWith(
        nome: patch['nome_completo'] as String?,
        email: patch['email'] as String?,
        telefone: patch['numero_celular'] as String?,
      ),
      () => ref.read(adminAccountsServiceProvider).updateUser(userId, patch),
    );
  }

  Future<void> _withOptimistic(
    String userId,
    AdminUserModel Function(AdminUserModel) apply,
    Future<AdminUserModel> Function() remote,
  ) async {
    final current = state.value;
    if (current == null) return;

    final optimistic = current
        .map((u) => u.id == userId ? apply(u) : u)
        .toList();
    state = AsyncData(optimistic);

    try {
      final updated = await remote();
      final finalList = optimistic
          .map((u) => u.id == userId ? updated : u)
          .toList();
      state = AsyncData(finalList);
    } catch (err) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, List<AdminUserModel>>(
  AdminUsersNotifier.new,
);
