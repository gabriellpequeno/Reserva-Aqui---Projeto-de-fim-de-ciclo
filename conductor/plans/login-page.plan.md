# Plan — Login Page (P2-A)

> Derivado de: `conductor/specs/login-page.spec.md`
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

> Sem novas dependências de pacote. Todos os pacotes (`dio`, `flutter_riverpod`,
> `go_router`, `shared_preferences`) já estão no `pubspec.yaml`.
> `AuthResponse`, `AuthNotifier` e `authServiceProvider` já existem e são reutilizados sem alteração.

- [x] Confirmar que `POST /usuarios/login` retorna `{ data: usuario, tokens: { accessToken, refreshToken } }`
- [x] Confirmar que `POST /hotel/login` retorna `{ data: hotel, tokens: { accessToken, refreshToken } }`

---

## Backend [CONCLUÍDO]

> Nenhum endpoint criado ou modificado. Ambos os endpoints já existem e estão operacionais.

- [x] Sanity check: `POST /usuarios/login` com credenciais válidas de hóspede → 200 + tokens
- [x] Sanity check: `POST /hotel/login` com credenciais válidas de anfitrião → 200 + tokens

---

## Frontend [CONCLUÍDO]

### 1. Service — Adicionar `loginGuest` ao `AuthService` [CONCLUÍDO]

- [x] **Modificar** `lib/features/auth/data/services/auth_service.dart`
  - Adicionar método `loginGuest(String email, String senha) → Future<AuthResponse>`
  - Chamada: `POST /usuarios/login` com body `{ 'email': email, 'senha': senha }`
  - Retorno: `AuthResponse.fromJson(response.data!)` — mesmo padrão do `loginHotel` existente

---

### 2. Roteamento — Corrigir navbar para não autenticados [CONCLUÍDO]

- [x] **Modificar** `lib/core/layouts/main_layout.dart`
  - Em `_navigateToProfile`: trocar `context.go('/auth')` por `context.go('/auth/login')` no branch `else` (usuário não autenticado)
  - Verificar que o redirect do router em `app_router.dart` (`!isAuthenticated && isProtected → '/auth/login'`) já aponta para `/auth/login` — se ainda apontar para `/auth`, corrigir também

---

### 3. `UserOrHostPage` — Adicionar fluxo de login com role [CONCLUÍDO]

- [x] **Modificar** `lib/features/auth/presentation/pages/user_or_host_page.dart`
  - Adicionar seção de login na página com dois botões:
    - `"Entrar como Hóspede"` → `context.push('/auth/login', extra: {'role': 'guest'})`
    - `"Entrar como Anfitrião"` → `context.push('/auth/login', extra: {'role': 'host'})`
  - Atualizar ou remover o `TextButton` "Já tem uma conta? Entrar" existente — se mantido, passar `extra: {'role': 'guest'}` como padrão
  - Avaliar layout durante implementação: botões empilhados abaixo dos de cadastro, ou separador visual entre as duas seções

---

### 4. `LoginPage` — Converter e integrar [CONCLUÍDO]

- [x] **Modificar** `lib/features/auth/presentation/pages/login_page.dart`
  - Converter de `StatelessWidget` para `ConsumerStatefulWidget`
  - Declarar variáveis de estado:
    - `final _formKey = GlobalKey<FormState>()`
    - `final _emailController = TextEditingController()`
    - `final _senhaController = TextEditingController()`
    - `bool _isLoading = false`
    - `late String _role` — populado no `didChangeDependencies()` a partir de `GoRouterState.of(context).extra`
  - Implementar `dispose()` para os dois controllers
  - Ler role em `didChangeDependencies()`:
    ```dart
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _role = extra?['role'] as String? ?? 'guest';
    ```
  - Envolver the `Column` in `Form(key: _formKey)`
  - Substituir os dois `AuthTextField` estáticos por versões com `controller` e `validator`:
    - Email: não vazio + regex `r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$'`
    - Senha: não vazio (sem validação de complexidade — responsabilidade do backend)
  - Implementar método `_submit()`:
    - `if (!_formKey.currentState!.validate()) return`
    - `setState(() => _isLoading = true)`
    - `try`: chamar `loginGuest` ou `loginHotel` conforme `_role`
    - Em sucesso: `authProvider.notifier.setAuth(access, refresh, AuthRole.guest|host)` → `if (mounted) context.go('/home')`
    - `catch DioException`: switch no `statusCode` → 401/429/default → SnackBar
    - `finally`: `if (mounted) setState(() => _isLoading = false)`
  - Substituir `PrimaryButton` "Login" por condicional loading:
    ```dart
    _isLoading
        ? const Center(child: CircularProgressIndicator())
        : PrimaryButton(text: 'Login', onPressed: _submit)
    ```
  - **Remover** os dois `SocialButton` (Google e Apple) e o `Row` separador "ou"
  - Manter `PrimaryButton` "cadastre-se agora" com `context.go('/auth')`

---

## Validação [CONCLUÍDO]

- [x] Executar `flutter analyze lib/` — zero erros novos introduzidos por esta feature
- [x] **Fluxo feliz — hóspede:** navbar (não autenticado) → `LoginPage` → preencher e-mail e senha válidos de hóspede → "Login" → `POST /usuarios/login` chamado → `setAuth(AuthRole.guest)` → navega para `/home`
- [x] **Fluxo feliz — anfitrião:** `UserOrHostPage` "Entrar como Anfitrião" → `LoginPage` → credenciais válidas de anfitrião → "Login" → `POST /hotel/login` chamado → `setAuth(AuthRole.host)` → navega para `/home`
- [x] **Credenciais inválidas (401):** e-mail ou senha errados → SnackBar "E-mail ou senha incorretos." — tela permanece aberta
- [x] **Rate limit (429):** múltiplas tentativas rápidas → SnackBar "Muitas tentativas. Aguarde alguns minutos e tente novamente."
- [x] **Validação local — e-mail vazio:** tocar "Login" sem preencher → erro inline no campo e-mail; sem chamada à API
- [x] **Validação local — e-mail inválido:** digitar `"abc"` → erro inline "E-mail inválido"; sem chamada à API
- [x] **Validação local — senha vazia:** tocar "Login" sem senha → erro inline; sem chamada à API
- [x] **Double-submit bloqueado:** tocar "Login" duas vezes rapidamente → somente uma requisição disparada
- [x] **Botões sociais removidos:** Google, Apple e separador "ou" não aparecem na tela
- [x] **Navbar corrigida:** usuário não autenticado toca ícone de perfil → vai para `LoginPage` (não para `UserOrHostPage`)
- [x] **"cadastre-se agora" funcional:** botão na `LoginPage` navega para `/auth` (`UserOrHostPage`)
- [x] **`mounted` check:** navegar para fora da tela durante submit → sem `setState after dispose` no console
- [x] **Sessão persistida:** após login bem-sucedido, fechar e reabrir o app → usuário permanece autenticado

---

## Regra de Atualização de Status

- Todas `[ ]` → `[PENDENTE]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`

Quando todas as seções estiverem `[CONCLUÍDO]`, atualizar o **Status geral** para `[CONCLUÍDO]`
e sincronizar com `conductor/plan.md`:
- Localizar bloco **"Fase 1 — Autenticação"**
- Marcar `[x]` na task: `- [ ] Tela de login no app (e-mail/senha + Google)`
- Adicionar sub-entry: `  - [x] Login page integrada (P2-A) — plan: plans/login-page.plan.md`
