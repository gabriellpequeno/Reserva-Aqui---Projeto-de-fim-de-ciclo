import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';

class UsuarioService {
  const UsuarioService(this._dio);

  final Dio _dio;

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: register
  // ROUTE:    POST /usuarios/register
  // AUTH:     none
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> register({
    required String nomeCompleto,
    required String email,
    required String senha,
    required String confirmarSenha,
    required String cpf,
    required String dataNascimento,
    String? numeroCelular,
    required void Function(Map<String, dynamic> usuario) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (nomeCompleto.trim().isEmpty ||
        email.trim().isEmpty ||
        senha.isEmpty ||
        cpf.trim().isEmpty ||
        dataNascimento.trim().isEmpty) {
      onError('Preencha todos os campos obrigatórios.');
      return;
    }

    if (senha != confirmarSenha) {
      onError('As senhas não coincidem.');
      return;
    }

    if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d])',
    ).hasMatch(senha)) {
      onError(
        'A senha deve conter maiúscula, minúscula, número e caractere especial.',
      );
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      onError('E-mail inválido.');
      return;
    }

    final cleanCpf = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCpf.length != 11) {
      onError('CPF deve conter exatamente 11 números.');
      return;
    }

    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dataNascimento)) {
      onError('Data de nascimento deve estar no formato DD/MM/AAAA.');
      return;
    }

    String? cleanCelular;
    if (numeroCelular != null && numeroCelular.isNotEmpty) {
      cleanCelular = numeroCelular.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanCelular.length != 11) {
        onError(
          'Número de celular deve conter exatamente 11 números (com DDD).',
        );
        return;
      }
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/usuarios/register',
        data: {
          'nome_completo': nomeCompleto.trim(),
          'email': email.trim(),
          'senha': senha,
          'cpf': cleanCpf,
          'data_nascimento': dataNascimento.trim(),
          if (cleanCelular != null) 'numero_celular': cleanCelular,
        },
      );
      onSuccess(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        400: 'Dados inválidos. Verifique os campos e tente novamente.',
        409: 'O e-mail ou CPF informado já está em uso.',
      }));
    } catch (_) {
      onError('Erro inesperado. Tente novamente.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: login
  // ROUTE:    POST /usuarios/login
  // AUTH:     none
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String senha,
    required void Function(Map<String, dynamic> usuario, Map<String, dynamic> tokens) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (email.trim().isEmpty || senha.isEmpty) {
      onError('Preencha o e-mail e a senha.');
      return;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/usuarios/login',
        data: {'email': email.trim(), 'senha': senha},
      );

      final data = response.data!;
      onSuccess(
        data['data'] as Map<String, dynamic>,
        data['tokens'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        400: 'Dados inválidos ao tentar fazer login.',
        401: 'E-mail ou senha incorretos.',
      }));
    } catch (_) {
      onError('Erro inesperado. Tente novamente.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: logout
  // ROUTE:    POST /usuarios/logout
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> logout({
    required String refreshToken,
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/usuarios/logout',
        data: {'refreshToken': refreshToken},
      );
      onSuccess();
    } on DioException catch (e) {
      onError(_handleDioError(e, {}));
    } catch (_) {
      onError('Sessão encerrada.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: getAutenticado
  // ROUTE:    GET /usuarios/me
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> getAutenticado({
    required void Function(Map<String, dynamic> usuario) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/usuarios/me');
      onSuccess(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        401: 'Sessão expirada. Faça login novamente.',
      }));
    } catch (_) {
      onError('Erro inesperado. Tente novamente.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: update
  // ROUTE:    PATCH /usuarios/me
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> update({
    String? nomeCompleto,
    String? email,
    String? dataNascimento,
    String? numeroCelular,
    required void Function(Map<String, dynamic> usuario) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (email != null &&
        email.trim().isNotEmpty &&
        !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      onError('E-mail inválido.');
      return;
    }

    if (dataNascimento != null &&
        dataNascimento.trim().isNotEmpty &&
        !RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dataNascimento)) {
      onError('Data de nascimento deve estar no formato DD/MM/AAAA.');
      return;
    }

    String? cleanCelular;
    if (numeroCelular != null && numeroCelular.trim().isNotEmpty) {
      cleanCelular = numeroCelular.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanCelular.length != 11) {
        onError(
          'Número de celular deve conter exatamente 11 números (com DDD).',
        );
        return;
      }
    }

    final data = <String, dynamic>{
      if (nomeCompleto != null && nomeCompleto.trim().isNotEmpty)
        'nome_completo': nomeCompleto.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (dataNascimento != null && dataNascimento.trim().isNotEmpty)
        'data_nascimento': dataNascimento.trim(),
      if (cleanCelular != null) 'numero_celular': cleanCelular,
    };

    if (data.isEmpty) {
      onError('Nenhum dado informado para atualização.');
      return;
    }

    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/usuarios/me',
        data: data,
      );
      onSuccess(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        400: 'Dados inválidos. Verifique os campos e tente novamente.',
        401: 'Sessão expirada. Faça login novamente.',
        409: 'O e-mail informado já está em uso por outra conta.',
      }));
    } catch (_) {
      onError('Erro inesperado. Tente novamente.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: changePassword
  // ROUTE:    POST /usuarios/change-password
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> changePassword({
    required String senhaAtual,
    required String novaSenha,
    required String confirmarNovaSenha,
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    if (senhaAtual.isEmpty || novaSenha.isEmpty) {
      onError('Preencha as senhas atual e nova.');
      return;
    }

    if (novaSenha != confirmarNovaSenha) {
      onError('As novas senhas não coincidem.');
      return;
    }

    if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d])',
    ).hasMatch(novaSenha)) {
      onError(
        'A nova senha deve conter maiúscula, minúscula, número e caractere especial.',
      );
      return;
    }

    try {
      await _dio.post<Map<String, dynamic>>(
        '/usuarios/change-password',
        data: {'senhaAtual': senhaAtual, 'novaSenha': novaSenha},
      );
      onSuccess();
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        400: 'Dados inválidos. Verifique as senhas e tente novamente.',
        401: 'A senha atual está incorreta ou sua sessão expirou.',
      }));
    } catch (_) {
      onError('Erro inesperado ao alterar senha.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: deleteConta
  // ROUTE:    DELETE /usuarios/me
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> deleteConta({
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/usuarios/me');
      onSuccess();
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        401: 'Sessão expirada. Faça login novamente antes de excluir.',
      }));
    } catch (_) {
      onError('Erro inesperado ao excluir a conta.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: listFavoritos
  // ROUTE:    GET /usuarios/favoritos
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> listFavoritos({
    required void Function(List<Map<String, dynamic>> favoritos) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/usuarios/favoritos',
      );
      final data = (response.data!['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        401: 'Sessão expirada. Faça login novamente.',
      }));
    } catch (_) {
      onError('Erro inesperado ao buscar favoritos.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: addFavorito
  // ROUTE:    POST /usuarios/favoritos
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> addFavorito({
    required String hotelId,
    required void Function(Map<String, dynamic> favorito) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (hotelId.trim().isEmpty) {
      onError('ID do hotel inválido.');
      return;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/usuarios/favoritos',
        data: {'hotel_id': hotelId},
      );
      onSuccess(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        401: 'Sessão expirada. Faça login novamente.',
        409: 'Este hotel já está nos seus favoritos.',
      }));
    } catch (_) {
      onError('Erro inesperado ao adicionar favorito.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: removeFavorito
  // ROUTE:    DELETE /usuarios/favoritos/{hotel_id}
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> removeFavorito({
    required String hotelId,
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    if (hotelId.trim().isEmpty) {
      onError('ID do hotel inválido.');
      return;
    }

    try {
      await _dio.delete<dynamic>('/usuarios/favoritos/$hotelId');
      onSuccess();
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        401: 'Sessão expirada. Faça login novamente.',
        404: 'O hotel informado não está nos seus favoritos.',
      }));
    } catch (_) {
      onError('Erro inesperado ao remover favorito.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: listReservas
  // ROUTE:    GET /usuarios/reservas
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> listReservas({
    required void Function(List<Map<String, dynamic>> reservas) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/usuarios/reservas',
      );
      final data = (response.data!['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        401: 'Sessão expirada. Faça login novamente.',
      }));
    } catch (_) {
      onError('Erro inesperado ao buscar histórico de reservas.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: createReserva
  // ROUTE:    POST /usuarios/reservas
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> createReserva({
    required String hotelId,
    required int numHospedes,
    required String dataCheckin,
    required String dataCheckout,
    required double valorTotal,
    int? quartoId,
    String? tipoQuarto,
    String? observacoes,
    required void Function(Map<String, dynamic> reserva) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (numHospedes < 1) {
      onError('Número mínimo de hóspedes é 1.');
      return;
    }
    if (valorTotal <= 0) {
      onError('O valor total deve ser maior que zero.');
      return;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/usuarios/reservas',
        data: {
          'hotel_id': hotelId,
          'num_hospedes': numHospedes,
          'data_checkin': dataCheckin,
          'data_checkout': dataCheckout,
          'valor_total': valorTotal,
          if (quartoId != null) 'quarto_id': quartoId,
          if (tipoQuarto != null) 'tipo_quarto': tipoQuarto,
          if (observacoes != null && observacoes.trim().isNotEmpty)
            'observacoes': observacoes.trim(),
        },
      );
      onSuccess(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        400: 'Dados inválidos ao criar reserva.',
        401: 'Sessão expirada. Faça login novamente.',
      }));
    } catch (_) {
      onError('Erro inesperado ao criar reserva.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: cancelReserva
  // ROUTE:    PATCH /usuarios/reservas/{codigo_publico}/cancelar
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> cancelReserva({
    required String codigoPublico,
    required void Function(Map<String, dynamic> reservaAtualizada) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (codigoPublico.trim().isEmpty) {
      onError('Código de reserva inválido.');
      return;
    }

    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/usuarios/reservas/$codigoPublico/cancelar',
      );
      onSuccess(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        401: 'Sessão expirada. Faça login novamente.',
        404: 'Reserva não encontrada.',
      }));
    } catch (_) {
      onError('Erro inesperado ao cancelar reserva.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: createAvaliacao
  // ROUTE:    POST /usuarios/avaliacoes
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> createAvaliacao({
    required String codigoPublico,
    required int notaLimpeza,
    required int notaAtendimento,
    required int notaConforto,
    required int notaOrganizacao,
    required int notaLocalizacao,
    String? comentario,
    required void Function(Map<String, dynamic> avaliacao) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (codigoPublico.trim().isEmpty) {
      onError('Código de reserva inválido.');
      return;
    }

    bool isNotaValida(int nota) => nota >= 1 && nota <= 5;
    if (!isNotaValida(notaLimpeza) ||
        !isNotaValida(notaAtendimento) ||
        !isNotaValida(notaConforto) ||
        !isNotaValida(notaOrganizacao) ||
        !isNotaValida(notaLocalizacao)) {
      onError('Todas as notas devem ser de 1 a 5.');
      return;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/usuarios/avaliacoes',
        data: {
          'codigo_publico': codigoPublico,
          'nota_limpeza': notaLimpeza,
          'nota_atendimento': notaAtendimento,
          'nota_conforto': notaConforto,
          'nota_organizacao': notaOrganizacao,
          'nota_localizacao': notaLocalizacao,
          if (comentario != null && comentario.trim().isNotEmpty)
            'comentario': comentario.trim(),
        },
      );
      onSuccess(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        400: 'Dados inválidos ao criar avaliação.',
        401: 'Sessão expirada. Faça login novamente.',
        404: 'Reserva não encontrada.',
        409: 'Você já avaliou esta reserva.',
      }));
    } catch (_) {
      onError('Erro inesperado ao enviar avaliação.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: updateAvaliacao
  // ROUTE:    PATCH /usuarios/avaliacoes/{codigo_publico}
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> updateAvaliacao({
    required String codigoPublico,
    int? notaLimpeza,
    int? notaAtendimento,
    int? notaConforto,
    int? notaOrganizacao,
    int? notaLocalizacao,
    String? comentario,
    required void Function(Map<String, dynamic> avaliacaoAtualizada) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (codigoPublico.trim().isEmpty) {
      onError('Código de reserva inválido.');
      return;
    }

    bool isNotaValida(int nota) => nota >= 1 && nota <= 5;
    if ((notaLimpeza != null && !isNotaValida(notaLimpeza)) ||
        (notaAtendimento != null && !isNotaValida(notaAtendimento)) ||
        (notaConforto != null && !isNotaValida(notaConforto)) ||
        (notaOrganizacao != null && !isNotaValida(notaOrganizacao)) ||
        (notaLocalizacao != null && !isNotaValida(notaLocalizacao))) {
      onError('As notas atualizadas devem ser de 1 a 5.');
      return;
    }

    final dataUpdates = <String, dynamic>{
      if (notaLimpeza != null) 'nota_limpeza': notaLimpeza,
      if (notaAtendimento != null) 'nota_atendimento': notaAtendimento,
      if (notaConforto != null) 'nota_conforto': notaConforto,
      if (notaOrganizacao != null) 'nota_organizacao': notaOrganizacao,
      if (notaLocalizacao != null) 'nota_localizacao': notaLocalizacao,
      if (comentario != null) 'comentario': comentario.trim(),
    };

    if (dataUpdates.isEmpty) {
      onError('Nenhum dado informado para atualização.');
      return;
    }

    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/usuarios/avaliacoes/$codigoPublico',
        data: dataUpdates,
      );
      onSuccess(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        400: 'Dados inválidos ao atualizar.',
        401: 'Sessão expirada. Faça login novamente.',
        404: 'Avaliação não encontrada.',
      }));
    } catch (_) {
      onError('Erro inesperado ao editar avaliação.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: registerFcmToken
  // ROUTE:    POST /dispositivos-fcm/usuario
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> registerFcmToken({
    required String fcmToken,
    String? origem,
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    if (fcmToken.trim().isEmpty) {
      onError('Token FCM inválido.');
      return;
    }

    try {
      await _dio.post<dynamic>(
        '/dispositivos-fcm/usuario',
        data: {
          'fcm_token': fcmToken.trim(),
          if (origem != null) 'origem': origem,
        },
      );
      onSuccess();
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        400: 'Dados inválidos ao registrar o dispositivo.',
        401: 'Sessão expirada. Faça login novamente.',
      }));
    } catch (_) {
      onError('Erro inesperado ao registrar token do dispositivo.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: removeFcmToken
  // ROUTE:    DELETE /dispositivos-fcm/usuario
  // AUTH:     UserBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> removeFcmToken({
    required String fcmToken,
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    if (fcmToken.trim().isEmpty) {
      onError('Token FCM inválido.');
      return;
    }

    try {
      await _dio.delete<dynamic>(
        '/dispositivos-fcm/usuario',
        data: {'fcm_token': fcmToken.trim()},
      );
      onSuccess();
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        401: 'Sessão expirada. Faça login novamente.',
      }));
    } catch (_) {
      onError('Erro inesperado ao remover token do dispositivo.');
    }
  }
}

// ─── Helper ──────────────────────────────────────────────────────────────────

String _handleDioError(DioException e, Map<int, String> statusMessages) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Tempo de conexão esgotado. Verifique sua internet.';
    case DioExceptionType.connectionError:
      return 'Sem conexão com o servidor. Verifique sua internet.';
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      final serverMsg = body is Map
          ? (body['error'] ?? body['message'])?.toString()
          : null;
      if (serverMsg != null) return serverMsg;
      if (statusCode != null && statusMessages.containsKey(statusCode)) {
        return statusMessages[statusCode]!;
      }
      return 'Erro inesperado (código $statusCode).';
    default:
      return 'Erro inesperado. Tente novamente.';
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final usuarioServiceProvider = Provider<UsuarioService>((ref) {
  return UsuarioService(ref.watch(dioProvider));
});
