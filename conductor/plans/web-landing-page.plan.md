# Plan — web-landing-page

> Derivado de: conductor/specs/web-landing-page.spec.md
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Criar estrutura de diretórios da feature: `lib/features/landing/presentation/pages/`, `lib/features/landing/presentation/widgets/`, `lib/features/landing/presentation/providers/`, `lib/features/landing/data/services/`, `lib/features/landing/data/models/`
- [x] Auditar `lib/features/home/presentation/widgets/room_card.dart` — verificar se depende de providers do `ShellRoute`; se sim, extrair parte visual para widget stateless reutilizável

---

## Backend [CONCLUÍDO]

> Nenhuma task de backend — endpoint `GET /quartos/recomendados` já existe; depoimentos são dados estáticos.

---

## Frontend [CONCLUÍDO]

### Dados & Providers
- [x] Criar `lib/features/landing/data/models/testimonial_model.dart` — definir `TestimonialModel` (id, userName, userPhotoUrl?, text, rating, hotelName?) e exportar lista estática `mockTestimonials` com ~6 entradas baseadas no seed do projeto
- [x] Criar `lib/features/landing/data/services/landing_service.dart` — método `getFeaturedRooms()` consumindo `GET /quartos/recomendados` via `dioProvider`; limitar a 6 resultados no cliente se o endpoint não suportar `limit`
- [x] Criar `lib/features/landing/presentation/providers/landing_provider.dart` — `AsyncNotifierProvider` para `getFeaturedRooms()`; depoimentos não precisam de provider

### Roteamento
- [x] Atualizar `lib/core/router/app_router.dart` — registrar `GoRoute(path: '/landing', ...)` fora do `ShellRoute` com redirect para `/` quando `width < Breakpoints.tablet`

### Widgets da Landing
- [x] Criar `lib/features/landing/presentation/widgets/landing_header.dart` — logo à esquerda + menu sanduíche à direita (mobile/tablet) ou links horizontais (desktop ≥ 1024px); links: Home `/`, Busca `/search`, Bene `/chat`, Login `/auth/login` ou Perfil `/profile` (baseado em `authProvider`)
- [x] Criar `lib/features/landing/presentation/widgets/hero_section.dart` — headline, subtítulo e 2 CTAs: "Explorar quartos" (→ `/search`) e "Cadastre-se" (→ abre modal de cadastro ou navega para `/auth/signup`)
- [x] Criar `lib/features/landing/presentation/widgets/how_it_works_section.dart` — passo a passo visual com ícone + título + descrição curta; dois fluxos: usuário (Buscar → Escolher → Reservar → Check-in) e anfitrião (Cadastrar Hotel → Visibilidade → Acompanhar Métricas)
- [x] Criar `lib/features/landing/presentation/widgets/featured_rooms_section.dart` — grid de até 6 cards usando `RoomCard` existente; exibir estado de loading (shimmer) e estado de erro
- [x] Criar `lib/features/landing/presentation/widgets/ai_assistant_section.dart` — apresentação do Bene: nome, descrição do que faz, mockup/screenshot ilustrativo e CTA para abrir o chat
- [x] Criar `lib/features/landing/presentation/widgets/testimonials_section.dart` — grid de cards de depoimentos usando `mockTestimonials`; cada card exibe avatar ou inicial do nome, texto, nota em estrelas e nome do hotel
- [x] Criar `lib/features/landing/presentation/widgets/landing_footer.dart` — links de âncora para seções da própria landing + links Sobre e Contato; recebe callbacks `onSectionTap` para scroll âncora
- [x] Criar `lib/features/landing/presentation/widgets/chat_fab.dart` — `FloatingActionButton` posicionado no canto inferior direito via `Stack`; ao clicar navega para `/chat` ou abre o widget de chat existente

### Página Principal
- [x] Criar `lib/features/landing/presentation/pages/landing_page.dart` — orquestra todos os widgets acima com `Stack` (header fixo + `CustomScrollView` com `SliverToBoxAdapter` por seção + `ChatFab`); adicionar `SliverPadding` no primeiro sliver para compensar altura do header fixo; implementar `_scrollTo(GlobalKey)` para scroll âncora do footer

---

## Validação [CONCLUÍDO]

- [x] Acessar `/landing` em **desktop (1280px)** — verificar que todas as seções (Hero, Como Funciona, Quartos em Destaque, Bene, Depoimentos, Footer) estão visíveis sem scroll horizontal
- [x] Acessar `/landing` em **mobile (375px)** — verificar redirect automático para `/` (homepage do app)
- [x] Clicar no ícone de menu sanduíche (tablet/mobile) — verificar que os links Home, Busca, Bene, Login/Perfil aparecem e redirecionam corretamente
- [x] Clicar em **"Explorar quartos"** no Hero — verificar redirecionamento para `/search`
- [x] Clicar em **"Cadastre-se"** no Hero — verificar abertura do fluxo de cadastro
- [x] Verificar seção **Quartos em Destaque** — máximo 6 cards com foto e comodidades; exibir shimmer durante carregamento
- [x] Verificar seção **Depoimentos** — 6 cards mockados com nome, texto, nota e hotel exibidos corretamente
- [x] Verificar que **`/`** (homepage atual) não foi alterada após registrar `/landing`
- [x] Acessar `/landing` autenticado — verificar que links Login/Cadastro no header se tornam "Perfil"
- [x] Verificar **ChatFab** — botão visível no canto inferior direito; ao clicar abre o chat com Bene
- [x] Testar scroll âncora do footer — clicar em cada link de seção e verificar que a página rola até a seção correta
- [x] Verificar layout responsivo em **768px** (tablet) — colunas e espaçamentos corretos nas seções
