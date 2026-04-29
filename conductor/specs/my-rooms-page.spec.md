# Spec — my-rooms-page

## Referência
- **PRD:** conductor/features/my-rooms-page.prd.md

## Abordagem Técnica

Criar `MyRoomsNotifier` + `MyRoomsState` seguindo o padrão Riverpod já estabelecido no projeto (mesmo estilo do `HotelDetailsNotifier`). Ao montar a tela, disparar em paralelo via `Future.wait` (com tratamento individual de exceções): `GET /hotel/quartos`, `GET /hotel/categorias` e `GET /hotel/reservas` (filtrado por janela de datas relevante).

No cliente, agregar os `Quarto[]` por `categoria_quarto_id` gerando `RoomCategoryCardModel[]`, anexar nome/descrição da categoria e calcular a ocupação por dia a partir das reservas ativas via um utilitário puro `AvailabilityCalculator` (testável isoladamente).

Os fluxos de escrita ficam em dialogs dedicados:
- **Delete:** `DeleteRoomDialog` coleta a quantidade N e dispara N chamadas `DELETE /hotel/quartos/:id` em paralelo via `Future.wait(eagerError: false)`; após execução, recarrega a lista e comunica sucessos/falhas parciais.
- **Reserva manual:** `ManualReservationDialog` exibe calendário de range com os dias lotados da categoria já marcados como indisponíveis; ao confirmar, chama `POST /hotel/reservas` com `canal_origem: "manual"`.

O backend recebe um ajuste mínimo em `Reserva.validateWalkin` para aceitar reservas manuais sem identificação de hóspede, preservando a validação estrita para walk-ins de balcão tradicionais.

## Componentes Afetados

### Backend
- **Modificado:** enum `CanalOrigem` (`Backend/src/entities/Reserva.ts`) — adicionar valor `"manual"` caso ainda não exista.
- **Modificado:** `Reserva.validateWalkin` (`Backend/src/entities/Reserva.ts`) — quando `canal_origem === "manual"`, dispensar a obrigatoriedade de identificação do hóspede (`user_id` / `nome_hospede` + `cpf_hospede` ou `telefone_contato`). Demais validações (datas, `num_hospedes`, `valor_total`) permanecem ativas.
- **Modificado:** `createReservaWalkin` (`Backend/src/services/reserva.service.ts`) — garantir que reservas manuais não disparem efeitos colaterais dependentes de hóspede (ex: notificações de confirmação, vínculo com fidelidade). Persistir `canal_origem = "manual"` no registro.
- **Verificação:** schema do banco já suporta (`nome_hospede`, `cpf_hospede`, `telefone_contato` são nullable). Não há migration necessária.
- Nenhum endpoint novo. Todos os demais fluxos da feature consomem endpoints já existentes.

### Frontend
- **Novo:** `MyRoomsNotifier` (`lib/features/rooms/presentation/notifiers/my_rooms_notifier.dart`)
- **Novo:** `MyRoomsState` (`lib/features/rooms/presentation/notifiers/my_rooms_state.dart`)
- **Novo:** `QuartoModel` (`lib/features/rooms/domain/models/quarto.dart`) — uma unidade física
- **Novo:** `CategoriaQuartoModel` (`lib/features/rooms/domain/models/categoria_quarto.dart`) — reavaliar reuso do `CategoriaModel` já existente em `hotel_details`; se divergir, criar dedicado
- **Novo:** `RoomCategoryCardModel` (`lib/features/rooms/domain/models/room_category_card.dart`) — modelo agregado que alimenta cada card
- **Novo:** `ReservaHotelModel` (`lib/features/rooms/domain/models/reserva_hotel.dart`) — subset dos campos necessários para cálculo de disponibilidade
- **Novo:** `AvailabilityCalculator` (`lib/features/rooms/domain/services/availability_calculator.dart`) — utilitário puro que recebe `List<ReservaHotelModel>` + `totalUnidades` e retorna `Set<DateTime>` de dias indisponíveis
- **Novo:** `DeleteRoomDialog` (`lib/features/rooms/presentation/widgets/delete_room_dialog.dart`) — confirmação + quantity picker (min 1, max = total de unidades)
- **Novo:** `ManualReservationDialog` (`lib/features/rooms/presentation/widgets/manual_reservation_dialog.dart`) — calendário de range com dias lotados marcados como indisponíveis
- **Modificado:** `my_rooms_page.dart` (`lib/features/rooms/presentation/pages/my_rooms_page.dart`) — remover mock, consumir `myRoomsNotifierProvider`, plugar busca local + filtro por categoria, wire dos dialogs, tratar estados (loading, error, empty), FAB para `add_room_page`, tap em editar navega para `edit_room_page`

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|---------------|
| Agregação por categoria no frontend | Backend entrega `Quarto[]` com `categoria_quarto_id`; agregar no cliente evita endpoint duplicado e é computacionalmente barato |
| N chamadas `DELETE` em paralelo (`Future.wait(eagerError: false)`) | Reusa endpoint já auditado com `hotelGuard`; permite coletar sucessos e falhas individuais |
| Recarregar lista do backend após delete | Fonte da verdade é o servidor; evita divergência de estado em falhas parciais |
| Disponibilidade computada client-side via `AvailabilityCalculator` puro | Nenhum endpoint dedicado existe hoje; classe pura é testável e trivialmente substituível pelo endpoint do backlog no futuro |
| Ajuste em `validateWalkin` em vez de novo endpoint de bloqueio | Reserva manual é semanticamente um walk-in; manter um único ponto canônico para reservas evita divergência de lógica |
| `canal_origem: "manual"` como marcador no banco | Distingue bloqueios de agenda de walk-ins reais; útil para relatórios e filtros futuros |
| Dialogs em arquivos dedicados (não inline na page) | Delete e reserva manual têm estado e regras próprias; separar melhora testabilidade e legibilidade |
| `Future.wait` com tratamento individual no load inicial | Mesma estratégia do `HotelDetailsNotifier`; falha em reservas não impede renderização de quartos/categorias |
| Busca e filtro locais (sem nova request) | Lista agregada é pequena; processamento client-side é instantâneo e reduz carga no backend |
| Filtrar `GET /hotel/reservas` por janela de datas (ex: próximos 6 meses) | Evita baixar histórico irrelevante para cálculo de disponibilidade atual |

## Contratos de API

| Método | Rota | Body | Response | Status |
|--------|------|------|----------|--------|
| GET | `/hotel/quartos` | — | `{ data: Quarto[] }` | existente |
| GET | `/hotel/categorias` | — | `{ data: Categoria[] }` | existente |
| GET | `/hotel/reservas?data_checkin_from=&data_checkout_to=` | — | `{ data: Reserva[] }` | existente |
| GET | `/uploads/hotels/:hotel_id/rooms/:quarto_id` | — | URL/binary da foto | existente |
| DELETE | `/hotel/quartos/:id` | — | 204 | existente (invocado N vezes em paralelo) |
| POST | `/hotel/reservas` | `{ canal_origem: "manual", tipo_quarto, num_hospedes, data_checkin, data_checkout, valor_total }` | `{ data: Reserva }` | **modificado** — aceitar sem identificação de hóspede quando `canal_origem === "manual"` |

**Nota:** Todos os endpoints `hotel/*` exigem `hotelGuard` (JWT + `hotel_id` no contexto).

## Modelos de Dados

```
QuartoModel {
  id: int
  numero: String
  categoriaQuartoId: int
  descricao: String?
  valorDiaria: double?
  disponivel: bool
  itens: List<QuartoItem>
}

QuartoItem {
  catalogoId: int
  nome: String
  categoria: String
  quantidade: int
}

CategoriaQuartoModel {
  id: int
  nome: String
  descricao: String?
  capacidade: int?
  precoBase: double?
}

RoomCategoryCardModel {
  categoriaId: int
  nomeCategoria: String
  descricao: String?
  totalUnidades: int
  quartoIds: List<int>      // usados no delete (N chamadas) e no cálculo de disponibilidade
  fotoUrl: String?
  valorBase: double?
}

ReservaHotelModel {
  id: int
  quartoId: int?
  tipoQuarto: String?
  categoriaQuartoId: int?   // derivado via join local com QuartoModel.categoriaQuartoId
  dataCheckin: DateTime
  dataCheckout: DateTime
  status: String             // filtrar apenas status ativos para ocupação
}

MyRoomsState {
  cards: List<RoomCategoryCardModel>
  categorias: List<CategoriaQuartoModel>
  reservas: List<ReservaHotelModel>
  diasIndisponiveisPorCategoria: Map<int, Set<DateTime>>
  busca: String
  categoriaSelecionada: int?
  loading: bool
  error: String?
  deleteInProgress: bool
  reservaInProgress: bool
}
```

**Contrato do `AvailabilityCalculator`:**
```
Set<DateTime> computeDiasIndisponiveis(
  List<ReservaHotelModel> reservasAtivas,
  int totalUnidades,
)
```
Para cada dia no intervalo agregado das reservas, contar sobreposições (checkin inclusivo, checkout exclusivo). Um dia `D` é indisponível quando `contagemReservasAtivasEm(D) >= totalUnidades`.

## Dependências

**Bibliotecas:**
- [x] `dio ^5.7.0` — cliente HTTP (já presente)
- [x] `flutter_riverpod ^3.3.1` — state management (já presente)
- [x] `go_router ^17.2.1` — navegação (já presente)
- [ ] `table_calendar` (ou equivalente já adotado) — calendário com seleção de range e marcação de dias indisponíveis. Verificar se já há lib utilizada em `room_details_page` e reusar.

**Serviços externos:** nenhum.

**Outras features:**
- [x] P0 — `dioProvider` configurado com interceptor de autenticação
- [x] P2-A — login host (JWT)
- [x] P3-B — perfil host com `hotel_id` carregado no estado global
- [ ] **Backend:** ajuste em `Reserva.validateWalkin` para aceitar reserva manual sem identificação (dependência interna; abrir PR em paralelo)

**Bloqueia:**
- P5-A (`add_room_page`) — navegação sai desta tela
- P5-B (`edit_room_page`) — navegação sai desta tela

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Delete parcial deixa estado inconsistente entre UI e backend | `Future.wait(eagerError: false)`; após execução recarregar via `GET /hotel/quartos` e exibir snackbar com `M/N removidas com sucesso` |
| `GET /hotel/reservas` pode trazer volume alto em hotéis com muita operação | Filtrar por janela de datas relevante (ex: próximos 6 meses) via query params; avaliar paginação se o backend suportar |
| Cálculo de disponibilidade client-side fica lento com >500 reservas | Extrair `AvailabilityCalculator` puro e memoizar por categoria; monitorar em produção; acelerar endpoint do backlog se persistir |
| Modificação em `validateWalkin` quebra walk-ins de balcão existentes | Manter exigência de identificação quando `canal_origem !== "manual"`; cobrir ambos os caminhos com testes antes de mergear |
| Reservas canceladas ou expiradas contabilizando ocupação | Filtrar por status ativos (`confirmada`, `checkin_realizado`, etc.) dentro do `AvailabilityCalculator`; confirmar a lista válida no enum `ReservaStatus` antes de fixar |
| Foto via `quarto_id` retorna 404 se o primeiro `quarto_id` não tiver upload | Fallback: tentar próxima unidade da categoria; se todas falharem, exibir placeholder |
| `table_calendar` ou similar não suporta nativamente "faixas indisponíveis" | Usar `holidayPredicate`/`disabledDayPredicate` para marcar dias do `Set<DateTime>` retornado pelo `AvailabilityCalculator` |
| Reserva manual enviada com `tipo_quarto` textual pode divergir de `categoria.nome` | Padronizar: enviar `tipo_quarto = categoria.nome` (exato) ou, preferencialmente, enviar `quarto_id` da primeira unidade da categoria |
| Concorrência: host deleta unidade enquanto outra reserva está sendo criada na mesma categoria | Tratar erros 409/404 no `DELETE` como "já removido" e seguir o fluxo; recarregar no final garante consistência |
| Enum `CanalOrigem` pode não conter `"manual"` ainda | Auditar o enum antes de iniciar; adicionar o valor caso ausente (parte do ajuste de backend) |
