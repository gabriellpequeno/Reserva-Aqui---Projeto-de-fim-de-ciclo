# Spec — Profile Pages Nav Fixes

## Referência
- **PRD:** conductor/features/profile-pages-nav-fixes.prd.md

## Abordagem Técnica
Corrigir navegação substituindo `context.go()` por `context.pop()` nas telas afetadas; adicionar widget de avatar reutilizável com suporte a `fotoPerfil` já mapeado nos models Flutter; integrar o endpoint de capa existente (`POST /api/uploads/hotels/:hotel_id/cover`) para upload da foto de capa do host. Avatar de usuário e avatar de host são tratados como EXT — exibir avatar estático com initials fallback até o backend implementar os endpoints ausentes.

## Componentes Afetados

### Backend
- **Nenhuma alteração nesta entrega** — endpoints de avatar (`/uploads/usuarios/:id/avatar` e `/uploads/hotels/:hotel_id/avatar`) não existem e são marcados como EXT
- Endpoint de capa já existe: `POST /api/uploads/hotels/:hotel_id/cover` (auth: HotelGuard, field: `foto`)

### Frontend
- **Novo:** `UserAvatarWidget` (`lib/features/profile/presentation/widgets/user_avatar_widget.dart`) — avatar circular com foto (`fotoPerfil`) ou initials fallback; parâmetro `onTap` opcional para trocar foto
- **Modificado:** `user_profile_page.dart` — substituir placeholder por `UserAvatarWidget` (somente leitura, EXT para upload)
- **Modificado:** `edit_profile_page.dart` — adicionar `UserAvatarWidget` com `onTap` desabilitado e banner "Em breve" até endpoint existir (EXT)
- **Modificado:** `host_profile_page.dart` — substituir placeholder por `UserAvatarWidget` (somente leitura, EXT para upload de avatar)
- **Modificado:** `edit_host_profile_page.dart` — campo de foto de capa com `image_picker` + upload via `POST /api/uploads/hotels/:hotel_id/cover`; campo de avatar do host com banner EXT
- **Modificado:** `settings_page.dart` — remover botão voltar duplicado em Termos, Privacidade e Sobre; garantir `context.pop()` em botões de voltar customizados

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|--------------|
| `UserAvatarWidget` reutilizável | Mesmo componente usado em perfil, edição e `hotel_details_page`; evita duplicação de lógica de fallback |
| `context.pop()` em vez de `context.go()` | Preserva o stack do GoRouter; `context.go()` reseta a navegação para a raiz |
| Upload de capa direto no repositório, sem serviço intermediário | Feature simples — nova camada seria over-engineering |
| Avatar de usuário/host como EXT | Endpoints e colunas de banco não existem no backend; implementar front sem back geraria estado inconsistente |

## Contratos de API

| Método | Rota | Body | Response |
|--------|------|------|----------|
| POST | `/api/uploads/hotels/:hotel_id/cover` | `multipart/form-data` (field: `foto`) | `{ id, storage_path, orientacao, criado_em }` |
| POST | `/api/uploads/usuarios/:id/avatar` | — | **EXT — endpoint não implementado** |
| POST | `/api/uploads/hotels/:hotel_id/avatar` | — | **EXT — endpoint não implementado** |

## Modelos de Dados

Nenhum model novo. Campos já existentes a utilizar:

```
UserProfileModel {
  fotoPerfil: String?   // JSON: foto_perfil
  // lib/features/profile/data/models/user_profile_model.dart
}

AdminHotelModel {
  capaUrl: String?      // JSON: capaUrl
  // lib/features/profile/domain/models/admin_hotel_model.dart
}
```

Verificar se `HotelDetailsState.coverUrls` é atualizado após upload de capa para refletir na `hotel_details_page`.

## Dependências

**Bibliotecas:**
- [ ] `image_picker` — seleção de foto da galeria/câmera (necessária apenas para upload de capa)

**Serviços externos:**
- Nenhum

**Outras features:**
- [ ] BUG-9 (botão voltar global) — padrão `context.pop()` a ser respeitado nesta entrega
- [ ] `hotel_details_page` — deve refletir `capaUrl` atualizado após upload de capa do host

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| Endpoints de avatar inexistentes no backend | Tratados como EXT: exibir avatar estático com initials fallback; não bloquear entrega |
| `hotel_details_page` pode fazer cache da imagem após upload de capa | Garantir que o widget de imagem força reload (ex: `key: ValueKey(capaUrl)`) após upload bem-sucedido |
| Campos `fotoPerfil`/`capaUrl` podem não chegar populados da API | Tratar null com fallback visual; não crashar se campo vier vazio |
