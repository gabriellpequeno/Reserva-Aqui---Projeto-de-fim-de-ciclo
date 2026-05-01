# Plan — Tickets Page

> Derivado de: conductor/specs/tickets-page.spec.md
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [CONCLUÍDO]

Nenhuma action necessária — sem migration, sem variável de ambiente nova, sem dependência nova.

---

## Backend [CONCLUÍDO]

Nenhuma action necessária — todos os endpoints já existem.

---

## Frontend [CONCLUÍDO]

- [x] Estender `Ticket` em `lib/features/tickets/domain/models/ticket.dart`:
  - Adicionar campos `codigoPublico`, `hotelId`, `quartoId` (nullable), `imageUrl` (nullable)
  - Adicionar factory `fromJson()` mapeando campos da API (ver spec para mapeamento completo)
  - Implementar lógica de status: `APROVADA` + `hoje >= data_checkin` → `hospedado`
  - Manter campos sem suporte na API com fallback fixo (`address: '—'`, `discounts: 0.0`, etc.)
  - Remover `mockTickets`
- [x] Criar `TicketsService` em `lib/features/tickets/data/services/tickets_service.dart`:
  - Método `fetchReservas()` — `GET /usuarios/reservas` com JWT
  - Método `fetchFotoQuarto(hotelId, quartoId)` — `GET /uploads/hotels/:hotel_id/rooms/:quarto_id`, retorna primeira URL ou null
- [x] Criar `TicketsNotifier` + `TicketsState` em `lib/features/tickets/presentation/notifiers/tickets_notifier.dart`:
  - Estado: `isLoading`, `tickets` (lista completa), `errorMessage`
  - Método `load()` — busca reservas e, para cada uma com `quartoId`, busca foto em paralelo
  - Método `refresh()` — para pull-to-refresh (recarrega do zero)
- [x] Atualizar `TicketsPage` em `lib/features/tickets/presentation/pages/tickets_page.dart`:
  - Substituir referências a `mockTickets` pelo provider (`ref.watch(ticketsNotifierProvider)`)
  - Chamar `load()` no `initState`
  - Envolver a lista em `RefreshIndicator` chamando `refresh()`
  - Exibir `CircularProgressIndicator` enquanto `isLoading`
  - Exibir banner de erro quando `errorMessage != null`
  - Manter estado vazio existente ("Nenhuma reserva encontrada") quando lista vazia

---

## Validação [PENDENTE]

- [ ] Usuário autenticado com reservas: lista real exibida com status e dados corretos ao abrir a tela
- [ ] Usuário sem reservas: estado vazio exibido corretamente
- [ ] Pull-to-refresh: lista atualizada ao arrastar para baixo
- [ ] Filtro por status: selecionar cada tab exibe apenas os tickets correspondentes; "Todos" exibe tudo
- [ ] Status `hospedado`: reserva `APROVADA` com checkin no passado exibe badge "Hospedado"
- [ ] Quarto sem foto: placeholder exibido sem crash
- [ ] Toque no ticket: navegação para `ticket_details_page` com `codigoPublico` correto
