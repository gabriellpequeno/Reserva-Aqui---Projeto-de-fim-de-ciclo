# Plan — Search Page Integration (P4-B)

> Derivado de: `conductor/specs/search-page-integration.spec.md`
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Criar pasta `lib/features/search/data/models/`
- [x] Criar pasta `lib/features/search/data/services/`
- [x] Criar pasta `lib/features/search/presentation/widgets/`

---

## Backend [CONCLUÍDO]

- [x] Endpoint `GET /api/quartos/busca` implementado (EXT-1)
- [x] Endpoint `GET /uploads/hotels/:hotel_id/rooms/:quarto_id` disponível

---

## Frontend [CONCLUÍDO]

- [x] Criar `SearchRoomResult` + `QuartoItem` com `fromJson` em `lib/features/search/data/models/search_room_result.dart`
- [x] Criar `SearchService` em `lib/features/search/data/services/search_service.dart` com método `searchRooms({required String q, String? checkin, String? checkout, int? hospedes})` que chama `GET /api/quartos/busca` via `DioClient`
- [x] Expor `searchServiceProvider` como `Provider<SearchService>` no mesmo arquivo
- [x] Criar helper `_mapItemsToIcons(List<QuartoItem> itens)` que converte `QuartoItem.nome`/`categoria` em `List<IconData>` (máximo 4 ícones, por keywords sem acento)
- [x] Criar `GuestsPickerSheet` em `lib/features/search/presentation/widgets/guests_picker_sheet.dart` — bottom sheet com contador (+/-), min 1, max 20, botão "Confirmar"
- [x] Atualizar `SearchNotifier.performSearch()` em `search_provider.dart`:
  - Guard: `destination.trim().length < 2` → não chama API
  - Chamar `SearchService.searchRooms` com `q`, `checkin`, `checkout`, `hospedes`
  - Mapear `List<SearchRoomResult>` → `List<FavoriteRoom>` usando helper de ícones e construindo `imageUrl` com `baseUrl`
  - Tratar erro (`DioException`) → resetar `isLoading: false`, manter `results` inalterados
- [x] Atualizar `SearchNotifier` para receber `SearchService` via `build()` usando `ref.watch(searchServiceProvider)`
- [x] Atualizar `search_page.dart` — campo de hóspedes: implementar `onTap` com `showModalBottomSheet(GuestsPickerSheet)` conectado ao `updateGuests()`
- [x] Atualizar `search_page.dart` — campo de datas: implementar `onTap` com `showDateRangePicker` (firstDate: hoje, lastDate: hoje + 365 dias); formatar exibição `dd/MM/yy - dd/MM/yy`; checar `context.mounted` antes de chamar `updateDateRange()`
- [x] Atualizar `search_page.dart` — campo de datas: substituir valor hardcoded `'14/04/26 - 15/04/26'` por exibição dinâmica do `state.dateRange` (se nulo, exibir hint 'Data')
- [x] Atualizar `search_page.dart` — campo de hóspedes: exibir `'${state.guests} Hóspede(s)'` dinamicamente
- [x] Atualizar `SearchPage._buildHotelCard()` — substituir `Image.asset` hardcoded por `Image.network(hotel.imageUrl, errorBuilder: (_, __, ___) => Image.asset('lib/assets/images/home_page.jpeg'))`

---

## Validação [PENDENTE]

- [ ] Testar busca ponta a ponta: digitar cidade no campo destino → clicar "Buscar" → resultados reais exibidos em lista (mobile) e grid (web)
- [ ] Testar guard de `q` curto: clicar "Buscar" com campo vazio → sem chamada à API (verificar via DevTools/log)
- [ ] Testar picker de datas: tocar campo de datas → date range picker abre → selecionar intervalo → campo exibe `dd/MM/yy - dd/MM/yy` formatado
- [ ] Testar picker de hóspedes: tocar campo de hóspedes → bottom sheet abre → incrementar/decrementar → confirmar → campo reflete novo valor
- [ ] Testar busca com datas e hóspedes preenchidos: verificar que params `checkin`, `checkout`, `hospedes` são enviados na query string
- [ ] Testar estado de loading: spinner exibido durante chamada à API
- [ ] Testar estado vazio: busca sem resultados exibe ícone + texto "Encontre o lugar perfeito"
- [ ] Testar imagem de quarto: card exibe imagem real via `Image.network`; verificar fallback quando imagem não existe
- [ ] Testar navegação: tocar em "Ver Mais" no card → navega para `/room_details/:id` com o id correto
- [ ] Verificar responsividade: grid em web (largura > 800px) e lista em mobile funcionam com dados reais
