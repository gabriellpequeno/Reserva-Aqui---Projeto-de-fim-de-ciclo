# PRD — responsividade-web-tablet

## Contexto

O app Reserva Aqui é uma aplicação Flutter com suporte web habilitado (`flutter run -d chrome`). Ele já funciona corretamente em mobile portrait, mas ao ser acessado via browser desktop ou tablet, o layout não aproveita o espaço horizontal disponível — o conteúdo se estica ou quebra visualmente. A Fase 10 (Polimento Final) exige que o produto seja entregue funcional no browser (MVP) e com ajustes para tablet (Nice to Have).

## Problema

O app não possui breakpoints definidos nem restrições de largura máxima. Em telas maiores (≥768px), o conteúdo ocupa 100% da largura sem controle, gerando layouts deformados, grids com colunas insuficientes e formulários excessivamente largos. Isso compromete a experiência do usuário no ambiente web, que é requisito MVP.

## Público-alvo

- **Usuários finais** que acessam o app via browser desktop ou tablet para buscar e reservar quartos
- **Anfitriões** que gerenciam seus quartos pelo painel web
- **Administradores** que acessam o painel admin via desktop

## Requisitos Funcionais

1. O sistema deve definir constantes de breakpoints (`tablet: 768px`, `desktop: 1024px`) em `lib/core/utils/breakpoints.dart` com helpers `isTablet(context)` e `isDesktop(context)`
2. Todas as páginas devem centralizar o conteúdo com largura máxima (`maxWidth: 600`) usando `Center > ConstrainedBox` no body do `Scaffold`
3. As páginas de listagem (`home_page`, `my_rooms_page`) devem exibir grid com `crossAxisCount` responsivo: 1 coluna em mobile, 2 colunas em tablet+
4. As páginas de detalhe (`hotel_details_page`, `room_details_page`) devem exibir layout de duas colunas em tablet (imagem | detalhes)
5. A página `checkout_page` deve exibir layout de duas colunas em tablet (resumo | formulário)
6. Os formulários de autenticação (`login_page`, `user_signup_page`, `host_signup_page`) devem ser renderizados como card centralizado com `maxWidth: 480`
7. Os formulários de edição (`edit_*_page.dart`) devem ter `maxWidth: 600`
8. As páginas de perfil (`user_profile_page`, `host_profile_page`, `admin_profile_page`) devem centralizar o conteúdo
9. A `BottomNavigationBar` não deve ultrapassar a largura máxima definida
10. O sistema deve funcionar corretamente nas quatro orientações-alvo: mobile portrait (375px), mobile landscape (667px), tablet portrait (768px) e desktop/web (1280px)

## Requisitos Não-Funcionais

- [ ] Performance: mudanças de layout devem ser baseadas apenas em `MediaQuery` (sem bibliotecas externas), sem impacto perceptível no tempo de renderização
- [ ] Segurança: nenhuma alteração em lógica de autenticação ou dados — apenas camada de apresentação
- [ ] Acessibilidade: widgets centralizados devem manter a ordem de foco e leitura de tela compatível com a estrutura atual
- [ ] Responsividade: o app deve funcionar sem quebras visuais em todas as quatro larguras-alvo (375px, 667px, 768px, 1280px)

## Critérios de Aceitação

- Dado que o usuário acessa o app via browser desktop (1280px), quando navegar para qualquer página, então o conteúdo deve estar centralizado e limitado a `maxWidth: 600` (ou 480 para formulários de auth)
- Dado que o usuário acessa a home em tablet (768px), quando a lista de quartos carregar, então o grid deve exibir 2 colunas
- Dado que o usuário acessa `hotel_details_page` em tablet (768px), quando a página carregar, então imagem e detalhes devem ser exibidos lado a lado em duas colunas
- Dado que o usuário acessa `checkout_page` em tablet (768px), quando a página carregar, então resumo e formulário devem ser exibidos em duas colunas
- Dado que o usuário acessa `login_page` em desktop, quando a página carregar, então o formulário deve aparecer como card centralizado com largura máxima de 480px
- Dado que o usuário está em mobile portrait (375px), quando navegar pelo app, então nenhuma página deve ter regressão visual em relação ao comportamento atual
- Dado que o usuário gira o dispositivo para landscape (667px), quando qualquer página estiver aberta, então o layout não deve quebrar nem criar overflow horizontal

## Fora de Escopo

- Redesenho de fluxos de navegação ou alteração de lógica de negócio
- Implementação de `NavigationRail` lateral para desktop (Nice to Have — pode ser feito em iteração futura)
- Sidebar de filtros na `search_page` em desktop (Nice to Have)
- Integração com backend ou alterações em APIs
- Criação de novas páginas ou features
- Suporte a telas menores que 375px
- Testes automatizados de responsividade (widget tests / integration tests) — validação manual nas quatro larguras-alvo
