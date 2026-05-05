# Plan — responsividade-web-tablet

> Derivado de: conductor/specs/responsividade-web-tablet.spec.md
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Criar `lib/core/utils/breakpoints.dart` com constantes `tablet: 768`, `desktop: 1024`, `maxContentWidth: 600`, `maxFormWidth: 480` e helpers `isTablet(context)` / `isDesktop(context)`
- [x] Auditar usos de `size.width > 900` em `home_page.dart` e breakpoint `600` inline em `main_layout.dart` — documentar quais serão substituídos e quais mantidos

---

## Backend [CONCLUÍDO]

> Nenhuma task de backend — feature exclusivamente de apresentação.

---

## Frontend [CONCLUÍDO]

### Core / Layout
- [x] Atualizar `lib/core/layouts/main_layout.dart` — substituir breakpoint `600` (troca drawer/bottom-nav) por `Breakpoints.tablet`; garantir que área de conteúdo do shell respeita `maxWidth`
- [x] Atualizar `lib/core/widgets/custom_bottom_nav.dart` — envolver em `Center > ConstrainedBox(maxWidth: Breakpoints.maxContentWidth)`

### Auth
- [x] Atualizar `lib/features/auth/presentation/pages/login_page.dart` — card centralizado `maxWidth: Breakpoints.maxFormWidth`
- [x] Atualizar `lib/features/auth/presentation/pages/user_signup_page.dart` — card centralizado `maxWidth: Breakpoints.maxFormWidth`
- [x] Atualizar `lib/features/auth/presentation/pages/host_signup_page.dart` — card centralizado `maxWidth: Breakpoints.maxFormWidth`
- [x] Atualizar `lib/features/auth/presentation/pages/user_or_host_page.dart` — card centralizado `maxWidth: Breakpoints.maxFormWidth`

### Home & Busca
- [x] Atualizar `lib/features/home/presentation/pages/home_page.dart` — grid de quartos com `crossAxisCount` responsivo (1 mobile → 2 tablet+); substituir `size.width > 900` por `isDesktop(context)`
- [x] Atualizar `lib/features/search/presentation/pages/search_page.dart` — conteúdo com `maxWidth: Breakpoints.maxContentWidth`

### Quartos
- [x] Atualizar `lib/features/rooms/presentation/pages/hotel_details_page.dart` — layout de 2 colunas (imagem | detalhes) em tablet+
- [x] Atualizar `lib/features/rooms/presentation/pages/room_details_page.dart` — layout de 2 colunas em tablet+
- [x] Atualizar `lib/features/rooms/presentation/pages/my_rooms_page.dart` — grid responsivo (1 → 2 colunas em tablet+)

### Checkout
- [x] Atualizar `lib/features/booking/presentation/pages/checkout_page.dart` — layout de 2 colunas (resumo | formulário) em tablet+

### Perfis
- [x] Atualizar `lib/features/profile/presentation/pages/user_profile_page.dart` — `maxWidth: Breakpoints.maxContentWidth`
- [x] Atualizar `lib/features/profile/presentation/pages/host_profile_page.dart` — `maxWidth: Breakpoints.maxContentWidth`
- [x] Atualizar `lib/features/profile/presentation/pages/admin_profile_page.dart` — `maxWidth: Breakpoints.maxContentWidth`
- [x] Atualizar `lib/features/profile/presentation/pages/edit_user_profile_page.dart` — `maxWidth: Breakpoints.maxContentWidth`
- [x] Atualizar `lib/features/profile/presentation/pages/edit_host_profile_page.dart` — `maxWidth: Breakpoints.maxContentWidth`
- [x] Atualizar `lib/features/profile/presentation/pages/edit_admin_profile_page.dart` — `maxWidth: Breakpoints.maxContentWidth`

### Notificações & Tickets & Favoritos
- [x] Atualizar `lib/features/notifications/presentation/pages/notifications_page.dart` — lista com `maxWidth: Breakpoints.maxContentWidth`
- [x] Atualizar `lib/features/tickets/presentation/pages/tickets_page.dart` — lista com `maxWidth: Breakpoints.maxContentWidth`
- [x] Atualizar `lib/features/tickets/presentation/pages/ticket_details_page.dart` — card centralizado `maxWidth: Breakpoints.maxContentWidth`
- [x] Atualizar `lib/features/favorites/presentation/pages/favorites_page.dart` — grid responsivo (1 → 2 colunas em tablet+)

---

## Validação [CONCLUÍDO]

- [x] Testar no Chrome DevTools em **375px** (mobile portrait) — nenhuma página deve ter regressão visual em relação ao comportamento anterior
- [x] Testar no Chrome DevTools em **667px** (mobile landscape) — nenhuma página deve ter overflow horizontal
- [x] Testar no Chrome DevTools em **768px** (tablet portrait) — grids devem exibir 2 colunas; páginas de detalhe em 2 colunas; bottom nav dentro do `maxWidth`
- [x] Testar no Chrome DevTools em **1280px** (desktop/web) — conteúdo centralizado em todas as páginas com `maxWidth` correto; formulários de auth com `maxWidth: 480`
- [x] Verificar que `login_page`, `user_signup_page` e `host_signup_page` aparecem como card centralizado em 1280px
- [x] Verificar que `hotel_details_page` e `room_details_page` exibem layout de 2 colunas em 768px
- [x] Verificar que `checkout_page` exibe layout de 2 colunas (resumo | formulário) em 768px
- [x] Verificar que girar o dispositivo entre portrait e landscape não quebra nenhuma página aberta
