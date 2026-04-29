# Plan — Settings Page

> Derivado de: conductor/specs/settings-page.spec.md
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Sem novas dependências — `shared_preferences` já está no pubspec

---

## Backend [CONCLUÍDO]

> Nenhum endpoint nesta entrega.

---

## Frontend [CONCLUÍDO]

- [x] Criar `ThemeNotifier` em `lib/core/theme/theme_notifier.dart` (`NotifierProvider` Riverpod + `shared_preferences`)
- [x] Conectar `ThemeNotifier` ao `MaterialApp` no `main.dart` via `ref.watch(themeProvider)`
- [x] Conectar toggle Dark Mode no `settings_page.dart` ao `ThemeNotifier`
- [x] Conectar toggle Notificações ao `shared_preferences` (persistir preferência local)
- [x] Criar telas estáticas legais: `terms_page.dart`, `privacy_page.dart`, `about_page.dart` em `lib/features/profile/presentation/pages/`
- [x] Implementar navegação nos tiles legais do `settings_page.dart`

---

## Validação [CONCLUÍDO]

- [x] Toggle Dark Mode muda o tema globalmente e persiste após hot restart
- [x] Toggle Notificações persiste o estado após hot restart
- [x] Tiles legais navegam para as telas corretas
- [x] Sem erros de tipo (`dynamic` desnecessário) e sem chaves `shared_preferences` hardcoded fora do notifier
