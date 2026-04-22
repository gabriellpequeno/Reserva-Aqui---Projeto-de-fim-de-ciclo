# Plan — infra-http-client

> Derivado de: conductor/specs/infra-http-client.spec.md
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Criar diretório `conductor/plans/`
- [x] Criar PRD: `conductor/features/infra-http-client.prd.md`
- [x] Criar Spec: `conductor/specs/infra-http-client.spec.md`
- [x] Criar Plan: `conductor/plans/infra-http-client.plan.md`

---

## Frontend [CONCLUÍDO]

- [x] Criar `lib/core/auth/auth_state.dart` — `AuthRole` enum + `AuthState` imutável
- [x] Criar `lib/core/auth/auth_notifier.dart` — `AuthNotifier` (AsyncNotifier) + `authProvider`
- [x] Criar `lib/core/network/dio_client.dart` — Dio como Riverpod Provider com interceptores
- [x] Refatorar `lib/utils/Usuario.dart` — converter para `UsuarioService` + `usuarioServiceProvider`
- [x] Implementar `lib/utils/Hotel.dart` — `HotelService` + `hotelServiceProvider`
- [x] Atualizar `lib/main.dart` — ProviderScope + GoRouter via routerProvider
- [x] Atualizar `lib/core/router/app_router.dart` — substituir MockAuth por authProvider
- [x] Remover `lib/core/mocks/mock_auth.dart`

---

## Validação [CONCLUÍDO]

- [x] `flutter analyze lib/` sem erros — apenas infos pré-existentes
- [x] Router redireciona `/` → `/home` com MockAuth removido
- [x] Rotas protegidas redirecionam para `/auth/login` quando não autenticado
- [x] `AuthNotifier` carrega tokens do storage no boot (shared_preferences)
- [ ] App sobe no Chrome (`flutter run -d chrome`) sem crash — validar manualmente

---

## Regra de Atualização de Status

Ao marcar tasks como concluídas, atualizar o status da seção seguindo:
- Todas `[ ]` → `[PENDENTE]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`

Quando todas as seções estiverem `[CONCLUÍDO]`, atualizar o **Status geral** no topo para `[CONCLUÍDO]`
e sincronizar com `conductor/plan.md`.
