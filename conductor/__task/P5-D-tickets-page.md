# P5-D — tickets_page - feat/reservation-history

## Tela
`lib/features/tickets/presentation/pages/tickets_page.dart`

## Prioridade
**P5 — Features Core (Feature mais interna)**

## Branch sugerida
`feat/tickets-page-integration`

---

## Estado Atual
Lista de reservas/ingressos do usuário. Usa modelo `Ticket` local com 5 registros mockados.

## O que integrar

- [ ] Ao entrar na tela, fazer `GET /usuarios/reservas` para buscar histórico real de reservas
- [ ] Criar `TicketsNotifier` (Riverpod) com:
  - [ ] Lista de reservas (`Ticket[]`)
  - [ ] Loading state
  - [ ] Método de refresh (pull-to-refresh)
- [ ] Mapear resposta da API para o modelo `Ticket` existente:
  - `codigo_publico`, `status`, `checkin`, `checkout`, `hotel`, `quarto`, `total`
- [ ] Mapear status do back (`AGUARDANDO`, `APROVADA`, `HOSPEDADO`, `CANCELADA`, `FINALIZADA`) para os status do front (`aguardo`, `aprovado`, `hospedado`, `cancelado`, `finalizado`)
- [ ] Para cada ticket, buscar foto: `GET /uploads/hotels/:hotel_id/rooms/:quarto_id`
- [ ] Filtro por status (se existir na tela)
- [ ] Tocar em ticket → `ticket_details_page` (P5-E) com `codigo_publico`
- [ ] Tratar estado vazio (nenhuma reserva)
- [ ] Pull-to-refresh para atualizar lista

---

## Endpoints usados

| Método | Rota                                          | Auth | Descrição                    |
|--------|-----------------------------------------------|------|------------------------------|
| GET    | `/usuarios/reservas`                          | ✅   | Histórico de reservas        |
| GET    | `/uploads/hotels/:hotel_id/rooms/:quarto_id`  | ❌   | Foto do quarto               |

---

## Dependências
- **Requer:** P0, P2-A (autenticado como guest), P5-C (ter reserva criada para testar)

## Bloqueia
- P5-E (`ticket_details_page`)
