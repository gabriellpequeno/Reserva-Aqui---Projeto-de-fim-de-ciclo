# Spec — responsividade-web-tablet

## Referência
- **PRD:** conductor/features/responsividade-web-tablet.prd.md

## Abordagem Técnica

Criar um arquivo centralizado de breakpoints em `lib/core/utils/breakpoints.dart` e propagar o padrão `Center > ConstrainedBox(maxWidth)` para todas as páginas listadas. O app já usa `LayoutBuilder` pontualmente em `main_layout.dart` e `home_page.dart` — a estratégia é padronizar esse padrão via `MediaQuery.of(context).size.width` com os helpers do novo arquivo, sem introduzir nenhuma biblioteca externa. A `BottomNavigationBar` já existe em `custom_bottom_nav.dart` e o `main_layout.dart` já alterna entre drawer e bottom nav em 600px — esse breakpoint será substituído pelas novas constantes.

---

## Componentes Afetados

### Frontend — Criar

| Arquivo | O que é |
|---------|---------|
| `lib/core/utils/breakpoints.dart` | Constantes `tablet` (768) e `desktop` (1024) + helpers `isTablet(context)` e `isDesktop(context)` |

### Frontend — Modificar

| Arquivo | O que muda |
|---------|-----------|
| `lib/core/layouts/main_layout.dart` | Substituir breakpoint inline `600` pelas constantes; garantir que a área de conteúdo respeita `maxWidth` |
| `lib/core/widgets/custom_bottom_nav.dart` | Envolver em `Center > ConstrainedBox(maxWidth: 600)` |
| `lib/features/home/presentation/pages/home_page.dart` | Grid de quartos com `crossAxisCount` responsivo (1→2); substituir `size.width > 900` pelas constantes |
| `lib/features/rooms/presentation/pages/hotel_details_page.dart` | Layout de 2 colunas (imagem \| detalhes) em tablet+ |
| `lib/features/rooms/presentation/pages/room_details_page.dart` | Layout de 2 colunas em tablet+ |
| `lib/features/rooms/presentation/pages/my_rooms_page.dart` | Grid responsivo (1→2 colunas) |
| `lib/features/booking/presentation/pages/checkout_page.dart` | Layout de 2 colunas (resumo \| formulário) em tablet+ |
| `lib/features/auth/presentation/pages/login_page.dart` | Card centralizado `maxWidth: 480` |
| `lib/features/auth/presentation/pages/user_signup_page.dart` | Card centralizado `maxWidth: 480` |
| `lib/features/auth/presentation/pages/host_signup_page.dart` | Card centralizado `maxWidth: 480` |
| `lib/features/auth/presentation/pages/user_or_host_page.dart` | Card centralizado `maxWidth: 480` |
| `lib/features/profile/presentation/pages/user_profile_page.dart` | Conteúdo centralizado `maxWidth: 600` |
| `lib/features/profile/presentation/pages/host_profile_page.dart` | Conteúdo centralizado `maxWidth: 600` |
| `lib/features/profile/presentation/pages/admin_profile_page.dart` | Conteúdo centralizado `maxWidth: 600` |
| `lib/features/profile/presentation/pages/edit_user_profile_page.dart` | `maxWidth: 600` |
| `lib/features/profile/presentation/pages/edit_host_profile_page.dart` | `maxWidth: 600` |
| `lib/features/profile/presentation/pages/edit_admin_profile_page.dart` | `maxWidth: 600` |
| `lib/features/notifications/presentation/pages/notifications_page.dart` | Lista com `maxWidth: 600` |
| `lib/features/tickets/presentation/pages/tickets_page.dart` | Lista com `maxWidth: 600` |
| `lib/features/tickets/presentation/pages/ticket_details_page.dart` | Card centralizado `maxWidth: 600` |
| `lib/features/search/presentation/pages/search_page.dart` | Conteúdo com `maxWidth: 600` |
| `lib/features/favorites/presentation/pages/favorites_page.dart` | Grid responsivo (1→2 colunas) |

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| `MediaQuery` puro, sem biblioteca de responsividade | O app já usa `LayoutBuilder`/`MediaQuery` — adicionar lib (como `responsive_framework`) seria dependência sem necessidade e pode conflitar com o comportamento atual do `main_layout.dart` |
| Breakpoints em arquivo separado (`breakpoints.dart`) | Evita magic numbers espalhados; já havia `600` e `900` inline em dois arquivos diferentes — centralizar elimina inconsistências |
| `Center > ConstrainedBox` como padrão | Mantém compatibilidade com `Scaffold` e `SingleChildScrollView` existentes; não requer refatoração estrutural das páginas |
| Manter `main_layout.dart` como ponto único de troca drawer/bottom-nav | O layout shell já é o lugar correto para isso via GoRouter `ShellRoute`; adicionar um segundo nível de troca nas páginas seria redundante |
| Grid `crossAxisCount` via `isTablet(context)` inline em cada página | Mais simples e legível que um widget genérico de grid — os grids têm `itemExtent` e `childAspectRatio` diferentes por página |

---

## Contratos de API

Nenhum endpoint novo ou modificado — esta feature é exclusivamente de apresentação.

---

## Modelos de Dados

Nenhum modelo novo ou modificado.

---

## Implementação de Referência

### `lib/core/utils/breakpoints.dart` (novo)
```dart
import 'package:flutter/widgets.dart';

class Breakpoints {
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double maxContentWidth = 600;
  static const double maxFormWidth = 480;
}

bool isTablet(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.tablet;

bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.desktop;
```

### Padrão de body para páginas simples
```dart
body: Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
    child: /* conteúdo existente */,
  ),
),
```

### Padrão de grid responsivo
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: isTablet(context) ? 2 : 1,
    childAspectRatio: 1.4,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  ),
  ...
)
```

### Padrão de layout de 2 colunas (tablet)
```dart
isTablet(context)
  ? Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: /* imagem/resumo */),
        const SizedBox(width: 24),
        Expanded(child: /* detalhes/formulário */),
      ],
    )
  : Column(children: [/* imagem/resumo */, /* detalhes/formulário */])
```

---

## Dependências

**Bibliotecas:**
- Nenhuma biblioteca nova — uso exclusivo de `MediaQuery` e `LayoutBuilder` nativos do Flutter

**Serviços externos:**
- Nenhum

**Outras features:**
- [ ] `P6-A` (se existir) — pode rodar em paralelo conforme definido na task

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| `main_layout.dart` usa breakpoint `600` inline para troca de navbar — mudança pode quebrar comportamento atual | Trocar o valor inline pelo `Breakpoints.tablet` (768) de forma controlada; testar mobile portrait (375px) antes de commitar |
| `home_page.dart` usa `size.width > 900` para lógica de exibição do heading web — conflita com novo `desktop: 1024` | Avaliar se o comportamento em 900–1024px é aceitável; ajustar para `Breakpoints.desktop` ou manter o valor original documentado |
| Páginas com `CustomScrollView` / `SliverList` podem não se comportar bem com `Center > ConstrainedBox` no body | Usar `SliverPadding` com padding horizontal calculado a partir da largura da tela nesses casos específicos |
| Overflow horizontal em landscape mobile (667px) pode surgir em páginas com Row fixas | Testar cada página em 667px após a modificação; usar `Flexible` em vez de `Expanded` onde houver conteúdo de largura variável |
