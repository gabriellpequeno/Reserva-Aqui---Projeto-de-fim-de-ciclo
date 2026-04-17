import 'package:dio/dio.dart';

// ─────────────────────────────────────────────────────────────────────────────
// API_functions.dart
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
final _pendingQueue = <({RequestOptions options, ErrorInterceptorHandler handler})>[];

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
          setTokens(tokens['accessToken'] as String, tokens['refreshToken'] as String);

          for (final pending in _pendingQueue) {
            pending.options.headers['Authorization'] = 'Bearer $_accessToken';
            dio.fetch(pending.options).then(
              (r) => pending.handler.resolve(r),
              onError: (e) => pending.handler.reject(e as DioException),
            );
          }
          _pendingQueue.clear();

          error.requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
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
//   await registerUser(
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
Future<void> registerUser({
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
  if (nomeCompleto.trim().isEmpty || email.trim().isEmpty || senha.isEmpty || cpf.trim().isEmpty || dataNascimento.trim().isEmpty) {
    onError('Preencha todos os campos obrigatórios.');
    return;
  }

  if (senha != confirmarSenha) {
    onError('As senhas não coincidem.');
    return;
  }

  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d])').hasMatch(senha)) {
    onError('A senha deve conter maiúscula, minúscula, número e caractere especial.');
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
      onError('Número de celular deve conter exatamente 11 números (com DDD).');
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
            onError(serverMsg ?? 'Dados inválidos. Verifique os campos e tente novamente.');
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
// FUNCTION: loginUser
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
//   await loginUser(
//     email: 'joao@email.com',
//     senha: 'Senha@123',
//     onSuccess: (usuario) {
//       print('Logado como: ${usuario['nome_completo']}');
//       Navigator.pushReplacementNamed(context, '/home');
//     },
//     onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(...),
//   );
// ─────────────────────────────────────────────────────────────────────────────
Future<void> loginUser({
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
      data: {
        'email': email.trim(),
        'senha': senha,
      },
    );
    
    final responseData = response.data!;
    final tokens = responseData['tokens'] as Map<String, dynamic>;
    final usuario = responseData['data'] as Map<String, dynamic>;
    
    // Grava os tokens na memória para que o interceptor os use nas próximas chamadas
    setTokens(tokens['accessToken'] as String, tokens['refreshToken'] as String);
    
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
// FUNCTION: logoutUser
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
//   await logoutUser(
//     onSuccess: () => Navigator.pushReplacementNamed(context, '/login'),
//     onError: (msg) => logError(msg),
//   );
// ─────────────────────────────────────────────────────────────────────────────
Future<void> logoutUser({
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
// FUNCTION: getUsuarioAutenticado
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
//   await getUsuarioAutenticado(
//     onSuccess: (usuario) {
//       print('Meu Perfil: \${usuario["nome_completo"]}');
//     },
//     onError: (msg) => print(msg),
//   );
// ─────────────────────────────────────────────────────────────────────────────
Future<void> getUsuarioAutenticado({
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
// FUNCTION: updateUsuario
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
//   await updateUsuario(
//     nomeCompleto: _nomeController.text,
//     // Deixe os outros parametros de fora ou passe null se não quiser mudar
//     onSuccess: (usuario) {
//       print('Nome alterado para: \${usuario["nome_completo"]}');
//     },
//     onError: (msg) => print(msg),
//   );
// ─────────────────────────────────────────────────────────────────────────────
Future<void> updateUsuario({
  String? nomeCompleto,
  String? email,
  String? dataNascimento,
  String? numeroCelular,
  required void Function(Map<String, dynamic> usuario) onSuccess,
  required void Function(String message) onError,
}) async {
  if (email != null && email.trim().isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
    onError('E-mail inválido.');
    return;
  }

  if (dataNascimento != null && dataNascimento.trim().isNotEmpty && !RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dataNascimento)) {
    onError('Data de nascimento deve estar no formato DD/MM/AAAA.');
    return;
  }

  String? cleanCelular;
  if (numeroCelular != null && numeroCelular.trim().isNotEmpty) {
    cleanCelular = numeroCelular.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCelular.length != 11) {
      onError('Número de celular deve conter exatamente 11 números (com DDD).');
      return;
    }
  }

  final data = <String, dynamic>{
    if (nomeCompleto != null && nomeCompleto.trim().isNotEmpty) 'nome_completo': nomeCompleto.trim(),
    if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    if (dataNascimento != null && dataNascimento.trim().isNotEmpty) 'data_nascimento': dataNascimento.trim(),
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
            onError(serverMsg ?? 'Dados inválidos. Verifique os campos e tente novamente.');
          case 401:
            onError(serverMsg ?? 'Sessão expirada. Faça login novamente.');
          case 409:
            onError(serverMsg ?? 'O e-mail informado já está em uso por outra conta.');
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
// FUNCTION: changePasswordUser
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
//   await changePasswordUser(
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
Future<void> changePasswordUser({
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

  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d])').hasMatch(novaSenha)) {
    onError('A nova senha deve conter maiúscula, minúscula, número e caractere especial.');
    return;
  }

  try {
    await _dio.post<Map<String, dynamic>>(
      '/usuarios/change-password',
      data: {
        'senhaAtual': senhaAtual,
        'novaSenha': novaSenha,
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
        final body = e.response?.data;
        final serverMsg = body is Map
            ? (body['error'] ?? body['message'])?.toString()
            : null;
        switch (statusCode) {
          case 400:
            onError(serverMsg ?? 'Dados inválidos. Verifique as senhas e tente novamente.');
          case 401:
            // Pode ser token expirado de vez ou a senhaAtual passada está incorreta
            onError(serverMsg ?? 'A senha atual está incorreta ou sua sessão expirou.');
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
