import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/Usuario.dart';
import '../../domain/models/admin_profile_state.dart';

/// Provider do perfil do admin autenticado.
///
/// Consome `GET /api/v1/usuarios/me` (mesmo endpoint do usuário comum — admin é
/// diferenciado pelo campo `papel` retornado pelo backend na Fase 1).
/// Segue 1:1 o padrão de `host_profile_provider.dart`.
class AdminProfileNotifier extends AsyncNotifier<AdminProfileState> {
  @override
  Future<AdminProfileState> build() async {
    return _fetch();
  }

  Future<AdminProfileState> _fetch() async {
    final completer = Completer<AdminProfileState>();

    await ref.read(usuarioServiceProvider).getAutenticado(
      onSuccess: (data) =>
          completer.complete(AdminProfileState.fromJson(data)),
      onError: (message) =>
          completer.completeError(Exception(message)),
    );

    return completer.future;
  }

  Future<void> updateProfile({
    String? nomeCompleto,
    String? email,
    String? numeroCelular,
  }) async {
    final completer = Completer<AdminProfileState>();

    await ref.read(usuarioServiceProvider).update(
      nomeCompleto: nomeCompleto,
      email: email,
      numeroCelular: numeroCelular,
      onSuccess: (data) =>
          completer.complete(AdminProfileState.fromJson(data)),
      onError: (message) =>
          completer.completeError(Exception(message)),
    );

    final updated = await completer.future;
    state = AsyncData(updated);
  }

  Future<void> changePassword({
    required String senhaAtual,
    required String novaSenha,
    required String confirmarNovaSenha,
  }) async {
    final completer = Completer<void>();

    await ref.read(usuarioServiceProvider).changePassword(
      senhaAtual: senhaAtual,
      novaSenha: novaSenha,
      confirmarNovaSenha: confirmarNovaSenha,
      onSuccess: () => completer.complete(),
      onError: (message) => completer.completeError(Exception(message)),
    );

    await completer.future;
  }
}

final adminProfileProvider =
    AsyncNotifierProvider<AdminProfileNotifier, AdminProfileState>(
  AdminProfileNotifier.new,
);
