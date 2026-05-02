# Plan — Dark Mode

> Derivado de: conductor/specs/dark-mode.spec.md
> Status geral: [PENDENTE]

---

## Setup & Infraestrutura [PENDENTE]

- [ ] Sem novas dependências — `flutter_riverpod` e `shared_preferences` já estão no pubspec
- [ ] Garantir que `ThemeNotifier` e toggle da `SettingsPage` (P3-E) estão funcionando como baseline antes de iniciar a migração

---

## Backend [CONCLUÍDO]

> Nenhum endpoint nesta entrega — feature 100% client-side.

---

## Frontend [PENDENTE]

### Camada de tokens

- [ ] Criar `lib/core/theme/app_theme.dart` com `AppTheme.light` e `AppTheme.dark`, cada um com `ThemeData` completo: `ColorScheme` explícito (light/dark), `textTheme`, `appBarTheme`, `cardTheme`, `dividerTheme`, `inputDecorationTheme`
- [ ] Definir explicitamente `onPrimary`, `onSurface`, `onSurfaceVariant`, `surfaceContainer`, `outline` nos dois `ColorScheme` para garantir contraste WCAG AA
- [ ] Substituir `ColorScheme.fromSeed` inline no `main.dart` pelo consumo de `AppTheme.light` / `AppTheme.dark`

### Migração de páginas (ordem de visibilidade do PRD)

- [ ] Migrar `home_page.dart` — trocar `Colors.white` / `AppColors.background*` por `Theme.of(context).colorScheme.*`
- [ ] Migrar `hotel_details_page.dart`
- [ ] Migrar `room_details_page.dart`
- [ ] Migrar `user_profile_page.dart`
- [ ] Migrar `host_profile_page.dart`
- [ ] Migrar `admin_profile_page.dart` (remover `AppColors.backgroundLight` fixo)
- [ ] Migrar `my_rooms_page.dart`
- [ ] Migrar `notifications_page.dart`
- [ ] Migrar `tickets_page.dart` e `ticket_details_page.dart`
- [ ] Migrar `search_page.dart`
- [ ] Migrar `checkout_page.dart`

### Widgets e layouts compartilhados

- [ ] Migrar widgets em `lib/core/widgets/` (cards, chips, botões customizados, placeholders)
- [ ] Migrar layouts em `lib/core/layouts/`
- [ ] Conferir ícones SVG com cor embutida — aplicar `ColorFilter` onde necessário
- [ ] Aplicar `color: colorScheme.surface` em containers de placeholder para evitar fundo branco no dark

### Limpeza do `AppColors`

- [ ] Após todas as páginas e widgets migrados, remover de `app_colors.dart`: `backgroundLight`, `backgroundDark`, `textPrimaryLight`, `textPrimaryDark`, `strokeLight`, `bgSecondary`
- [ ] Manter apenas `primary` e `secondary` (brand)
- [ ] Rodar `flutter analyze` e corrigir referências remanescentes

---

## Validação [PENDENTE]

- [ ] `flutter analyze` sem warnings relacionados a cores/tema
- [ ] Rodar `flutter run -d chrome` com Dark Mode ativo — conferir Home, Hotel Details, Room Details, Profiles, My Rooms, Notifications, Tickets, Search, Checkout
- [ ] Rodar em emulador Android com Dark Mode ativo — mesma conferência
- [ ] Alternar o toggle na `SettingsPage` e verificar que todas as telas reagem sem reiniciar o app
- [ ] Reabrir o app — preferência de tema persiste (baseline do P3-E)
- [ ] Conferir contraste mínimo WCAG AA em textos principais sobre fundo escuro
- [ ] Conferir que ícones e placeholders não têm fundo branco visível no Dark Mode
- [ ] Conferir que botões com fundo `primary` usam `onPrimary` (não `Colors.white` fixo) para o texto
