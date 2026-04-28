# Plan — Hotel Details Page

> Derivado de: conductor/specs/hotel-details-page.spec.md
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Verificar se `GET /hotel/:hotel_id` retorna dados básicos do hotel sem autenticação — reutilizando `GET /:hotel_id/configuracao` que retorna nome, descricao, cidade, uf

---

## Backend [PENDENTE]

- [ ] Nenhuma task de backend necessária — todos os endpoints já existem

---

## Frontend [CONCLUÍDO]

- [x] Criar `HotelDetailsState` (`lib/features/rooms/presentation/notifiers/hotel_details_state.dart`) com campo `isLoading`, `hasError` global e seções: nome, descricao, cidade, uf, coverUrls, comodidades, categorias, avaliacoes, notaMedia, politicas
- [x] Criar modelos de domínio consolidados em `lib/features/rooms/domain/models/hotel_details.dart`:
  - `ComodidadeHotelModel`
  - `CategoriaHotelModel` (com itens)
  - `AvaliacaoHotelModel` (com cálculo de timeAgo)
  - `PoliticasHotelModel`
- [x] Criar `HotelDetailsNotifier` (`lib/features/rooms/presentation/notifiers/hotel_details_notifier.dart`) disparando 5 futures em paralelo com `Future.wait` e tratamento individual via try/catch — cada falha não bloqueia as demais
- [x] Convertida `hotel_details_page.dart` de `ConsumerWidget` para `ConsumerStatefulWidget`
- [x] Seção de comodidades: agrupada por categoria com chips
- [x] Substituir todos os dados mockados por `ref.watch(hotelDetailsNotifierProvider)` — nome, descrição, local, avaliações, políticas
- [x] Implementar filtro de camas: sem filtro ativo por padrão, toggle on tap (usar Set<int> local state)

---

## Validação [PENDENTE]

- [ ] Navegar para a tela com um `hotelId` real e verificar que nome, descrição e fotos (capa e perfil) renderizam corretamente
- [ ] Verificar que avaliações e nota média aparecem corretamente
- [ ] Verificar que comodidades do hotel aparecem na seção de catálogo
- [ ] Verificar que cards de quartos aparecem sem filtro ativo por padrão; selecionar e desselecionar filtro de camas e confirmar comportamento
- [ ] Verificar loading states (skeletons/loaders) em cada seção durante o carregamento
- [ ] Testar com `hotelId` inválido e verificar que mensagem de erro adequada é exibida
