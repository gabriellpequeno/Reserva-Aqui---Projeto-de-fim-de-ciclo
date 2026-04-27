# Plan — Search Page Integration

> Derivado de: conductor/specs/search-page-integration.spec.md
> Status geral: [PENDENTE]

---

## Setup & Infraestrutura [PENDENTE]

- [~] Alinhar `API_PREFIX` do backend (`Backend/src/app.ts:34`, hoje `/api`) com `_baseUrl` do Dio (`Frontend/lib/core/network/dio_client.dart:6`, hoje `http://localhost:3000/api/v1`) — ajustar um dos dois para consistência
- [ ] Confirmar que `intl` está declarado no `Frontend/pubspec.yaml` (necessário para `DateFormat('dd/MM/yy')` e formatação de rating)
- [ ] Centralizar lista de status de reserva bloqueantes (`'SOLICITADA'`, `'AGUARDANDO_PAGAMENTO'`, `'APROVADA'`) em constante exportada no `searchRoom.service.ts`

---

## Backend [PENDENTE]

- [ ] Estender validações em `Backend/src/controllers/searchRoom.controller.ts`: `q` (2–255 chars após trim), `checkin`+`checkout` em par no formato ISO `YYYY-MM-DD`, `hospedes` inteiro entre 1–20, `amenidades` CSV até 20 IDs positivos, com mensagens 400 específicas por campo
- [ ] Estender assinatura e corpo de `searchRooms` em `Backend/src/services/searchRoom.service.ts` para receber `{ q, checkin?, checkout?, hospedes?, amenidadeIds? }`
- [ ] Adicionar JOIN com `categoria_quarto cq ON cq.id = q.categoria_quarto_id` e filtro `cq.capacidade_pessoas >= $hospedes` quando `hospedes` presente
- [ ] Adicionar subquery `q.id IN (SELECT quarto_id FROM itens_do_quarto WHERE catalogo_id = ANY($amenidades) GROUP BY quarto_id HAVING COUNT(DISTINCT catalogo_id) = N)` para AND lógico de amenidades
- [ ] Adicionar `NOT EXISTS` em `reserva` (`r.quarto_id = q.id AND r.status IN (<status_bloqueantes>) AND r.data_checkin < $checkout AND r.data_checkout > $checkin`) para excluir reservas sobrepostas
- [ ] Manter `unaccent()` em `nome_hotel`, `cidade`, `uf`; manter escape de wildcards SQL (`%`, `_`, `\`) em `q`; manter `LIMIT 20` no fan-out; manter `deleted_at IS NULL` em `quarto`, `categoria_quarto`, `catalogo`
- [ ] Atualizar `Backend/src/routes/searchRoom.routes.test.ts` com happy path para cada filtro individual e combinações
- [ ] Adicionar testes 400: `q` ausente, `< 2` chars, `> 255` chars, `checkin`/`checkout` isolado, `checkout <= checkin`, data retroativa, formato inválido, `hospedes` não numérico/fora de range/decimal, `amenidades` malformado/> 20 IDs
- [ ] Adicionar testes de filtro: reserva `APROVADA` sobreposta exclui quarto; reserva `CANCELADA`/`CONCLUIDA` sobreposta NÃO exclui; sobreposição parcial e contenção total; `hospedes=3` exclui quarto com `capacidade=2`; amenity AND lógico (quarto com 1 de 2 amenidades é excluído)
- [ ] Adicionar testes de segurança: tentativas de SQL wildcard em `q` (`%`, `_`, `\`) são escapadas, não executadas
- [ ] Rodar `EXPLAIN` nas queries estendidas e confirmar uso dos índices existentes (`idx_reserva_datas`, `idx_quarto_ativo`); adicionar índice se degradação for observada

---

## Frontend [PENDENTE]

### Camada data/ & domain/

- [ ] Criar `Frontend/lib/features/search/data/dtos/search_room_result_dto.dart` com `SearchRoomResultDto` e `AmenityDto` aninhado, ambos com `fromJson(Map<String, dynamic>)`
- [ ] Criar `Frontend/lib/features/search/domain/models/amenity.dart` (`catalogoId: int`, `nome: String`, `categoria: String`, `quantidade: int`)
- [ ] Criar `Frontend/lib/features/search/domain/models/hotel_rating_summary.dart` (`average: double?`, `count: int`)
- [ ] Criar `Frontend/lib/features/search/domain/models/search_result_room.dart` (`roomId`, `hotelId`, `numero`, `descricao`, `precoDiaria`, `amenities: List<Amenity>`, `nomeHotel`, `cidade`, `uf`, `imageUrl: String?`, `rating: double?`, `reviewCount: int`) com factory `fromDto` sem rating/imageUrl
- [ ] Criar `Frontend/lib/features/search/data/services/search_service.dart` com `searchRooms({required String q, DateTime? checkin, DateTime? checkout, int? hospedes, List<int>? amenidadeIds})` → `GET /api/quartos/busca`, formatando datas como `YYYY-MM-DD` e amenidades como CSV, traduzindo `DioException` para `SearchException`
- [ ] Criar `Frontend/lib/features/search/data/services/avaliacao_service.dart` com `fetchHotelRating(String hotelId)` → `GET /api/hotel/:id/avaliacoes`, calculando média de `nota_total` e count, retornando `average: null` quando vazio
- [ ] Criar `Frontend/lib/features/search/data/services/upload_service.dart` com `fetchFirstRoomPhotoUrl(String hotelId, int quartoId)` → `GET /api/uploads/hotels/:hotel_id/rooms/:quarto_id`, retornando `url` da foto com menor `ordem` ou `null` se `fotos[]` vazio
- [ ] Registrar `searchServiceProvider`, `avaliacaoServiceProvider`, `uploadServiceProvider` como Riverpod Providers consumindo `dioProvider`
- [ ] Escrever testes unitários de `fromJson` dos DTOs e mapeamento DTO→domain

### Notifier & State

- [ ] Redefinir `SearchState` em `Frontend/lib/features/search/presentation/providers/search_provider.dart`: campos `destination`, `dateRange: DateTimeRange?`, `guests: int?`, `selectedAmenityIds: Set<int>`, `availableAmenities: List<Amenity>`, `results: List<SearchResultRoom>`, `isLoading`, `error: String?`, `hasSearched: bool`
- [ ] Remover os 3 `FavoriteRoom` hardcoded do `SearchNotifier`
- [ ] Implementar `performSearch()` com fluxo: validar `destination.trim().length >= 2` → `searchService.searchRooms(...)` → `Future.wait` de `fetchHotelRating` para cada `hotelId` único → `Future.wait` de `fetchFirstRoomPhotoUrl` para cada quarto → mesclar (`rating`/`reviewCount` do summary, `imageUrl` do upload) → derivar `availableAmenities` deduplicando `itens[]` por `catalogoId`
- [ ] Adicionar setters `updateDateRange(DateTimeRange?)`, `updateGuests(int?)`, `toggleAmenity(int catalogoId)` / `setAmenities(Set<int>)`
- [ ] Tratar erros no `performSearch` setando `state.error` e mantendo `isLoading = false`

### UI — SearchPage & Widgets

- [ ] Atualizar `Frontend/lib/features/search/presentation/pages/search_page.dart`: remover string hardcoded `"14/04/26 - 15/04/26"` e `Image.asset(...home_page.jpeg...)` mockado
- [ ] Conectar campo de datas a `showDateRangePicker()` (firstDate = hoje, lastDate = hoje + 2 anos), formatar display com `intl` como `dd/MM/yy - dd/MM/yy`, placeholder `"Selecionar datas"` quando null
- [ ] Criar `Frontend/lib/features/search/presentation/widgets/guest_counter_bottom_sheet.dart`: contador +/− com range 1–20, valor inicial `state.guests ?? 1`, botões "Confirmar" (chama `onConfirm(int)`) e "Limpar" (passa `null`), dismiss não altera state
- [ ] Conectar campo de hóspedes ao `GuestCounterBottomSheet`, placeholder `"Hóspedes"` quando null
- [ ] Criar `Frontend/lib/features/search/presentation/widgets/amenities_filter_dropdown.dart`: lista com Checkbox agrupada por `categoria`, botões "Aplicar" e "Limpar", mensagem `"Faça uma busca para filtrar por comodidades"` quando `availableAmenities` vazio
- [ ] Conectar ícone de filtro (lado direito) ao `AmenitiesFilterDropdown`; ao aplicar, atualizar `selectedAmenityIds` e disparar nova busca
- [ ] Criar `Frontend/lib/features/search/presentation/widgets/search_result_card.dart` consumindo `SearchResultRoom`: `Image.network(url)` quando `imageUrl != null`, placeholder visual neutro (ícone de cama/hotel) caso contrário; rating formatado via `intl` ou `"Sem avaliações"` quando `rating == null`; chips com `amenities[].nome`; `onTap: context.push('/room_details/${room.roomId}')`
- [ ] Renderizar resultados em `GridView.builder` (web) ou `ListView.builder` (mobile) com `SearchResultCard`
- [ ] Implementar empty state diferenciado (sem busca vs. busca sem resultados vs. busca com filtros ativos sem resultados)
- [ ] Implementar exibição de erro via `SnackBar` quando `state.error != null`
- [ ] Conectar botão "Buscar" a `searchNotifier.performSearch()`

---

## Validação [PENDENTE]

- [ ] Busca com `q` simples retorna quartos reais do backend (sem mock) e renderiza em grid (web) / lista (mobile)
- [ ] Date range picker abre ao tocar no campo, seleciona intervalo, formata exibição como `dd/MM/yy - dd/MM/yy` e envia ISO `YYYY-MM-DD` à API
- [ ] `GuestCounterBottomSheet` abre ao tocar no campo, ajusta valor no range 1–20, botão "Confirmar" aplica, "Limpar" remove filtro, dismiss sem confirmar não altera state
- [ ] `AmenitiesFilterDropdown` mostra mensagem "Faça uma busca para filtrar por comodidades" quando `availableAmenities` vazio
- [ ] Após 1ª busca, dropdown popula com `itens[]` dos resultados (sem duplicatas, agrupados por categoria)
- [ ] Selecionar múltiplas comodidades e aplicar dispara nova busca; backend retorna apenas quartos com TODAS as comodidades (AND lógico)
- [ ] Buscar com `checkin`/`checkout` selecionados: quarto com reserva `APROVADA` sobreposta NÃO aparece; quarto com reserva `CANCELADA` ou `CONCLUIDA` sobreposta APARECE
- [ ] Buscar com `hospedes=3` exclui quarto cuja `categoria_quarto.capacidade_pessoas = 2`
- [ ] Filtros omitidos não são enviados à API (`dateRange == null`, `guests == null`, `selectedAmenityIds.isEmpty` → params ausentes na query string)
- [ ] Card exibe imagem real via `Image.network(url)` usando foto de menor `ordem`; quarto sem foto exibe placeholder visual neutro (sem foto genérica simulando quarto)
- [ ] Card exibe rating calculado (média de `nota_total` via `Future.wait` paralelo); hotel sem avaliações exibe exatamente `"Sem avaliações"` (nunca `0.0` ou valor fixo)
- [ ] Tocar em um card navega para `/room_details/:roomId` via `context.push`
- [ ] Empty state real aparece ao buscar sem resultados, diferenciado quando há filtros ativos
- [ ] Erro 400 ou 500 do backend aciona `SnackBar` com a mensagem do corpo
- [ ] Layout responsivo: grid em web, lista em mobile
- [ ] Acessibilidade: date picker, bottom sheet de hóspedes e dropdown de comodidades navegáveis via teclado com foco visível na web
- [ ] Testes unitários backend: cada caso 400 da tabela de validações do spec
- [ ] Teste de segurança: tentativa de `%`, `_`, `\` no parâmetro `q` é escapada e não altera a semântica do LIKE
- [ ] Zero hardcode confirmado: `grep` no código final não retorna `rating: '4.`, `"14/04/26"`, `'wifi'`, `Image.asset(...home_page.jpeg...)` nem outras strings mockadas anteriores
