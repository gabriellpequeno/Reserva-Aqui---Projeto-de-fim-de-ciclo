# Plan — my-rooms-page

> Derivado de: conductor/specs/my-rooms-page.spec.md
> Status geral: [EM ANDAMENTO] — Frontend concluído, Backend pendente (PR separada), Validação parcial

**Dependências:** Requer P0 (infra-http-client), P2-A (login host) e P3-B (perfil host com `hotel_id`) já concluídos.
**Bloqueia:** P5-A (add_room_page) e P5-B (edit_room_page).

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Auditar enum `CanalOrigem` em `Backend/src/entities/Reserva.ts` — confirmado: `'MANUAL'` ausente, necessidade registrada no bloco Backend
- [x] Auditar valores do enum `ReservaStatus` em `Backend/src/entities/Reserva.ts` — status ativos: `SOLICITADA`, `AGUARDANDO_PAGAMENTO`, `APROVADA`; ignorados: `CANCELADA`, `CONCLUIDA`
- [x] Verificar no `Frontend/pubspec.yaml` — sem lib externa necessária; utilizado `showDateRangePicker` nativo do Flutter (v3.41.7) com `SelectableDayForRangePredicate`

---

## Backend [PENDENTE] — próximo passo, não executar agora

> ⚠️ Este bloco documenta as alterações de backend necessárias para o fluxo de reserva manual. Será feito em PR próprio, em paralelo com a implementação do frontend.

- [ ] Adicionar valor `"manual"` ao enum `CanalOrigem` em `Backend/src/entities/Reserva.ts` caso ainda não exista
- [ ] Modificar `Reserva.validateWalkin` em `Backend/src/entities/Reserva.ts` para dispensar a obrigatoriedade de identificação do hóspede (`user_id` / `nome_hospede` + `cpf_hospede` ou `telefone_contato`) quando `canal_origem === "manual"`. Demais validações (datas, `num_hospedes`, `valor_total`) permanecem ativas
- [ ] Ajustar `createReservaWalkin` em `Backend/src/services/reserva.service.ts` para:
  - Persistir `canal_origem = "manual"` quando recebido no input
  - Não disparar efeitos colaterais dependentes de hóspede (notificações de confirmação, vínculos de fidelidade, etc.) em reservas manuais
- [ ] Adicionar testes unitários cobrindo:
  - Walk-in tradicional continua exigindo identificação do hóspede (regressão)
  - Walk-in com `canal_origem: "manual"` aceita criação sem identificação
  - Reserva manual não aciona notificações/efeitos dependentes de hóspede
- [ ] Abrir PR no backend com as alterações acima

---

## Frontend [CONCLUÍDO]

### Modelos de Domínio

- [x] Criar `QuartoModel` + `QuartoItem` em `lib/features/rooms/domain/models/quarto.dart`
- [x] Criar `CategoriaQuartoModel` — reutilizado `CategoriaHotelModel` de `hotel_details.dart` (estrutura compatível com `GET /:hotel_id/categorias`)
- [x] Criar `RoomCategoryCardModel` em `lib/features/rooms/domain/models/room_category_card.dart`
- [x] Criar `ReservaHotelModel` em `lib/features/rooms/domain/models/reserva_hotel.dart` com constante `kStatusAtivos`

### Domínio / Lógica

- [x] Criar `AvailabilityCalculator` em `lib/features/rooms/domain/services/availability_calculator.dart` — função pura `computeDiasIndisponiveis(reservas, quartoIds, totalUnidades)` retornando `Set<DateTime>`
- [ ] Cobrir `AvailabilityCalculator` com testes unitários:
  - Sem reservas → conjunto vazio
  - Reservas parciais (não atingem total de unidades) → conjunto vazio
  - Dia com todas as unidades ocupadas → dia no conjunto
  - Cenário 23/04–29/04 (2 unidades) + 29/04–31/04 (3 unidades) com total 3 → apenas 29/04 no conjunto
  - Reservas com status cancelada/expirada ignoradas

### State (Riverpod)

- [x] Criar `MyRoomsState` em `lib/features/rooms/presentation/notifiers/my_rooms_state.dart` com getter `cardsFiltrados` embutido
- [x] Criar `MyRoomsNotifier` em `lib/features/rooms/presentation/notifiers/my_rooms_notifier.dart` via `NotifierProvider`
- [x] `myRoomsNotifierProvider` criado como `NotifierProvider<MyRoomsNotifier, MyRoomsState>`

### Widgets

- [x] Criar `DeleteRoomDialog` — fluxo 4 passos (confirmação → quantity → permanente/temporário → aviso reserva ativa), visual alinhado ao padrão da app (branco, laranja, sem ícone externo)
- [x] Criar `ManualReservationDialog` — `showDateRangePicker` nativo com `SelectableDayForRangePredicate` bloqueando dias lotados; campos de hóspedes e valor removidos (calculado internamente); visual alinhado (fundo branco, título laranja, borda azul no seletor)

### Página

- [x] Converter `my_rooms_page.dart` para `ConsumerStatefulWidget`, remover mock
- [x] Consumir `ref.watch(myRoomsNotifierProvider)`, renderizar `state.cardsFiltrados`
- [x] Estados: loading, erro (com retry), vazio (com CTA), filtro sem resultado
- [x] Busca local por nome da categoria
- [x] Filtro `Todos / Disponíveis / Indisponíveis` via `FiltroDisponibilidade` enum
- [x] Card ativo: foto, nome, total de unidades, valor, descrição; ações "Reserva manual" + "Desativar"
- [x] Card inativo: foto 45% opacidade, badge "Desativado", próxima reserva ativa ou "Sem reservas ativas"; ações "Reativar" + "Remover"
- [x] Wire "editar" → `/edit_room/:id`, FAB → `/add_room`
- [x] Pull-to-refresh com `RefreshIndicator`; snackbars de resultado

### Ajustes pós-implementação (UI + comportamento)

- [x] Reduzir altura do card (160 → 120px), foto (130 → 110px), aumentar fonte do nome categoria (15 → 17px)
- [x] `VerticalDivider` entre botões de ação corrigido com `IntrinsicHeight`
- [x] Remover filtro por categoria (decisão de produto: busca por nome é suficiente)
- [x] `AvailabilityCalculator` corrigido para contar reservas BALCAO sem `quarto_id` via `tipo_quarto` (case-insensitive)
- [x] Backend — `Reserva.validateWalkin`: identificação do hóspede tornada opcional para walk-ins de balcão sem hóspede (bloqueio de agenda)
- [x] Backend — `init_tenant.sql`: constraint `chk_hospede_identificado` atualizada para dispensar identificação quando `canal_origem = 'BALCAO'`
- [x] Backend — constraint `hotel_99999999000199` (schema de teste) atualizada via `ALTER TABLE`
- [x] Fluxo de desativação substituiu o de remoção: permanente deleta se sem reservas, marca `disponivel=false` se com reservas; temporário sempre marca `disponivel=false`
- [x] Verificação de bloqueio de exclusão em card inativo: exclusão bloqueada se `reservasAtivas > quartosAtivos`
- [x] Seed `seed.my-rooms-page.ts` criado com 5 cenários de teste; corrigido `updateConfiguracaoHotel` + criação de `hospede` antes das reservas
- [x] Notifier: load usa `_fetchHotelId` via `GET /hotel/me` (autossuficiente, sem depender de `hostProfileProvider`); trigger migrado para `Future.microtask`

---

## Validação [EM ANDAMENTO]

- [x] **Listagem inicial:** cards agrupados por categoria com foto, nome, total de unidades e valor base renderizados corretamente
- [ ] **Estado vazio:** com hotel sem quartos cadastrados, verificar que CTA "Adicionar primeiro quarto" é exibido
- [x] **Delete parcial:** Suíte Família (4 unidades) → deletar 2 → card permanece com 2 unidades (C4 ✅)
- [x] **Delete total:** Quarto Single Business (1 unidade) → deletar 1 → card desaparece da lista (C3 ✅)
- [ ] **Cancelar delete:** no modal de confirmação e no quantity picker, cancelar não dispara nenhuma requisição
- [ ] **Falha parcial no delete:** simular erro em 1 das N chamadas → snackbar exibe contagem correta e lista é recarregada
- [x] **Reserva manual — happy path:** criar reserva → dia passa a aparecer indisponível no calendário após reload (C2 ✅)
- [x] **Cenário chave de disponibilidade:** Suíte Master com 2+3 reservas sobrepostas → dias lotados bloqueados no calendário (C1 ✅)
- [x] **BALCAO sem quarto_id conta para disponibilidade:** após 2 reservas manuais no Duplo Premium, calendário bloqueia os dias (fix AvailabilityCalculator + tipo_quarto ✅)
- [ ] **Disponibilidade no `room_details`:** com todas as unidades de uma categoria ocupadas em um dia X, usuário final vê "indisponível"
- [x] **Busca local:** buscar "master", "duplo", "single", "família" filtra corretamente (C5 ✅)
- [x] **Filtro Disponíveis/Indisponíveis:** chips `Todos / Disponíveis / Indisponíveis` funcionando (substitui filtro por categoria)
- [x] **Card inativo:** visual diferenciado (fundo cinza, foto 45% opacidade, badge, info de próxima reserva)
- [x] **Desativar temporário:** unidades marcadas como `disponivel=false`, aparecem no card inativo
- [x] **Desativar permanente sem reserva:** unidades deletadas imediatamente
- [x] **Desativar permanente com reserva:** unidades marcadas como `disponivel=false` com aviso da próxima reserva no dialog
- [x] **Reativar:** unidades voltam a `disponivel=true` e somem do card inativo
- [x] **Remover do card inativo sem reservas bloqueantes:** DELETE imediato
- [x] **Remover do card inativo bloqueado:** dialog "Exclusão bloqueada" quando reservasAtivas > quartosAtivos
- [ ] **Pull-to-refresh:** puxar a tela recarrega a lista do backend
- [ ] **Erro de rede inicial:** desligar backend → mensagem de erro com botão "Tentar novamente"
- [ ] **Navegação para editar:** tocar em "editar" navega para `edit_room_page`
- [ ] **Navegação para adicionar:** tocar no FAB navega para `add_room_page`
- [ ] **Acessibilidade:** `semanticLabel` nos botões verificados em leitor de tela
- [ ] **Responsividade:** layout em portrait e landscape

---

## Sincronização com o Plan Geral

Conforme `conductor/prompts/prompt-plan-generator.md`, ao atualizar checkboxes neste arquivo:

1. Atualize o status de cada seção (`[PENDENTE]` → `[EM ANDAMENTO]` → `[CONCLUÍDO]`) conforme a regra: todas `[ ]` → PENDENTE, algumas `[x]` → EM ANDAMENTO, todas `[x]` → CONCLUÍDO.
2. Atualize o **Status geral** no topo quando todas as seções estiverem `[CONCLUÍDO]`.
3. Sincronize com `conductor/plan.md`:
   - Localize a fase **P4-E — My Rooms Page**
   - Reflita o status do header e marque as tasks resumidas como `[x]` à medida que as tasks detalhadas aqui forem concluídas
   - Quando o Status geral deste plan for `[CONCLUÍDO]`, marque a fase em `plan.md` como `[CONCLUÍDO]` e garanta que todos os checkboxes resumidos estejam `[x]`
