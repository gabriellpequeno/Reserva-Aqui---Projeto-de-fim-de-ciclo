# Spec — Gestão de Agendamentos do Host

## Referência
- **PRD:** `conductor/features/gestao-agendamentos-host.prd.md`
- **Task:** `conductor/__task/BUG-8-host-agendamentos-myrooms.md`

---

## Abordagem Técnica

Reutilizar a infraestrutura já existente de tickets: o `Ticket` model (suporta ambos os formatos user e hotel), o `TicketsService` (já chama `/hotel/reservas` para role=host e já tem `updateReservaStatus`) e o `TicketsNotifier` (já tem `aprovarReserva` e `negarReserva`). Criar uma `AgendamentosPage` dedicada — visual similar à `TicketsPage` mas com calendário de filtro e ações de gestão. A tela de detalhe (`AgendamentoDetailPage`) exibe os mesmos dados do ticket do hóspede acrescidos dos botões Confirmar/Cancelar. Nenhum dependency novo é adicionado ao pubspec — o calendário usa `CalendarDatePicker` nativo do Flutter e o guard de conectividade usa tratamento de erro do Dio já existente.

---

## Descobertas Técnicas (pré-implementação)

| # | Descoberta | Impacto |
|---|-----------|---------|
| 1 | `_updateStatus` **já envia push na aprovação** (`APROVADA`) via `getUserTokens + sendPush`, mas **não envia no cancelamento** (`CANCELADA`) | Adicionar bloco análogo para `CANCELADA` |
| 2 | `listReservasController` **já aceita** `data_checkin_from`, `data_checkin_to`, `status`, `nome_hospede` como query params | Nenhum backend extra para o calendário |
| 3 | FCM data payload já inclui `{ codigo_publico, tipo: 'APROVACAO_RESERVA' }` | Deep-link já tem base; adicionar `reserva_id` (int) para navegação direta |
| 4 | `TicketsNotifier` já tem `aprovarReserva(reservaId)` e `negarReserva(reservaId)` | Reutilizar no `AgendamentosNotifier` |
| 5 | `Ticket.fromJson` já suporta formato `/hotel/reservas` (`id`, `tipo_quarto`, `nome_hospede`) | Modelo sem alterações |

---

## Componentes Afetados

### Backend

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Modificado** | `src/services/reserva.service.ts` → `_updateStatus` | Adicionar bloco de push para `CANCELADA` (análogo ao de `APROVADA`); adicionar `reserva_id` numérico ao `data` do payload FCM |
| **Novo** | `src/controllers/reserva.controller.ts` → `getReservasAtivasByCategoriaController` | Retorna `{ count, reservas_ativas }` de uma categoria específica |
| **Novo** | `src/routes/reserva.routes.ts` — `hotelReservaRouter` | Registrar `GET /categorias/:categoria_id/reservas-ativas` com `hotelGuard` |
| **Verificar** | `PATCH /:hotel_id/categorias/:id` | Confirmar que aceita `{ ativo: false }` — a lógica de desativar quarto deve existir ou ser adicionada ao `quarto.service.ts` |

### Frontend

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Novo** | `lib/features/bookings/presentation/pages/agendamentos_page.dart` | Tela de listagem de agendamentos do host |
| **Novo** | `lib/features/bookings/presentation/pages/agendamento_detail_page.dart` | Detalhe com botões Confirmar / Cancelar |
| **Novo** | `lib/features/bookings/presentation/notifiers/agendamentos_notifier.dart` | `AsyncNotifier<List<Ticket>>` sempre com role=host; suporte a filtro de data e status |
| **Novo** | `lib/features/bookings/presentation/widgets/calendar_filter_widget.dart` | `CalendarDatePicker` nativo com callback `onDateSelected`; dias com reservas marcados visualmente |
| **Modificado** | `lib/core/auth/auth_notifier.dart` → `clear()` | Adicionar `ref.invalidate(hostProfileProvider)` e `ref.invalidate(userProfileProvider)` antes de limpar tokens |
| **Modificado** | `lib/features/rooms/presentation/pages/my_rooms_page.dart` | Guard de exclusão: checar endpoint antes de excluir; adicionar ação "Desativar" |
| **Modificado** | `lib/core/router/app_router.dart` | Registrar rotas `/host/agendamentos` e `/host/agendamentos/:reservaId` |
| **Modificado** | `lib/features/notifications/` (handler FCM) | Ao receber push com `tipo == 'RESERVA_SOLICITADA'` ou `'APROVACAO_RESERVA'`, navegar para `/host/agendamentos/:reservaId` |

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| `AgendamentosPage` separada da `TicketsPage` | Estética similar, lógica distinta: host precisa de calendário, aprovação, guard de exclusão — misturar por role aumentaria complexidade |
| Reutilizar `Ticket` model e `TicketsService` | Já suportam formato `/hotel/reservas` e têm métodos de aprovação implementados; duplicar seria retrabalho |
| `CalendarDatePicker` nativo em vez de `table_calendar` | Evita nova dependência pesada; funcionalidade necessária (selecionar data e marcar dias) é coberta pelo widget nativo |
| Filtro de data via query params (backend) | `listReservasController` já suporta `data_checkin_from/to` — usar diretamente sem filtro no cliente |
| Offline via erro Dio | `TicketsService.updateReservaStatus` já trata `DioException`; exibir `SnackBar` no erro sem `connectivity_plus` |
| Guard de exclusão via endpoint dedicado | Evita lógica no cliente que pode ser burla; o backend é a fonte de verdade das reservas ativas |

---

## Contratos de API

### Endpoints existentes (sem alteração na assinatura)

| Método | Rota | Auth | Query params relevantes |
|--------|------|------|------------------------|
| GET | `/api/hotel/reservas` | hotelGuard | `status`, `data_checkin_from`, `data_checkin_to`, `nome_hospede` |
| GET | `/api/hotel/reservas/:id` | hotelGuard | — |
| PATCH | `/api/hotel/reservas/:id/status` | hotelGuard | — |

**Body** do PATCH status:
```json
{ "status": "APROVADA" | "CANCELADA" | "CONCLUIDA" }
```

**Resposta** GET `/hotel/reservas` (item):
```json
{
  "id": 42,
  "codigo_publico": "RA-XXXXXX",
  "tipo_quarto": "Suíte Luxo",
  "nome_hospede": "Maria Silva",
  "data_checkin": "2026-06-01",
  "data_checkout": "2026-06-05",
  "num_hospedes": 2,
  "valor_total": "850.00",
  "status": "SOLICITADA",
  "hotel_id": "uuid"
}
```

### Endpoint a criar

**`GET /api/hotel/reservas/categorias/:categoria_id/reservas-ativas`**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| Auth | hotelGuard | Obrigatório |
| `:categoria_id` | integer | ID da categoria do quarto |

Resposta `200`:
```json
{
  "data": {
    "categoria_id": 5,
    "reservas_ativas": 3,
    "total_unidades": 4
  }
}
```

Usado por: `MyRoomsPage` antes de excluir para decidir se bloqueia (exclusão) ou permite (exclusão ou desativação).

### Alteração em endpoint existente (FCM payload)

Adicionar `reserva_id` (string numérica) ao campo `data` do push de aprovação e do novo push de cancelamento em `_updateStatus`:

```typescript
data: {
  codigo_publico: atualizada.codigo_publico,
  reserva_id:    String(atualizada.id),        // ← NOVO
  tipo:          'APROVACAO_RESERVA',           // ou 'CANCELAMENTO_RESERVA' (novo)
}
```

---

## Modelos de Dados

Nenhuma tabela nova. Modelos existentes reutilizados:

**`Ticket` (frontend — sem alterações)**
```
Ticket {
  id:             String   // reserva_tenant_id
  codigoPublico:  String
  hotelId:        String
  quartoId:       int?
  hotelName:      String   // ← nome do hotel no contexto host
  roomType:       String
  nomeHospede:    String?  // ← preenchido pelo formato /hotel/reservas
  checkIn:        DateTime
  checkOut:       DateTime
  guestCount:     int
  status:         TicketStatus
  statusRaw:      String   // status cru do backend
  total:          double
}
```

**`reserva` (backend tenant DB — sem alterações de schema)**

**Único ajuste de dado**: bloco de `sendPush` para `CANCELADA` a ser adicionado em `_updateStatus`:
```typescript
if (input.status === 'CANCELADA' && atualizada.user_id) {
  getUserTokens(atualizada.user_id).then(tokens =>
    sendPush(tokens, {
      title: 'Reserva cancelada',
      body:  `Sua reserva em ${nome_hotel} foi cancelada.`,
      data:  {
        codigo_publico: atualizada.codigo_publico,
        reserva_id:    String(atualizada.id),
        tipo:          'CANCELAMENTO_RESERVA',
      },
    }),
  ).catch(() => {});
}
```

---

## Fluxo de Navegação

```
Host Dashboard / BottomNav
  └─ Agendamentos (/host/agendamentos)
        ├─ Campo de busca (nome do hóspede / código)
        ├─ Chips de status (Todos | Aguardo | Em Andamento | ...)
        ├─ Botão calendário → abre CalendarDatePicker
        │     └─ Dias com reservas: marcados com dot
        │     └─ Selecionar dia → filtra lista por data_checkin_from=data&data_checkin_to=data
        └─ Card de agendamento → botão "Detalhes"
              └─ AgendamentoDetailPage (/host/agendamentos/:reservaId)
                    ├─ Status SOLICITADA: botões [Confirmar] [Cancelar]
                    ├─ Status APROVADA/HOSPEDADO: botão [Cancelar] + alerta de confirmação
                    └─ Status CONCLUIDA/CANCELADA: somente leitura

Push Notification (nova reserva)
  └─ data.tipo == 'RESERVA_SOLICITADA'
        └─ navegar para /host/agendamentos/:reserva_id
```

---

## Dependências

**Bibliotecas:**
- [x] `firebase_messaging` — já instalado; usar handler existente para deep-link
- [x] `go_router` — já instalado; registrar novas rotas
- [x] `flutter_riverpod` — já instalado; novo `AgendamentosNotifier`

**Nenhuma dependência nova no `pubspec.yaml`.**

**Outras features / providers:**
- [x] `TicketsService` (`tickets_service.dart`) — reutilizado sem alterações
- [x] `Ticket` model (`ticket.dart`) — reutilizado sem alterações
- [x] `TicketsNotifier` — lógica de aprovação/cancelamento reutilizada no `AgendamentosNotifier`
- [ ] `hostProfileProvider` — necessário no `AuthNotifier.clear()` para invalidação
- [ ] `hotelGuard` backend — já existe; nenhuma alteração

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| `CANCELADA` não enviava push ao usuário | Corrigir em `_updateStatus` como primeira etapa do backend — antes de qualquer teste de integração |
| Deep-link de notificação pode não ter `reserva_id` no payload atual | Adicionar ao payload antes de publicar; testar com notificação manual via Firebase Console |
| `CalendarDatePicker` nativo não permite marcar dots nos dias | Investigar `TableCalendar` como fallback se o requisito visual for crítico — decisão a tomar ao implementar o widget |
| `PATCH /:hotel_id/categorias/:id` pode não aceitar `{ ativo: false }` | Verificar `quarto.service.ts` antes de implementar o front do guard; se não existir, criar |
| Invalidar `hostProfileProvider` no `clear()` pode quebrar builds se o provider não estiver importado no `auth_notifier.dart` | Usar `ref.invalidate` via `ProviderContainer` ou garantir import correto |

---

## Ordem de Implementação Sugerida

```
1. Backend: adicionar push de CANCELADA + reserva_id no payload FCM
2. Backend: criar GET /hotel/reservas/categorias/:id/reservas-ativas
3. Backend: verificar/implementar { ativo: false } em PATCH categorias/:id
4. Frontend: corrigir AuthNotifier.clear() — invalidar providers de perfil
5. Frontend: AgendamentosNotifier + AgendamentosPage (lista)
6. Frontend: CalendarFilterWidget integrado à AgendamentosPage
7. Frontend: AgendamentoDetailPage com Confirmar/Cancelar
8. Frontend: deep-link FCM → AgendamentoDetailPage
9. Frontend: MyRoomsPage — guard de exclusão + ação de desativar
```
