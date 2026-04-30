# Plan — auth-logout-bugfix

> Status geral: [PENDENTE]

---

## Diagnóstico

### Bug 1 — `clear()` nunca é chamado no logout (causa raiz)

Ambas as páginas de perfil chamam apenas `context.go('/auth')` no botão "sair" — sem chamar `authProvider.notifier.clear()`. Resultado:

| Consequência | Por quê |
|---|---|
| Token permanece ativo no `SharedPreferences` | `clear()` nunca é chamado |
| `AuthState` permanece `isAuthenticated = true` no Riverpod | Estado não é limpo |
| Aba de perfil volta para o perfil | Router vê usuário autenticado e navega normalmente |
| FCM token **não** é removido do backend | `_removeFcmToken` dentro de `clear()` nunca executa |

**Arquivos:** `user_profile_page.dart:97` e `host_profile_page.dart:122`

---

### Bug 2 — Roteamento pós-logout vai para cadastro

`context.go('/auth')` aponta para `UserOrHostPage` (tela de escolha hóspede/host — visualmente parece cadastro). O destino correto é `/auth/login`.

---

### Bug 3 — Refresh token não é invalidado no backend

`authProvider.notifier.clear()` limpa o estado local mas **não chama** o endpoint REST de logout (`POST /usuarios/logout` ou `POST /hotel/logout`). O refresh token fica válido no banco de dados do backend até expirar.

**Observação:** `utils/Usuario.dart` e `utils/Hotel.dart` têm funções de logout REST prontas mas não são usadas.

---

## Correções

### Fix 1 — `user_profile_page.dart` — chamar `clear()` e navegar para login

```dart
// ANTES
onPressed: () => context.go('/auth'),

// DEPOIS
onPressed: () async {
  await ref.read(authProvider.notifier).clear();
  if (context.mounted) context.go('/auth/login');
},
```

### Fix 2 — `host_profile_page.dart` — mesmo fix

```dart
// ANTES
onPressed: () => context.go('/auth'),

// DEPOIS
onPressed: () async {
  await ref.read(authProvider.notifier).clear();
  if (context.mounted) context.go('/auth/login');
},
```

### Fix 3 — `auth_notifier.dart` — invalidar refresh token no backend

Adicionar chamada REST ao `clear()`, por role, antes de limpar o estado local:

```dart
Future<void> clear() async {
  final role         = state.asData?.value.role;
  final refreshToken = state.asData?.value.refreshToken;

  // Remove FCM token (fire-and-forget)
  if (role != null) _removeFcmToken(role);

  // Invalida refresh token no backend (fire-and-forget — falha não bloqueia logout)
  if (refreshToken != null && role != null) {
    _callLogoutEndpoint(role, refreshToken);
  }

  final prefs = await SharedPreferences.getInstance();
  await Future.wait([
    prefs.remove(_accessKey),
    prefs.remove(_refreshKey),
    prefs.remove(_roleKey),
  ]);
  state = const AsyncData(AuthState());
}

void _callLogoutEndpoint(AuthRole role, String refreshToken) {
  // Usar DioClient — fire-and-forget, o backend invalida o token no banco
  // endpoint: POST /usuarios/logout ou POST /hotel/logout
  // body: { refresh_token: refreshToken }
}
```

> **Nota:** verificar qual campo o backend espera no body do logout antes de implementar.

---

## Tasks

### Correções de UI [CONCLUÍDO]

- [x] `user_profile_page.dart`: substituir `context.go('/auth')` por `await clear()` + `context.go('/auth/login')`
- [x] `host_profile_page.dart`: mesma correção

### Correções de AuthNotifier [CONCLUÍDO]

- [x] `auth_notifier.dart`: adicionar chamada REST de logout no `clear()` por role
- [x] Endpoint confirmado: `POST /usuarios/logout` e `POST /hotel/logout` — body `{ refreshToken }`

### Validação [PENDENTE]

- [ ] Logout como hóspede → vai para `/auth/login` ✅
- [ ] Logout como hotel → vai para `/auth/login` ✅
- [ ] Após logout, apertar aba de perfil → permanece em `/auth/login` (não volta para perfil) ✅
- [ ] Após logout, refresh token não funciona mais no backend ✅
- [ ] Após logout, FCM token removido do backend ✅

---

## Arquivos a modificar

| Arquivo | Linha | O que muda |
|---------|-------|-----------|
| `lib/features/profile/presentation/pages/user_profile_page.dart` | ~97 | `onPressed` do botão "sair" |
| `lib/features/profile/presentation/pages/host_profile_page.dart` | ~122 | `onPressed` do botão "sair" |
| `lib/core/auth/auth_notifier.dart` | `clear()` | Adicionar chamada REST de logout |
