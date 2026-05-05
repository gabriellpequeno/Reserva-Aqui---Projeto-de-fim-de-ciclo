# P6-A — dark-mode
> Derivada de: PRD (Tema obrigatório em todas as plataformas) + Fase 10 Polimento Final

## Objetivo
Garantir que o Dark Mode funcione corretamente em todas as telas do app. O `ThemeNotifier` e o toggle na `SettingsPage` já existem (P3-E); o que falta é aplicar os tokens de cor semanticamente em todos os widgets e páginas que ainda usam `AppColors` ou `Colors` hardcoded.

## Prioridade
**Alta** — Dark/Light mode é requisito MVP do PRD. Sem isso a apresentação mostra telas quebradas no tema escuro.

---

## Pré-condições (o que já existe, não refazer)

- `lib/core/theme/theme_notifier.dart` — `ThemeNotifier` com Riverpod, persiste preferência em `shared_preferences`
- `SettingsPage` — toggle Dark Mode conectado ao `ThemeNotifier`
- `main.dart` — `MaterialApp.router` já consome `themeMode` do notifier

---

## O que precisa ser feito

### 1. Auditar uso de cores hardcoded
- [ ] Buscar `AppColors.backgroundLight`, `Colors.white`, `Color(0xFF...)` em todos os arquivos de `presentation/`
- [ ] Listar páginas que ignoram `Theme.of(context)` e usam cor fixa

### 2. Criar/revisar tokens semânticos em `AppColors`
- [ ] Garantir que existam pares semânticos: `surface`, `onSurface`, `background`, `onBackground`, `cardBackground`, `divider`
- [ ] Se necessário, adicionar variantes dark em `ThemeData` (no `app_theme.dart` ou equivalente)

### 3. Substituir hardcoded por tokens semânticos
Páginas prioritárias a corrigir (em ordem de visibilidade):
- [ ] `home_page.dart` — `backgroundColor: Colors.white` / `AppColors.backgroundLight`
- [ ] `my_rooms_page.dart` — `backgroundColor: Colors.white`
- [ ] `hotel_details_page.dart`
- [ ] `room_details_page.dart`
- [ ] `notifications_page.dart`
- [ ] `admin_profile_page.dart` — `AppColors.backgroundLight` fixo
- [ ] `host_profile_page.dart`
- [ ] `user_profile_page.dart`
- [ ] `tickets_page.dart` / `ticket_details_page.dart`
- [ ] `search_page.dart`
- [ ] `checkout_page.dart`
- [ ] Todos os widgets compartilhados em `core/widgets/`

### 4. Validação visual
- [ ] Rodar em `flutter run -d chrome` com tema Dark ativado nas configurações
- [ ] Rodar em emulador Android com tema Dark
- [ ] Verificar contraste mínimo em textos sobre fundos escuros
- [ ] Verificar ícones e imagens placeholder sem fundo branco visível

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `lib/core/theme/app_colors.dart` | Adicionar tokens semânticos se faltarem |
| `lib/core/theme/app_theme.dart` (ou equivalente) | Garantir `darkTheme` com `ColorScheme.dark` correto |
| Todas as `*_page.dart` listadas acima | Substituir cores hardcoded por `Theme.of(context).colorScheme.*` |
| Widgets em `core/widgets/` | Mesma substituição |

---

## Dependências
- **Não bloqueia** nenhuma outra task — pode rodar em paralelo com P6-B
- **Não depende de** backend

## Observações
- Não criar um segundo sistema de tema — usar o `ThemeNotifier` existente
- Priorizar visibilidade para a apresentação: Home, Hotel Details, Room Details e Profile primeiro
