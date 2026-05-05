# Spec — web-landing-page

## Referência
- **PRD:** conductor/features/web-landing-page.prd.md

## Abordagem Técnica

Criar uma nova feature `landing` em `lib/features/landing/` seguindo a arquitetura de features existente no projeto (presentation/pages + presentation/widgets + data/services). A página será registrada no `app_router.dart` como rota pública `/landing`, fora do `ShellRoute` (sem bottom nav / drawer). Em mobile (< 768px) a rota `/landing` redireciona para `/`. O menu sanduíche será um widget próprio dentro da feature. Os quartos em destaque serão buscados da API via endpoint existente; os depoimentos serão **dados estáticos mockados** (sem endpoint de reviews no backend). A identidade visual seguirá `app_colors.dart` e os componentes reutilizáveis existentes (`RoomCard`, `primary_button.dart`).

---

## Componentes Afetados

### Backend — Modificar / Criar

| Arquivo | O que muda |
|---------|-----------|
| API — endpoint de destaques | Usar `GET /quartos/recomendados` (já existe em `home_notifier.dart`) com `limit=6` se suportado, ou filtrar no cliente |

> Endpoint de reviews não existe e não será criado nesta entrega — depoimentos são dados estáticos.

### Frontend — Criar

| Arquivo | O que é |
|---------|---------|
| `lib/features/landing/presentation/pages/landing_page.dart` | Página principal — orquestra todas as seções |
| `lib/features/landing/presentation/widgets/landing_header.dart` | Header fixo com logo + menu sanduíche (ou links horizontais em desktop) |
| `lib/features/landing/presentation/widgets/hero_section.dart` | Seção Hero: headline, subtítulo, 2 CTAs |
| `lib/features/landing/presentation/widgets/how_it_works_section.dart` | Seção "Como funciona": fluxo usuário + fluxo anfitrião |
| `lib/features/landing/presentation/widgets/featured_rooms_section.dart` | Seção de quartos em destaque: grid de até 6 `RoomCard` |
| `lib/features/landing/presentation/widgets/ai_assistant_section.dart` | Seção "Bene, IA no WhatsApp": descrição + mockup + CTA |
| `lib/features/landing/presentation/widgets/testimonials_section.dart` | Seção de depoimentos: cards com dados estáticos mockados |
| `lib/features/landing/presentation/widgets/landing_footer.dart` | Footer com links de seções, Sobre, Contato |
| `lib/features/landing/presentation/widgets/chat_fab.dart` | FAB fixo no canto direito para abrir o chat com Bene |
| `lib/features/landing/data/services/landing_service.dart` | Chamadas à API: somente quartos em destaque |
| `lib/features/landing/data/models/testimonial_model.dart` | Model para depoimentos (dados estáticos definidos no próprio arquivo) |
| `lib/features/landing/presentation/providers/landing_provider.dart` | Riverpod provider somente para quartos em destaque; depoimentos não usam provider |

### Frontend — Modificar

| Arquivo | O que muda |
|---------|-----------|
| `lib/core/router/app_router.dart` | Adicionar rota `/landing` fora do `ShellRoute`; adicionar redirect mobile→`/` quando `width < 768` |

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| Rota `/landing` fora do `ShellRoute` | A landing não usa bottom nav nem drawer — tem header e footer próprios. Colocá-la fora do shell evita sobrepor a navegação do app |
| Redirect `/landing` → `/` em mobile (< 768px) | PRD define que em mobile o visitante vai direto para a homepage do app; o redirect no router é mais limpo que condicional dentro da página |
| Reutilizar `RoomCard` existente (`lib/features/home/presentation/widgets/room_card.dart`) | Garante identidade visual idêntica ao app sem duplicação de código |
| Reutilizar `primary_button.dart` para CTAs | Mesma razão — consistência de estilo sem esforço |
| Reutilizar `GET /quartos/recomendados` para quartos em destaque | Endpoint já existe e retorna dados reais; evita criar endpoint novo no backend |
| `ScrollController` com chaves `GlobalKey` para scroll-to-section | O menu sanduíche aponta para rotas internas do app — mas links internos da landing (footer) precisam de scroll âncora; `GlobalKey` é a solução idiomática em Flutter web |
| `chat_fab.dart` como widget independente posicionado com `Stack` | Permite reutilização futura e não acopla a lógica do chat à estrutura da landing |
| Depoimentos com dados estáticos (`mockTestimonials` em `testimonial_model.dart`) | Endpoint de reviews não existe no backend e não será criado nesta entrega; dados mockados realistas baseados no seed do projeto (5 hotéis, 6 usuários) eliminam a dependência |

---

## Contratos de API

| Método | Rota | Query Params | Response |
|--------|------|-------------|----------|
| GET | `/quartos/recomendados` | `limit=6` (se suportado) | `Room[]` — modelo já existente em `room.dart` |

> Depoimentos não consomem API — dados definidos estaticamente em `testimonial_model.dart`.

---

## Modelos de Dados

```
TestimonialModel {
  id: String
  userName: String
  userPhotoUrl: String?   // URL de avatar ou null (exibe inicial do nome)
  text: String
  rating: double          // 1.0 – 5.0
  hotelName: String?
}
```

O arquivo `testimonial_model.dart` exporta também a lista estática `mockTestimonials` com ~6 entradas baseadas nos usuários e hotéis do seed do projeto. Não há `createdAt` — depoimentos estáticos não precisam de timestamp.

> `Room` e `RoomCard` já existem — não há modelo novo para a seção de destaque.

---

## Estrutura de Navegação da Landing

```
/landing
├── LandingHeader (fixo, z-index alto)
│   ├── Logo (→ /landing)
│   └── Menu sanduíche / links horizontais em desktop
│       ├── Home        → /
│       ├── Busca       → /search
│       ├── Bene        → /chat (ou scroll para #ai-section)
│       ├── Login       → /auth/login       (se não autenticado)
│       └── Perfil      → /profile          (se autenticado)
│
├── HeroSection          (#hero)
├── HowItWorksSection    (#como-funciona)
├── FeaturedRoomsSection (#quartos)
├── AiAssistantSection   (#bene)
├── TestimonialsSection  (#depoimentos)
├── LandingFooter
│   ├── Links de seção (âncoras)
│   └── Sobre / Contato
│
└── ChatFab (Stack, fixo canto inferior direito)
```

---

## Implementação de Referência

### Registro da rota em `app_router.dart`
```dart
GoRoute(
  path: '/landing',
  redirect: (context, state) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.tablet) return '/';
    return null;
  },
  builder: (context, state) => const LandingPage(),
),
```

### Estrutura da `LandingPage`
```dart
Scaffold(
  body: Stack(
    children: [
      CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: HeroSection(...)),
          SliverToBoxAdapter(child: HowItWorksSection()),
          SliverToBoxAdapter(child: FeaturedRoomsSection()),
          SliverToBoxAdapter(child: AiAssistantSection()),
          SliverToBoxAdapter(child: TestimonialsSection()),
          SliverToBoxAdapter(child: LandingFooter(onSectionTap: _scrollTo)),
        ],
      ),
      Positioned(top: 0, left: 0, right: 0, child: LandingHeader(...)),
      Positioned(bottom: 24, right: 24, child: ChatFab()),
    ],
  ),
)
```

### Header responsivo
```dart
// mobile/tablet: ícone sanduíche → Drawer ou BottomSheet
// desktop (≥ 1024px): links horizontais no AppBar
isDesktop(context)
  ? Row(children: [_NavLink('Home'), _NavLink('Busca'), ...])
  : IconButton(icon: Icon(Icons.menu), onPressed: _openMenu)
```

---

## Dependências

**Bibliotecas:**
- [ ] Nenhuma nova — usa `flutter_riverpod`, `go_router`, `dio` e `flutter_svg` já presentes no `pubspec.yaml`

**Serviços externos:**
- [ ] API backend (já configurada via `dio_client.dart`) — somente endpoint de recomendados; reviews não consomem API

**Outras features:**
- [ ] `responsividade-web-tablet` — os helpers `isTablet(context)` / `isDesktop(context)` e `Breakpoints` serão usados na landing; implementar em paralelo ou antes
- [ ] `chat` — `ChatFab` abre a rota `/chat` ou o widget de chat existente em `lib/features/chat/`; dependência de interface, não de dados
- [ ] `auth` — o header altera links (Login/Cadastro → Perfil) com base no `authProvider` já existente

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| `GlobalKey` para scroll âncora pode conflitar com `CustomScrollView` em alguns casos de rebuild | Usar `Scrollable.ensureVisible` com `GlobalKey` apenas no footer; testar no Chrome antes de fechar a feature |
| Header fixo com `Stack` + `CustomScrollView` pode gerar problema de padding no primeiro `SliverToBoxAdapter` | Adicionar `SliverPadding` com `top: kToolbarHeight + 16` no primeiro sliver para compensar a altura do header |
| Redirect mobile no router usa `MediaQuery` — em hot reload pode não disparar corretamente | Aceitar comportamento em dev; em produção o redirect funciona corretamente no carregamento inicial |
| `RoomCard` existente pode ter dependências de providers que não existem fora do `ShellRoute` | Auditar `room_card.dart` antes de reutilizar; se depender de providers do shell, extrair a parte visual para um widget sem estado |
