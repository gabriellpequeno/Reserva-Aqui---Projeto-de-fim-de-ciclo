# Spec — Dark Mode

## Referência
- **PRD:** conductor/features/dark-mode.prd.md
- **Task origem:** conductor/__task/P6-A-dark-mode.md

## Abordagem Técnica
Trabalho puramente front-end, sem backend. Três eixos:

- **Camada de tokens:** extrair o `ThemeData` que hoje está inline no `main.dart` para um novo `app_theme.dart`, declarando `ColorScheme.light()` e `ColorScheme.dark()` **explícitos** (em vez do `ColorScheme.fromSeed` atual, que não dá controle sobre contraste).
- **Camada de uso:** substituir os ~410 usos de `AppColors.*` / `Colors.white` / `Color(0xFF...)` em páginas e widgets por `Theme.of(context).colorScheme.*` e `Theme.of(context).textTheme.*`.
- **Papel do `AppColors`:** manter apenas cores **brand** (`primary`, `secondary`) e tokens neutros que não mudam entre temas. Tudo que depende do tema passa a vir do `ColorScheme`.

O `ThemeNotifier` (Riverpod) e o toggle na `SettingsPage` **não são tocados** — já funcionam e estão cobertos pelo PRD da Settings.

## Componentes Afetados

### Backend
Nenhum.

### Frontend

**Novo:**
- `lib/core/theme/app_theme.dart` — `AppTheme.light` / `AppTheme.dark` com `ThemeData` completo, incluindo `ColorScheme`, `textTheme`, `appBarTheme`, `cardTheme`, `dividerTheme` e `inputDecorationTheme`.

**Modificado:**
- `lib/main.dart` — remover `ThemeData` inline e consumir `AppTheme.light` / `AppTheme.dark`.
- `lib/core/theme/app_colors.dart` — remover os pares `backgroundLight`/`backgroundDark`, `textPrimaryLight`/`textPrimaryDark` (migram para o `ColorScheme`). Manter `primary`, `secondary` e qualquer cor neutra independente de tema.
- Páginas em `lib/features/*/presentation/pages/` (prioridade por visibilidade):
  - `home_page.dart`, `hotel_details_page.dart`, `room_details_page.dart`
  - `user_profile_page.dart`, `host_profile_page.dart`, `admin_profile_page.dart`
  - `my_rooms_page.dart`, `notifications_page.dart`
  - `tickets_page.dart`, `ticket_details_page.dart`
  - `search_page.dart`, `checkout_page.dart`
- Widgets compartilhados em `lib/core/widgets/` e layouts em `lib/core/layouts/` — mesma substituição.

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|---------------|
| Extrair `ThemeData` para `app_theme.dart` | Hoje vive inline em `main.dart`; mover para arquivo dedicado evita que `main.dart` cresça e facilita revisão de tokens |
| Substituir `ColorScheme.fromSeed` por `ColorScheme.light/dark` explícitos | `fromSeed` gera paleta automática mas não garante contraste WCAG AA; definindo cores manualmente controlamos fundo/texto com precisão |
| Manter `AppColors` só com cores brand | Evita conflito entre "cor fixa do app" e "cor semântica do tema" — o critério fica óbvio para quem for mexer depois |
| Não criar wrapper `context.colors` | Flutter já expõe `Theme.of(context).colorScheme` — abstração adicional seria ruído |
| Não tocar no `ThemeNotifier` | Já funciona e está coberto pela Settings Page spec (P3-E) |

## Contratos de API
Nenhum — feature 100% visual/client-side.

## Modelos de Dados
Nenhum. A única persistência é a já existente em `shared_preferences`:

```
theme_mode: string   ('light' | 'dark' | 'system')
```

## Mapa de Substituição (referência para o código)

| Cor hardcoded usada hoje | Substituir por |
|--------------------------|----------------|
| `Colors.white`, `AppColors.backgroundLight` (como fundo de Scaffold/página) | `Theme.of(context).colorScheme.surface` |
| `AppColors.backgroundDark` | — (removido; vem do `colorScheme.surface` no dark) |
| `AppColors.textPrimaryLight` / `textPrimaryDark` | `Theme.of(context).colorScheme.onSurface` |
| `AppColors.greyText` | `Theme.of(context).colorScheme.onSurfaceVariant` |
| `AppColors.strokeLight` | `Theme.of(context).dividerColor` |
| `AppColors.bgSecondary` (cards, chips) | `Theme.of(context).colorScheme.surfaceContainer` |
| `AppColors.primary` | **mantém** `AppColors.primary` (brand) |
| `AppColors.secondary` | **mantém** `AppColors.secondary` (brand) |

## Dependências

**Bibliotecas:**
- [x] `flutter_riverpod` — já no pubspec (usado pelo `ThemeNotifier` existente)
- [x] `shared_preferences` — já no pubspec

**Serviços externos:** nenhum.

**Outras features:**
- [x] `ThemeNotifier` e toggle da `SettingsPage` — entregues em P3-E, não precisam ser refeitos.

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Remover chaves de `AppColors` quebra builds em páginas não migradas | Fazer o trabalho em duas passadas: (1) adicionar `AppTheme` + migrar páginas; (2) só então remover tokens legados do `AppColors`. Rodar `flutter analyze` a cada passo |
| ~410 usos de `AppColors` — migração manual propensa a erro | Priorizar pelas páginas listadas no PRD (ordem de visibilidade); validar visualmente cada página no dark antes de prosseguir |
| Contraste insuficiente em textos sobre `primary` (ex: botões) | Definir `onPrimary` explicitamente no `ColorScheme` e usá-lo em vez de `Colors.white` fixo |
| Ícones SVG com cores embutidas que não respondem ao tema | Conferir SVGs durante a validação; se houver cor embutida, substituir por `ColorFilter` ou `Icon` semântico |
| Placeholders e imagens remotas com fundo branco | Aplicar `color: colorScheme.surface` no container-pai do placeholder; documentar caso a caso |

## Plano de Execução Sugerido

1. Criar `lib/core/theme/app_theme.dart` com `AppTheme.light` e `AppTheme.dark` (ambos os `ColorScheme` explícitos).
2. Apontar `main.dart` para `AppTheme.light` / `AppTheme.dark`.
3. Migrar páginas na ordem do PRD (home → hotel details → room details → profiles → my rooms → notifications → tickets → search → checkout).
4. Migrar widgets compartilhados em `core/widgets/` e `core/layouts/`.
5. Remover os tokens `backgroundLight/backgroundDark/textPrimaryLight/textPrimaryDark` de `AppColors`.
6. Validar: `flutter analyze`, `flutter run -d chrome` (dark), emulador Android (dark), conferência manual de contraste.

## Questões Abertas

### Detecção automática do tema do SO
O PRD lista "seguir configuração do SO" como **fora de escopo**. O `ThemeNotifier` já retorna `ThemeMode.system` por padrão quando não há preferência salva, então tecnicamente já temos o comportamento — mas não há UI para voltar ao "modo sistema" depois que o usuário toca no toggle. Decisão desta entrega: não adicionar tri-state no toggle; manter o comportamento atual (primeira abertura segue o SO; após tocar, fica fixo em light/dark).
