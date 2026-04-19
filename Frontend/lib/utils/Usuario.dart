import 'package:dio/dio.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Usuario.dart
//
// Centralises every HTTP call from the ReservAqui Flutter app to its backend.
// ALL FUNCTIONS USE THE CALLBACK PATTERN: onSuccess and onError.
// NO EXCEPTIONS should ever be thrown from these functions to the UI.
// ─────────────────────────────────────────────────────────────────────────────

const String _baseUrl = 'http://localhost:3000/api';

// ── Token store (in-memory) ───────────────────────────────────────────────────
String? _accessToken;
String? _refreshToken;

void setTokens(String accessToken, String refreshToken) {
  _accessToken = accessToken;
  _refreshToken = refreshToken;
}

void clearTokens() {
  _accessToken = null;
  _refreshToken = null;
}

void Function()? onSessionExpired;

// ── Refresh-only Dio ──────────────────────────────────────────────────────────
final Dio _refreshDio = Dio(
  BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ),
);

// ── Main Dio client with Auto-Refresh Interceptor ─────────────────────────────
bool _isRefreshing = false;
final _pendingQueue =
    <({RequestOptions options, ErrorInterceptorHandler handler})>[];

final Dio _dio = () {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401 || _refreshToken == null) {
          if (error.response?.statusCode == 401) {
            clearTokens();
            onSessionExpired?.call();
          }
          handler.next(error);
          return;
        }

        if (_isRefreshing) {
          _pendingQueue.add((options: error.requestOptions, handler: handler));
          return;
        }

        _isRefreshing = true;
        try {
          final res = await _refreshDio.post<Map<String, dynamic>>(
            '/usuarios/refresh', // or /hotel/refresh depending on context
            data: {'refreshToken': _refreshToken},
          );
          final tokens = res.data!['tokens'] as Map<String, dynamic>;
          setTokens(
            tokens['accessToken'] as String,
            tokens['refreshToken'] as String,
          );

          for (final pending in _pendingQueue) {
            pending.options.headers['Authorization'] = 'Bearer $_accessToken';
            dio
                .fetch(pending.options)
                .then(
                  (r) => pending.handler.resolve(r),
                  onError: (e) => pending.handler.reject(e as DioException),
                );
          }
          _pendingQueue.clear();

          error.requestOptions.headers['Authorization'] =
              'Bearer $_accessToken';
          handler.resolve(await dio.fetch(error.requestOptions));
        } catch (_) {
          _pendingQueue.clear();
          clearTokens();
          onSessionExpired?.call();
          handler.next(error);
        } finally {
          _isRefreshing = false;
        }
      },
    ),
  );
  return dio;
}();

class Usuario {
  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: registerUsuario
  // ROUTE:    POST /usuarios/register
  // AUTH:     none
  // PURPOSE:  Registra um novo hóspede e retorna os dados do usuário criado.
  //
  // HOW IT WORKS:
  //   1. Valida nome, formato de e-mail, força da senha, formatação da data e CPF localmente.
  //   2. Remove traços e pontos do CPF e celular antes de enviar à API.
  //   3. Invokes onSuccess with [Map<String, dynamic> usuario] on success.
  //   4. Invokes onError with a localized message on HTTP error or validation failure.
  //
  // USAGE EXAMPLE:
  //   await Usuario.register(
  //     nomeCompleto: 'João Silva',
  //     email: 'joao@email.com',
  //     senha: 'Senha@123',
  //     confirmarSenha: 'Senha@123',
  //     cpf: '12345678901',
  //     dataNascimento: '01/01/1990',
  //     onSuccess: (usuario) => print(usuario['nome_completo']),
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> register({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 400:
              onError(
                serverMsg ??
                    'Dados inválidos. Verifique os campos e tente novamente.',
              );
            case 409:
              onError(serverMsg ?? 'O e-mail ou CPF informado já está em uso.');
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado. Tente novamente.');
      }
    } catch (_) {
      onError('Erro inesperado. Tente novamente.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: login
  // ROUTE:    POST /usuarios/login
  // AUTH:     none
  // PURPOSE:  Realiza o login do hóspede, grava os tokens na memória e retorna os dados.
  //
  // HOW IT WORKS:
  //   1. Valida localmente se e-mail e senha não estão vazios.
  //   2. Faz a requisição POST.
  //   3. Se sucesso, intercepta os 'tokens' e salva localmente com `setTokens()`.
  //   4. Invokes onSuccess com [Map<String, dynamic> usuario].
  //   5. Invokes onError com mensagem traduzida (ex: credenciais inválidas) no erro.
  //
  // USAGE EXAMPLE:
  //   await Usuario.login(
  //     email: 'joao@email.com',
  //     senha: 'Senha@123',
  //     onSuccess: (usuario) {
  //       print('Logado como: ${usuario['nome_completo']}');
  //       Navigator.pushReplacementNamed(context, '/home');
  //     },
  //     onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(...),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> login({
    required String email,
    required String senha,
    required void Function(Map<String, dynamic> usuario) onSuccess,
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

      final responseData = response.data!;
      final tokens = responseData['tokens'] as Map<String, dynamic>;
      final usuario = responseData['data'] as Map<String, dynamic>;

      // Grava os tokens na memória para que o interceptor os use nas próximas chamadas
      setTokens(
        tokens['accessToken'] as String,
        tokens['refreshToken'] as String,
      );

      onSuccess(usuario);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 400:
              onError(serverMsg ?? 'Dados inválidos ao tentar fazer login.');
            case 401:
              onError(serverMsg ?? 'E-mail ou senha incorretos.');
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado. Tente novamente.');
      }
    } catch (_) {
      onError('Erro inesperado. Tente novamente.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: logout
  // ROUTE:    POST /usuarios/logout
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Desloga o hóspede invalidando os tokens no servidor e limpando a memória local.
  //
  // HOW IT WORKS:
  //   1. Valida de forma transparente se existe `_refreshToken` na memória protegida.
  //   2. Executa POST /usuarios/logout enviando o `refreshToken`.
  //   3. Invoca a função global `clearTokens()` invalidando o acesso no app, mesmo em caso de erro na API.
  //   4. Invokes onSuccess() se finalizado localmente.
  //
  // USAGE EXAMPLE:
  //   await Usuario.logout(
  //     onSuccess: () => Navigator.pushReplacementNamed(context, '/login'),
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> logout({
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    if (_refreshToken == null) {
      clearTokens();
      onSuccess();
      return;
    }

    try {
      await _dio.post<Map<String, dynamic>>(
        '/usuarios/logout',
        data: {'refreshToken': _refreshToken},
      );
      clearTokens();
      onSuccess();
    } on DioException catch (e) {
      clearTokens();
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Sessão encerrada');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Sessão encerrada');
        default:
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          onError(serverMsg ?? 'Sessão encerrada');
      }
    } catch (_) {
      clearTokens();
      onError('Sessão encerrada');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: getAutenticado
  // ROUTE:    GET /usuarios/me
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Obtém os dados do perfil do hóspede logado.
  //
  // HOW IT WORKS:
  //   1. O servidor identifica o usuário logado via Token.
  //   2. Invokes onSuccess com [Map<String, dynamic> usuario] contendo nome, e-mail, etc.
  //   3. O Refresh automático ocorre nos bastidores se o token expirou.
  //   4. Invokes onError em caso de erro 401 definitivo ou sem rede.
  //
  // USAGE EXAMPLE:
  //   await Usuario.getAutenticado(
  //     onSuccess: (usuario) {
  //       print('Meu Perfil: \${usuario["nome_completo"]}');
  //     },
  //     onError: (msg) => print(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> getAutenticado({
    required void Function(Map<String, dynamic> usuario) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/usuarios/me');
      onSuccess(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 401:
              onError(serverMsg ?? 'Sessão expirada. Faça login novamente.');
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado. Tente novamente.');
      }
    } catch (_) {
      onError('Erro inesperado. Tente novamente.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: update
  // ROUTE:    PATCH /usuarios/me
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Atualiza os dados de perfil do hóspede logado.
  //
  // HOW IT WORKS:
  //   1. Faz validações client-side apenas nos campos que foram preenchidos (opcionais).
  //   2. Filtra campos vazios para não enviar "lixo" no payload.
  //   3. O interceptor do `_dio` cuida do Token e do Auto-Refresh silenciosamente.
  //   4. Invokes onSuccess com [Map<String, dynamic> usuario] atualizado.
  //   5. Lida com mensagens de erro, incluindo o conflito (409) se o novo email já existir.
  //
  // USAGE EXAMPLE:
  //   await Usuario.update(
  //     nomeCompleto: _nomeController.text,
  //     // Deixe os outros parametros de fora ou passe null se não quiser mudar
  //     onSuccess: (usuario) {
  //       print('Nome alterado para: \${usuario["nome_completo"]}');
  //     },
  //     onError: (msg) => print(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> update({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 400:
              onError(
                serverMsg ??
                    'Dados inválidos. Verifique os campos e tente novamente.',
              );
            case 401:
              onError(serverMsg ?? 'Sessão expirada. Faça login novamente.');
            case 409:
              onError(
                serverMsg ??
                    'O e-mail informado já está em uso por outra conta.',
              );
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado. Tente novamente.');
      }
    } catch (_) {
      onError('Erro inesperado. Tente novamente.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: changePassword
  // ROUTE:    POST /usuarios/change-password
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Altera a senha do hóspede logado.
  //
  // HOW IT WORKS:
  //   1. Faz validação local para confirmar se a `novaSenha` bate com `confirmarNovaSenha`.
  //   2. Valida a força da senha nova localmente (maiúscula, minúscula, número e símbolo).
  //   3. O interceptor do `_dio` cuida da injeção do Token e auto-refresh.
  //   4. Invokes onSuccess() vazio (a resposta da API é um MessageResponse simples).
  //   5. Trata 401 para quando a senha atual fornecida não bate no banco.
  //
  // USAGE EXAMPLE:
  //   await Usuario.changePassword(
  //     senhaAtual: _senhaAtualController.text,
  //     novaSenha: _novaSenhaController.text,
  //     confirmarNovaSenha: _confirmarSenhaController.text,
  //     onSuccess: () {
  //       // Ex.: Mostrar sucesso e limpar os campos da tela
  //       print('Senha alterada com sucesso!');
  //     },
  //     onError: (msg) => print(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> changePassword({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 400:
              onError(
                serverMsg ??
                    'Dados inválidos. Verifique as senhas e tente novamente.',
              );
            case 401:
              // Pode ser token expirado de vez ou a senhaAtual passada está incorreta
              onError(
                serverMsg ??
                    'A senha atual está incorreta ou sua sessão expirou.',
              );
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado ao alterar senha.');
      }
    } catch (_) {
      onError('Erro inesperado ao alterar senha.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: deleteConta
  // ROUTE:    DELETE /usuarios/me
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Desativa/Exclui a conta do hóspede logado.
  //
  // HOW IT WORKS:
  //   1. O servidor identifica o usuário logado via Token.
  //   2. Executa a requisição DELETE.
  //   3. O interceptor do `_dio` cuida do Token e do Auto-Refresh silenciosamente.
  //   4. Limpa os tokens da memória (`clearTokens()`) após deletar com sucesso, pois
  //      a sessão atual não será mais válida, garantindo offline state.
  //   5. Invokes onSuccess().
  //   6. Invokes onError em caso de problemas na rede ou servidor.
  //
  // USAGE EXAMPLE:
  //   await Usuario.deleteConta(
  //     onSuccess: () {
  //       // Ex.: Mostrar mensagem de despedida e ir para a tela de login.
  //       Navigator.pushReplacementNamed(context, '/login');
  //     },
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> deleteConta({
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/usuarios/me');
      clearTokens();
      onSuccess();
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 401:
              onError(
                serverMsg ??
                    'Sessão expirada. Faça login novamente antes de excluir.',
              );
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado ao excluir a conta.');
      }
    } catch (_) {
      onError('Erro inesperado ao excluir a conta.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: listFavoritos
  // ROUTE:    GET /usuarios/favoritos
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Lista os hotéis favoritados pelo hóspede logado.
  //
  // HOW IT WORKS:
  //   1. Invokes onSuccess com [List<Map<String, dynamic>> favoritos] em caso de sucesso.
  //   2. O interceptor do `_dio` cuida do Token e do Auto-Refresh silenciosamente.
  //   3. Invokes onError com mensagem traduzida em caso de erro.
  //
  // USAGE EXAMPLE:
  //   await Usuario.listFavoritos(
  //     onSuccess: (favoritos) {
  //       setState(() => _favoritos = favoritos);
  //     },
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> listFavoritos({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 401:
              onError(serverMsg ?? 'Sessão expirada. Faça login novamente.');
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado ao buscar favoritos.');
      }
    } catch (_) {
      onError('Erro inesperado ao buscar favoritos.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: addFavorito
  // ROUTE:    POST /usuarios/favoritos
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Adiciona um hotel aos favoritos do hóspede logado.
  //
  // HOW IT WORKS:
  //   1. Faz a chamada POST enviando o `hotel_id`.
  //   2. Invokes onSuccess com [Map<String, dynamic> favorito] em caso de sucesso.
  //   3. Invokes onError com mensagem traduzida em caso de erro (ex: já favoritado).
  //
  // USAGE EXAMPLE:
  //   await Usuario.addFavorito(
  //     hotelId: 'e28a...',
  //     onSuccess: (favorito) => print('Hotel favoritado com sucesso!'),
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> addFavorito({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 401:
              onError(serverMsg ?? 'Sessão expirada. Faça login novamente.');
            case 409:
              onError(serverMsg ?? 'Este hotel já está nos seus favoritos.');
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado ao adicionar favorito.');
      }
    } catch (_) {
      onError('Erro inesperado ao adicionar favorito.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: removeFavorito
  // ROUTE:    DELETE /usuarios/favoritos/{hotel_id}
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Remove um hotel dos favoritos do hóspede logado.
  //
  // HOW IT WORKS:
  //   1. Faz a chamada DELETE com o `hotel_id` na URL.
  //   2. Invokes onSuccess sem dados retornados em caso de sucesso (204 No Content).
  //   3. Invokes onError com mensagem traduzida em caso de erro.
  //
  // USAGE EXAMPLE:
  //   await Usuario.removeFavorito(
  //     hotelId: 'e28a...',
  //     onSuccess: () => print('Removido dos favoritos.'),
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> removeFavorito({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 401:
              onError(serverMsg ?? 'Sessão expirada. Faça login novamente.');
            case 404:
              onError(
                serverMsg ?? 'O hotel informado não está nos seus favoritos.',
              );
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado ao remover favorito.');
      }
    } catch (_) {
      onError('Erro inesperado ao remover favorito.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: listReservas
  // ROUTE:    GET /usuarios/reservas
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Lista o histórico de reservas feitas pelo hóspede logado.
  //
  // HOW IT WORKS:
  //   1. Invokes onSuccess com [List<Map<String, dynamic>> reservas] em caso de sucesso.
  //   2. Invokes onError com mensagem traduzida em caso de erro.
  //
  // USAGE EXAMPLE:
  //   await Usuario.listReservas(
  //     onSuccess: (reservas) {
  //       setState(() => _minhasReservas = reservas);
  //     },
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> listReservas({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 401:
              onError(serverMsg ?? 'Sessão expirada. Faça login novamente.');
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado ao buscar histórico de reservas.');
      }
    } catch (_) {
      onError('Erro inesperado ao buscar histórico de reservas.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: createReserva
  // ROUTE:    POST /usuarios/reservas
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Cria uma nova reserva para o hóspede logado.
  //
  // HOW IT WORKS:
  //   1. Formata os dados essenciais (hotel_id, data_checkin, etc.).
  //   2. Invokes onSuccess com [Map<String, dynamic> reserva] criada.
  //   3. Invokes onError com validações em caso de falha (ex: quarto indisponível).
  //
  // USAGE EXAMPLE:
  //   await Usuario.createReserva(
  //     hotelId: 'e28a...',
  //     numHospedes: 2,
  //     dataCheckin: '2024-12-01', // formato YYYY-MM-DD
  //     dataCheckout: '2024-12-05',
  //     valorTotal: 500.0,
  //     quartoId: 10,
  //     onSuccess: (reserva) => print('Reserva criada!'),
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> createReserva({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 400:
              onError(serverMsg ?? 'Dados inválidos ao criar reserva.');
            case 401:
              onError(serverMsg ?? 'Sessão expirada. Faça login novamente.');
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado ao criar reserva.');
      }
    } catch (_) {
      onError('Erro inesperado ao criar reserva.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: cancelReserva
  // ROUTE:    PATCH /usuarios/reservas/{codigo_publico}/cancelar
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Cancela uma reserva específica do hóspede logado.
  //
  // HOW IT WORKS:
  //   1. Envia requisição PATCH com o código público da reserva na URL.
  //   2. Invokes onSuccess com [Map<String, dynamic> reserva] atualizada.
  //   3. Invokes onError com mensagem traduzida (ex: já cancelada ou não encontrada).
  //
  // USAGE EXAMPLE:
  //   await Usuario.cancelReserva(
  //     codigoPublico: 'uuid-da-reserva',
  //     onSuccess: (reservaAtualizada) => print('Reserva cancelada!'),
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> cancelReserva({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 401:
              onError(serverMsg ?? 'Sessão expirada. Faça login novamente.');
            case 404:
              onError(serverMsg ?? 'Reserva não encontrada.');
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado ao cancelar reserva.');
      }
    } catch (_) {
      onError('Erro inesperado ao cancelar reserva.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: createAvaliacao
  // ROUTE:    POST /usuarios/avaliacoes
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Avalia uma estadia concluída do hóspede logado.
  //
  // HOW IT WORKS:
  //   1. Valida se as notas estão entre 1 e 5 localmente.
  //   2. Invokes onSuccess com [Map<String, dynamic> avaliacao] recém-criada.
  //   3. Invokes onError com mensagens localizadas (ex: reserva não encontrada ou já avaliada).
  //
  // USAGE EXAMPLE:
  //   await Usuario.createAvaliacao(
  //     codigoPublico: 'uuid-da-reserva',
  //     notaLimpeza: 5,
  //     notaAtendimento: 4,
  //     notaConforto: 5,
  //     notaOrganizacao: 4,
  //     notaLocalizacao: 5,
  //     comentario: 'Excelente hotel!',
  //     onSuccess: (avaliacao) => print('Avaliação enviada com sucesso!'),
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> createAvaliacao({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 400:
              onError(serverMsg ?? 'Dados inválidos ao criar avaliação.');
            case 401:
              onError(serverMsg ?? 'Sessão expirada. Faça login novamente.');
            case 404:
              onError(serverMsg ?? 'Reserva não encontrada.');
            case 409:
              onError(serverMsg ?? 'Você já avaliou esta reserva.');
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado ao enviar avaliação.');
      }
    } catch (_) {
      onError('Erro inesperado ao enviar avaliação.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: updateAvaliacao
  // ROUTE:    PATCH /usuarios/avaliacoes/{codigo_publico}
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Edita uma avaliação já existente do hóspede logado.
  //
  // HOW IT WORKS:
  //   1. Envia apenas as notas e comentário opcionais na requisição PATCH.
  //   2. Valida previamente as notas informadas (entre 1 e 5).
  //   3. Invokes onSuccess com [Map<String, dynamic> avaliacao] atualizada.
  //   4. Invokes onError em caso de falha (ex: avaliação não encontrada).
  //
  // USAGE EXAMPLE:
  //   await Usuario.updateAvaliacao(
  //     codigoPublico: 'uuid-da-reserva',
  //     notaLimpeza: 4, // Modificando a nota anterior
  //     onSuccess: (avaliacaoAtualizada) => print('Avaliação editada!'),
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> updateAvaliacao({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final body = e.response?.data;
          final serverMsg = body is Map
              ? (body['error'] ?? body['message'])?.toString()
              : null;
          switch (statusCode) {
            case 400:
              onError(serverMsg ?? 'Dados inválidos ao atualizar.');
            case 401:
              onError(serverMsg ?? 'Sessão expirada. Faça login novamente.');
            case 404:
              onError(serverMsg ?? 'Avaliação não encontrada.');
            default:
              onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado ao editar avaliação.');
      }
    } catch (_) {
      onError('Erro inesperado ao editar avaliação.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: registerFcmToken
  // ROUTE:    POST /dispositivos-fcm/usuario
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Registra o token do dispositivo (FCM) para o hóspede receber push notifications.
  //
  // HOW IT WORKS:
  //   1. Envia o `fcm_token` e a `origem` (APP_IOS, APP_ANDROID ou DASHBOARD_WEB).
  //   2. Invokes onSuccess sem parâmetros em caso de sucesso (204 No Content).
  //   3. Invokes onError em caso de erro na requisição.
  //
  // USAGE EXAMPLE:
  //   await Usuario.registerFcmToken(
  //     fcmToken: 'token-gerado-pelo-firebase',
  //     origem: 'APP_ANDROID', // Opcional
  //     onSuccess: () => print('FCM Token registrado!'),
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> registerFcmToken({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          switch (statusCode) {
            case 400:
              onError('Dados inválidos ao registrar o dispositivo.');
            case 401:
              onError('Sessão expirada. Faça login novamente.');
            default:
              onError('Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado ao registrar token do dispositivo.');
      }
    } catch (_) {
      onError('Erro inesperado ao registrar token do dispositivo.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FUNCTION: removeFcmToken
  // ROUTE:    DELETE /dispositivos-fcm/usuario
  // AUTH:     UserBearer (Injetado via Auto-Refresh Interceptor)
  // PURPOSE:  Remove o token do dispositivo FCM do hóspede, parando as push notifications.
  //
  // HOW IT WORKS:
  //   1. Envia o `fcm_token` a ser deletado.
  //   2. Invokes onSuccess sem parâmetros em caso de sucesso (204 No Content).
  //   3. Invokes onError em caso de erro.
  //
  // USAGE EXAMPLE:
  //   await Usuario.removeFcmToken(
  //     fcmToken: 'token-que-estava-registrado',
  //     onSuccess: () => print('FCM Token removido!'),
  //     onError: (msg) => logError(msg),
  //   );
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> removeFcmToken({
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
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          onError('Tempo de conexão esgotado. Verifique sua internet.');
        case DioExceptionType.connectionError:
          onError('Sem conexão com o servidor. Verifique sua internet.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          switch (statusCode) {
            case 401:
              onError('Sessão expirada. Faça login novamente.');
            default:
              onError('Erro inesperado (código $statusCode).');
          }
        default:
          onError('Erro inesperado ao remover token do dispositivo.');
      }
    } catch (_) {
      onError('Erro inesperado ao remover token do dispositivo.');
    }
  }
}
