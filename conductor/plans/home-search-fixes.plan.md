# Plan — home-search-fixes

> Derivado de: conductor/specs/home-search-fixes.spec.md
> Status geral: [CONCLUÍDO]

---

## Backend [CONCLUÍDO]

- [x] Verificar se endpoint `/quartos/recomendados` retorna campo `preco` (float) — sim, `home_notifier.dart` já usa `_parsePrice(data['price'])`
- [x] Documentar se endpoint precisa de modificação no backend — não precisa; `/uploads/hotels/:hotel_id/rooms/:quarto_id` já em uso no search_provider; `dio_client.dart` usa `/api/v1` como base

---

## Frontend [CONCLUÍDO]

### Home Page
- [x] Ajustar slide 1: descer título com paddingTop adequado — `top: MediaQuery.of(context).padding.top + 24`
- [x] Ajustar slide 1: aproximar logo do texto, igualar largura com SizedBox — `SizedBox(width: 260)` envolvendo texto; `SizedBox(height: 6)` entre texto e logo
- [x] Ajustar slide 2: adicionar padding top ao conteúdo — `SizedBox(height: 60)` (era 40)
- [x] Remover barra vertical semitransparente (chevron_right) no lado direito do slide 2 — removido Stack + Positioned com chevron_right
- [x] Não adicionar indicadores de dots (foram tentados e removidos por causar conflito visual com EXPLORAR)

### RoomCard
- [x] Reorganizar layout: mover avaliação para ao lado das comodidades — rating badge na Row das comodidades (direita)
- [x] Adicionar campo de preço da diária no card — parâmetro opcional `double? price`
- [x] Formatar nota com toStringAsFixed(1) — `_formatRating()` com parse + toStringAsFixed(1)
- [x] Adicionar parâmetros `cardWidth` e `cardMargin` para reutilização na search page

### Search Page
- [x] Centralizar logo no header — `Stack(alignment: Alignment.center)` com `Center(logo)` e `Align(right, notif icon)`
- [x] Adicionar padding top ao conteúdo — `EdgeInsets.fromLTRB(24, 60, 24, 24)` (era 50)
- [x] Implementar herança de pesquisa: receber query da home e executar busca automaticamente — `initialQuery` no constructor + `postFrameCallback` com `performSearch()`
- [x] Adicionar filtro de comodidades — `_buildFilterPanel()` + toggle com `Icons.tune` (Buscar button + tune icon em Row)
- [x] Herança de comodidades da home — `initialAmenities` set aplicado no `initState`
- [x] Padronizar cards com o RoomCard da home — `LayoutBuilder` + `RoomCard(cardWidth, cardMargin)`
- [x] Modificar para exibir foto do quarto via endpoint `/uploads/hotels/:hotel_id/rooms/:quarto_id` — já feito no `search_provider.dart`

### Router
- [x] Rota `/search` aceita parâmetro de query e amenities — extra pode ser `String` ou `Map{query, amenities}`; `SearchPage(initialQuery, initialAmenities)`

### Home Page — navegação
- [x] `_submitSearch` passa `extra: Map{query, amenities}` — sem mais chamada direta ao `searchProvider`
- [x] Import `search_provider` removido do home_page.dart

---

## Validação [PENDENTE]

- [ ] Testar visualmente slide 1 da home: título posicionado, logo/textos com mesma largura
- [ ] Testar visualmente slide 2 da home: conteúdo com padding, sem chevron lateral
- [ ] Testar RoomCard: avaliação ao lado das comodidades, preço visível, nota com 1 casa decimal
- [ ] Testar search page: logo centralizado, conteúdo com padding adequado
- [ ] Testar herança de pesquisa: digitar na home → navegar → busca executada automaticamente
- [ ] Testar herança de filtros: selecionar comodidades na home → navegar → filtros pré-selecionados na search
- [ ] Testar filtro de comodidades na search page
- [ ] Testar consistência visual entre cards da home e da busca
- [ ] Testar foto do card: verificar se é foto do quarto e não do hotel
