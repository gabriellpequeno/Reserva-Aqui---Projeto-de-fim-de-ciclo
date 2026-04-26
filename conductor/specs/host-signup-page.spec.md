# Spec — Host Signup Page (P1-C)

## Referência
- **PRD:** `conductor/features/host-signup-page.prd.md`
- **Task:** `_tasks/integration/P1-C-host-signup-page.md`
- **Arquivo principal:** `Frontend/lib/features/auth/presentation/pages/host_signup_page.dart`
- **Branch:** `feat/host-signup-page-integration`

---

## Abordagem Técnica

Converter `HostSignUpPage` de `StatelessWidget` para `ConsumerStatefulWidget` (Riverpod), seguindo o padrão já estabelecido em `UserSignUpPage`. A particularidade desta feature é que **`POST /hotel/register` não retorna tokens** — retorna apenas `{ data: hotel }`. Por isso, após o registro com sucesso, é necessário um **auto-login** via `POST /hotel/login` para obter `accessToken` + `refreshToken` antes de persistir a sessão.

Fluxo de dois steps:
1. `POST /hotel/register` → 201 com dados do hotel
2. `POST /hotel/login` (email + senha em memória) → `{ tokens: { accessToken, refreshToken } }`
3. `authProvider.notifier.setAuth(access, refresh, AuthRole.host)`
4. `context.go('/home')`

O estado de carregamento é local (`setState`), sem `StateNotifier` dedicado. A lógica de rede vai para `HostAuthService`, extendendo o `auth_service.dart` existente.

---

## Componentes Afetados

### Backend
- Nenhum. Endpoints `POST /hotel/register` e `POST /hotel/login` já existem.

### Frontend

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Modificado** | `lib/features/auth/presentation/pages/host_signup_page.dart` | Converter para `ConsumerStatefulWidget`; adicionar controllers, `Form`, validação, loading e chamada real à API (register + auto-login) |
| **Novo** | `lib/features/auth/data/models/register_host_request.dart` | DTO com os 11 campos obrigatórios + 2 opcionais do `POST /hotel/register` |
| **Modificado** | `lib/features/auth/data/services/auth_service.dart` | Adicionar `registerHotel(RegisterHostRequest)` e `loginHotel(email, senha)` → `AuthResponse` |

> `AuthResponse` (`lib/features/auth/data/models/auth_response.dart`) já existe e mapeia `json['tokens']` — reutilizado sem alteração.

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| Auto-login após register | `POST /hotel/register` retorna só `{ data: hotel }` sem tokens; a única forma de obter tokens imediatamente é chamando `POST /hotel/login` na sequência |
| Senha mantida em variável local durante o flow | Necessária para repassar ao `loginHotel` logo após o register; descartada (sem persistência) após o login |
| `ConsumerStatefulWidget` em vez de `StateNotifier` dedicado | Estado de loading é local e transitório; sem necessidade de compartilhamento — mesmo padrão de `UserSignUpPage` |
| Adicionar `registerHotel` + `loginHotel` no `auth_service.dart` existente | Evita criar novo arquivo de serviço para apenas 2 métodos relacionados; mantém todos os métodos de auth agrupados |
| `Form` + `GlobalKey<FormState>` para validação | `AuthTextField` já expõe `validator` e `controller`; sem custo de refatoração do widget |
| `context.go('/home')` após setAuth | GoRouter limpa o stack removendo as rotas de auth, impedindo o usuário de voltar ao cadastro com o botão Back |
| Role fixo `AuthRole.host` | O endpoint `/hotel/login` autentica somente anfitriões; role não precisa ser inferido da resposta |
| Campos `cnpj` e `cep` normalizados antes do envio | Backend valida dígitos puros (14 para CNPJ, 8 para CEP); máscaras visuais seriam removidas com `replaceAll(RegExp(r'\D'), '')` |

---

## Contratos de API

| Método | Rota | Body | Response (2xx) |
|--------|------|------|----------------|
| POST | `/hotel/register` | `{ nome_hotel, cnpj, telefone, email, senha, cep, uf, cidade, bairro, rua, numero, complemento?, descricao? }` | 201 `{ data: { hotel_id, nome_hotel, email, schema_name, criado_em } }` |
| POST | `/hotel/login` | `{ email, senha }` | 200 `{ data: hotel, tokens: { accessToken, refreshToken } }` |

### Erros esperados

| Status | Origem | Significado | Mensagem ao usuário |
|--------|--------|-------------|---------------------|
| 400 | register ou login | Campo ausente ou inválido (CNPJ, CEP, senha fraca, UF) | "Dados inválidos. Verifique os campos." |
| 409 | register | CNPJ ou e-mail já cadastrado | "Este CNPJ ou e-mail já está cadastrado." |
| 401 | login (auto) | Credenciais recusadas pós-register | "Erro no servidor. Tente novamente mais tarde." |
| 5xx | qualquer | Erro interno | "Erro no servidor. Tente novamente mais tarde." |

---

## Modelos de Dados

```dart
// lib/features/auth/data/models/register_host_request.dart
class RegisterHostRequest {
  final String nomeHotel;   // → 'nome_hotel'
  final String cnpj;        // normalizado: 14 dígitos
  final String telefone;    // normalizado: só dígitos
  final String email;
  final String senha;
  final String cep;         // normalizado: 8 dígitos
  final String uf;          // 2 letras maiúsculas
  final String cidade;
  final String bairro;
  final String rua;
  final String numero;
  final String? complemento;
  final String? descricao;

  Map<String, dynamic> toJson() => {
    'nome_hotel': nomeHotel,
    'cnpj': cnpj,
    'telefone': telefone,
    'email': email,
    'senha': senha,
    'cep': cep,
    'uf': uf.toUpperCase(),
    'cidade': cidade,
    'bairro': bairro,
    'rua': rua,
    'numero': numero,
    if (complemento != null && complemento!.isNotEmpty) 'complemento': complemento,
    if (descricao != null && descricao!.isNotEmpty) 'descricao': descricao,
  };
}

// Reutilizado sem alteração:
// lib/features/auth/data/models/auth_response.dart
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  // fromJson lê json['tokens']['accessToken'] e json['tokens']['refreshToken']
}
```

### Adições em `auth_service.dart`

```dart
// Novo: cadastro de hotel — retorna apenas dados (sem tokens)
Future<void> registerHotel(RegisterHostRequest request) async {
  await _dio.post<Map<String, dynamic>>(
    '/hotel/register',
    data: request.toJson(),
  );
}

// Novo: login de hotel — retorna tokens via AuthResponse
Future<AuthResponse> loginHotel(String email, String senha) async {
  final response = await _dio.post<Map<String, dynamic>>(
    '/hotel/login',
    data: { 'email': email, 'senha': senha },
  );
  return AuthResponse.fromJson(response.data!);
}
```

---

## Fluxo de Execução (Submit)

```
[Anfitrião toca "Cadastrar Hotel"]
       │
       ▼
[Form.validate()] ──INVÁLIDO──► Erros inline nos campos, interrompe
       │ VÁLIDO
       ▼
[isLoading = true] → botão → CircularProgressIndicator
       │
       ▼
[authService.registerHotel(request)]  ← POST /hotel/register
       │
       ├─ ERRO ──► catch(DioException)
       │              ├─ 409 ──► SnackBar "Este CNPJ ou e-mail já está cadastrado."
       │              ├─ 400 ──► SnackBar "Dados inválidos. Verifique os campos."
       │              └─ 5xx  ──► SnackBar "Erro no servidor. Tente novamente mais tarde."
       │                          [isLoading = false]
       │ SUCESSO (201)
       ▼
[authService.loginHotel(email, senhaLocal)]  ← POST /hotel/login
       │
       ├─ ERRO ──► SnackBar "Erro no servidor. Tente novamente mais tarde."
       │           [isLoading = false]
       │ SUCESSO
       ▼
[authProvider.notifier.setAuth(access, refresh, AuthRole.host)]
       │
       ▼
[if (mounted)] context.go('/home')
```

---

## Validações Locais (antes do POST)

| Campo | Regra | Normalização antes do envio |
|-------|-------|-----------------------------|
| `nome hotel` | Não vazio | `trim()` |
| `cnpj` | 14 dígitos numéricos | `replaceAll(RegExp(r'\D'), '')` |
| `telefone` | Mínimo 10 dígitos | `replaceAll(RegExp(r'\D'), '')` |
| `email` | Contém `@` e `.` | `trim()` |
| `cep` | 8 dígitos numéricos | `replaceAll(RegExp(r'\D'), '')` |
| `uf` | Exatamente 2 letras | `toUpperCase()` |
| `cidade`, `bairro`, `rua`, `numero` | Não vazio | `trim()` |
| `senha` | ≥ 8 chars; contém maiúscula, minúscula, `@` e dígito | — |
| `confirmar senha` | Igual ao campo `senha` | — (não enviado ao backend) |
| `complemento`, `descricao` | Sem validação obrigatória | `trim()`, omitidos do JSON se vazios |

> Regra de senha alinhada com `Anfitriao.ts#validateSenha`: `/[A-Z]/`, `/[a-z]/`, `/@/`, `/[0-9]/`.

---

## Dependências

**Bibliotecas (já no projeto):**
- [x] `flutter_riverpod` — `ConsumerStatefulWidget`, acesso a `authProvider` e `authServiceProvider`
- [x] `dio` — cliente HTTP via `dioProvider`
- [x] `go_router` — redirecionamento via `context.go('/home')`
- [x] `shared_preferences` — usado internamente por `AuthNotifier.setAuth`

**Outras features:**
- [x] P0 — `AuthNotifier` (`authProvider`) — `setAuth(access, refresh, AuthRole.host)`
- [x] P1-A — `app_router.dart` — rota `/home` já definida no `ShellRoute`

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Auto-login falha após register com sucesso (201) | Tratado no segundo `catch`; exibe erro genérico e libera o botão — usuário pode tentar manualmente pela tela de login |
| Double-submit (toque duplo) | `isLoading = true` desabilita o botão imediatamente; segundo toque ignorado |
| Senha fraca recusada pelo backend (400) com mensagem técnica | Validar a regra de senha localmente antes do POST, com mensagem amigável |
| `context.go('/home')` após widget desmontado | Verificar `mounted` antes de chamar `context.go` no bloco `finally`/`then` |
| `uf` em minúsculas recusado pelo backend (`/^[A-Z]{2}$/`) | `toUpperCase()` aplicado no `RegisterHostRequest.toJson()` e no validator inline |
| Campos `complemento`/`descricao` vazios enviados como string vazia | Omitir do JSON quando vazios via `if (complemento != null && complemento!.isNotEmpty)` |
