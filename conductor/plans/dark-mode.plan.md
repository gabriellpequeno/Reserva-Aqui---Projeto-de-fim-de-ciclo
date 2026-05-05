# Plan — Dark Mode

> Derivado de: conductor/specs/dark-mode.spec.md
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Sem novas dependências — `flutter_riverpod` e `shared_preferences` já estão no pubspec
- [x] Garantir que `ThemeNotifier` e toggle da `SettingsPage` (P3-E) estão funcionando como baseline antes de iniciar a migração

---

## Backend [CONCLUÍDO]

> Nenhum endpoint nesta entrega — feature 100% client-side.

---

## Frontend [CONCLUÍDO]

### Camada de tokens [CONCLUÍDO]

- [x] Criar `lib/core/theme/app_theme.dart` com `AppTheme.light` e `AppTheme.dark`, cada um com `ThemeData` completo: `ColorScheme` explícito (light/dark), `textTheme`, `appBarTheme`, `cardTheme`, `dividerTheme`, `inputDecorationTheme`
- [x] Definir explicitamente `onPrimary`, `onSurface`, `onSurfaceVariant`, `surfaceContainer`, `outline` nos dois `ColorScheme` para garantir contraste WCAG AA
- [x] Substituir `ColorScheme.fromSeed` inline no `main.dart` pelo consumo de `AppTheme.light` / `AppTheme.dark`

### Migração de páginas (ordem de visibilidade do PRD) [CONCLUÍDO]

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

### Widgets e layouts compartilhados [CONCLUÍDO]

- [x] `custom_app_bar.dart` — chevron migrado para `colorScheme.onSurface`
- [x] `profile_header.dart` e `profile_menu_item.dart` — avatar, menu, dividers
- [x] `auth_text_field.dart` e `date_picker_field.dart` — reescritos para usar `InputDecoration` theme-aware
- [x] `profile_form_section.dart`, `guests_picker_sheet.dart`, `chat_bubble.dart`, `ticket_card.dart`, `favorite_card.dart`, `availability_checker.dart` — migrados
- [x] `delete_room_dialog.dart` e `manual_reservation_dialog.dart` — dialogs, `showDateRangePicker` herda `AppTheme.dark`
- [x] `main_layout.dart` — já usava tokens corretos
- **Decisões intencionais mantidas como brand:**
  - `custom_bottom_nav.dart` — `CustomPainter` pinta a barra com `AppColors.primary` (identidade visual fixa)
  - `primary_button.dart` — defaults `AppColors.secondary`/`AppColors.primary` como brand; chamadores sobrescrevem quando precisam
  - Textos sobre imagens hero (Home, brand headers) permanecem `Colors.white`

### Limpeza do `AppColors` [CONCLUÍDO]

- [x] Removidos: `backgroundLight`, `backgroundDark`, `textPrimaryLight`, `textPrimaryDark`, `strokeLight`, `bgSecondary`, `greyText`
- [x] `AppColors` agora expõe apenas `primary` e `secondary` (brand)
- [x] `flutter analyze` sem warnings relacionados a cores/tema (22 issues restantes são pré-existentes e sem relação com dark mode)

---

## Validação [PENDENTE — responsabilidade do usuário]

- [x] `flutter analyze` sem warnings relacionados a cores/tema
- [ ] Rodar `flutter run -d chrome` com Dark Mode ativo — conferir Home, Hotel Details, Room Details, Profiles, My Rooms, Notifications, Tickets, Search, Checkout, Favorites, Chat, Auth (login/signup), Settings
- [ ] Rodar em emulador Android com Dark Mode ativo — mesma conferência
- [ ] Alternar o toggle na `SettingsPage` e verificar que todas as telas reagem sem reiniciar o app
- [ ] Reabrir o app — preferência de tema persiste (baseline do P3-E)
- [ ] Conferir contraste mínimo WCAG AA em textos principais sobre fundo escuro
- [ ] Conferir que ícones e placeholders não têm fundo branco visível no Dark Mode
- [ ] Conferir que botões com fundo `primary` usam `onPrimary` (não `Colors.white` fixo) para o texto
- [ ] Conferir que `showDatePicker` e `showDateRangePicker` (checkout, availability checker, search, signup) abrem já em dark
