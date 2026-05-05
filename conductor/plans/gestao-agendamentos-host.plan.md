# Plan — Gestão de Agendamentos do Host

> Derivado de: `conductor/specs/gestao-agendamentos-host.spec.md`
> Status geral: [PENDENTE]

---

## Dependências

- **BUG-7** (padronização de status dos tickets) deve estar concluído antes de iniciar o frontend — o mapeamento `SOLICITADA → Aguardo`, `APROVADA → Em Andamento` etc. precisa estar alinhado entre backend e frontend.

---

## Setup & Infraestrutura [PENDENTE]

- [ ] Verificar se `PATCH /:hotel_id/categorias/:id` em `quarto.service.ts` já aceita `{ ativo: false }` — documentar resultado antes de qualquer outra task

---

## Backend [PENDENTE]

### Push de cancelamento e payload FCM
- [ ] `src/services/reserva.service.ts` → `_updateStatus`: adicionar bloco `sendPush` para `CANCELADA` (análogo ao bloco de `APROVADA`) com título "Reserva cancelada" e body descritivo
- [ ] Adicionar `reserva_id: String(atualizada.id)` ao campo `data` do payload FCM em **todos** os pushes de `_updateStatus` (aprovação e cancelamento)
- [ ] Confirmar que o `tipo` do push de nova reserva (`RESERVA_SOLICITADA`) já está sendo enviado ao host quando hóspede cria reserva — se não, adicionar em `createReservaUsuario`

### Endpoint de reservas ativas por categoria
- [ ] `src/services/reserva.service.ts`: criar função `getReservasAtivasByCategoria(hotelId, categoriaId)` — conta reservas com status `SOLICITADA` ou `APROVADA` para a categoria; também retorna `total_unidades` da categoria
- [ ] `src/controllers/reserva.controller.ts`: criar `getReservasAtivasByCategoriaController` — lê `hotelId` do `hotelGuard` e `categoria_id` de `req.params`; responde `{ data: { categoria_id, reservas_ativas, total_unidades } }`
- [ ] `src/routes/reserva.routes.ts`: registrar `GET /categorias/:categoria_id/reservas-ativas` no `hotelReservaRouter` com `hotelGuard`

### Desativar quarto
- [ ] Se `{ ativo: false }` não existir em `quarto.service.ts`: implementar `desativarCategoria(hotelId, categoriaId)` que faz `UPDATE categoria SET ativo = false WHERE id = $1` — quartos desativados devem ser excluídos de queries públicas de busca e disponibilidade

---

## Frontend [PENDENTE]

### Fix de Auth State (pré-condição)
- [ ] `lib/core/auth/auth_notifier.dart` → método `clear()`: adicionar `ref.invalidate(hostProfileProvider)` e `ref.invalidate(userProfileProvider)` **antes** de limpar os tokens do `SharedPreferences` — garantir que os imports estejam corretos

### AgendamentosNotifier
- [ ] Criar `lib/features/bookings/presentation/notifiers/agendamentos_notifier.dart`
  - `AsyncNotifier<List<Ticket>>` sempre com role=host
  - Estado interno: `TicketStatus? statusFilter` e `DateTime? dateFilter`
  - `build()`: chama `TicketsService.fetchReservas(role: AuthRole.host)` com query params de filtro quando definidos
  - Método `setStatusFilter(TicketStatus?)`: atualiza filtro e recarrega
  - Método `setDateFilter(DateTime?)`: atualiza filtro com `data_checkin_from` e `data_checkin_to` iguais à data selecionada e recarrega
  - Método `clearDateFilter()`: remove filtro de data e recarrega
  - Reutilizar `aprovarReserva(reservaId)` e `negarReserva(reservaId)` do `TicketsNotifier` (ou replicar chamando `TicketsService.updateReservaStatus` diretamente)

### CalendarFilterWidget
- [ ] Criar `lib/features/bookings/presentation/widgets/calendar_filter_widget.dart`
  - Usa `CalendarDatePicker` nativo do Flutter (sem dependência nova)
  - Recebe `Set<DateTime> datasComReserva` para marcar dots nos dias
  - Callback `onDateSelected(DateTime?)` chamado ao selecionar ou limpar data
  - Exibido via `showModalBottomSheet` ou `showDialog` acionado pelo botão de calendário na `AgendamentosPage`
  - Dias com reservas: usar `Decoration` no `dayBuilder` para exibir dot abaixo do número

### AgendamentosPage
- [ ] Criar `lib/features/bookings/presentation/pages/agendamentos_page.dart`
  - `ConsumerStatefulWidget` consumindo `agendamentosNotifierProvider`
  - Header: mesmo estilo da `TicketsPage` (cor primária, logo, título "Agendamentos")
  - Campo de busca textual: filtra localmente por `nomeHospede`, `codigoPublico` e `roomType`
  - Chips de status horizontal rolável: **Todos | Aguardo | Em Andamento | Hospedado | Cancelado | Finalizado**
  - Botão calendário (ícone `Icons.calendar_month`) ao lado da busca → abre `CalendarFilterWidget`
  - Indicador visual de data ativa (ex: chip com a data selecionada e botão de limpar `×`)
  - Lista: `ListView.separated` de `TicketCard` adaptado (exibe `nomeHospede` no lugar onde o hóspede vê o hotel)
  - Estado vazio, loading e erro tratados
  - Pull-to-refresh

### AgendamentoDetailPage
- [ ] Criar `lib/features/bookings/presentation/pages/agendamento_detail_page.dart`
  - Recebe `reservaId` (int) via parâmetro de rota
  - Carrega detalhes via `GET /api/hotel/reservas/:id`
  - Layout similar ao detalhe do ticket do hóspede: código, hóspede, quarto, datas, total, status
  - **Status `SOLICITADA`**: exibe botões **[Confirmar]** e **[Cancelar]** lado a lado
  - **Status `APROVADA` ou `HOSPEDADO`**: exibe apenas botão **[Cancelar]**
  - **Status `CONCLUIDA` ou `CANCELADA`**: somente leitura, sem botões de ação
  - Ao tocar em **Cancelar**: exibir `AlertDialog` — "Tem certeza que deseja cancelar esta reserva?" com ações [Não] e [Sim, cancelar]
  - Após confirmar cancelamento ou aprovação: chamar `agendamentosNotifier.aprovarReserva` ou `negarReserva` → ao retornar à lista, ela está atualizada
  - Loading state durante a ação (desabilitar botões enquanto aguarda resposta)
  - Tratar erro de Dio com `SnackBar` descritivo

### Roteamento
- [ ] `lib/core/router/app_router.dart`: registrar `GoRoute` para `/host/agendamentos` → `AgendamentosPage`
- [ ] `lib/core/router/app_router.dart`: registrar `GoRoute` para `/host/agendamentos/:reservaId` → `AgendamentoDetailPage` (extrair `int.parse(state.pathParameters['reservaId']!)`)
- [ ] Conectar entrada na `AgendamentosPage` ao bottom nav ou dashboard do host (verificar onde está o ponto de entrada atual)

### Deep-link via FCM
- [ ] Localizar o handler de push notification do Firebase (`FirebaseMessaging.onMessageOpenedApp` e `getInitialMessage`) no `main.dart` ou em serviço dedicado
- [ ] Adicionar case para `data['tipo'] == 'RESERVA_SOLICITADA'`: navegar para `/host/agendamentos/${data['reserva_id']}`
- [ ] Adicionar case para `data['tipo'] == 'APROVACAO_RESERVA'` recebido pelo **hóspede**: navegar para `/tickets` (ou detalhe do ticket se `codigo_publico` estiver no payload)
- [ ] Testar deep-link com notificação manual via Firebase Console

### MyRoomsPage — Guard de Exclusão
- [ ] `lib/features/rooms/presentation/pages/my_rooms_page.dart`: antes de excluir um quarto, chamar `GET /hotel/reservas/categorias/:categoria_id/reservas-ativas`
- [ ] Se `reservas_ativas >= total_unidades`: bloquear exclusão e exibir `AlertDialog` — "Este quarto possui reservas ativas. Desative-o para que não receba novas reservas." com botões [Fechar] e [Desativar]
- [ ] Se `reservas_ativas < total_unidades` ou `reservas_ativas == 0`: prosseguir com exclusão normal (confirmação existente)
- [ ] Ação "Desativar": chamar `PATCH /:hotel_id/categorias/:id` com `{ ativo: false }` → atualizar lista localmente removendo o card (ou marcando como inativo)

---

## Validação [PENDENTE]

- [ ] **Fluxo de aprovação ponta a ponta**: hóspede cria reserva → host vê na lista com status **Aguardo** → host toca em Detalhes → toca em Confirmar → status muda para **Em Andamento** → hóspede recebe push de aprovação
- [ ] **Fluxo de cancelamento pelo host**: host abre detalhe → toca Cancelar → alerta exibido → confirma → status muda para **Cancelado** → hóspede recebe push de cancelamento
- [ ] **Deep-link**: host com app em background recebe push de nova reserva → toca na notificação → app abre diretamente no detalhe da reserva com botões visíveis
- [ ] **Filtro por status**: cada chip filtra a lista corretamente; chip "Todos" exibe todas as reservas
- [ ] **Filtro por data**: selecionar dia no calendário exibe apenas reservas com checkin naquele dia; dias com reservas têm dot; limpar filtro restaura lista completa
- [ ] **Busca textual**: digitar nome do hóspede ou código público filtra a lista em tempo real
- [ ] **Pull-to-refresh**: arrastar lista para baixo atualiza os dados do backend
- [ ] **Troca de conta host**: logout hotel A → login hotel B → `AgendamentosPage` exibe reservas do hotel B; `HostProfilePage` exibe dados do hotel B (sem resquício do hotel A)
- [ ] **Guard de exclusão**: tentar excluir quarto com `reservas_ativas >= total_unidades` → diálogo de bloqueio exibido; quarto não é excluído
- [ ] **Desativar quarto**: quarto desativado desaparece do card na `MyRoomsPage`; hóspede não vê o quarto em buscas; reservas existentes permanecem intactas nos tickets
- [ ] **Estado offline**: tentar confirmar/cancelar sem conexão → `SnackBar` de erro exibido; status da reserva não muda
