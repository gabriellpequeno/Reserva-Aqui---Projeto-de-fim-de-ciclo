---
name: flutter-api-bridge
description: >
  Generates and maintains `Frontend/lib/utils/API_functions.dart` — the single source of truth
  for all HTTP calls from the Flutter app to the ReservAqui backend. Use this skill whenever
  a developer asks to "add an API function", "criar função de API", "implementar chamada para
  o backend", "adicionar endpoint no Flutter", "conectar tela com a API", or any variation
  of wiring a Flutter screen to a backend route. Also trigger this skill when a developer
  describes a feature that needs API data — even if they don't explicitly mention "API_functions.dart".
  Never rewrite the existing file; always append. Uses Dio as the HTTP client.
---

# Flutter API Bridge

This skill manages the shared API utility layer for the ReservAqui Flutter app. When a
developer describes something they want to do — fetch hotels with available suites in Rio,
log in a user, create a reservation — this skill:

1. **Reads the Swagger** to understand what the backend can actually do
2. **Figures out how** to satisfy the request (one call, multiple calls, client-side filtering)
3. **Writes the Dart function** into `Frontend/lib/utils/API_functions.dart`
4. **Or explains honestly** why it can't be done and what would need to change on the backend

The file grows incrementally — each new function is **appended**, never overwritten.

---

## Project layout

```
ReservAqui/
├── Backend/
│   ├── swagger.yaml            ← PRIMARY source of truth for routes and schemas
│   └── src/
│       ├── app.ts              ← API_PREFIX=/api, PORT=3000
│       └── routes/             ← secondary reference if swagger is ambiguous
└── Frontend/
    └── lib/
        └── utils/
            └── API_functions.dart   ← TARGET FILE (create or append)
```

**Base URL**: `http://localhost:3000/api` (development). Configured once in the shared
`_dio` instance — change only `_baseUrl` for production.

---

## Step 1 — Read the Swagger first

**Always start here.** Open `Backend/swagger.yaml` and find every endpoint relevant to the
developer's request. The Swagger is the authoritative contract: it has paths, HTTP methods,
required/optional parameters, query strings, request body schemas, and response shapes.

Look for:
- `paths` — lists every endpoint with method, auth requirement, request/response
- `parameters` — query params and path params for GET endpoints
- `requestBody` — JSON fields for POST/PATCH endpoints
- `security` — `UserBearer` = authGuard (usuario token), `HotelBearer` = hotelGuard (hotel token)
- `responses` — what the backend actually returns on 200/201

> If you need details about a schema (e.g., what fields `Quarto` has), it's in
> `components/schemas`. Cross-reference freely.

---

## Step 2 — Analyse the developer's intent

The developer may describe something in natural language. Your job is to map it to API
capabilities. There are three possible outcomes:

### ✅ Directly achievable
The backend has one endpoint that does exactly what's needed. Write the function.

### 🔀 Achievable via composition
No single endpoint does it, but combining 2–3 calls (or client-side filtering of a list
response) achieves the goal. Write a function that coordinates the calls internally.
Document clearly how each call contributes.

**Example — "listar hotéis com suítes disponíveis no Rio de Janeiro":**
- The backend has `GET /hotel/catalogo` to list hotels, and `GET /hotel/{hotel_id}/quartos`
  to list rooms for a specific hotel
- There is **no single endpoint** that filters by city AND room type simultaneously
- Solution: fetch all hotels, filter client-side by `cidade === 'Rio de Janeiro'`, then
  for each hotel fetch rooms and filter by `disponivel === true` and category name containing
  "suíte" — document this strategy in the function's HOW IT WORKS section
- Warn the developer about N+1 performance implications and suggest caching or a backend
  endpoint if the list grows large

### ❌ Not achievable — backend needs to evolve

If even composition can't satisfy the request (e.g., the data simply doesn't exist in any
endpoint, or would require a new database query), be transparent:

1. Explain exactly **why** it's not possible today
2. Suggest the **minimum backend change** that would make it possible (new query param,
   new endpoint, new field in an existing response)
3. Optionally write a **stub function** that documents the intended signature and throws
   `UnimplementedError` until the backend is ready

---

## Step 3 — Check `API_functions.dart` for existing functions

Before writing anything:
- If the file **doesn't exist**: create it from scratch with the boilerplate header below
- If the function **already exists**: tell the developer and stop — never duplicate
- If the file **exists but lacks the function**: append only the new function at the end

---

## Step 4 — Write the Dart function

### Function comment block (required for every function)

```dart
// ─────────────────────────────────────────────────────────────────────────────
// FUNCTION: functionName
// ROUTE:    METHOD /path  (relative — base URL is already set in _dio)
//           If composed: lists all routes used, one per line
// AUTH:     none | Bearer (usuario) | Bearer (hotel)
// PURPOSE:  One sentence — what this does for the developer.
//
// HOW IT WORKS:
//   1. [Describe each step]
//   2. Invokes onSuccess with [description of return value] on success.
//   3. Invokes onError with a localized message on HTTP error or validation failure.
//
// PERFORMANCE NOTE (if composed):
//   Makes N+1 requests where N = number of results from the first call.
//
// USAGE EXAMPLE:
//   await functionName(
//     param: 'value',
//     onSuccess: (data) => print(data),
//     onError: (msg) => logError(msg),
//   );
// ─────────────────────────────────────────────────────────────────────────────
```

### Single-endpoint function template

```dart
Future<void> functionName({
  required String param1,
  String? optionalParam,
  required void Function(Map<String, dynamic> data) onSuccess,
  required void Function(String message) onError,
}) async {
  // Client-side format validation before making request
  if (param1.isEmpty) {
    onError('O parâmetro não pode ser vazio.');
    return;
  }

  try {
    final response = await _dio.post<Map<String, dynamic>>(
      '/path/to/endpoint',
      data: {
        'field1': param1,
        if (optionalParam != null) 'field2': optionalParam,
      },
    );
    onSuccess(response.data!);
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
            onError(serverMsg ?? 'Não autenticado.');
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
```

### GET with query parameters

```dart
Future<void> listItems({
  String? cidade,
  required void Function(List<Map<String, dynamic>> items) onSuccess,
  required void Function(String message) onError,
}) async {
  try {
    final response = await _dio.get<List<dynamic>>(
      '/path/to/endpoint',
      queryParameters: {
        if (cidade != null) 'cidade': cidade,
      },
    );
    final data = (response.data ?? []).cast<Map<String, dynamic>>();
    onSuccess(data);
  } on DioException catch (e) {
    // Implement standard DioException handling block here (timeout, badResponse, fallback)
    onError('Erro ao listar itens.');
  } catch (_) {
    onError('Erro inesperado ao listar itens.');
  }
}
```

### Composed function (multiple API calls)

```dart
Future<void> listHoteisComSuiteNoRio({
  String? cidade,
  bool? somenteDisponivel,
  required void Function(List<Map<String, dynamic>> items) onSuccess,
  required void Function(String message) onError,
}) async {
  try {
    // Step 1: list hotels, optionally filter by city client-side
    final hotelsRes = await _dio.get<List<dynamic>>('/hotel/catalogo');
    final hotels = (hotelsRes.data ?? []).cast<Map<String, dynamic>>();
    final filtered = cidade != null
        ? hotels.where((h) =>
            (h['cidade'] as String?)?.toLowerCase() == cidade.toLowerCase())
            .toList()
        : hotels;

    // Step 2: for each hotel, fetch rooms and filter
    final results = <Map<String, dynamic>>[];
    for (final hotel in filtered) {
      final roomsRes = await _dio.get<List<dynamic>>('/hotel/${hotel['hotel_id']}/quartos');
      final rooms = (roomsRes.data ?? []).cast<Map<String, dynamic>>();
      final suites = rooms.where((r) {
        final isSuite = (r['tipo'] as String? ?? '').toLowerCase().contains('suite') ||
            (r['tipo'] as String? ?? '').toLowerCase().contains('suíte');
        final disponivel = somenteDisponivel == true ? r['disponivel'] == true : true;
        return isSuite && disponivel;
      }).toList();
      if (suites.isNotEmpty) {
        results.add({...hotel, 'quartos_disponiveis': suites});
      }
    }
    onSuccess(results);
  } on DioException catch (e) {
    // Standard error handling
    onError('Erro ao buscar hotéis compostos.');
  } catch (_) {
    onError('Erro inesperado.');
  }
}
```

### Return types

Adapt to what the route actually yields via `onSuccess`:
- Single object → `onSuccess(Map<String, dynamic> data)`
- List → `onSuccess(List<Map<String, dynamic>> list)`
- No body (DELETE 204) → `onSuccess()` with no parameters
- Tokens → `onSuccess(Map<String, dynamic> user, String access, String refresh)`

---

## Step 5 — File boilerplate (first-time creation only)

```dart
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
```

---

## Step 6 — Ensure `dio` is in pubspec.yaml

Check `Frontend/pubspec.yaml`. If `dio:` is missing under `dependencies`, add it:

```yaml
dependencies:
  dio: ^5.7.0
```

Remind the developer to run `flutter pub get`.

---

## Step 7 — Report back

Tell the developer:
- The **function signature** (name, parameters, return type)
- How to import: `import 'package:reservaqui/utils/API_functions.dart';`
- A **minimal usage snippet** for their specific case
- If the solution is composed: explain the strategy and any performance trade-offs

---

## Code quality rules

- **Stateless/Interceptor** — no explicit tokens passed to functions. The auto-refresh interceptor handles authentication headers behind the scenes.
- **Callback Pattern** — ALWAYS use `onSuccess(...)` and `onError(String message)`. NO try-catch blocks in the UI. Functions catch all `DioException`s and map status codes to user-friendly messages for `onError`.
- **camelCase params, snake_case JSON** — map them explicitly inside the function body
- **Comments in English** — user-facing strings in Portuguese
- **Field names from Swagger** — copy them exactly from the schema to avoid silent 400s
- **Composed functions are OK** — but always document the N+1 risk and suggest a backend
  solution when appropriate

---

## Route cheat sheet (Swagger `servers.url` = `http://localhost:3000/api`)

| Feature                           | Swagger path prefix              | Auth              |
|-----------------------------------|----------------------------------|-------------------|
| Login/registro usuário            | `/usuarios`                      | none / UserBearer |
| Login/registro hotel              | `/hotel`                         | none / HotelBearer|
| Catálogo de hotéis públicos       | `/hotel/catalogo`                | none              |
| Perfil do hotel autenticado       | `/hotel/me`                      | HotelBearer       |
| Quartos do hotel                  | `/hotel/quartos`                 | HotelBearer       |
| Categorias de quarto              | `/hotel/categorias-quarto`       | HotelBearer       |
| Reservas (hotel)                  | `/hotel/reservas`                | HotelBearer       |
| Reservas (usuário)                | `/usuarios/reservas`             | UserBearer        |
| Avaliações (usuário)              | `/usuarios/avaliacoes`           | UserBearer        |
| Avaliações (público)              | `/hotel/{hotel_id}/avaliacoes`   | none              |
| Upload de fotos                   | `/uploads`                       | HotelBearer       |
| Notificações push (FCM)           | `/dispositivos-fcm`              | UserBearer        |
| Saldo e saques                    | `/hotel/saldo`                   | HotelBearer       |
| Pagamentos                        | `/hotel/reservas/:id/pagamentos` | HotelBearer       |
| Consulta pública de reserva       | `/reservas/:codigo_publico`      | none              |
