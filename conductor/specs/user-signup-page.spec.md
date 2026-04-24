# Spec — User Signup Page (P1-B)

## Referência
- **PRD:** `conductor/features/user-signup-page.prd.md`
- **Arquivo principal:** `Frontend/lib/features/auth/presentation/pages/user_signup_page.dart`
- **Branch:** `feat/user-signup-page-integration`

---

## Abordagem Técnica

Converter `UserSignUpPage` de `StatelessWidget` para `ConsumerStatefulWidget` (Riverpod), introduzindo:

1. Um `GlobalKey<FormState>` para validação local via `TextFormField` nativo do `AuthTextField`
2. Um `TextEditingController` por campo do formulário
3. Um `AuthService` (novo) responsável pela chamada `POST /usuarios/register` via `dioProvider`
4. Um `authSignupProvider` local à página (ou `StateProvider<bool> isLoading`) para controlar o estado de loading e impedir double-submit
5. Após sucesso, chamar `authProvider.notifier.setAuth(...)` com `role: AuthRole.guest` e redirecionar via `context.go('/home')`

Não será criado um `StateNotifier` dedicado para esta feature — o estado de carregamento é local e efêmero. A lógica de negócio vai para `AuthService`, mantendo a página fina.

---

## Componentes Afetados

### Backend
- Nenhum. O endpoint `POST /usuarios/register` já existe.

### Frontend

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Modificado** | `lib/features/auth/presentation/pages/user_signup_page.dart` | Converter para `ConsumerStatefulWidget`; adicionar controllers, `Form`, validação, loading e chamada real à API |
| **Novo** | `lib/features/auth/data/services/auth_service.dart` | Encapsula `POST /usuarios/register`; retorna model com tokens ou lança exceção tipada |
| **Novo** | `lib/features/auth/data/models/register_request.dart` | DTO com campos `nome`, `cpf`, `telefone`, `email`, `senha` |
| **Novo** | `lib/features/auth/data/models/auth_response.dart` | DTO de resposta com `accessToken` e `refreshToken` |
| **Modificado** | `lib/features/auth/presentation/widgets/auth_text_field.dart` | Já aceita `controller` e `validator` — nenhuma mudança necessária |

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| `ConsumerStatefulWidget` em vez de `StateNotifier` dedicado | Estado de loading é local e transitório; não há necessidade de compartilhamento entre widgets |
| `AuthService` separado da página | Separa responsabilidade de rede da UI; facilita teste unitário da chamada |
| `Form` + `GlobalKey<FormState>` para validação local | Padrão Flutter; `AuthTextField` já expõe `validator` e `controller` — sem custo de refatoração |
| `context.go('/home')` após sucesso | GoRouter já define `/home` no `ShellRoute`; `go` limpa o stack de auth, impedindo voltar para o cadastro |
| Role fixo `AuthRole.guest` no signup de hóspede | O endpoint de cadastro de hóspede nunca retorna role `host`; a distinção é feita no endpoint separado de host |
| Tratamento de erro por `statusCode` no `catch` do `DioException` | Padrão já adotado no `dio_client.dart`; centraliza tratamento sem criar abstrações extras |

---

## Contratos de API

| Método | Rota | Body | Response (2xx) |
|--------|------|------|----------------|
| POST | `/usuarios/register` | `{ nome, cpf, telefone, email, senha }` | `{ tokens: { accessToken, refreshToken } }` |

### Erros esperados

| Status | Significado | Mensagem ao usuário |
|--------|-------------|---------------------|
| 400 | Campo inválido pelo servidor | Mensagem do campo retornado pela API ou "Dados inválidos. Verifique os campos." |
| 409 | E-mail já cadastrado | "Este e-mail já está cadastrado." |
| 5xx | Erro interno do servidor | "Erro no servidor. Tente novamente mais tarde." |

---

## Modelos de Dados

```dart
// lib/features/auth/data/models/register_request.dart
class RegisterRequest {
  final String nome;
  final String cpf;
  final String telefone;
  final String email;
  final String senha;
}

// lib/features/auth/data/models/auth_response.dart
class AuthResponse {
  final String accessToken;
  final String refreshToken;
}
```

---

## Fluxo de Execução (Submit)

```
[Usuário toca "Cadastrar"]
       │
       ▼
[Form.validate()] ──INVÁLIDO──► Exibe erros inline nos campos, interrompe
       │ VÁLIDO
       ▼
[isLoading = true] → botão desabilitado + CircularProgressIndicator
       │
       ▼
[AuthService.register(request)]
       │
       ├─ SUCESSO ──► authProvider.setAuth(access, refresh, AuthRole.guest)
       │                      └──► context.go('/home')
       │
       └─ ERRO (DioException)
              ├─ 409 ──► SnackBar "Este e-mail já está cadastrado."
              ├─ 400 ──► SnackBar com mensagem da API ou mensagem genérica
              └─ 5xx / timeout ──► SnackBar "Erro no servidor. Tente novamente."
                        [isLoading = false] → botão reabilitado
```

---

## Validações Locais (antes do POST)

| Campo | Regra |
|-------|-------|
| `nome` | Não vazio; mínimo 3 caracteres |
| `cpf` | Não vazio; 11 dígitos numéricos (formato livre, normalizar antes de enviar) |
| `telefone` | Não vazio; mínimo 10 dígitos |
| `email` | Formato válido via `RegExp` ou `Uri.parse` |
| `senha` | Mínimo 8 caracteres |
| `confirmar senha` | Igual ao campo `senha` |

---

## Dependências

**Bibliotecas (já no projeto):**
- [x] `flutter_riverpod` — gerenciamento de estado e injeção de `dioProvider`
- [x] `dio` — cliente HTTP via `dioProvider`
- [x] `go_router` — redirecionamento via `context.go`
- [x] `shared_preferences` — usado internamente pelo `AuthNotifier.setAuth`

**Outras features:**
- [x] P0 — `AuthNotifier` (`authProvider`) — salvar tokens pós-cadastro
- [x] P1-A — `app_router.dart` — rota `/home` já definida no `ShellRoute`

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Double-submit (usuário toca duas vezes) | `isLoading = true` desabilita o botão imediatamente antes da chamada |
| Resposta da API com shape diferente do esperado | Acessar `response.data['tokens']` com cast seguro; logar e exibir erro genérico se estrutura divergir |
| CPF/telefone com máscaras visuais divergindo do formato aceito pela API | Normalizar (remover traço, ponto, parênteses, espaço) antes de montar o `RegisterRequest` |
| `context.go('/home')` chamado após widget desmontado | Verificar `mounted` antes de navegar no `then/catch` da Future |
