# Spec — Tickets Page

## Referência
- **PRD:** conductor/features/tickets-page.prd.md

## Abordagem Técnica
Criar `TicketsNotifier` (Riverpod) que busca o histórico real via `GET /usuarios/reservas` ao entrar na tela. O filtro por status e a busca textual já existem na página e operam sobre a lista local — basta trocar `mockTickets` pela lista do notifier. O status `hospedado` não existe no backend: será inferido no cliente quando `status == APROVADA` e `hoje >= data_checkin`.

## Componentes Afetados

### Backend
Nenhum — todos os endpoints necessários já existem.

### Frontend
- **Novo:** `TicketsService` (`lib/features/tickets/data/services/tickets_service.dart`) — chamadas HTTP para `GET /usuarios/reservas` e `GET /uploads/hotels/:hotel_id/rooms/:quarto_id`
- **Novo:** `TicketsNotifier` + `TicketsState` (`lib/features/tickets/presentation/notifiers/tickets_notifier.dart`)
- **Modificado:** `Ticket` (`lib/features/tickets/domain/models/ticket.dart`) — adicionar `fromJson()`, campos `codigoPublico`, `hotelId`, `quartoId`; remover `mockTickets`
- **Modificado:** `TicketsPage` (`lib/features/tickets/presentation/pages/tickets_page.dart`) — substituir `mockTickets` pelo provider, adicionar `RefreshIndicator`, estados de loading e vazio real

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|---------------|
| Filtro e busca client-side sobre lista já carregada | Evita chamada extra ao backend a cada mudança de filtro; lista de reservas de um usuário tende a ser pequena |
| Status `hospedado` inferido no cliente | Backend não possui esse estado; inferir via `APROVADA` + `hoje >= data_checkin` mantém compatibilidade sem alterar a API |
| Foto carregada de forma lazy e nullable por card | Endpoint de imagem pode não retornar resultado para todos os quartos; evita bloquear renderização da lista |

## Contratos de API

| Método | Rota | Auth | Response |
|--------|------|------|----------|
| GET | `/usuarios/reservas` | ✅ JWT usuário | `HistoricoReserva[]` |
| GET | `/uploads/hotels/:hotel_id/rooms/:quarto_id` | ❌ | `{ fotos: [{ url, ordem }] }` |

## Modelos de Dados

```
Ticket {
  // campos já existentes
  id            String   ← reserva_tenant_id (como string)
  hotelName     String   ← nome_hotel
  roomType      String   ← tipo_quarto
  checkIn       DateTime ← data_checkin
  checkOut      DateTime ← data_checkout
  total         double   ← valor_total
  status        TicketStatus ← mapeado do status do backend (ver tabela abaixo)
  guestCount    int      ← num_hospedes
  // campos novos
  codigoPublico String   ← codigo_publico (para navegação para ticket_details)
  hotelId       String   ← hotel_id (para buscar foto)
  quartoId      int?     ← quarto_id (nullable — quarto pode não ter sido atribuído)
  imageUrl      String?  ← carregado via segundo endpoint (nullable)
  // campos sem suporte na API — fallback fixo
  address       String   ← '—'
  checkInTime   String   ← '—'
  checkOutTime  String   ← '—'
  subtotal      double   ← igual a total (sem breakdown na API)
  discounts     double   ← 0.0
  taxes         double   ← 0.0
}
```

**Mapeamento de status backend → TicketStatus:**

| Backend | TicketStatus | Regra |
|---------|-------------|-------|
| `SOLICITADA` | `aguardo` | — |
| `AGUARDANDO_PAGAMENTO` | `aguardando` | — |
| `APROVADA` (hoje < checkin) | `aprovado` | — |
| `APROVADA` (hoje >= checkin) | `hospedado` | inferido no cliente |
| `CONCLUIDA` | `finalizado` | — |
| `CANCELADA` | `cancelado` | — |

## Dependências

**Bibliotecas:**
- Nenhuma nova — Riverpod, Dio e go_router já estão no projeto

**Outras features:**
- [ ] P0 / P2-A — autenticação de usuário (JWT necessário para `GET /usuarios/reservas`)
- [ ] P5-C — checkout page (para existirem reservas reais a exibir)

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| `quartoId` nulo em reservas sem quarto atribuído | Não buscar foto; exibir imagem placeholder no card |
| Campos `checkInTime`, `checkOutTime` e `address` ausentes na API | Exibir `'—'` como fallback; campos existem no model mas não serão preenchidos nesta fase |
| `discounts` e `taxes` não existem na API | Fixar em `0.0`; sem impacto visual relevante até definição futura |
