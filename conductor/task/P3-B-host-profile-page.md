# P3-B — host_profile_page - feat/get-host-profile

## Tela
`lib/features/profile/presentation/pages/host_profile_page.dart`

## Prioridade
**P3 — Perfil (Feature média)**

## Branch sugerida
`feat/host-profile-page-integration`

---

## Estado Atual
Exibe dados do perfil do anfitrião/hotel. Dados provavelmente hardcoded ou mockados.

## O que integrar

- [ ] Ao entrar na tela, fazer `GET /hotel/me` para buscar dados do hotel autenticado
- [ ] Mapear dados da resposta para os widgets:
  - Nome do hotel, email, foto de capa, avaliação média, etc.
- [ ] Criar `HostProfileNotifier` (Riverpod) para guardar o estado
- [ ] Tratar loading state
- [ ] Tratar erros de rede
- [ ] Buscar fotos de capa do hotel via `GET /uploads/hotels/:hotel_id/cover`
- [ ] Exibir avaliações gerais se disponível
- [ ] Botões de navegação:
  - "Editar perfil" → `edit_host_profile_page` (P3-D)
  - "Meus quartos" → `my_rooms_page` (P4-E)
  - "Configurações" → `settings_page` (P3-E)

---

## Endpoints usados

| Método | Rota                                  | Auth | Descrição                    |
|--------|---------------------------------------|------|------------------------------|
| GET    | `/hotel/me`                           | ✅   | Buscar perfil do hotel       |
| GET    | `/uploads/hotels/:hotel_id/cover`     | ❌   | Listar fotos de capa         |

---

## Dependências
- **Requer:** P0 (interceptor), P2-A (login host)

## Bloqueia
- P3-D (`edit_host_profile_page`)
- P4-E (`my_rooms_page`)
