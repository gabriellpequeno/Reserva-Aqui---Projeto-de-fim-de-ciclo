# Plan — Dark Mode

> Derivado de: conductor/specs/dark-mode.spec.md
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Sem novas dependências — `flutter_riverpod` e `shared_preferences` já estão no pubspec
- [x] Garantir que `ThemeNotifier` e toggle da `SettingsPage` (P3-E) estão funcionando como baseline antes de iniciar a migração

---

## Backend [CONCLUÍDO]

> Nenhum endpoint nesta entrega — feature 100% client-side.

---

## Frontend [EM ANDAMENTO]

### Camada de tokens [CONCLUÍDO]

- [x] Criar `lib/core/theme/app_theme.dart` com `AppTheme.light` e `AppTheme.dark`, cada um com `ThemeData` completo: `ColorScheme` explícito (light/dark), `textTheme`, `appBarTheme`, `cardTheme`, `dividerTheme`, `inputDecorationTheme`
- [x] Definir explicitamente `onPrimary`, `onSurface`, `onSurfaceVariant`, `surfaceContainer`, `outline` nos dois `ColorScheme` para garantir contraste WCAG AA
- [x] Substituir `ColorScheme.fromSeed` inline no `main.dart` pelo consumo de `AppTheme.light` / `AppTheme.dark`

### Migração de páginas (ordem de visibilidade do PRD) [EM ANDAMENTO]

- [x] Migrar `home_page.dart` — trocar `Colors.white` / `AppColors.background*` por `Theme.of(context).colorScheme.*`
- [x] Migrar `hotel_details_page.dart`
- [x] Migrar `room_details_page.dart`
- [x] Migrar `user_profile_page.dart`
- [x] Migrar `host_profile_page.dart`
- [x] Migrar `admin_profile_page.dart` (remover `AppColors.backgroundLight` fixo)
- [x] Migrar `my_rooms_page.dart` (fluxo principal; dialogs internos ficam para follow-up)
- [x] Migrar `notifications_page.dart`
- [x] Migrar `tickets_page.dart` e `ticket_details_page.dart`
- [x] Migrar `search_page.dart` (Scaffold + divider; refs de `AppColors.greyText` internas ficam para follow-up)
- [x] Migrar `checkout_page.dart`

### Widgets e layouts compartilhados [EM ANDAMENTO]

- [x] `custom_app_bar.dart` — chevron migrado para `colorScheme.onSurface`
- [x] `profile_header.dart` e `profile_menu_item.dart` — avatar, menu, dividers
- [ ] `custom_bottom_nav.dart` — **decisão intencional**: mantém `AppColors.primary` como cor brand da barra (usa `CustomPainter`). Ícones `Colors.white` são intencionais sobre o fundo brand
- [ ] `primary_button.dart` — **decisão intencional**: defaults `AppColors.secondary` / `AppColors.primary` são brand; chamadores podem sobrescrever
- [x] `main_layout.dart` — já usa `Theme.of(context).primaryColor`; drawer tinha tokens corretos
- [ ] Feature widgets que aparecem nas páginas migradas (`room_card`, `ticket_card`, `favorite_card`, `chat_bubble`, widgets de forms/dialogs, etc.) — **follow-up**
- [ ] Conferir ícones SVG com cor embutida — aplicar `ColorFilter` onde necessário
- [ ] Aplicar `color: colorScheme.surface` em containers de placeholder para evitar fundo branco no dark

### Limpeza do `AppColors` [PENDENTE]

- [ ] Após todas as páginas e widgets migrados, remover de `app_colors.dart`: `backgroundLight`, `backgroundDark`, `textPrimaryLight`, `textPrimaryDark`, `strokeLight`, `bgSecondary`
- [ ] Manter apenas `primary` e `secondary` (brand)
- [ ] Rodar `flutter analyze` e corrigir referências remanescentes

---

## Validação [EM ANDAMENTO]

- [x] `flutter analyze` sem warnings relacionados a cores/tema (29 issues restantes são pré-existentes — `withOpacity` deprecations, file naming, etc.)
- [ ] Rodar `flutter run -d chrome` com Dark Mode ativo — conferir Home, Hotel Details, Room Details, Profiles, My Rooms, Notifications, Tickets, Search, Checkout
- [ ] Rodar em emulador Android com Dark Mode ativo — mesma conferência
- [ ] Alternar o toggle na `SettingsPage` e verificar que todas as telas reagem sem reiniciar o app
- [ ] Reabrir o app — preferência de tema persiste (baseline do P3-E)
- [ ] Conferir contraste mínimo WCAG AA em textos principais sobre fundo escuro
- [ ] Conferir que ícones e placeholders não têm fundo branco visível no Dark Mode
- [ ] Conferir que botões com fundo `primary` usam `onPrimary` (não `Colors.white` fixo) para o texto

---

## Follow-up (para próxima sessão)

Fora do escopo desta entrega mas mapeado:

- Feature widgets compartilhados não migrados ainda: `room_card`, `ticket_card`, `favorite_card`, `chat_bubble`, `profile_form_section`, `auth_text_field`, `availability_checker`, `guests_picker_sheet`, `manual_reservation_dialog`, `delete_room_dialog`
- Páginas secundárias ainda com cores hardcoded: `chat_page`, `favorites_page`, `about_page`, `login_page`, `host_signup_page`, `add_room_page`, `edit_room_page`, `edit_admin/host/user_profile_page`, `settings_page`
- Dialogs internos de `my_rooms_page` (reativar, remover definitivamente, exclusão bloqueada) ainda em `Colors.white` fixo
- `search_page`: muitos usos de `AppColors.greyText` internos aguardando substituição
- Limpeza final do `AppColors` só após as listas acima estarem migradas
