# Spec — Login Page (P2-A)

## Referência
- **PRD:** `conductor/features/login-page.prd.md`
- **Task:** `_tasks/integration/P2-A-login-page.md`
- **Arquivo principal:** `Frontend/lib/features/auth/presentation/pages/login_page.dart`
- **Branch sugerida:** `feat/login-page-integration`

---

## Abordagem Técnica

Converter `LoginPage` de `StatelessWidget` para `ConsumerStatefulWidget` (Riverpod), seguindo o padrão já estabelecido em `UserSignUpPage` e `HostSignUpPage`.

O desafio central desta feature é **detectar o role do usuário** sem adicionar um seletor dentro da tela de login. A solução: `UserOrHostPage` passa o role via GoRouter `extra` ao navegar para `/auth/login`. A `LoginPage` lê esse valor no `build()` e escolhe qual endpoint chamar.

Fluxo de submit:
1. `Form.validate()` — email e senha
2. `authService.loginGuest(email, senha)` **ou** `authService.loginHotel(email, senha)` conforme role
3. `authProvider.notifier.setAuth(access, refresh, role)`
4. `context.go('/home')`

Estado de loading local (`setState`) — sem `StateNotifier` dedicado, idêntico ao padrão das páginas de signup.

Os botões de Google, Apple e o separador "ou" são **removidos** da UI nesta entrega.

---

## Componentes Afetados

### Backend
- Nenhum. `POST /usuarios/login` e `POST /hotel/login` já existem e estão operacionais.

### Frontend

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Modificado** | `lib/features/auth/presentation/pages/login_page.dart` | Converter para `ConsumerStatefulWidget`; adicionar controllers, Form, validação, role via `extra`, loading, chamada real à API, remoção dos botões sociais |
| **Modificado** | `lib/features/auth/presentation/pages/user_or_host_page.dart` | Adicionar botões "Entrar como Hóspede" / "Entrar como Anfitrião" que navegam para `/auth/login` com `extra: {'role': 'guest'|'host'}` |
| **Modificado** | `lib/features/auth/data/services/auth_service.dart` | Adicionar `loginGuest(email, senha)` → `AuthResponse` |
| **Modificado** | `lib/core/layouts/main_layout.dart` | `_navigateToProfile`: trocar `context.go('/auth')` por `context.go('/auth/login')` quando não autenticado |

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| Role passado via GoRouter `extra` em vez de seletor na `LoginPage` | `UserOrHostPage` já discrimina guest/host antes do login; adicionar um seletor duplicaria essa lógica e pioraria o fluxo — dois passos se tornam um |
| Fallback `'guest'` quando `extra` é null | Protege contra acesso direto à rota `/auth/login` (ex: redirect do router para rota protegida) sem quebrar o fluxo |
| `loginGuest()` adicionado ao `AuthService` existente | Mantém todos os métodos de auth agrupados; evita criar novo arquivo para um único método |
| `ConsumerStatefulWidget` sem `StateNotifier` dedicado | Estado de loading é local e transitório; sem necessidade de compartilhamento — padrão já estabelecido |
| Remover botões Google/Apple em vez de ocultar com `Visibility` | Código morto aumenta ruído; quando SSO for implementado, os botões serão readicionados com lógica real |
| `context.go('/home')` após `setAuth` | Limpa o stack de auth, impedindo o usuário de voltar à tela de login com Back |
| Navbar (não autenticado) aponta para `/auth/login` em vez de `/auth` | `LoginPage` é o ponto de entrada natural para quem quer acessar a conta; o cadastro fica no passo seguinte via "cadastre-se agora" — reduz o atrito para o fluxo mais comum (login) |

---

## Contrato de API

| Método | Rota | Body | Response (2xx) |
|--------|------|------|----------------|
| POST | `/usuarios/login` | `{ email, senha }` | 200 `{ data: usuario, tokens: { accessToken, refreshToken } }` |
| POST | `/hotel/login` | `{ email, senha }` | 200 `{ data: hotel, tokens: { accessToken, refreshToken } }` |

### Erros esperados

| Status | Origem | Mensagem ao usuário |
|--------|--------|---------------------|
| 401 | ambos | "E-mail ou senha incorretos." |
| 429 | ambos | "Muitas tentativas. Aguarde alguns minutos e tente novamente." |
| 5xx | ambos | "Erro no servidor. Tente novamente mais tarde." |

---

## Modelos de Dados

```dart
// Reutilizado sem alteração:
// lib/features/auth/data/models/auth_response.dart
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  // fromJson lê json['tokens']['accessToken'] e json['tokens']['refreshToken']
}
```

### Adição em `auth_service.dart`

```dart
// Novo: login de hóspede
Future<AuthResponse> loginGuest(String email, String senha) async {
  final response = await _dio.post<Map<String, dynamic>>(
    '/usuarios/login',
    data: {'email': email, 'senha': senha},
  );
  return AuthResponse.fromJson(response.data!);
}
```

---

## Passagem de Role via GoRouter

### Em `user_or_host_page.dart`

A página atual só tem botões de cadastro. Precisam ser adicionados botões de login que passam o role:

```dart
// Botão login hóspede
onPressed: () => context.push('/auth/login', extra: {'role': 'guest'})

// Botão login anfitrião
onPressed: () => context.push('/auth/login', extra: {'role': 'host'})
```

> O TextButton "Já tem uma conta? Entrar" existente deve ser atualizado para também passar `extra: {'role': 'guest'}` como padrão (ou removido em favor dos dois botões explícitos — decisão de UX a definir na implementação).

### Em `login_page.dart`

```dart
// Leitura do role no initState ou diretamente no build:
final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
final role = extra?['role'] as String? ?? 'guest';
```

> `role` deve ser armazenado em variável de instância (`late final String _role`) para uso no `_submit()`.

---

## Fluxo de Execução (Submit)

```
[Usuário toca "Login"]
        │
        ▼
[Form.validate()] ──INVÁLIDO──► Erros inline nos campos, interrompe
        │ VÁLIDO
        ▼
[isLoading = true] → botão → CircularProgressIndicator
        │
        ▼
[_role == 'guest'?]
  ├─ SIM → authService.loginGuest(email, senha)   ← POST /usuarios/login
  └─ NÃO → authService.loginHotel(email, senha)   ← POST /hotel/login
        │
        ├─ ERRO (DioException)
        │    ├─ 401 ──► SnackBar "E-mail ou senha incorretos."
        │    ├─ 429 ──► SnackBar "Muitas tentativas. Aguarde alguns minutos..."
        │    └─ 5xx ──► SnackBar "Erro no servidor. Tente novamente mais tarde."
        │               [isLoading = false]
        │ SUCESSO
        ▼
[authProvider.notifier.setAuth(access, refresh, role == 'guest' ? AuthRole.guest : AuthRole.host)]
        │
        ▼
[if (mounted)] context.go('/home')
```

---

## Validações Locais (antes do POST)

| Campo | Regra |
|-------|-------|
| `email` | Não vazio; formato válido via `RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$')` |
| `senha` | Não vazio; mínimo 1 caractere (validação de complexidade é responsabilidade do backend) |

> Login não valida complexidade de senha — é papel do backend retornar 401. Validar senha fraca no login seria UX ruim (usuário com senha antiga "fraca" não conseguiria entrar).

---

## Dependências

**Bibliotecas (já no projeto):**
- [x] `flutter_riverpod` — `ConsumerStatefulWidget`, acesso a `authProvider` e `authServiceProvider`
- [x] `dio` — via `authServiceProvider`
- [x] `go_router` — leitura de `extra` e redirecionamento via `context.go('/home')`
- [x] `shared_preferences` — usado internamente por `AuthNotifier.setAuth`

**Outras features:**
- [x] P0 — `AuthNotifier` (`authProvider`) — `setAuth(access, refresh, role)`
- [x] P1-A — rota `/home` já definida no `ShellRoute` do `app_router.dart`
- [x] P1-B / P1-C — contas de hóspede e anfitrião existentes para teste do fluxo

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| `GoRouterState.of(context).extra` lança exceção se acessado antes do widget estar na árvore | Ler `extra` dentro do `build()` ou no `didChangeDependencies()`, não no `initState()` |
| `extra` é `null` quando usuário acessa `/auth/login` via navbar (`MainLayout` não passa `extra`) | Fallback `?? 'guest'` garante que o fluxo não quebra — usuário pode selecionar role explicitamente após chegar na tela |
| Double-submit (toque duplo no botão) | `isLoading = true` desabilita o botão imediatamente antes da chamada |
| `context.go('/home')` após widget desmontado | `if (mounted)` antes de navegar no bloco `try/finally` |
| Rate limiting (429) pode confundir o usuário se a mensagem não for clara | Mensagem explícita com instrução de tempo de espera |
| `UserOrHostPage` com dois conjuntos de botões (cadastro + login) pode ficar verbosa | Avaliar layout durante implementação — pode usar abas ou seções separadas |
