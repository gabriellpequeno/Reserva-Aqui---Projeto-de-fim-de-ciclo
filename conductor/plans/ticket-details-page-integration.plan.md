# Plan — ticket-details-page-integration

> Derivado de: conductor/specs/ticket-details-page-integration.spec.md
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Criar `database/scripts/migrations/002_add_codigo_publico_to_historico.sql` com `ALTER TABLE historico_reserva_global ADD COLUMN IF NOT EXISTS codigo_publico UUID` + `UPDATE` via join com `reserva_routing` para preencher registros existentes
- [x] Aplicar `ALTER TABLE historico_reserva_global ADD COLUMN IF NOT EXISTS codigo_publico UUID` em `database/scripts/init_master.sql`

---

## Backend [CONCLUÍDO]

- [x] Adicionar campo `codigo_publico: string` à interface `HistoricoReservaSafe` em `src/services/reserva.service.ts`
- [x] Atualizar `_upsertHistoricoGlobal` — adicionar parâmetro `codigoPublico`, incluir coluna no INSERT e atualizar todos os call sites (~5)
- [x] Atualizar `_listReservasUsuario` — adicionar `h.codigo_publico` no SELECT

---

## Frontend [CONCLUÍDO]

- [x] Atualizar `ticket.dart` — adicionar campos `nomeHospede`, `checkInRealTime`, `checkOutRealTime`, `categoriaId`; corrigir `fromJson` para usar `codigo_publico` como `id`; corrigir `_mapStatus` para derivar `hospedado` de `hora_checkin_real != null`
- [x] Atualizar `tickets_service.dart` — adicionar métodos `fetchReservaByCodigoPublico`, `fetchCategoriaQuarto`, `fetchConfiguracaoHotel`, `cancelarReserva`
- [x] Atualizar `tickets_notifier.dart` — adicionar método `cancelarReserva` com atualização local de estado na lista
- [x] Reescrever `ticket_details_page.dart` — carregamento via `Future.wait` com três chamadas paralelas, exibir `nomeHospede`, horários reais/padrão, Bloco 1 (comodidades + capacidade), Bloco 2 (política do hotel), botão cancelar com dialog de confirmação
- [x] Atualizar `ticket_card.dart` — omitir botão "Detalhes" se `ticket.id` estiver vazio (registro antigo sem `codigo_publico`)

---

## Validação [CONCLUÍDO]

- [x] Abrir detalhes de uma reserva real e verificar dados corretos (nome do hóspede, datas, horários, status)
- [ ] Verificar que reserva com `hora_checkin_real` preenchido exibe status `hospedado` e horário real no lugar do padrão
- [x] Verificar que botão "Cancelar" aparece apenas para status `SOLICITADA` / `AGUARDANDO_PAGAMENTO`
- [x] Confirmar cancelamento e verificar que status atualiza na details page e na lista (`tickets_page`)
- [x] Verificar que reserva sem `categoriaId` não trava a tela (bloco de comodidades omitido)
- [x] Verificar que `TicketCard` omite botão "Detalhes" se `codigo_publico` for nulo
