# Plan — User Profile Page (P3-A)

> Derivado de: conductor/specs/user-profile-page.spec.md
> Status geral: [PENDENTE]

---

## Setup & Infraestrutura [CONCLUÍDO]

> Todas as dependências já estão no projeto — nenhuma instalação necessária.

- [x] `flutter_riverpod` disponível no pubspec
- [x] `dio` + `dioProvider` configurados em `lib/core/network/dio_client.dart`
- [x] `go_router` com rota `/profile/user` definida em `lib/core/router/app_router.dart`
- [x] `usuarioServiceProvider.getAutenticado()` implementado em `lib/utils/Usuario.dart`

---

## Backend [CONCLUÍDO]

> Nenhuma alteração necessária — endpoint `GET /usuarios/me` já existe e está em produção.

- [x] Endpoint `GET /usuarios/me` autenticado via Bearer token

---

## Frontend [CONCLUÍDO]

- [x] Criar `UserProfileModel` com `fromJson` em `lib/features/profile/data/models/user_profile_model.dart`
  - Campos: `id`, `nomeCompleto`, `email`, `cpf?`, `numeroCelular?`, `fotoPerfil?`, `dataNascimento?`
  - Usar `json['id'].toString()` para suportar `id` como `int` ou `String`
- [x] Criar `UserProfileNotifier` (`AsyncNotifier<UserProfileModel>`) em `lib/features/profile/presentation/providers/user_profile_provider.dart`
  - `build()`: chama `usuarioServiceProvider.getAutenticado()` e retorna `UserProfileModel.fromJson(data)`
  - Expor `userProfileProvider` via `AsyncNotifierProvider`
- [x] Converter `UserProfilePage` de `StatelessWidget` para `ConsumerWidget` em `lib/features/profile/presentation/pages/user_profile_page.dart`
  - Adicionar `ref.watch(userProfileProvider)` no início do `build()`
  - Tratar `AsyncLoading` → `Center(CircularProgressIndicator())`
  - Tratar `AsyncData` → passar `model.nomeCompleto`, `model.email`, `model.fotoPerfil` para `ProfileHeader`
  - Tratar `AsyncError` → exibir mensagem + `ElevatedButton('Tentar novamente', onPressed: () => ref.invalidate(userProfileProvider))`

---

## Validação [PENDENTE]

- [ ] Dado que o usuário está autenticado, ao abrir `/profile/user`, os dados reais (nome e e-mail) retornados por `GET /usuarios/me` são exibidos no `ProfileHeader`
- [ ] Dado que a requisição ainda está em andamento, a tela exibe `CircularProgressIndicator` e não os dados hardcoded
- [ ] Dado que o backend não retorna `foto_perfil`, o `ProfileHeader` exibe o ícone padrão (`Icons.person`) sem erros
- [ ] Dado que ocorre erro de rede ou timeout, a tela exibe a mensagem de erro e o botão "Tentar novamente"; ao tocar no botão, o fetch é refeito
- [ ] Dado que o token está expirado (401), o interceptor do P0 tenta o refresh; se falhar, o app redireciona para `/auth/login` sem exibir erro na tela de perfil
- [ ] Ao tocar em "Editar perfil", o app navega para `/profile/user/edit`
- [ ] Ao tocar em "Configurações", o app navega para `/profile/settings`
