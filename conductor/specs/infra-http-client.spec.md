# Spec — infra-http-client

## Referência
- **PRD:** conductor/features/infra-http-client.prd.md

## Abordagem Técnica

Criar uma camada de infraestrutura de rede e autenticação baseada em Riverpod com três responsabilidades isoladas:

1. **`AuthNotifier`** — fonte de verdade do estado de autenticação. Persiste tokens via `shared_preferences` e expõe métodos para login, logout e clear. É um `AsyncNotifier` para tratar a leitura assíncrona do storage na inicialização.

2. **`DioClient`** — instância Dio encapsulada em um Riverpod `Provider`. Recebe o `AuthNotifier` via `ref` e configura os interceptores de auth (Bearer token) e auto-refresh com fila de requisições pendentes. O endpoint de refresh é selecionado dinamicamente com base no `AuthRole` do estado atual.

3. **`UsuarioService` / `HotelService`** — classes que substituem os métodos estáticos com singleton Dio próprio. Recebem o Dio injetado via construtor e são expostos como Riverpod `Provider`s. Mantêm o padrão de callbacks (`onSuccess`/`onError`) pois as páginas P1+ ainda vão ser implementadas — a migração para `async/await` é escopo de P1.

O `main.dart` será reescrito para usar `ProviderScope` e `GoRouter` via `routerProvider`. O `app_router.dart` passa a escutar o `authProvider` para decidir redirects.

## Componentes Afetados

### Frontend
- **Novo:** `AuthRole` enum + `AuthState` classe imutável (`lib/core/auth/auth_state.dart`)
- **Novo:** `AuthNotifier` + `authProvider` (`lib/core/auth/auth_notifier.dart`)
- **Novo:** `DioClient` + `dioProvider` (`lib/core/network/dio_client.dart`)
- **Modificado:** `lib/utils/Usuario.dart` — converte de static class com Dio próprio para `UsuarioService` + `usuarioServiceProvider`
- **Modificado:** `lib/utils/Hotel.dart` — implementado do zero como `HotelService` + `hotelServiceProvider`
- **Modificado:** `lib/main.dart` — reescrito com `ProviderScope` + `GoRouter`
- **Modificado:** `lib/core/router/app_router.dart` — remove `MockAuth`, usa `authProvider`
- **Removido:** `lib/core/mocks/mock_auth.dart`

### Backend
- Nenhuma alteração. Os endpoints já existem e estão documentados.

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| Dio como Riverpod Provider (não singleton global) | Permite injetar `AuthNotifier` via `ref`, eliminando acoplamento via callbacks globais (`onSessionExpired`). Facilita testes com override de providers. |
| `AsyncNotifier` para `AuthNotifier` | A inicialização lê `shared_preferences`, que é assíncrona. `AsyncNotifier.build()` trata isso nativamente, expondo `AsyncValue<AuthState>` ao router. |
| Manter callbacks (`onSuccess`/`onError`) em `UsuarioService` | As páginas P1+ ainda serão implementadas; migrar o padrão de callback agora seria scope creep. O padrão funciona bem com `ConsumerStatefulWidget`. |
| `AuthRole` determina o endpoint de refresh | `guest` → `POST /usuarios/refresh`, `host` → `POST /hotel/refresh`. Sem essa distinção, anfitriões não conseguem renovar tokens. |
| Fila de pending requests durante refresh | Evita múltiplas chamadas concorrentes de refresh quando N requisições retornam 401 simultaneamente. |
| `shared_preferences` para persistência de tokens | Já está no `pubspec.yaml`, suporta iOS/Android/Web, API simples. Suficiente para o MVP. |

## Contratos de API

Endpoints consumidos por esta feature (já existentes no backend):

| Método | Rota | Body | Response |
|--------|------|------|----------|
| POST | `/usuarios/refresh` | `{ refreshToken: string }` | `{ tokens: { accessToken, refreshToken } }` |
| POST | `/hotel/refresh` | `{ refreshToken: string }` | `{ tokens: { accessToken, refreshToken } }` |
| POST | `/usuarios/logout` | `{ refreshToken: string }` | `{ message: string }` |
| POST | `/hotel/logout` | `{ refreshToken: string }` | `{ message: string }` |

## Modelos de Dados

```
AuthRole {
  guest   // hóspede — usa endpoints /usuarios/*
  host    // anfitrião — usa endpoints /hotel/*
}

AuthState {
  accessToken:  String?    // null = não autenticado
  refreshToken: String?
  role:         AuthRole?
  isAuthenticated: bool    // computed: accessToken != null && role != null
}
```

Persistência no `shared_preferences`:
```
Chave                   Tipo     Valor
auth_access_token       String   accessToken JWT
auth_refresh_token      String   refreshToken
auth_role               String   "guest" | "host"
```

## Dependências

**Bibliotecas (já no pubspec.yaml):**
- [x] `dio` 5.7.0 — cliente HTTP
- [x] `flutter_riverpod` 3.3.1 — gerenciamento de estado
- [x] `shared_preferences` 2.5.5 — persistência de tokens
- [x] `go_router` 17.2.1 — roteamento

**Outras features:**
- Nenhuma — esta feature é pré-requisito de todas as outras.

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| `shared_preferences` no web armazena em `localStorage` (não criptografado) | Aceitável para MVP; para produção, avaliar `flutter_secure_storage`. |
| `dioProvider` recria o Dio a cada rebuild se o provider pai mudar | Usar `ref.read` (não `ref.watch`) dentro dos interceptores para evitar rebuild em cascata. |
| Router reagindo antes do `authProvider` terminar de carregar do storage | Tratar `AsyncValue.loading` no redirect do router — não redirecionar até o estado ser resolvido. |
| Race condition: múltiplos 401 simultâneos disparam múltiplos refreshes | A flag `_isRefreshing` e a fila `_pendingQueue` já resolvem isso na implementação do interceptor. |
