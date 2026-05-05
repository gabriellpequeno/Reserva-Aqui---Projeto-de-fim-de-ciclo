# P6-B — responsividade-web-tablet
> Derivada de: PRD (App mobile Web obrigatório — MVP; Layout tablet — Nice to Have) + Fase 10 Polimento Final

## Objetivo
Adaptar o layout do app para funcionar corretamente em telas maiores (browser desktop e tablet). O app já funciona em mobile portrait; o que falta é usar o espaço horizontal disponível nas telas maiores sem quebrar o layout.

## Prioridade
**Alta para Web** (MVP), **Média para tablet** (Nice to Have segundo PRD).

---

## Pré-condições (o que já existe, não refazer)

- App Flutter com suporte web habilitado (`flutter run -d chrome` funciona)
- Estrutura de páginas em `lib/features/*/presentation/pages/`
- `GoRouter` configurado para web

---

## O que precisa ser feito

### 1. Definir breakpoints
- [ ] Criar constante de breakpoints em `lib/core/utils/breakpoints.dart` (ou equivalente):
  ```dart
  static const double tablet = 768;
  static const double desktop = 1024;
  ```
- [ ] Criar helper `isTablet(context)` / `isDesktop(context)` baseado em `MediaQuery.of(context).size.width`

### 2. Layout com largura máxima (Web)
- [ ] Centralizar conteúdo com `maxWidth` em todas as páginas — sugestão: `maxWidth: 600` para mobile-first no browser
- [ ] Envolver `Scaffold` bodies com `Center > ConstrainedBox` ou `Align` onde necessário

### 3. Ajustes por página (Web/Tablet)

#### Navegação
- [ ] `BottomNavigationBar` — em desktop, considerar `NavigationRail` lateral (Nice to Have)
- [ ] Verificar que o navbar não ultrapassa largura máxima

#### Páginas de listagem
- [ ] `home_page.dart` — grid de cards com `crossAxisCount` responsivo (1 coluna mobile, 2 tablet+)
- [ ] `my_rooms_page.dart` — mesma lógica de grid
- [ ] `search_page.dart` — filtros podem ir para sidebar em desktop (Nice to Have)
- [ ] `notifications_page.dart` — lista com `maxWidth`

#### Páginas de detalhe
- [ ] `hotel_details_page.dart` — layout de duas colunas em tablet (imagem | detalhes)
- [ ] `room_details_page.dart` — idem
- [ ] `ticket_details_page.dart` — card centralizado com `maxWidth`

#### Formulários e perfis
- [ ] `login_page.dart` / `user_signup_page.dart` / `host_signup_page.dart` — card centralizado com `maxWidth: 480`
- [ ] `user_profile_page.dart` / `host_profile_page.dart` / `admin_profile_page.dart` — conteúdo centralizado
- [ ] Formulários de edição (`edit_*_page.dart`) — `maxWidth: 600`

#### Checkout
- [ ] `checkout_page.dart` — layout de duas colunas em tablet (resumo | formulário)

### 4. Testar orientações
- [ ] Portrait mobile (375px)
- [ ] Landscape mobile (667px)
- [ ] Tablet portrait (768px)
- [ ] Desktop/Web (1280px)

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `lib/core/utils/breakpoints.dart` | **Criar** — constantes e helpers de breakpoint |
| Todas as `*_page.dart` listadas | Adicionar `ConstrainedBox` / `maxWidth` / grid responsivo |
| `lib/core/widgets/` compartilhados | Garantir que respondam a `MediaQuery` |

---

## Dependências
- **Não bloqueia** nenhuma outra task — pode rodar em paralelo com P6-A
- **Não depende de** backend

## Observações
- Priorizar Web (MVP) sobre tablet (Nice to Have) — fazer na ordem listada
- Não redesenhar fluxos, apenas adaptar layouts existentes
- Landscape portrait já é requisito MVP — verificar que nenhuma página quebra ao girar o device
