import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';

class HotelService {
  const HotelService(this._dio);

  final Dio _dio;

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: login
  // ROUTE:    POST /hotel/login
  // AUTH:     none
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String senha,
    required void Function(Map<String, dynamic> hotel, Map<String, dynamic> tokens) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (email.trim().isEmpty || senha.isEmpty) {
      onError('Preencha o e-mail e a senha.');
      return;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/hotel/login',
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
  // FUNCTION: register
  // ROUTE:    POST /hotel/register
  // AUTH:     none
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> register({
    required String nomeHotel,
    required String email,
    required String senha,
    required String confirmarSenha,
    required String cnpj,
    String? telefone,
    String? endereco,
    required void Function(Map<String, dynamic> hotel) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (nomeHotel.trim().isEmpty ||
        email.trim().isEmpty ||
        senha.isEmpty ||
        cnpj.trim().isEmpty) {
      onError('Preencha todos os campos obrigatórios.');
      return;
    }

    if (senha != confirmarSenha) {
      onError('As senhas não coincidem.');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      onError('E-mail inválido.');
      return;
    }

    final cleanCnpj = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCnpj.length != 14) {
      onError('CNPJ deve conter exatamente 14 números.');
      return;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/hotel/register',
        data: {
          'nome_hotel': nomeHotel.trim(),
          'email': email.trim(),
          'senha': senha,
          'cnpj': cleanCnpj,
          if (telefone != null && telefone.trim().isNotEmpty)
            'telefone': telefone.trim(),
          if (endereco != null && endereco.trim().isNotEmpty)
            'endereco': endereco.trim(),
        },
      );
      onSuccess(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        400: 'Dados inválidos. Verifique os campos e tente novamente.',
        409: 'O e-mail ou CNPJ informado já está em uso.',
      }));
    } catch (_) {
      onError('Erro inesperado. Tente novamente.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: logout
  // ROUTE:    POST /hotel/logout
  // AUTH:     HotelBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> logout({
    required String refreshToken,
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/hotel/logout',
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
  // ROUTE:    GET /hotel/me
  // AUTH:     HotelBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> getAutenticado({
    required void Function(Map<String, dynamic> hotel) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/hotel/me');
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
  // ROUTE:    PATCH /hotel/me
  // AUTH:     HotelBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> update({
    String? nomeHotel,
    String? email,
    String? telefone,
    String? endereco,
    String? descricao,
    required void Function(Map<String, dynamic> hotel) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (email != null &&
        email.trim().isNotEmpty &&
        !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      onError('E-mail inválido.');
      return;
    }

    final data = <String, dynamic>{
      if (nomeHotel != null && nomeHotel.trim().isNotEmpty)
        'nome_hotel': nomeHotel.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (telefone != null && telefone.trim().isNotEmpty)
        'telefone': telefone.trim(),
      if (endereco != null && endereco.trim().isNotEmpty)
        'endereco': endereco.trim(),
      if (descricao != null && descricao.trim().isNotEmpty)
        'descricao': descricao.trim(),
    };

    if (data.isEmpty) {
      onError('Nenhum dado informado para atualização.');
      return;
    }

    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/hotel/me',
        data: data,
      );
      onSuccess(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        400: 'Dados inválidos. Verifique os campos e tente novamente.',
        401: 'Sessão expirada. Faça login novamente.',
        409: 'O e-mail informado já está em uso.',
      }));
    } catch (_) {
      onError('Erro inesperado. Tente novamente.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: changePassword
  // ROUTE:    POST /hotel/change-password
  // AUTH:     HotelBearer
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

    try {
      await _dio.post<Map<String, dynamic>>(
        '/hotel/change-password',
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
  // FUNCTION: listReservas
  // ROUTE:    GET /hotel/reservas
  // AUTH:     HotelBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> listReservas({
    String? status,
    required void Function(List<Map<String, dynamic>> reservas) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/hotel/reservas',
        queryParameters: {if (status != null) 'status': status},
      );
      final data = (response.data!['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        401: 'Sessão expirada. Faça login novamente.',
      }));
    } catch (_) {
      onError('Erro inesperado ao buscar reservas.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: updateReservaStatus
  // ROUTE:    PATCH /hotel/reservas/{codigo_publico}/status
  // AUTH:     HotelBearer
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> updateReservaStatus({
    required String codigoPublico,
    required String novoStatus,
    required void Function(Map<String, dynamic> reserva) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (codigoPublico.trim().isEmpty) {
      onError('Código de reserva inválido.');
      return;
    }

    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/hotel/reservas/$codigoPublico/status',
        data: {'status': novoStatus},
      );
      onSuccess(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      onError(_handleDioError(e, {
        401: 'Sessão expirada. Faça login novamente.',
        404: 'Reserva não encontrada.',
      }));
    } catch (_) {
      onError('Erro inesperado ao atualizar status da reserva.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: registerFcmToken
  // ROUTE:    POST /dispositivos-fcm/hotel
  // AUTH:     HotelBearer
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
        '/dispositivos-fcm/hotel',
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

final hotelServiceProvider = Provider<HotelService>((ref) {
  return HotelService(ref.watch(dioProvider));
});
