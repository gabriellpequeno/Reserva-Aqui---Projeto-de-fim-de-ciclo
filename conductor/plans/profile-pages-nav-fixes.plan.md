# Plan — Profile Pages Nav Fixes

> Derivado de: conductor/specs/profile-pages-nav-fixes.spec.md
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Adicionar dependência `image_picker` no `pubspec.yaml` — já estava presente (`^1.2.1`)

---

## Backend [CONCLUÍDO]

- [x] ~~Avatar de usuário~~ — EXT: `POST /uploads/usuarios/:id/avatar` não implementado no backend; aguardar endpoint
- [x] ~~Avatar de host~~ — EXT: `POST /uploads/hotels/:hotel_id/avatar` não implementado no backend; aguardar endpoint

---

## Frontend [CONCLUÍDO]

- [x] Criar `UserAvatarWidget` (`lib/features/profile/presentation/widgets/user_avatar_widget.dart`) — avatar circular com initials fallback
- [x] Atualizar `user_profile_page.dart` — via `ProfileHeader` já atualizado com `UserAvatarWidget`
- [x] Atualizar `edit_user_profile_page.dart` — `UserAvatarWidget` + banner EXT adicionado; botão voltar já usava `context.pop()`
- [x] Atualizar `host_profile_page.dart` — via `ProfileHeader` já atualizado com `UserAvatarWidget`
- [x] Atualizar `edit_host_profile_page.dart` — campo de foto de capa com `image_picker` + upload via `POST /api/uploads/hotels/:hotel_id/cover`; avatar do host com banner EXT
- [x] Corrigir `settings_page.dart` — `Navigator.push` substituído por `context.push` com rotas GoRouter fora do shell (`parentNavigatorKey: _rootNavigatorKey`)
- [x] Registrar rotas `/profile/settings/terms`, `/profile/settings/privacy`, `/profile/settings/about` em `app_router.dart`

---

## Validação [PENDENTE]

- [ ] Usuário sem foto → avatar exibe initials corretamente em perfil e edição
- [ ] Usuário com `fotoPerfil` preenchida → avatar exibe a foto na tela de perfil
- [ ] Host faz upload de foto de capa → `hotel_details_page` reflete a nova imagem após upload
- [ ] Telas Termos, Privacidade e Sobre → apenas um botão de voltar, retorna para Configurações
- [ ] `edit_user_profile_page` → botão voltar retorna para perfil, não para home
- [ ] Nenhuma tela do fluxo de perfil usa `context.go()` em botão de voltar customizado
