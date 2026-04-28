# Spec — Edit User Profile Page (P3-C)

## Referência
- **PRD:** `conductor/features/edit-user-profile-page.prd.md`
- **Arquivo principal:** `Frontend/lib/features/profile/presentation/pages/edit_user_profile_page.dart`
- **Branch:** `feat/edit-user-profile-page-integration`

---

## Abordagem Técnica

Converter `EditUserProfilePage` de `StatefulWidget` puro para `ConsumerStatefulWidget` (Riverpod), mantendo toda a UI já construída (sem nenhuma mudança de layout) e substituindo os três pontos de mock por integração real:

1. **`initState`:** eliminar strings hardcoded; pré-popular controllers com dados do `userProfileProvider` já em memória (P3-A precisa estar completo).
2. **Submit de dados pessoais:** chamar `usuarioServiceProvider.update()` — método já implementado em `lib/utils/Usuario.dart` (linhas 185–247); em caso de sucesso, invalidar `userProfileProvider` e navegar com `context.pop()`.
3. **Submit de senha:** chamar `usuarioServiceProvider.changePassword()` — também já implementado (linhas 254–294); em caso de sucesso, limpar os três campos de senha e exibir snackbar separado.

> ⚡ **Nenhum novo service ou endpoint será criado.** Todo o código de rede já existe e está validado. O trabalho é unicamente de wiring (ligação) entre a UI e os métodos existentes.

---

## Componentes Afetados

### Backend
- **Nenhum.** Os dois endpoints (`PATCH /usuarios/me` e `POST /usuarios/change-password`) já existem e estão documentados.

### Frontend

| Tipo | Arquivo | O que muda |
|------|---------|------------|
| **Modificado** | `lib/features/profile/presentation/pages/edit_user_profile_page.dart` | Trocar `StatefulWidget` → `ConsumerStatefulWidget`; pré-popular controllers no `initState` com dados do `userProfileProvider`; substituir `Future.delayed` por chamadas reais aos services; remover validação hardcoded `'123456'`; separar fluxo de submit em dois (`_savePersonalData` + `_savePassword`); adicionar `_isLoadingPassword` separado |
| **Sem alteração** | `lib/features/profile/presentation/providers/user_profile_provider.dart` | Já existe. Apenas `ref.invalidate(userProfileProvider)` será chamado após update bem-sucedido |
| **Sem alteração** | `lib/features/profile/data/models/user_profile_model.dart` | Já existe com todos os campos necessários |
| **Sem alteração** | `lib/utils/Usuario.dart` | `update()` e `changePassword()` já estão implementados |

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|---------------|
| `ConsumerStatefulWidget` em vez de `ConsumerWidget` | A página tem estado local mutável (7 `TextEditingController`, 3 flags `_obscure*`, 2 flags `_isLoading`); `ConsumerStatefulWidget` é o tipo correto para formulários com Riverpod |
| Dois métodos de submit separados (`_savePersonalData` / `_savePassword`) | Feedbacks independentes (PRD RF #10); evita acoplamento de estado de loading — `_isLoading` cobre dados pessoais, `_isLoadingPassword` cobre senha |
| `ref.invalidate(userProfileProvider)` após update bem-sucedido | Força o re-fetch de `/usuarios/me` no provider; `UserProfilePage` (P3-A) re-renderiza automaticamente com dados frescos sem nenhum código extra |
| Não criar `_isLoadingPersonal` + `_isLoadingPassword` como `StateProvider` | Riverpod é overkill para estado de UI local (loading de botão); `setState` é correto aqui — Riverpod gerencia apenas estado de rede e domínio |
| Pré-popular no `initState` lendo `ref.read(userProfileProvider)` | O provider já foi carregado pela `UserProfilePage` (P3-A); `ref.read` (não `ref.watch`) no `initState` não causa rebuild — é o padrão correto para leitura única de inicialização |
| `context.pop()` após save de dados pessoais (não `context.go`) | Mantém o stack de navegação; volta para `UserProfilePage` que exibe os dados atualizados via `ref.watch(userProfileProvider)` |
| Campos de senha limpados após troca bem-sucedida | UX: evita reenvio acidental; confirmação visual de que a operação foi concluída |

---

## Contratos de API

### `PATCH /usuarios/me` — Atualizar dados pessoais

| Método | Rota | Auth | Body | Response (200) |
|--------|------|------|------|----------------|
| `PATCH` | `/usuarios/me` | Bearer JWT | `{ nome_completo?, email?, numero_celular?, data_nascimento? }` | `{ data: { id, nome_completo, email, cpf, numero_celular, foto_perfil, data_nascimento } }` |

**Regras de campo (validação no service):**
| Campo Flutter | Campo API | Formato esperado pelo backend |
|---------------|-----------|-------------------------------|
| `_nameController.text` | `nome_completo` | string livre |
| `_emailController.text` | `email` | deve conter `@` e `.com` |
| `_phoneController.text` | `numero_celular` | `(xx) xxxxx-xxxx` ou `(xx) xxxx-xxxx` |
| `_birthdateController.text` | `data_nascimento` | `dd/mm/aaaa` |

> ⚠️ O método `update()` do `UsuarioService` já aplica a máscara de celular (`replaceAll(RegExp(r'[^\d]'), '')`) e valida o formato antes de enviar.

#### Erros tratados pelo `_handleDioError`
| Status | Mensagem exibida |
|--------|-----------------|
| `400` | `"Dados inválidos. Verifique os campos e tente novamente."` |
| `401` | `"Sessão expirada. Faça login novamente."` |
| `409` | `"O e-mail informado já está em uso por outra conta."` |
| timeout | `"Tempo de conexão esgotado. Verifique sua internet."` |

---

### `POST /usuarios/change-password` — Trocar senha

| Método | Rota | Auth | Body | Response (200) |
|--------|------|------|------|----------------|
| `POST` | `/usuarios/change-password` | Bearer JWT | `{ senhaAtual: string, novaSenha: string }` | `{ message: "Senha alterada com sucesso. Faça login novamente." }` |

> ⚠️ O método `changePassword()` já valida localmente: senhas não podem ser vazias, `novaSenha === confirmarNovaSenha`, e `novaSenha` deve atender a regex de complexidade (`/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d])/`).

#### Comportamento pós-sucesso
- Trocar senha **invalida todos os refresh tokens** no backend.
- Implicação: o usuário será deslogado na próxima vez que o `accessToken` expirar.
- **Não** forçar logout imediato na UI (fora do escopo desta task).

#### Erros tratados
| Status | Mensagem exibida |
|--------|-----------------|
| `400` | `"Dados inválidos. Verifique as senhas e tente novamente."` |
| `401` | `"A senha atual está incorreta ou sua sessão expirou."` |

---

## Modelos de Dados

Nenhum model novo é criado. O `UserProfileModel` existente já cobre todos os campos necessários para pré-popular e atualizar o estado:

```dart
// lib/features/profile/data/models/user_profile_model.dart (existente — não alterar)
class UserProfileModel {
  final String id;
  final String nomeCompleto;   // → _nameController
  final String email;          // → _emailController
  final String? cpf;           // read-only (não editável nesta tela)
  final String? numeroCelular; // → _phoneController
  final String? fotoPerfil;    // fora de escopo (P3-C)
  final String? dataNascimento;// → _birthdateController
}
```

---

## Fluxo de Execução

### Fluxo 1 — Inicialização

```
[Usuário navega para /profile/user/edit]
       │
       ▼
[EditUserProfilePage.initState()]
       │
       ├─ ref.read(userProfileProvider)
       │       └─ AsyncData(UserProfileModel)
       │               ├─ _nameController.text     = model.nomeCompleto
       │               ├─ _emailController.text    = model.email
       │               ├─ _phoneController.text    = model.numeroCelular ?? ''
       │               └─ _birthdateController.text = model.dataNascimento ?? ''
       │
       └─ AsyncLoading / AsyncError
               └─ controllers iniciam vazios (fallback seguro)
```

### Fluxo 2 — Salvar Dados Pessoais

```
[Usuário clica em "Salvar Alterações"]
       │
       ▼
[_formKey.currentState!.validate()]
       │
       ├─ inválido → exibe erros inline nos campos (Flutter Form nativo)
       │
       └─ válido
               │
               ▼
       [setState(() => _isLoading = true)]  ← desabilita botões
               │
               ▼
       [usuarioServiceProvider.update(
           nomeCompleto, email, numeroCelular, dataNascimento,
           onSuccess: ...,
           onError: ...,
       )]
               │
               ├─ onSuccess(usuario)
               │       ├─ ref.invalidate(userProfileProvider)  ← atualiza P3-A
               │       ├─ ScaffoldMessenger.showSnackBar('Perfil atualizado com sucesso ✓')
               │       └─ context.pop()
               │
               └─ onError(message)
                       ├─ ScaffoldMessenger.showSnackBar(message)
                       └─ setState(() => _isLoading = false)
```

### Fluxo 3 — Trocar Senha

```
[Usuário preenche campos de senha e clica em "Salvar Alterações"]
       │
       ▼
[_formKey.currentState!.validate()]
       │  (campos de senha são validados junto ao Form)
       │
       └─ válido + _passwordController.text.isNotEmpty
               │
               ▼
       [setState(() => _isLoadingPassword = true)]
               │
               ▼
       [usuarioServiceProvider.changePassword(
           senhaAtual, novaSenha, confirmarNovaSenha,
           onSuccess: ...,
           onError: ...,
       )]
               │
               ├─ onSuccess()
               │       ├─ _currentPasswordController.clear()
               │       ├─ _passwordController.clear()
               │       ├─ _confirmPasswordController.clear()
               │       └─ ScaffoldMessenger.showSnackBar('Senha alterada com sucesso ✓')
               │
               └─ onError(message)
                       └─ ScaffoldMessenger.showSnackBar(message)
               │
               └─ finally: setState(() => _isLoadingPassword = false)
```

> **Nota:** Os dois fluxos (dados pessoais + senha) podem ser executados na mesma submissão se ambos os grupos estiverem preenchidos. A ordem de execução é: **dados pessoais primeiro**, **senha depois** (se os campos estiverem preenchidos). Cada um tem seu snackbar e loading independente.

---

## Pseudocódigo de Implementação

```dart
// ANTES (mock):
void initState() {
  _nameController = TextEditingController(text: 'Acesse agora');  // ← remover
  _emailController = TextEditingController(text: 'usuario@user.com'); // ← remover
  ...
}

// DEPOIS (integração):
void initState() {
  super.initState();
  final profile = ref.read(userProfileProvider).valueOrNull;
  _nameController     = TextEditingController(text: profile?.nomeCompleto ?? '');
  _emailController    = TextEditingController(text: profile?.email ?? '');
  _phoneController    = TextEditingController(text: profile?.numeroCelular ?? '');
  _birthdateController = TextEditingController(text: profile?.dataNascimento ?? '');
  _currentPasswordController = TextEditingController();
  _passwordController        = TextEditingController();
  _confirmPasswordController = TextEditingController();
}

// ANTES (mock):
Future<void> _savProfile() async {
  await Future.delayed(const Duration(seconds: 1)); // ← remover
}

// DEPOIS (integração — dividido em dois):
Future<void> _savePersonalData() async { ... }
Future<void> _savePassword() async { ... }

// Validator da senha atual — ANTES:
if (_passwordController.text.isNotEmpty && value != '123456') { // ← remover
  return 'Senha atual incorreta';
}

// DEPOIS: campo obrigatório se nova senha estiver preenchida (sem comparação local):
if (_passwordController.text.isNotEmpty && (value?.isEmpty ?? true)) {
  return 'Insira sua senha atual para alterar';
}
// Validação real é feita pelo backend via changePassword()
```

---

## Dependências

**Bibliotecas (já no projeto):**
- [x] `flutter_riverpod` — `ConsumerStatefulWidget`, `ref.read`, `ref.invalidate`
- [x] `dio` — cliente HTTP via `dioProvider` (usado internamente por `usuarioServiceProvider`)
- [x] `go_router` — `context.pop()` já configurado no `app_router.dart`

**Outras features:**
- [x] **P3-A** (`user_profile_page`) — `userProfileProvider` deve estar carregado com dados reais antes de abrir esta tela; sem P3-A, os campos iniciam vazios (fallback seguro via `valueOrNull`)
- [x] **P0** — `dio_client.dart` com interceptor Bearer token; o Dio já injeta o accessToken automaticamente em todas as requisições autenticadas

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| `ref.read(userProfileProvider)` retorna `AsyncLoading` no `initState` (P3-A ainda não carregou) | `valueOrNull` retorna `null` de forma segura; campos ficam vazios — comportamento aceitável (usuário pode preencher manualmente) |
| Submit simultâneo de dados pessoais + senha causa race condition | Desabilitar ambos os botões enquanto qualquer operação estiver em andamento (`_isLoading \|\| _isLoadingPassword`); executar os dois calls de forma sequencial, não paralela |
| `data_nascimento` chegando em formato `YYYY-MM-DD` do backend e sendo enviada como `DD/MM/AAAA` | `update()` já valida o formato `DD/MM/AAAA` — garantir que `_birthdateController` é pré-populado com o valor já convertido; se o backend retorna `YYYY-MM-DD`, converter no `initState` antes de popular o controller |
| Trocar senha invalida refresh tokens; usuário pode ser deslogado de forma abrupta após a próxima expiração do access token | Documentar comportamento esperado; não tratar nesta task (escopo de auth — P2) |
| Campo `numero_celular` vindo do backend sem formatação (apenas dígitos) e sendo exibido sem máscara | O `UsuarioService.update()` já remove a máscara antes de enviar; na exibição, o campo é apenas texto livre — aceitável para MVP; máscara pode ser adicionada via `input_formatters` em iteração futura |

---

## Referências

- PRD: [`conductor/features/edit-user-profile-page.prd.md`](../features/edit-user-profile-page.prd.md)
- Spec predecessor (P3-A): [`conductor/specs/user-profile-page.spec.md`](./user-profile-page.spec.md)
- Arquivo alvo: `Frontend/lib/features/profile/presentation/pages/edit_user_profile_page.dart`
- Service de rede: `Frontend/lib/utils/Usuario.dart` (métodos `update`, linhas 185–247; `changePassword`, linhas 254–294)
- Provider: `Frontend/lib/features/profile/presentation/providers/user_profile_provider.dart`
- Model: `Frontend/lib/features/profile/data/models/user_profile_model.dart`
- API.md: seção 5 — Perfil do Hóspede (linhas 411–478)
