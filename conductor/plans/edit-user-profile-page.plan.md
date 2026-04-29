# Plan — Edit User Profile Page (P3-C)

> Derivado de: conductor/specs/edit-user-profile-page.spec.md
> Status geral: [PENDENTE]

---

## Setup & Infraestrutura [CONCLUÍDO]

> Todas as dependências, services, providers e models já estão no projeto — nenhuma instalação ou criação de arquivo de infra necessária.

- [x] `flutter_riverpod` disponível no pubspec
- [x] `dio` + `dioProvider` configurados em `lib/core/network/dio_client.dart`
- [x] `go_router` com rota `/profile/user/edit` definida em `lib/core/router/app_router.dart`
- [x] `UserProfileModel` implementado em `lib/features/profile/data/models/user_profile_model.dart`
- [x] `userProfileProvider` + `UserProfileNotifier` implementados em `lib/features/profile/presentation/providers/user_profile_provider.dart`
- [x] `usuarioServiceProvider.update()` implementado em `lib/utils/Usuario.dart` (linhas 185–247)
- [x] `usuarioServiceProvider.changePassword()` implementado em `lib/utils/Usuario.dart` (linhas 254–294)

---

## Backend [CONCLUÍDO]

> Nenhuma alteração necessária — ambos os endpoints já existem e estão em produção.

- [x] Endpoint `PATCH /usuarios/me` autenticado via Bearer token — atualiza nome, email, celular e data de nascimento
- [x] Endpoint `POST /usuarios/change-password` autenticado via Bearer token — troca a senha e invalida refresh tokens

---

## Frontend [PENDENTE]

### 1. Converter tipo do widget

- [ ] Alterar `EditUserProfilePage` de `StatefulWidget` para `ConsumerStatefulWidget`
  - Trocar `State<EditUserProfilePage>` por `ConsumerState<EditUserProfilePage>`
  - Adicionar import de `flutter_riverpod`

### 2. Adicionar estado de loading de senha

- [ ] Declarar `bool _isLoadingPassword = false;` ao lado do `_isLoading` existente
  - `_isLoading` → cobre o submit de dados pessoais
  - `_isLoadingPassword` → cobre o submit de troca de senha

### 3. Corrigir initState — remover dados hardcoded

- [ ] Substituir `TextEditingController(text: 'Acesse agora')` por `TextEditingController(text: profile?.nomeCompleto ?? '')`
- [ ] Substituir `TextEditingController(text: 'usuario@user.com')` por `TextEditingController(text: profile?.email ?? '')`
- [ ] Pré-popular `_phoneController` com `profile?.numeroCelular ?? ''`
- [ ] Pré-popular `_birthdateController` com `profile?.dataNascimento ?? ''`
  - ⚠️ Se `dataNascimento` vier do backend em `YYYY-MM-DD`, converter para `dd/mm/aaaa` antes de popular
- [ ] Leitura via `ref.read(userProfileProvider).valueOrNull` (não `ref.watch` — leitura única no `initState`)

### 4. Implementar `_savePersonalData()`

- [ ] Renomear / substituir o método `_savProfile()` por `_savePersonalData()`
- [ ] Remover o `Future.delayed(const Duration(seconds: 1))` (mock)
- [ ] Chamar `ref.read(usuarioServiceProvider).update(...)` com os valores dos controllers:
  - `nomeCompleto: _nameController.text`
  - `email: _emailController.text`
  - `numeroCelular: _phoneController.text`
  - `dataNascimento: _birthdateController.text`
- [ ] No `onSuccess`: chamar `ref.invalidate(userProfileProvider)`, exibir `SnackBar` de sucesso e `context.pop()`
- [ ] No `onError`: exibir `SnackBar` com a mensagem de erro retornada pelo service
- [ ] Envolver em `try/finally` garantindo `setState(() => _isLoading = false)` sempre ao fim

### 5. Implementar `_savePassword()`

- [ ] Criar método `Future<void> _savePassword()` independente
- [ ] Acionar apenas se `_passwordController.text.isNotEmpty`
- [ ] Chamar `ref.read(usuarioServiceProvider).changePassword(...)`:
  - `senhaAtual: _currentPasswordController.text`
  - `novaSenha: _passwordController.text`
  - `confirmarNovaSenha: _confirmPasswordController.text`
- [ ] No `onSuccess`: limpar os três campos de senha e exibir `SnackBar` de confirmação independente
- [ ] No `onError`: exibir `SnackBar` com a mensagem de erro (ex: `"A senha atual está incorreta ou sua sessão expirou."`)
- [ ] Usar `_isLoadingPassword` para controlar o estado de loading desta operação

### 6. Unificar o submit no botão "Salvar"

- [ ] Atualizar `onPressed` do `PrimaryButton` para chamar sequencialmente:
  1. `_savePersonalData()` — sempre (se o form for válido)
  2. `_savePassword()` — apenas se `_passwordController.text.isNotEmpty`
- [ ] Desabilitar o botão "Salvar" e "Cancelar" enquanto `_isLoading || _isLoadingPassword`

### 7. Corrigir validator da senha atual

- [ ] Remover a linha `if (_passwordController.text.isNotEmpty && value != '123456')` do validator de `_currentPasswordController`
- [ ] Manter apenas: se `_passwordController.text.isNotEmpty && (value?.isEmpty ?? true)` → `'Insira sua senha atual para alterar'`
- [ ] A validação real da senha atual é feita pelo backend via `changePassword()`

---

## Validação [PENDENTE]

- [ ] Dado que o usuário está autenticado e o P3-A carregou os dados, ao abrir `/profile/user/edit`, os campos nome, email, telefone e data de nascimento devem exibir os dados reais do usuário (não `"Acesse agora"` ou `"usuario@user.com"`)
- [ ] Dado que o usuário altera o nome e clica em "Salvar", a requisição `PATCH /usuarios/me` é disparada; ao retornar 200, o `userProfileProvider` é invalidado, um snackbar verde aparece e a tela volta para `UserProfilePage` exibindo o nome atualizado
- [ ] Dado que o usuário tenta salvar um e-mail já cadastrado, o backend retorna 409 e a tela exibe a mensagem `"O e-mail informado já está em uso por outra conta."` sem fechar ou congelar
- [ ] Dado que `nova_senha !== confirmar_nova_senha`, o form bloqueia o submit com mensagem de erro inline no campo `"Confirmar Senha"`, sem chamar nenhuma API
- [ ] Dado que os três campos de senha estão preenchidos corretamente, a requisição `POST /usuarios/change-password` é disparada; ao retornar 200, os três campos de senha são limpos e um snackbar específico de confirmação de senha é exibido
- [ ] Dado que a senha atual está incorreta, o backend retorna 401/400 e a tela exibe `"A senha atual está incorreta ou sua sessão expirou."` sem afetar os campos de dados pessoais
- [ ] Dado que qualquer requisição está em andamento, os botões "Salvar Alterações" e "Cancelar" estão desabilitados (sem duplo submit)
- [ ] Dado que o P3-A ainda não carregou (AsyncLoading), a tela abre com os campos vazios sem crash; o usuário pode preencher manualmente
- [ ] A validação hardcoded contra `'123456'` foi completamente removida e não causa mais falsos positivos/negativos

---

## Sincronização com plan.md

> Quando todas as seções acima estiverem `[CONCLUÍDO]`, atualizar `conductor/plan.md`:
> - Localizar o bloco de P3-C ou `edit-user-profile-page`
> - Marcar o status como `[CONCLUÍDO]`
> - Se não existir, criar nova fase com tasks resumidas e status `[CONCLUÍDO]`
