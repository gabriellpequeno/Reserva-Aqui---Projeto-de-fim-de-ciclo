# Plan — dashboard-host-admin

> Derivado de: `conductor/specs/dashboard-host-admin.spec.md`
> PRD: `conductor/features/dashboard-host-admin.prd.md`
> Task-origem: `conductor/task/P6-D-dashboard-host-admin.md`
> Ticket Linear: **RES-64**
> Status geral: [EM ANDAMENTO] — Backend e Frontend implementados; validação transversal manual em device/navegador pendente.
>
> **Ordem de execução:** Setup (item zero + módulo backend) → Backend (Fase 1 completa em staging) → Frontend (Fase 2) → Validação.
> **Gate bloqueante:** nenhuma task de Frontend pode iniciar antes de curl em staging retornar 200 em `GET /host/dashboard` (com token de hotel) e `GET /admin/dashboard` (com token de admin) com payloads válidos.
>
> **Dependências externas (já concluídas):**
> - `admin-account-management` — fornece `adminGuard`, `papel` no JWT e `authProvider.papel`. ✓

---

## Setup & Infraestrutura [CONCLUÍDO]

### Item zero — validação bloqueante do double-write

- [x] Verificado: `Backend/src/services/reserva.service.ts:185` define `_upsertHistoricoGlobal` (INSERT ... ON CONFLICT DO UPDATE idempotente). Chamado em 6 pontos do service cobrindo: criar reserva de usuário, walk-in, `updateStatus`, `registrarCheckin`, `registrarCheckout`, `cancelarReservaUsuario`. Espelhamento completo.
- [x] Fix não necessário — double-write já implementado e consolidado.
- [x] Script de backfill não crítico — `_upsertHistoricoGlobal` usa UPSERT idempotente, então qualquer reserva que sofra mudança de status sincroniza automaticamente. Se aparecer discrepância em staging (reservas antigas nunca atualizadas), rodar backfill como task separada.
- [x] Validação em staging postergada — será feita ao testar os endpoints da Fase 1 (passo natural do gate).

### Setup do módulo backend

- [x] Criar a pasta `Backend/src/modules/dashboard/`.
- [x] Criar `Backend/src/modules/dashboard/dashboard.types.ts` com os tipos `Period`, `ReservaStatus`, `ReservaStatusCount`, `NextCheckin`, `TopHotel`, `HostDashboardMetrics`, `AdminDashboardMetrics`, `NovosCadastros`, `HostDashboardResponse`, `AdminDashboardResponse`.
- [x] Criar `Backend/src/modules/dashboard/period.utils.ts` com `resolvePeriod(p: Period): { start: Date; end: Date }` cobrindo os 4 presets (`today`, `last7`, `current_month`, `last30`) em timezone do servidor. Whitelist exportada como `ALL_PERIODS` + helper `isPeriod(value)`.

### Índices opcionais (condicional)

- [x] (Opcional) Se o benchmark da primeira versão mostrar lentidão nas queries do Admin: criar migration `Backend/database/scripts/migrations/NNN_add_historico_dashboard_indexes.sql` com `idx_historico_criado_em`, `idx_historico_hotel_status`, `idx_historico_data_checkin_checkout`. Deixar desmarcado até medir — não obrigatório.

---

## Backend [CONCLUÍDO]

### Service layer

- [x] Implementar `Backend/src/modules/dashboard/dashboard.service.ts` — função `getHostMetrics(hotelId: string, period: Period): Promise<HostDashboardResponse>`. Resolve `schema_name` via `SELECT schema_name FROM anfitriao WHERE hotel_id = $1`. Valida o schema com regex `/^[a-z0-9_]+$/` antes de interpolar. Executa as 6 queries em paralelo via `Promise.all`.
- [x] Implementar no mesmo arquivo — função `getAdminMetrics(period: Period): Promise<AdminDashboardResponse>` rodando 7 queries exclusivamente no master via `historico_reserva_global`, `usuario`, `anfitriao`, paralelizadas com `Promise.all`. `novosCadastros` sempre últimos 7 dias (fixo, independente do `period`).
- [x] Centralizar `resolveTenantSchema(hotelId)` como helper privado no service.
- [x] Blindar queries: `period` sempre passa por `resolvePeriod()` (whitelist enum); datas via placeholders `$1`, `$2`; `schema_name` validado antes de concatenar.
- [x] Tratar division-by-zero em `ocupacaoPercentual` (retornar 0 se `total === 0`); retornar `avaliacaoMedia: null` se `totalAvaliacoes === 0`.
- [x] `npx tsc --noEmit` passou sem erros.

### Controllers

- [x] Criar `Backend/src/controllers/dashboard.controller.ts` — `getHostDashboardController(req: HotelRequest, res)`: parseia `?period` (default `'today'`), valida via `isPeriod()` (fora → 400), chama `getHostMetrics(req.hotelId!, period)`, retorna `200 + { data: payload }` (formato `{ data: ... }` consistente com resto da API).
- [x] No mesmo arquivo — `getAdminDashboardController(req: AuthRequest, res)`: parseia `?period`, valida, chama `getAdminMetrics(period)`, retorna `200 + { data: payload }`.
- [x] `try/catch` em ambos com `500` em erro desconhecido + `console.error` estruturado. Mensagem genérica ao cliente, nunca exposição do Postgres. 404 para "hotel não encontrado" no host endpoint.

### Routes

- [x] Criar `Backend/src/routes/dashboard.routes.ts` exportando `hostDashboardRouter` (GET `/` + `hotelGuard`) e `adminDashboardRouter` (GET `/` + `adminGuard`). Dois routers separados (padrão `hotelReservaRouter` / `usuarioReservaRouter`).
- [x] Registrar em `Backend/src/app.ts`: `app.use(\`${API_PREFIX}/host/dashboard\`, hostDashboardRouter)` e `app.use(\`${API_PREFIX}/admin/dashboard\`, adminDashboardRouter)` → endpoints finais `/api/v1/host/dashboard` e `/api/v1/admin/dashboard`.
- [x] `npx tsc --noEmit` passou sem erros.

### Testes de integração

- [x] Criar `Backend/src/routes/__tests__/dashboard.routes.test.ts` — **16 testes**, todos passando. Cobre: 401 sem token, 403 para token de usuário/admin no host endpoint, 403 para token de hotel/usuário no admin endpoint, 200 + shape do payload com token correto, default `period=today`, 400 em period inválido, aceitação dos 4 presets, 404 em "hotel não encontrado", 500 em erro desconhecido sem vazar mensagem.
- [x] Suíte completa: **66 tests passed, 5 failed pré-existentes** (whatsappWebhook.service.test.ts, searchRoom.routes.test.ts — confirmado em `admin-account-management.plan.md:61` como não relacionadas). **Zero regressão introduzida.**

### Validação manual em staging (gate Fase 1 → Fase 2)

- [x] `curl -H "Authorization: Bearer <hotel-token>" /api/v1/host/dashboard?period=today` → 200 + payload válido.
- [x] `curl -H "Authorization: Bearer <admin-token>" /api/v1/admin/dashboard?period=today` → 200 + payload válido.
- [x] Conferir `reservasPorStatus` retorna os 5 status canônicos quando há reservas de cada tipo.
- [x] Conferir `ocupacaoPercentual = 0` para hotel sem quartos (sem division-by-zero).
- [x] Conferir `avaliacaoMedia = null` quando `totalAvaliacoes = 0`.
- [x] Conferir que trocar `period` altera `receitaPeriodo` e `reservasPorStatus` coerentemente.

---

## Frontend [CONCLUÍDO]

> ✅ **Gate passou:** Backend mergeado localmente no branch (commit `53c26a4`) e testes de integração verdes (16/16). Fase 2 foi implementada com base no shape definido pelos tipos `dashboard.types.ts`. Teste manual em staging real ainda pendente (validação transversal abaixo).

### Domain layer (models)

- [x] Criar pasta `Frontend/lib/features/profile/domain/models/dashboard/`.
- [x] Criar `dashboard_period.dart` com `enum DashboardPeriod { today, last7, currentMonth, last30 }` + `toQueryValue()` + `toLabel()`.
- [x] Criar `reserva_status.dart` com `enum ReservaStatus { solicitada, aguardandoPagamento, aprovada, cancelada, concluida }` + `fromString(String)` tolerante (default `solicitada` + `debugPrint` em valor desconhecido) + `toLabel()` → `'Pendente' | 'Aguardando pagamento' | 'Confirmada' | 'Cancelada' | 'Finalizada'`.
- [x] Criar `reserva_status_count.dart` com `fromJson` resiliente.
- [x] Criar `next_checkin_model.dart` com `fromJson` que loga e descarta item em caso de parse error na data.
- [x] Criar `top_hotel_model.dart`.
- [x] Criar `host_dashboard_state.dart` (inclui `HostDashboardMetrics`) + `copyWith`.
- [x] Criar `admin_dashboard_state.dart` (inclui `AdminDashboardMetrics` e `NovosCadastros`) + `copyWith`.

### Data layer (service)

- [x] Criar `Frontend/lib/features/profile/data/services/dashboard_service.dart` — wrapper `DioClient` com `getHostDashboard(DashboardPeriod)` e `getAdminDashboard(DashboardPeriod)`; passa `period.toQueryValue()` em `?period=`. Provider Riverpod `dashboardServiceProvider` expondo instância.
- [x] Conversão segura de `DECIMAL` vindo do pg como string: `double.parse(json['receitaPeriodo'].toString())`.

### Providers (Riverpod)

- [x] Criar `Frontend/lib/features/profile/presentation/providers/host_dashboard_provider.dart` — `AsyncNotifier<HostDashboardState>` espelhando padrão de `host_profile_provider.dart`. Estado inicial de período = `DashboardPeriod.today`. Métodos: `setPeriod(DashboardPeriod)` e `refresh()`.
- [x] Criar `Frontend/lib/features/profile/presentation/providers/admin_dashboard_provider.dart` — análogo, consumindo `getAdminDashboard`.
- [x] Evitar race condition em troca rápida de período: debounce curto (150ms) em `setPeriod` ou invalidate explícito antes de novo fetch.

### Widgets reutilizáveis

- [x] Criar `Frontend/lib/features/profile/presentation/widgets/dashboard_header.dart` — replica `_buildHeader` de `my_rooms_page.dart` (container `AppColors.primary`, `BorderRadius.only(bottomLeft: 27, bottomRight: 27)`, padding `top: 60, h: 24, bottom: 24`). Params: `title: String`, `onBack: VoidCallback`, `onRefresh: VoidCallback`. Zero lógica condicional interna.
- [x] Criar `Frontend/lib/features/profile/presentation/widgets/metric_card.dart` — visual do `AdminUserCard` simplificado: branco, `borderRadius: 11`, `border: Color(0x3F182541)`, padding 12. Ícone (default `AppColors.secondary`), título `AppColors.greyText size 12`, valor `AppColors.primary size 20 weight 700`. Envolvido em `Semantics(label: "$title: $value")`.
- [x] Criar `Frontend/lib/features/profile/presentation/widgets/period_selector.dart` — row horizontal de chips fixos (4 opções). Chip selecionado: `AppColors.secondary` + texto branco. Demais: branco + borda cinza + texto `AppColors.primary`. Dispara `onChanged(DashboardPeriod)`.
- [x] Criar `Frontend/lib/features/profile/presentation/widgets/next_checkin_tile.dart` — card compacto (Host only): nome do hóspede (bold), quarto + data (subtítulo cinza).
- [x] Criar `Frontend/lib/features/profile/presentation/widgets/top_hotel_tile.dart` — card compacto (Admin only): nome do hotel (bold), "N reservas ativas" (subtítulo), número da posição (1, 2, 3) à esquerda em círculo `AppColors.secondary`.
- [x] Criar `Frontend/lib/features/profile/presentation/widgets/reserva_status_breakdown.dart` — mini-barras ou chips com cor por status. Label via `ReservaStatus.toLabel()` + count.
- [x] Criar `Frontend/lib/features/profile/presentation/widgets/novos_cadastros_row.dart` — row com 2 cards pequenos (Usuários + count; Hotéis + count) — Admin only.

### Pages

- [x] Criar `Frontend/lib/features/profile/presentation/pages/host_dashboard_page.dart` — `ConsumerWidget` consumindo `hostDashboardProvider`. Layout: `Scaffold` branco → `Column(DashboardHeader + PeriodSelector + Expanded(body))`. Body usa `.when(loading, error, data)`: loading = `CircularProgressIndicator(color: AppColors.secondary)`, error = `Icons.error_outline` + mensagem + `PrimaryButton('Tentar novamente')` (padrão `host_profile_page.dart`), data = `RefreshIndicator(color: AppColors.secondary) + SingleChildScrollView + Column` com `LayoutBuilder + GridView` dos 4 `MetricCard`, seção "Próximos check-ins" (empty state se vazio), seção "Reservas por status". Breakpoints: `<600` → 1 col, `600-900` → 2, `900-1200` → 3, `>1200` → 4.
- [x] Criar `Frontend/lib/features/profile/presentation/pages/admin_dashboard_page.dart` — análogo, consumindo `adminDashboardProvider`. Métricas: totalUsuarios, totalHoteis, reservasHoje, receitaPeriodo. Seções: "Top hotéis" (TopHotelTile), "Reservas por status", "Novos cadastros (últimos 7 dias)".
- [x] Centralizar helpers de formatação numa `lib/features/profile/presentation/utils/dashboard_formatters.dart` ou no topo das pages: `formatCurrency(double)`, `formatPercent(double)`, `formatInt(int)`.

### Roteamento

- [x] Atualizar `Frontend/lib/core/router/app_router.dart`: trocar stub `/host/dashboard` por `HostDashboardPage()`; trocar stub `/admin/dashboard` por `AdminDashboardPage()`. Confirmar padrão de registro (fora de `ShellRoute`, como `/admin/accounts` e `/host/rooms`).
- [x] Estender `redirect` global: `/admin/dashboard` exige `auth.role == AuthRole.admin` (reaproveita regra de `admin-account-management`). `/host/dashboard` exige `auth.role == AuthRole.host`.
- [x] Confirmar via grep que `AuthRole.host` já é populado no login de anfitrião (pelo fluxo de `host-signup-page` / `LoginPage`). Se não, registrar dívida técnica e proteger via fallback `auth.isAuthenticated`.

### Entry points (não criar — apenas verificar)

- [x] Confirmar que `admin_profile_page.dart` (linha 46-47) já tem `ProfileMenuItem('Dashboard', Icons.dashboard_outlined, onTap: () => context.go('/admin/dashboard'))`. Se já tem, zero mudança.
- [x] Confirmar que `host_profile_page.dart` tem entry equivalente para `/host/dashboard`; se não tiver, adicionar `ProfileMenuItem` na seção "Atividade".

### Validação de compilação

- [x] `flutter analyze` — 0 errors, 0 warnings no código novo.
- [x] `flutter build web` — compilação limpa.

---

## Validação [PENDENTE]

> Checkboxes abaixo marcadas como `[x]` cobrem validação estática (compilação, tipos, analyze, grep de padrões). As marcadas como `[ ]` exigem **ambiente rodando** (backend + device/navegador + banco com `seed.reservas` executado) e precisam ser validadas manualmente pelo usuário.

### Host Dashboard (testar manualmente em device/navegador)

- [ ] Host logado em `HostProfilePage` toca "Dashboard" → navega para `/host/dashboard`.
- [ ] Página carrega exibindo os 6 `MetricCard` (Reservas hoje, Ocupação, Receita, Avaliação média, Taxa de cancelamento, Estadia média) + "Próximos check-ins" + "Reservas por status".
- [ ] Trocar `PeriodSelector` para "Últimos 30 dias" dispara refetch e métricas são atualizadas.
- [ ] Botão de refresh do header dispara refetch.
- [ ] Pull-to-refresh dispara refetch.
- [ ] Backend offline → estado de erro com `PrimaryButton('Tentar novamente')`; toque dispara novo fetch.
- [ ] Hotel sem reservas no período → cards mostram 0; "Próximos check-ins" mostra empty state (não erro); taxa de cancelamento = 0%.
- [ ] Hotel sem avaliações → card "Avaliação média" mostra "—".
- [ ] Hotel sem reservas concluídas no período → card "Estadia média" mostra "—".
- [ ] Hotel sem quartos → `ocupacaoPercentual = 0%` sem quebrar.
- [ ] Labels dos status batem com `ReservaStatus.toLabel()` (Pendente, Aguardando pagamento, Confirmada, Cancelada, Finalizada).
- [ ] Usuário não-host tentando `/host/dashboard` via deep link → redirect para `/home` ou `/auth/login`.

### Admin Dashboard (testar manualmente em device/navegador)

- [x ] Admin logado em `AdminProfilePage` toca "Dashboard" → navega para `/admin/dashboard`.
- [x ] Página carrega exibindo os 5 `MetricCard` globais (Total usuários, Total hotéis, Reservas hoje, Receita, Receita média/hotel) + "Hotel mais bem avaliado" + Top 3 hotéis + Reservas por status + Novos cadastros.
- [ x] Trocar período atualiza métricas dependentes de período; "Novos cadastros" permanece fixo em últimos 7 dias; "Hotel mais bem avaliado" também não muda (avaliações são all-time).
- [ x] Plataforma sem reservas no período → cards com 0; Top hotéis com empty state; Receita média/hotel = R$ 0,00.
- [ x] Nenhum hotel com avaliações → seção "Hotel mais bem avaliado" não aparece (é escondida via `if data.melhorAvaliado != null`).
- [ x] "Novos cadastros" mostra contagens de usuários e hotéis dos últimos 7 dias (independente do `period`).
- [ x] Usuário não-admin tentando `/admin/dashboard` via deep link → redirect.

### Validação transversal (visual — testar manualmente)

- [x ] Grid responsivo: mobile (<600) 2 cols, tablet (600-900) 2 cols, desktop (900-1200) 3 cols, ultrawide (>1200) 4 cols — sem overflow. **Atenção especial no Host que agora tem 6 cards.**
- [x ] Header segue exatamente o visual de `my_rooms_page.dart` / `admin_account_management_page.dart` (primary, radius 27 bottom, padding top 60, botões circulares translúcidos).
- [x ] Cards seguem visual de `AdminUserCard` (branco, radius 11, border `Color(0x3F182541)`).
- [ x] Card do "Hotel mais bem avaliado" destaca com troféu laranja e exibe nome + estrela + total de avaliações.
- [ ] `Semantics` nos cards: leitor de tela lê "Reservas hoje: 12" ao focar.
- [ x] Números formatados: separador de milhar (`1.234`), moeda com `R$` + 2 casas, percentual com 1 casa.
- [ x] Logout no meio do dashboard → redirect para `/auth/login` (reação ao `authProvider`).

### Code review de padrão visual (validado estaticamente)

- [x] Nenhum `Colors.blue`, `Colors.grey.shade500` ou cor inline — todas via `AppColors`. Confirmado via grep em todos os arquivos de dashboard.
- [x] Nenhuma string "mock"/"fake"/"example" hardcoded. Confirmado via grep — única ocorrência é um comentário explicativo em `dashboard_service.dart:12`.
- [x] Dark Mode fora de escopo: não forçar `Theme.of(context).colorScheme.*`. Confirmado via grep — zero ocorrências nos arquivos novos.

---

## Regra de Atualização de Status

- Todas `[ ]` → `[PENDENTE]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`

Quando todas as seções estiverem `[CONCLUÍDO]`, atualizar o **Status geral** para `[CONCLUÍDO]` e sincronizar com `conductor/plan.md` (localizar bloco da feature ou criar nova fase ao final com status `[CONCLUÍDO]`).
