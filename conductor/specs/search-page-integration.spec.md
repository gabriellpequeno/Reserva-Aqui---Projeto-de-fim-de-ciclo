# Spec — Search Page Integration

## Referência

- **PRD:** `conductor/features/search-page-integration.prd.md`
- **Branch:** `feat/search-page-integration`

---

## Abordagem Técnica

Integrar a UI do Flutter (SearchPage + SearchNotifier) ao backend real, substituindo **todos** os dados mockados (resultados, rating, comodidades, imagem) por dados vindos da API. Esta versão implementa filtros funcionais de ponta-a-ponta no backend (`q`, `checkin`, `checkout`, `hospedes`, `amenidades`) e monta os controles de UI (date range picker, contador de hóspedes, dropdown de comodidades) com estado real.

Princípios norteadores:

- **Zero hardcode.** `rating`, `imageUrl`, `amenities`, `price`, `destination` e demais campos vêm exclusivamente da API.
- **Filtros reais no backend.** `checkin`/`checkout` excluem quartos com reservas ativas sobrepostas; `hospedes` filtra por `categoria_quarto.capacidade_pessoas`; `amenidades` filtra via junção `itens_do_quarto`.
- **Agregações derivadas em runtime.** Rating por hotel é calculado a partir de `/api/hotel/:hotel_id/avaliacoes` (chamadas paralelas, uma por hotel único dos resultados). Dropdown de comodidades é derivado do `itens[]` dos resultados correntes.
- **Camada `data/` nova no frontend.** Feature `search` hoje só tem `presentation/` — é preciso introduzir `data/services/`, `data/dtos/` e `domain/models/` próprios.

---

## Componentes Afetados

### Backend

**Modificado: `Backend/src/controllers/searchRoom.controller.ts`**
- Validar `q` (obrigatório, 2–255 chars, trim) com mensagens específicas por caso.
- Validar `checkin` e `checkout`: ambos presentes juntos, formato ISO `YYYY-MM-DD`, `checkout > checkin`, não retroativos.
- Validar `hospedes`: inteiro ≥ 1 e ≤ 20; rejeitar `"abc"`, `"NaN"`, negativos, decimais.
- Validar `amenidades`: CSV de inteiros positivos (`catalogo_id`), máximo 20 IDs, rejeitar não numéricos.
- Em erro de validação, retornar 400 com `{ error: "<mensagem>" }` apontando o campo inválido.

**Modificado: `Backend/src/services/searchRoom.service.ts`**
- Expandir a assinatura de `searchRooms` para receber `{ q, checkin?, checkout?, hospedes?, amenidades? }`.
- No fan-out por tenant (`withTenant(schemaName, client)`):
  - JOIN `categoria_quarto cq ON cq.id = q.categoria_quarto_id` (sempre necessário para capacidade).
  - JOIN `itens_do_quarto iq ON iq.quarto_id = q.id` e `catalogo c ON c.id = iq.catalogo_id AND c.deleted_at IS NULL`.
  - Se `hospedes` enviado: `AND cq.capacidade_pessoas >= $hospedes`.
  - Se `amenidades` enviado: subquery `WHERE q.id IN (SELECT quarto_id FROM itens_do_quarto WHERE catalogo_id = ANY($amenidades) GROUP BY quarto_id HAVING COUNT(DISTINCT catalogo_id) = <tamanho_do_array>)` — exige que o quarto tenha TODAS as comodidades selecionadas.
  - Se `checkin` e `checkout` enviados: `AND NOT EXISTS (SELECT 1 FROM reserva r WHERE r.quarto_id = q.id AND r.status IN ('SOLICITADA','AGUARDANDO_PAGAMENTO','APROVADA') AND r.data_checkin < $checkout AND r.data_checkout > $checkin)`.
- Manter `unaccent()` em `nome_hotel`, `cidade`, `uf`; manter escape de wildcards `%`, `_`, `\` em `q`; manter `LIMIT 20` no fan-out mestre.
- Manter `deleted_at IS NULL` em `quarto`, `categoria_quarto`, `catalogo`.

**Modificado: `Backend/src/routes/searchRoom.routes.test.ts`**
- Happy path com cada filtro individualmente e combinações.
- `q` ausente, `q.length < 2`, `q.length > 255` → 400.
- `checkin` sem `checkout` (e vice-versa) → 400.
- `checkout <= checkin` → 400.
- Data inválida (`"abc"`, `"2026-13-99"`) → 400.
- `hospedes = "abc"`, `"-1"`, `"0"`, `"21"`, `"1.5"` → 400.
- `amenidades = "abc"`, `"1,abc,3"`, CSV com 21 IDs → 400.
- Tentativas de SQL wildcard em `q` (`%`, `_`, `\`) devem ser escapadas, não executadas.
- Filtro de datas: quarto com reserva `APROVADA` sobreposta é excluído; quarto com reserva `CANCELADA` ou `CONCLUIDA` sobreposta é incluído; sobreposição parcial e contenção total testadas.
- Filtro de hóspedes: quarto de capacidade 2 excluído quando `hospedes=3`; incluído quando `hospedes=2`.
- Filtro de amenidades: quarto que tem apenas 1 das 2 amenidades requisitadas é excluído (AND lógico).

### Frontend

**Novo: `Frontend/lib/features/search/data/dtos/search_room_result_dto.dart`**
- DTO espelhando a resposta da API (`quarto_id`, `hotel_id`, `numero`, `descricao`, `valor_diaria`, `itens`, `nome_hotel`, `cidade`, `uf`).
- `fromJson(Map<String, dynamic>)` obrigatório.
- DTO aninhado `AmenityDto` (`catalogo_id`, `nome`, `categoria`, `quantidade`).

**Novo: `Frontend/lib/features/search/domain/models/search_result_room.dart`**
- Modelo de domínio próprio do feature `search` (não reusa `FavoriteRoom`, cujos tipos são inadequados — `rating: String`, `amenities: List<IconData>`).
- Campos: `roomId: int`, `hotelId: String`, `numero: String`, `descricao: String?`, `precoDiaria: String`, `amenities: List<Amenity>`, `nomeHotel: String`, `cidade: String`, `uf: String`, `imageUrl: String?` (primeira foto ou `null`), `rating: double?` (média das avaliações do hotel ou `null`), `reviewCount: int` (default 0).
- Factory `fromDto(SearchRoomResultDto)` sem rating/imageUrl — esses vêm em passos separados.

**Novo: `Frontend/lib/features/search/domain/models/amenity.dart`**
- Campos: `catalogoId: int`, `nome: String`, `categoria: String`, `quantidade: int`.
- Substitui o uso atual de `List<IconData>` para amenidades.

**Novo: `Frontend/lib/features/search/data/services/search_service.dart`**
- `Future<List<SearchRoomResultDto>> searchRooms({required String q, DateTime? checkin, DateTime? checkout, int? hospedes, List<int>? amenidadeIds})` → `GET /api/quartos/busca`.
- Formatar datas como `YYYY-MM-DD`; formatar `amenidadeIds` como CSV.
- Tratar erros `DioException` e traduzir para `SearchException` com mensagem extraída do `error` do corpo.

**Novo: `Frontend/lib/features/search/data/services/avaliacao_service.dart`**
- `Future<HotelRatingSummary> fetchHotelRating(String hotelId)` → `GET /api/hotel/:hotel_id/avaliacoes`.
- Calcula média de `nota_total` e `count` a partir da lista de avaliações. Retorna `HotelRatingSummary(average: null, count: 0)` quando vazio.

**Novo: `Frontend/lib/features/search/data/services/upload_service.dart`**
- `Future<String?> fetchFirstRoomPhotoUrl(String hotelId, int quartoId)` → `GET /api/uploads/hotels/:hotel_id/rooms/:quarto_id`, retorna JSON `{ fotos: [{ id, ordem, url }] }`.
- Retorna a `url` do item com menor `ordem`, ou `null` se array vazio.

**Modificado: `Frontend/lib/features/search/presentation/providers/search_provider.dart` (renomear o arquivo para `search_notifier.dart` se o padrão do projeto for esse — confirmar com os outros features)**
- Remover os 3 `FavoriteRoom` hardcoded.
- `SearchState` passa a guardar: `destination`, `dateRange: DateTimeRange?`, `guests: int?` (null = não filtrado), `selectedAmenityIds: Set<int>`, `results: List<SearchResultRoom>`, `availableAmenities: List<Amenity>` (derivado após cada busca), `isLoading`, `error: String?`.
- `performSearch()` fluxo:
  1. Validar `destination.trim().length >= 2`, senão setar `error` e abortar.
  2. Chamar `searchService.searchRooms(...)` com parâmetros atuais.
  3. Para cada `hotelId` único dos resultados, chamar `avaliacaoService.fetchHotelRating(hotelId)` em paralelo (`Future.wait`).
  4. Para cada quarto, chamar `uploadService.fetchFirstRoomPhotoUrl(hotelId, quartoId)` em paralelo (`Future.wait`).
  5. Mesclar: `rating` vem do summary do hotel; `imageUrl` vem do resultado do upload; `amenities` vem do próprio resultado.
  6. Derivar `availableAmenities` deduplicando por `catalogoId` de todos os `itens[]`.
- `toggleAmenity(int catalogoId)` altera `selectedAmenityIds` sem buscar novamente (usuário confirma no dropdown).
- `updateDateRange(DateTimeRange?)`, `updateGuests(int?)`: setters normais.

**Modificado: `Frontend/lib/features/search/presentation/pages/search_page.dart`**
- Remover a string hardcoded `"14/04/26 - 15/04/26"` (linha 119 atual).
- Campo de datas `onTap`: abrir `showDateRangePicker()` do Material (firstDate = hoje, lastDate = hoje + 2 anos). Formatar com `intl` (`DateFormat('dd/MM/yy')`) como `"dd/MM/yy - dd/MM/yy"`. Placeholder `"Selecionar datas"` quando null.
- Campo de hóspedes `onTap`: abrir `GuestCounterBottomSheet` novo. Placeholder `"Hóspedes"` quando null.
- Ícone de filtro (lado direito): abrir `AmenitiesFilterDropdown` novo com `state.availableAmenities`, seleção atual `state.selectedAmenityIds`. Ao confirmar, aciona `toggleAmenity` (ou `setAmenities(Set<int>)`) e re-executa `performSearch()`.
- Botão de busca: aciona `performSearch()`.
- Render dos resultados: `ListView.builder` / `GridView.builder` com `SearchResultCard` novo (ou `FavoriteCard` adaptado — ver item abaixo).
- Se `state.results.isEmpty && !isLoading && hasSearched`, mostrar empty state real.
- Se `state.error != null`, mostrar snackbar/erro.

**Novo: `Frontend/lib/features/search/presentation/widgets/guest_counter_bottom_sheet.dart`**
- Bottom sheet modal com contador (+ / −), range 1–20.
- Valor inicial = `state.guests ?? 1`.
- Botão "Confirmar" chama `onConfirm(int)` e fecha o sheet.
- Botão "Limpar" passa `null` e fecha (remove o filtro).
- Dismiss (swipe/backdrop) não altera estado.

**Novo: `Frontend/lib/features/search/presentation/widgets/amenities_filter_dropdown.dart`**
- Dropdown/bottom sheet com lista de `Amenity` vinda de `state.availableAmenities`.
- Agrupar visualmente por `categoria`.
- Cada item com `Checkbox` controlado por `selectedIds.contains(catalogoId)`.
- Botão "Aplicar" retorna `Set<int>` via callback. Botão "Limpar" retorna `<int>{}`.
- Se `availableAmenities` vazio (nenhuma busca feita ainda ou resultados sem itens), mostrar mensagem "Faça uma busca para filtrar por comodidades".

**Novo: `Frontend/lib/features/search/presentation/widgets/search_result_card.dart`** *(alternativa: adaptar `FavoriteCard`)*
- Consome `SearchResultRoom`.
- Se `imageUrl == null`, `Image.asset` com placeholder neutro (ex: ícone de cama/hotel) — não é hardcode de dado, é fallback visual declarado.
- Se `rating == null`, exibir "Sem avaliações"; se presente, formatar com `intl` (ex: `4.5 (23)`).
- Exibir `amenities` como chips horizontais com o `nome` real.
- `onTap`: `context.push('/room_details/${room.roomId}')` (rota já existe em `app_router.dart:136-143`).

**Modificado: `Frontend/lib/features/favorites/domain/models/favorite_room.dart`** *(opcional, apenas se for reusar no search)*
- Não alterar agora — a mudança de tipos (`rating: String` → `double?`, `amenities: List<IconData>` → `List<Amenity>`) quebraria `FavoritesNotifier` e `RoomDetailsPage`. Criar modelo novo `SearchResultRoom` e deixar refactor de `FavoriteRoom` para outra feature.

**Modificado: `Frontend/lib/core/network/dio_client.dart`**
- Validar `baseUrl` contra o backend: hoje está `http://localhost:3000/api/v1`, mas `Backend/src/app.ts:34` usa `API_PREFIX = '/api'`. Confirmar se o `.env` do backend define `API_PREFIX=/api/v1`. Se não, **ajustar `_baseUrl` para `http://localhost:3000/api`**. Essa task é pré-requisito para qualquer chamada funcionar.

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---|---|
| **Filtros reais no backend (não client-side)** | Evita transferir lista inteira para o cliente só para filtrar depois. Faz uso correto dos índices já existentes (`idx_reserva_datas`, `idx_quarto_ativo`). |
| **Filtro `amenidades` com AND lógico (`HAVING COUNT = N`)** | Semântica natural: usuário que marca "WiFi + Ar" espera quartos com **ambos**, não quartos com qualquer um dos dois. |
| **Rating calculado em runtime no frontend** | Schema atual não expõe `avg_rating` agregado; calcular no cliente evita mudança de schema e mantém endpoint de busca simples. N chamadas paralelas de `/avaliacoes` é aceitável com `LIMIT 20` no fan-out (no máximo ~20 hotéis únicos). |
| **`imageUrl` obtido em chamada separada** | `GET /api/uploads/hotels/:hotel_id/rooms/:quarto_id` é um endpoint de metadados; não faz sentido duplicar seu payload dentro da resposta de busca. Chamadas paralelas via `Future.wait` mantêm latência baixa. |
| **Dropdown de comodidades derivado dos resultados** | Não há endpoint global `/api/comodidades`; derivar dos `itens[]` evita N chamadas a `/api/hotel/:id/catalogo` (per-tenant). Trade-off: dropdown só aparece após a 1ª busca. |
| **Modelo `SearchResultRoom` separado de `FavoriteRoom`** | Tipos de `FavoriteRoom` (rating String, amenities List<IconData>) são incompatíveis com dados reais. Refatorar `FavoriteRoom` aqui expandiria o escopo para features não relacionadas. |
| **`checkin`/`checkout` obrigatórios em par** | Disponibilidade sem intervalo fechado não faz sentido; rejeitar combinação parcial evita bugs sutis. |
| **Capacidade por categoria, não por quarto** | `capacidade_pessoas` vive em `categoria_quarto` no schema atual (`init_tenant.sql:47`) — o filtro JOIN respeita essa modelagem. |
| **`LIMIT 20` mantido no fan-out de hotéis** | Controla carga; primeira versão não precisa de paginação. |
| **Format de data `dd/MM/yy - dd/MM/yy` (exibição)** / ISO 8601 (API) | `intl` formata para o usuário; API aceita apenas `YYYY-MM-DD` para evitar ambiguidade. |

---

## Contratos de API

### GET /api/quartos/busca

| Aspect | Detalhe |
|---|---|
| **Método** | GET |
| **Rota** | `/api/quartos/busca` |
| **Auth** | ❌ Público |
| **Query Params** | |
| — `q` | ✅ **Obrigatório**, string, 2–255 chars (após trim) |
| — `checkin` | ⚪ Opcional, `YYYY-MM-DD`. Exige `checkout` junto. Não pode ser anterior a hoje. |
| — `checkout` | ⚪ Opcional, `YYYY-MM-DD`. Exige `checkin` junto. Deve ser estritamente maior que `checkin`. |
| — `hospedes` | ⚪ Opcional, inteiro entre 1 e 20. |
| — `amenidades` | ⚪ Opcional, CSV de inteiros positivos (`catalogo_id`), até 20 IDs. Filtro AND (quarto precisa ter TODAS). |

**Response (200 OK):**
```json
[
  {
    "quarto_id": 123,
    "hotel_id": "uuid-or-id",
    "numero": "101",
    "descricao": "Suite deluxe com varanda",
    "valor_diaria": "R$ 350,00",
    "itens": [
      { "catalogo_id": 1, "nome": "WiFi", "categoria": "Technology", "quantidade": 1 },
      { "catalogo_id": 2, "nome": "Ar-condicionado", "categoria": "Comfort", "quantidade": 1 }
    ],
    "nome_hotel": "Hotel Paradise",
    "cidade": "São Paulo",
    "uf": "SP"
  }
]
```

**Response (400 Bad Request)** — mensagens por caso:

| Situação | `error` |
|---|---|
| `q` ausente | `"Parâmetro q é obrigatório"` |
| `q` < 2 chars | `"Parâmetro q deve ter no mínimo 2 caracteres"` |
| `q` > 255 chars | `"Parâmetro q não pode exceder 255 caracteres"` |
| `checkin` ou `checkout` isolado | `"checkin e checkout devem ser enviados juntos"` |
| Data com formato inválido | `"Formato de data inválido em <campo> (use YYYY-MM-DD)"` |
| `checkout <= checkin` | `"checkout deve ser posterior a checkin"` |
| `checkin` retroativo | `"checkin não pode ser anterior à data atual"` |
| `hospedes` não numérico | `"Parâmetro hospedes deve ser um inteiro"` |
| `hospedes` fora de 1–20 | `"Parâmetro hospedes deve estar entre 1 e 20"` |
| `amenidades` malformado | `"Parâmetro amenidades deve ser CSV de inteiros"` |
| `amenidades` > 20 IDs | `"Parâmetro amenidades não pode exceder 20 IDs"` |

**Response (500 Internal Server Error):**
```json
{ "error": "Erro interno" }
```

### GET /api/uploads/hotels/:hotel_id/rooms/:quarto_id

| Aspect | Detalhe |
|---|---|
| **Método** | GET |
| **Rota** | `/api/uploads/hotels/:hotel_id/rooms/:quarto_id` |
| **Auth** | ❌ Público |
| **Response (200)** | `{ "fotos": [{ "id": number, "ordem": number, "criado_em": string, "url": string }] }` |

> ⚠️ Correção em relação ao spec anterior: este endpoint retorna **JSON de metadados**, não a imagem binária. O binário é servido em `/api/uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id`. O frontend usa `url` direto em `Image.network()`.

### GET /api/hotel/:hotel_id/avaliacoes

| Aspect | Detalhe |
|---|---|
| **Método** | GET |
| **Rota** | `/api/hotel/:hotel_id/avaliacoes` |
| **Auth** | ❌ Público |
| **Response (200)** | `{ "data": AvaliacaoSafe[] }` — campos relevantes: `nota_total: number`, `nota_limpeza`, `nota_atendimento`, `nota_conforto`, `nota_organizacao`, `nota_localizacao`, `comentario: string \| null` |
| **Uso no frontend** | Calcular `average = mean(data.map(a => a.nota_total))` e `count = data.length`. Se `data` vazio → `average = null`. |

---

## Modelos de Dados

### Backend — input do service

```typescript
interface SearchRoomsInput {
  q: string;                  // 2-255, trim, escapado
  checkin?: string;           // YYYY-MM-DD
  checkout?: string;          // YYYY-MM-DD
  hospedes?: number;          // 1-20
  amenidadeIds?: number[];    // até 20, catalogo_id
}
```

### Backend — output (inalterado)

```typescript
interface SearchRoomResult {
  quarto_id: number;
  hotel_id: string;
  numero: string;
  descricao: string | null;
  valor_diaria: string;
  itens: { catalogo_id: number; nome: string; categoria: string; quantidade: number }[];
  nome_hotel: string;
  cidade: string;
  uf: string;
}
```

### Frontend — domínio

```dart
class Amenity {
  final int catalogoId;
  final String nome;
  final String categoria;
  final int quantidade;
}

class HotelRatingSummary {
  final double? average; // null quando count == 0
  final int count;
}

class SearchResultRoom {
  final int roomId;
  final String hotelId;
  final String numero;
  final String? descricao;
  final String precoDiaria;
  final List<Amenity> amenities;
  final String nomeHotel;
  final String cidade;
  final String uf;
  final String? imageUrl; // null quando sem fotos
  final double? rating;   // null quando hotel sem avaliações
  final int reviewCount;
}

class SearchState {
  final String destination;
  final DateTimeRange? dateRange;
  final int? guests;                    // null = não filtrado
  final Set<int> selectedAmenityIds;    // catalogo_id selecionados
  final List<Amenity> availableAmenities; // derivado dos resultados
  final List<SearchResultRoom> results;
  final bool isLoading;
  final String? error;
  final bool hasSearched;
}
```

---

## Dependências

### Bibliotecas (Flutter)

- ✅ `dio` — já em uso, `dioProvider` em `lib/core/network/dio_client.dart`.
- ✅ `flutter_riverpod` — já em uso.
- ✅ `intl` — para `DateFormat('dd/MM/yy')` e formatação de rating. Verificar `pubspec.yaml`.
- ✅ `go_router` — já em uso (`app_router.dart`).

### Serviços Externos

- ✅ `GET /api/quartos/busca` — busca cross-tenant (**a ser estendido com filtros reais nesta feature**).
- ✅ `GET /api/hotel/:hotel_id/avaliacoes` — já implementado, público.
- ✅ `GET /api/uploads/hotels/:hotel_id/rooms/:quarto_id` — já implementado, público, retorna JSON de metadados.

### Outras Features

- ✅ `HTTP client setup` — `dioProvider` já existe. **Pré-requisito:** conferir `_baseUrl` em `dio_client.dart:6` (`/api/v1`) contra `API_PREFIX` do backend (`/api`).
- ✅ `Route /room_details/:roomId` — já definida em `Frontend/lib/core/router/app_router.dart:136-143`.

---

## Riscos Técnicos

| Risco | Mitigação |
|---|---|
| Mudança de assinatura do `searchRooms` service quebra testes existentes | Atualizar `searchRoom.routes.test.ts` junto; considerar parâmetros opcionais com defaults para não quebrar chamadores que ainda só passam `q`. |
| N+1 de chamadas a `/avaliacoes` e `/uploads` prejudica latência | `Future.wait` em paralelo; `LIMIT 20` garante no máximo ~20 hotéis + ~20 rooms. Se latência virar problema, considerar endpoint agregado (fora do escopo). |
| Filtro de amenidades com AND retorna 0 resultados com frequência | Aceitar como comportamento correto; UI deixa claro no empty state que filtros estão ativos e oferece "Limpar filtros". |
| Baseurl divergente entre frontend e backend (`/api/v1` vs `/api`) | Task explícita de conferência antes da integração começar. |
| `quarto.capacidade` inexistente no schema | Usar `categoria_quarto.capacidade_pessoas` via JOIN (confirmado em `init_tenant.sql:47`). |
| Status de reserva que bloqueiam datas podem mudar | Centralizar a lista `('SOLICITADA','AGUARDANDO_PAGAMENTO','APROVADA')` em constante no service para futuras mudanças. |
| Quarto sem foto quebra `Image.network` | `imageUrl` é `String?`; card usa fallback visual declarado (`Image.asset` placeholder). |
| Hotel sem avaliações causa divisão por zero | `HotelRatingSummary.average` é `double?` e fica `null` quando `data.length == 0`. |
| SQL wildcard injection em `q` | Escape de `%`, `_`, `\` já existe em `searchRoom.service.ts:42-44` — manter e cobrir em testes. |
| Usuário fecha picker sem confirmar | Date picker e bottom sheets não alteram state no dismiss; só no `onConfirm`. |
| `amenidades` com IDs que não existem | `catalogo_id` inválidos simplesmente não casam no JOIN; resultado vazio é aceitável. |

---

## Fluxo de Implementação

### Phase 0 — Pré-requisito de infra (bloqueante)

1. Conferir `API_PREFIX` no `.env` do backend e `_baseUrl` em `Frontend/lib/core/network/dio_client.dart:6`. Alinhar para `/api` ou `/api/v1` consistentemente.

### Phase 1 — Backend (filtros reais)

1. Estender `searchRoom.controller.ts` com as validações novas e tradução para tipos do service.
2. Estender `searchRoom.service.ts` com JOINs (`categoria_quarto`, `itens_do_quarto`, subquery de reserva) e WHEREs condicionais.
3. Atualizar `searchRoom.routes.test.ts` cobrindo happy paths e cada validação 400.
4. Verificar `EXPLAIN` das queries se houver preocupação de performance; considerar índices adicionais se necessário.

### Phase 2 — Frontend (camada data/)

1. Criar `SearchRoomResultDto`, `AmenityDto` e `SearchResultRoom`, `Amenity`, `HotelRatingSummary`.
2. Criar `SearchService`, `AvaliacaoService`, `UploadService` com providers Riverpod.
3. Escrever testes unitários de `fromJson` e mapeamentos DTO→domain.

### Phase 3 — Frontend (notifier e UI)

1. Reescrever `SearchNotifier.performSearch()` com fluxo real (busca + rating + imagem em paralelo).
2. Implementar `showDateRangePicker()` no campo de datas.
3. Criar e integrar `GuestCounterBottomSheet`.
4. Criar e integrar `AmenitiesFilterDropdown` (derivado dos resultados).
5. Criar `SearchResultCard` (ou adaptar `FavoriteCard` com wrapper de mapeamento).
6. Remover todos os strings hardcoded de data (`"14/04/26 - 15/04/26"`), amenities (`"wifi"`, etc.), `Image.asset` mockado.
7. Empty state real e error handling.

### Phase 4 — Testes & QA

1. Testes de widget para `SearchPage` (pickers abrem, callbacks disparam).
2. Teste de integração (mock `Dio`) para `SearchNotifier.performSearch()` cobrindo: sucesso, lista vazia, erro 400, erro 500, hotel sem avaliações, quarto sem foto.
3. QA manual em web (grid) e mobile (lista): selecionar datas, hóspedes, comodidades, submeter, tocar num card → `/room_details/:id`.
4. Verificar queries SQL reais no banco (log) ao mudar filtros no app.

---

## Notas Importantes

- **Zero hardcode por contrato:** `rating`, `imageUrl`, `amenities`, `price`, `destination`, `dateRange` — **todos** vêm de API ou de input real do usuário. O único "valor fixo" aceitável é um placeholder visual (ex: ícone quando `imageUrl == null`), não dado fingido.
- **Autocomplete de cidades** (RF #1 do PRD) é removido desta versão — não há endpoint `/api/cidades` no backend. Campo destino é texto livre. PRD precisa ser atualizado em paralelo.
- **Filtros opcionais** só são enviados à API quando o usuário efetivamente os seleciona. `dateRange == null`, `guests == null`, `selectedAmenityIds.isEmpty` → params omitidos.
- **Formato de data exibido:** `dd/MM/yy - dd/MM/yy` via `intl`. Formato enviado à API: `YYYY-MM-DD` (ISO 8601).
- **Rating fallback:** quando `rating == null`, exibir "Sem avaliações" (não "0.0" e não placeholder falso).
- **Imagem fallback:** quando `imageUrl == null`, exibir ícone/placeholder neutro declarado em asset — **não** uma foto genérica que simule um quarto real.
