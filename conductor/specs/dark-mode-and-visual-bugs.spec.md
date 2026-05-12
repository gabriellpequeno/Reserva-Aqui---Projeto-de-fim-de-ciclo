# Spec — dark-mode-and-visual-bugs

## Referência
- **PRD:** `conductor/features/dark-mode-and-visual-bugs.prd.md`

---

## Abordagem Técnica

A estratégia é de **normalização progressiva por camadas**, evitando refactor global:

1. **Camada de tokens** — expandir `AppColors` com cores de status temáticas; não criar um novo design system.
2. **Camada de widget** — estender `CustomAppBar` para aceitar parâmetro `showNotificationIcon`; todas as telas migram para esse widget único.
3. **Camada de tela** — substituir `scaffoldBackgroundColor` hardcoded e `Colors.white/black` por `colorScheme.*` em cada arquivo listado no PRD.
4. **Camada de estado** — isolar o estado de comodidades em `AddRoomPage` para eliminar rebuild global.
5. **Camada de conteúdo/dados** — corrigir carregamento de imagens de perfil, notas de hotéis, Title Case e textos da seção "Legal".

Nenhum novo provider ou serviço de backend é necessário — todas as correções são de camada de apresentação (UI) e de estado local.

---

## Componentes Afetados

### Core / Shared

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Modificado** | `lib/core/theme/app_colors.dart` | Adicionar constantes de status: `successColor`, `successContainer`, `errorColor`, `errorContainer`, `warningColor` |
| **Modificado** | `lib/core/widgets/custom_app_bar.dart` | Adicionar parâmetro `showNotificationIcon` (bool, default `false`); adicionar parâmetro `title` (String?, opcional) para títulos de telas específicas |

### Features — Dark Mode / Scaffold Background

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Modificado** | `lib/features/booking/presentation/pages/checkout_page.dart` | `scaffoldBackgroundColor`, `Colors.white` em cards e dividers, cores de erro → `colorScheme.*` e `AppColors` |
| **Modificado** | `lib/features/booking/presentation/pages/reservation_success_page.dart` | `scaffoldBackgroundColor`, ícone de sucesso verde, logo ausente |
| **Modificado** | `lib/features/booking/presentation/pages/public_ticket_page.dart` | `scaffoldBackgroundColor`, migrar para `CustomAppBar` |
| **Modificado** | `lib/features/booking/presentation/pages/whatsapp_payment_page.dart` | `scaffoldBackgroundColor`, migrar para `CustomAppBar` |
| **Modificado** | `lib/features/chat/presentation/pages/chat_page.dart` | `scaffoldBackgroundColor: Colors.white`, ícone de voltar não-padrão |
| **Modificado** | `lib/features/booking/presentation/widgets/payment_bottom_sheet.dart` | Handle cinza, cores de status, fundo do item selecionado |

### Features — Dark Mode (bug report original)

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Modificado** | Tela **Assistente** (chat/assistant page) | Substituir cores hardcoded por `colorScheme.*` |
| **Modificado** | Tela **Check-in** (sem login) | Substituir cores hardcoded por `colorScheme.*` |
| **Modificado** | Tela **Minha Reserva** (sem login) | Substituir cores hardcoded por `colorScheme.*` |
| **Modificado** | Tela **Hotel Details** — hover do favorito | Usar `colorScheme.primaryContainer` no estado ativo |
| **Modificado** | Tela **Quarto** — toast "link copiado" | Usar `SnackBar` com `backgroundColor: colorScheme.inverseSurface` |
| **Modificado** | Tela **Reservar** | Dark mode global + hover do seletor de pagamento |
| **Modificado** | Dashboard **Hotel** | Substituir cores hardcoded por `colorScheme.*` |
| **Modificado** | Tela **Detalhes do Agendamento** (Hotel) | Substituir cores hardcoded por `colorScheme.*` |
| **Modificado** | Dashboard **Admin** | Substituir cores hardcoded por `colorScheme.*` |

### Features — Padronização de Headers

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Modificado** | `lib/features/bookings/presentation/pages/agendamentos_page.dart` | Migrar para `CustomAppBar` com `title: 'Agendamentos'` |
| **Modificado** | `lib/features/bookings/presentation/pages/agendamento_detail_page.dart` | Migrar para `CustomAppBar`; corrigir ícone de voltar |
| **Modificado** | `lib/features/rooms/presentation/pages/my_rooms_page.dart` | Migrar para `CustomAppBar` |
| **Modificado** | `lib/features/tickets/presentation/pages/tickets_page.dart` | Migrar para `CustomAppBar` |
| **Modificado** | `lib/features/favorites/presentation/pages/favorites_page.dart` | Migrar para `CustomAppBar`; corrigir `borderRadius` 30 → 27 |
| **Modificado** | `lib/features/rooms/presentation/pages/add_room_page.dart` | Migrar para `CustomAppBar`; corrigir ícone de notificação |
| **Modificado** | `lib/features/notifications/presentation/pages/notifications_page.dart` | Incluir logo via `CustomAppBar` |
| **Modificado** | `lib/features/profile/presentation/pages/admin_account_management_page.dart` | Substituir `logo.svg` + `colorFilter` por `logoDark.svg` diretamente |
| **Modificado** | `lib/features/search/presentation/pages/hotel_details_page.dart` | Corrigir ícone de voltar na SliverAppBar |

### Features — Bugs Visuais

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Modificado** | Tela **Criação de Conta Hotel** (auth) | Adicionar ícones nos TextFormFields seguindo padrão do User |
| **Modificado** | Tela **Criação de Conta Hotel** — Termos e Condições | Substituir overlay por `showModalBottomSheet` com o componente `TermsBottomSheet` do User |
| **Modificado** | Seção **Legal** (User, Hotel, Admin) | Substituir textos placeholder por conteúdo real |
| **Modificado** | Tela **Quarto** — ícone de favoritar | Corrigir estado hover/tap com `InkWell` + animação |
| **Modificado** | Tela **Reservar** | Reposicionar botão "Finalizar Reserva" para o final da tela |
| **Modificado** | Tela **Reservar** | Implementar tela/widget de feedback pós-pagamento |
| **Modificado** | Tela **Search** — cards de resultado | Investigar e corrigir carregamento de notas/avaliações |
| **Modificado** | Tela **Perfil** (User, Hotel, Admin) | Aplicar `.toTitleCase()` extension nos campos de nome |
| **Modificado** | Tela **Agendamentos** — filtros horizontais | Adicionar `ShaderMask` com gradiente nas bordas para indicar scroll |
| **Modificado** | Tela **Agendamentos** — calendário | Passar lista de datas com agendamentos para o widget de calendário |
| **Modificado** | `lib/features/rooms/presentation/pages/add_room_page.dart` | Isolar estado `_selectedAmenityIds` em `ConsumerWidget` dedicado |
| **Modificado** | Tela **Clientes** (Admin) | Corrigir carregamento de imagens; adicionar fallback com avatar padrão |

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| Estender `CustomAppBar` com `showNotificationIcon` e `title` em vez de criar novo widget | O widget já implementa a lógica correta de logo e back button; adicionar parâmetros é menos invasivo do que refatorar 12 telas com widgets novos |
| Usar `colorScheme.inverseSurface` / `colorScheme.onInverseSurface` para toasts e snackbars | Material Design 3 define esses tokens especificamente para superfícies de notificação que precisam contrastar com o fundo — automático em dark e light |
| Adicionar `AppColors.successColor`, `AppColors.errorColor` como cores estáticas (não tema-aware) em `app_colors.dart` | As cores de status têm semântica fixa (verde = ok, vermelho = erro); o ajuste ao tema é feito via `.withValues(alpha:)` sobre `colorScheme.surface` para containers |
| Usar `ShaderMask` com `LinearGradient` para indicar scroll horizontal nos filtros | Solução puramente declarativa em Flutter, sem dependência extra; gradiente nas bordas é mais sutil e elegante do que setas ou scroll indicators |
| Isolar `_selectedAmenityIds` em widget filho na `AddRoomPage` | O `setState` chamado no widget raiz reconstrói toda a árvore; extrair para `ConsumerStatefulWidget` filho limita o rebuild ao chip de comodidade sem tocar o formulário principal |
| `Title Case` via extension method em `String` (`lib/core/utils/string_extensions.dart`) | Reutilizável em todos os perfis; mantém a transformação na camada de apresentação sem tocar nos modelos de domínio |

---

## Contratos de API

> Esta feature é integralmente de camada de apresentação. **Nenhum endpoint novo ou modificado** é necessário.
>
> Exceção: investigar se os endpoints de busca de hotéis (`GET /hotels`) e de clientes admin retornam os campos `rating` e `profileImageUrl` corretamente — se não, a correção no backend está fora do escopo desta spec e deve ser tratada como bug de backend separado.

---

## Modelos de Dados

Nenhum modelo de dados novo. Alteração em `AppColors`:

```dart
// lib/core/theme/app_colors.dart — adições
class AppColors {
  // ... existentes ...
  
  // Status colors (semântica fixa — não variam com o tema)
  static const Color successColor     = Color(0xFF1E7A1E);  // Verde
  static const Color successContainer = Color(0xFFDCF5DC);  // Verde claro (light mode)
  static const Color errorColor       = Color(0xFFC0392B);  // Vermelho
  static const Color errorContainer   = Color(0xFFFDE8E8);  // Rosa claro (light mode)
  static const Color warningColor     = Color(0xFFEC6725);  // Laranja (já existe como secondary)
}
```

> Em dark mode, os containers de status devem usar `colorScheme.errorContainer` (M3) para error e equivalente para success — verificar se o `app_theme.dart` já define `errorContainer` no `ColorScheme.dark`.

---

## Detalhamento de Implementação

### A. Expansão do `CustomAppBar`

```dart
// Assinatura final proposta
class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.showBackButton = true,
    this.fallbackRoute,
    this.showNotificationIcon = false,   // NOVO
    this.title,                          // NOVO — null = só logo
  });

  final bool showBackButton;
  final String? fallbackRoute;
  final bool showNotificationIcon;       // NOVO
  final String? title;                   // NOVO

  @override Size get preferredSize => const Size.fromHeight(100);
}
```

**Lógica do `title`:**
- `null` → exibe o logo centralizado (comportamento atual)
- String não-nula → exibe o texto com `fontSize: 20`, `fontWeight: w700`, `color: colorScheme.onPrimary`

**Lógica do `showNotificationIcon`:**
- `false` → espaço vazio à direita (comportamento atual)
- `true` → `Icons.notifications_none`, tamanho 24, `color: colorScheme.onPrimary`, com `InkWell` que navega para `/notifications`

### B. Padrão de substituição de cor hardcoded

```dart
// ❌ Antes (hardcoded)
scaffoldBackgroundColor: const Color(0xFFD9D9D9),
color: Colors.white,
color: Colors.black,

// ✅ Depois (tema-aware)
scaffoldBackgroundColor: theme.colorScheme.surface,
color: theme.colorScheme.surfaceContainer,
color: theme.colorScheme.onSurface,

// ❌ Antes (status hardcoded)
color: const Color(0xFF1E7A1E),           // Verde sucesso
color: const Color(0xFFC0392B),           // Vermelho erro
color: const Color(0xFFFDE8E8),           // Rosa fundo erro

// ✅ Depois
color: AppColors.successColor,
color: AppColors.errorColor,
color: theme.colorScheme.errorContainer,
```

### C. Padrão de toast/snackbar tema-aware

```dart
// ✅ SnackBar Material 3 que respeita dark mode automaticamente
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Link copiado'),
    backgroundColor: theme.colorScheme.inverseSurface,
    // onInverseSurface para o texto (contraste automático)
  ),
);
```

### D. Title Case via extension

```dart
// lib/core/utils/string_extensions.dart (criar se não existir)
extension StringExtensions on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }
}

// Uso nas telas de Perfil:
Text(user.name.toTitleCase())
```

### E. Indicador de scroll horizontal (filtros de Agendamentos)

```dart
ShaderMask(
  shaderCallback: (Rect bounds) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        Colors.white,
        Colors.white,
        Colors.transparent,
      ],
      stops: const [0.0, 0.05, 0.95, 1.0],
    ).createShader(bounds);
  },
  blendMode: BlendMode.dstIn,
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: filtros),
  ),
)
```

> **Nota:** `Colors.white` aqui é a máscara de opacidade do shader, não uma cor visível — é correto e funciona em dark mode.

### F. Isolamento de estado das comodidades (AddRoomPage)

Extrair o `GridView` de comodidades para um `ConsumerStatefulWidget` filho (`AmenitiesSelector`) que mantém `Set<int> _selectedIds` internamente e expõe `onChanged(Set<int>)` para o pai. O pai nunca chama `setState` ao alterar comodidades.

```dart
class AmenitiesSelector extends ConsumerStatefulWidget {
  const AmenitiesSelector({
    super.key,
    required this.initialSelected,
    required this.onChanged,
  });
  final Set<int> initialSelected;
  final void Function(Set<int>) onChanged;
  // ...
}
```

---

## Dependências

**Bibliotecas (já existentes no projeto — nenhuma nova):**
- [x] `flutter_riverpod` — gerenciamento de estado dos providers
- [x] `flutter_svg` — renderização dos logos SVG
- [x] `go_router` — navegação ao clicar no ícone de notificações no `CustomAppBar`
- [x] `shared_preferences` — persistência do tema (já implementado)

**Serviços externos:** nenhum

**Outras features (dependências de dados):**
- [ ] **Bug de backend (se confirmado):** endpoint de busca deve retornar campo `rating` nos cards de hotel — investigar antes de implementar req. 38
- [ ] **Bug de backend (se confirmado):** endpoint de clientes admin deve retornar `profileImageUrl` — investigar antes de implementar req. 40
- [ ] **Conteúdo da seção "Legal":** textos reais dos Termos de Uso, Privacidade e Sobre o App devem ser fornecidos pelo time de produto antes de implementar req. 34

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Migrar todas as telas para `CustomAppBar` pode quebrar layouts que têm altura ou padding customizado no header | Revisar `preferredSize` (atualmente 100pt) em cada tela antes de migrar; ajustar se necessário via parâmetro novo |
| `ShaderMask` no indicador de scroll pode ter conflito com tema escuro dependendo do `blendMode` | Testar em dark mode e light mode; ajustar `stops` do gradiente se as bordas ficarem muito opacas |
| Isolar comodidades em widget filho pode quebrar o `_formKey` se o submit ainda precisar validar comodidades | `onChanged` do `AmenitiesSelector` atualiza o state do pai sem `setState` — verificar se a validação do submit continua funcionando |
| Correção do `scaffoldBackgroundColor` de `Color(0xFFD9D9D9)` para `colorScheme.surface` pode alterar o visual em light mode (branco puro em vez de cinza) | Validar com design/PO se o visual resultante está aceitável; `colorScheme.surfaceContainerLow` é uma alternativa que mantém o cinza levemente acinzentado |
| Campos de nome em Title Case podem quebrar nomes próprios que usam letras maiúsculas internas (ex: "McAlister") | Aceitar como limitação conhecida; a extensão pode ser documentada como `toSimpleTitleCase` |
| Dados de rating/imagens de perfil podem não existir no backend | Implementar com dados de fallback (nota `0.0` com exibição neutra; avatar padrão via `CircleAvatar`) independente do backend |

---

## Ordem de Implementação Sugerida

> Sequência que minimiza conflitos e permite testes incrementais:

1. `app_colors.dart` — adicionar constantes de status *(sem risco, sem dependências)*
2. `string_extensions.dart` — criar extension de Title Case *(sem risco)*
3. `custom_app_bar.dart` — adicionar `showNotificationIcon` e `title` *(bloco de headers depende disso)*
4. Scaffolds com background hardcoded (req. 13–17) — 5 arquivos, mudança cirúrgica
5. Headers — migrar telas uma a uma para `CustomAppBar` (req. 1–12)
6. Dark mode por tela (req. 18–31)
7. `payment_bottom_sheet.dart` — cores de status (req. 29–31)
8. `AmenitiesSelector` — isolamento de estado (req. 44)
9. Bugs visuais de dados (req. 38–40) — após investigação de backend
10. Bugs visuais remanescentes (req. 32–37, 41–43, 45–46)
