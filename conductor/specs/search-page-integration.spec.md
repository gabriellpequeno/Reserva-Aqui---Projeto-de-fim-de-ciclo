# Spec — Search Page Integration (P4-B)

## Referência
- **PRD:** `conductor/features/search-page-integration.prd.md`

## Abordagem Técnica

Criar um `SearchService` isolado para encapsular a chamada HTTP ao endpoint `GET /api/quartos/busca` (EXT-1, já implementado no backend). Modificar `SearchNotifier.performSearch()` para delegar ao service em vez do mock atual. Implementar os dois pickers ausentes (`showDateRangePicker` nativo do Material para datas; `GuestsPickerSheet` como bottom sheet com contador para hóspedes) diretamente em `search_page.dart`. Mapear o response do backend (`SearchRoomResult`) para o modelo de UI `FavoriteRoom`, construindo a URL de imagem dinamicamente a partir de `hotel_id` + `quarto_id`.

## Componentes Afetados

### Backend
- **N/A** — endpoint EXT-1 (`GET /api/quartos/busca`) já implementado e disponível.

### Frontend
- **Novo:** `SearchRoomResult` (`lib/features/search/data/models/search_room_result.dart`) — model local que representa o JSON retornado pelo backend; inclui `fromJson`.
- **Novo:** `SearchService` (`lib/features/search/data/services/search_service.dart`) — encapsula a chamada `GET /quartos/busca`, retorna `List<SearchRoomResult>`; exposto como Riverpod `Provider`.
- **Novo:** `GuestsPickerSheet` (`lib/features/search/presentation/widgets/guests_picker_sheet.dart`) — bottom sheet com contador (+/-), min 1, max 20, confirma via botão.
- **Modificado:** `SearchNotifier.performSearch()` — substituir `Future.delayed` + mock por chamada real ao `SearchService`; mapear response → `FavoriteRoom`; adicionar guard para `destination` vazio (min 2 chars); tratar erro com reset de `isLoading`.
- **Modificado:** `SearchPage._buildSearchHeader()` — implementar `onTap` do campo de datas (chama `showDateRangePicker`) e do campo de hóspedes (chama `showModalBottomSheet` com `GuestsPickerSheet`); exibir data formatada `dd/MM/yy - dd/MM/yy` a partir do `dateRange` do estado.
- **Modificado:** `SearchPage._buildHotelCard()` — substituir `Image.asset` hardcoded por `Image.network(hotel.imageUrl, errorBuilder: ...)` com fallback para asset local.

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|---------------|
| `SearchService` isolado em vez de chamar `dio` direto no notifier | Separação clara: notifier orquestra estado, service faz I/O — alinhado ao padrão já adotado em `UsuarioService`/`HotelService`. |
| `SearchRoomResult` como model local, **não** reutilizar `FavoriteRoom` no parse | Response do backend tem campos distintos (`quarto_id`, `hotel_id`, `itens[]`, `valor_diaria` como string). `FavoriteRoom` é o contrato da UI — converter após o I/O. |
| Manter `_buildHotelCard` local em vez de usar `FavoriteCard` da feature Favorites | `FavoriteCard` tem lógica de Dismissible (swipe-to-delete) acoplada ao `favoritesProvider` — comportamento incorreto no contexto de resultados de busca. |
| `showDateRangePicker` nativo do Material sem biblioteca extra | Zero novas dependências; já alinhado ao design system do projeto. |
| `GuestsPickerSheet` como widget separado em vez de inline | Testável isoladamente; reutilizável em outras telas (home, room details) sem duplicação. |
| Datas enviadas à API como ISO `yyyy-MM-dd` | Formato canônico esperado pelo backend; evita ambiguidade de locale. |
| `rating: '—'` como placeholder | Backend EXT-1 não expõe rating nesta versão (documentado no spec da EXT-1 como dívida). UI não quebra; campo fica reservado. |
| `double.tryParse` em vez de `double.parse` em `valor_diaria` | Postgres retorna `numeric` como string; `tryParse` retorna `0.0` em vez de lançar exceção em edge cases. |
| `Image.network` com `errorBuilder` + fallback asset | Graceful degradation quando quarto não tem imagem cadastrada no backend. |

## Contratos de API

| Método | Rota | Query Params | Response |
|--------|------|--------------|----------|
| GET | `/api/quartos/busca` | `q` (string, obrigatório, min 2 chars); `checkin?` (ISO date `yyyy-MM-dd`); `checkout?` (ISO date `yyyy-MM-dd`); `hospedes?` (int ≥ 1) | `200` → `SearchRoomResult[]` · `400` → `{ error: string }` · `500` → `{ error: string }` |
| GET | `/uploads/hotels/:hotel_id/rooms/:quarto_id` | — | Bytes da imagem (multipart/form-data ou image/*) |

## Modelos de Dados

**Nenhuma tabela nova. Sem migration.**

Response do backend mapeado para model local Flutter:

```
SearchRoomResult {
  quarto_id:     int       // vira FavoriteRoom.id (toString)
  hotel_id:      String    // uuid — usado para construir imageUrl
  numero:        String
  descricao:     String?   // vira FavoriteRoom.title (fallback: 'Quarto #$quarto_id')
  valor_diaria:  String    // numeric do Postgres → double.tryParse → FavoriteRoom.price
  itens:         List<QuartoItem>  // → FavoriteRoom.amenities via _mapItemsToIcons()
  nome_hotel:    String    // → FavoriteRoom.hotelName
  cidade:        String    // → FavoriteRoom.destination ('$cidade, $uf')
  uf:            String
}

QuartoItem {
  catalogo_id:  int
  nome:         String
  categoria:    String
  quantidade:   int
}
```

Mapeamento `SearchRoomResult` → `FavoriteRoom`:

```
id           = quarto_id.toString()
title        = descricao ?? 'Quarto #$quarto_id'
hotelName    = nome_hotel
destination  = '$cidade, $uf'
imageUrl     = '$baseUrl/uploads/hotels/$hotel_id/rooms/$quarto_id'
rating       = '—'
amenities    = _mapItemsToIcons(itens)  // ≤ 4 ícones por keywords em nome/categoria
price        = double.tryParse(valor_diaria) ?? 0.0
```

Mapping de ícones por keyword no `nome` ou `categoria` do `QuartoItem` (case-insensitive, sem acento):

```
wifi / internet       → Icons.wifi
cama / bed            → Icons.king_bed
café / cafe / manhã   → Icons.free_breakfast
ar / ac / condicionado → Icons.ac_unit
piscina / pool        → Icons.pool
spa / massagem        → Icons.spa
tv / televisao        → Icons.tv
estacionamento / vaga → Icons.local_parking
(default / sem match) → ícone omitido (max 4 ícones exibidos)
```

## Dependências

**Bibliotecas:**
- [x] `dio` (^5.7.0) — já presente no `pubspec.yaml`
- [x] `flutter_riverpod` (^3.3.1) — já presente
- [x] Material `showDateRangePicker` — nativo do Flutter SDK, sem dependência extra

**Serviços externos:**
- [x] Backend `GET /api/quartos/busca` (EXT-1) — implementado

**Outras features:**
- [x] P0 — `DioClient` como Riverpod Provider (`lib/core/network/dio_client.dart`) — reutilizado no `SearchService`
- [x] `FavoriteRoom` model (`lib/features/favorites/domain/models/favorite_room.dart`) — modelo de destino do mapeamento

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| `q` vazio / curto ao clicar "Buscar" | Guard no `performSearch()`: se `destination.trim().length < 2`, exibir `SnackBar` e retornar sem chamar a API. |
| `Image.network` sem imagem cadastrada no backend | `errorBuilder` no widget: fallback para `Image.asset('lib/assets/images/home_page.jpeg')`. |
| `showDateRangePicker` retorna `null` (usuário cancela) | Verificar `if (picked != null)` antes de chamar `updateDateRange`. |
| `double.tryParse` em `valor_diaria` retornar `null` | Fallback `?? 0.0` — preço zero é visualmente óbvio e não quebra o layout. |
| `context.mounted` stale após await do datepicker | Checar `if (context.mounted)` antes de chamar o notifier após qualquer `await`. |
| Backend retorna lista vazia para `q` válido | Estado vazio já implementado no `SearchNotifier` — nenhuma ação extra. |
| `itens[]` vazio → `amenities` lista vazia | `FavoriteCard`/`_buildHotelCard` já faz `Wrap` vazio sem crash — aceito. |
