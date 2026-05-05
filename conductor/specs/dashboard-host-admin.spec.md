# Spec — dashboard-host-admin

> Ticket Linear: **RES-64**
> Entrega em **duas fases sequenciais**: **Fase 1 — Backend** (endpoints `GET /host/dashboard` e `GET /admin/dashboard`, pré-requisito bloqueante) → **Fase 2 — Frontend** (telas, providers, widget `MetricCard`). Nenhum trabalho de Fase 2 começa antes de a Fase 1 estar mergeada e disponível em staging.

## Referência

- **PRD:** [`conductor/features/dashboard-host-admin.prd.md`](../features/dashboard-host-admin.prd.md)
- **Task de origem:** `conductor/task/P6-D-dashboard-host-admin.md`
- **Referências de padrão — Backend:**
  - `Backend/src/middlewares/authGuard.ts` — padrão de JWT guard com `AuthRequest` e `userPapel`
  - `Backend/src/middlewares/hotelGuard.ts` — guard de anfitrião com `HotelRequest` e `hotelId`
  - `Backend/src/middlewares/adminGuard.ts` — já existente (entregue em `admin-account-management`)
  - `Backend/src/controllers/admin.controller.ts` — padrão de controller admin usando `adminGuard`
  - `Backend/src/modules/hotel/` — padrão de organização em `modules/{feature}/`
  - `Backend/database/scripts/init_master.sql` — `usuario`, `anfitriao`, `historico_reserva_global`
  - `Backend/database/scripts/init_tenant.sql` — `reserva`, `quarto`, `avaliacao` (por tenant)
- **Referências de padrão — Frontend:**
  - `Frontend/lib/features/profile/presentation/providers/admin_profile_provider.dart` — padrão Riverpod `AsyncNotifier`
  - `Frontend/lib/features/profile/presentation/providers/host_profile_provider.dart` — `AsyncNotifier` com `Completer`
  - `Frontend/lib/features/profile/presentation/pages/admin_account_management_page.dart` — header curvo + corpo scrollable + busca
  - `Frontend/lib/features/rooms/presentation/pages/my_rooms_page.dart` — header curvo padrão + layout de lista
  - `Frontend/lib/features/profile/presentation/widgets/admin_user_card.dart` — padrão visual de card (radius 11, borda `0x3F182541`)
  - `Frontend/lib/core/router/app_router.dart` — `GoRoute` + `redirect` global
  - `Frontend/lib/core/theme/app_colors.dart` — tokens de cor (`primary #182541`, `secondary #EC6725`, etc.)

---

## Abordagem Técnica

**Entrega em duas fases sequenciais** — mesmo padrão de `admin-account-management`.

### Fase 1 — Backend

Criar dois endpoints `GET` agregando métricas **on-the-fly** (sem tabelas novas, sem cache de aplicação):

- `GET /host/dashboard?period=today|last7|current_month|last30` — protegido por `hotelGuard`. Resolve `req.hotelId → schema_name` e conecta ao schema tenant para rodar as queries de `reserva`, `quarto`, `avaliacao` daquele hotel.
- `GET /admin/dashboard?period=today|last7|current_month|last30` — protegido por `adminGuard` (já existente). **Queries rodam exclusivamente no master** usando `usuario`, `anfitriao` e `historico_reserva_global` — zero iteração pelos schemas tenants.

**Decisão-chave 1:** *um endpoint único por papel* (não endpoints individuais por métrica) — reduz round-trips e simplifica state management no frontend.

**Decisão-chave 2:** *Admin Dashboard lê 100% do master* via `historico_reserva_global`, que já existe e é o espelho global das reservas por design. Isso evita agregação cross-schema, que seria `O(N)` com o número de hotéis.

**Decisão-chave 3:** *`topHoteis` do Admin Dashboard é calculado por "reservas ativas"* (count de reservas `APROVADA` com intervalo `data_checkin`–`data_checkout` intersectando o período) em vez de "ocupação %" — porque o total de quartos por hotel vive no schema tenant, não no master. Proporcional à ocupação, consultável só no master. Registrado no PRD (RF-2 #11).

**Pré-requisito bloqueante:** validar manualmente que `reserva.controller.ts` mantém `historico_reserva_global` sincronizado (INSERT ao criar, UPDATE ao mudar status). Sem isso, o Admin Dashboard retorna números errados.

**Status das reservas:** a API devolve os status **canônicos do banco** (`SOLICITADA`, `AGUARDANDO_PAGAMENTO`, `APROVADA`, `CANCELADA`, `CONCLUIDA`) — tradução para labels UI-friendly ("Pendente", "Confirmada", etc.) é responsabilidade do frontend. Sem mapping implícito na API.

### Fase 2 — Frontend

Duas páginas novas (`HostDashboardPage`, `AdminDashboardPage`) em `Frontend/lib/features/profile/presentation/pages/`, cada uma consumindo um `AsyncNotifier` parametrizado pelo período. Um único `DashboardService` em `data/services/` faz os fetches autenticados via `DioClient`.

**Estrutura visual replica exatamente o vocabulário já existente** — sem redesenho:

- Header curvo `AppColors.primary` + `BorderRadius.only(bottomLeft: 27, bottomRight: 27)` + `padding: EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24)` (padrão de `my_rooms_page.dart` e `admin_account_management_page.dart`).
- Row no header: botão voltar circular `white.withAlpha(0.2)` | centro com logo SVG + "Dashboard" | botão refresh circular `white.withAlpha(0.2)`.
- Seletor de período: chips horizontais fixos abaixo do header (4 opções cabem em qualquer tela).
- Body em `SingleChildScrollView` com `RefreshIndicator(color: AppColors.secondary)`.
- Grid de `MetricCard` via `LayoutBuilder` (ajusta `crossAxisCount` por largura disponível).
- Seções auxiliares ("Próximos check-ins", "Top Hotéis", "Reservas por status", "Novos cadastros") usando cards/chips no mesmo vocabulário de `AdminUserCard` (branco, radius 11, border `0x3F182541`, tipografia `AppColors`).

**Sem fallback mock em runtime.** Erros viram estado de erro com `PrimaryButton('Tentar novamente')` (padrão `host_profile_page.dart`).

**Dark Mode não é escopo** desta feature — entrega em P6-A (tokens semânticos do theme).

**Guards de rota:** estender `redirect` global do `app_router.dart` para exigir `auth.papel == 'admin'` em `/admin/*` (se ainda não cobre `/admin/dashboard`) e token de anfitrião válido em `/host/*`.

---

## Fase 1 — Backend

### Arquivos novos

| Arquivo | Responsabilidade |
|---------|------------------|
| `Backend/src/controllers/dashboard.controller.ts` | `getHostDashboardController(req, res)` e `getAdminDashboardController(req, res)` — parseiam `?period`, chamam o service, serializam response |
| `Backend/src/routes/dashboard.routes.ts` | Router Express com `GET /host/dashboard` (`hotelGuard`) e `GET /admin/dashboard` (`adminGuard`) |
| `Backend/src/modules/dashboard/dashboard.service.ts` | Funções `getHostMetrics(hotelId, period)` e `getAdminMetrics(period)` — encapsulam SQL agregado |
| `Backend/src/modules/dashboard/dashboard.types.ts` | Tipos compartilhados: `Period`, `HostDashboardResponse`, `AdminDashboardResponse`, `ReservaStatusCount`, `NextCheckin`, `TopHotel` |
| `Backend/src/modules/dashboard/period.utils.ts` | Helper `resolvePeriod(p: Period): { start: Date; end: Date }` — converte preset em range SQL |

### Arquivos modificados

| Arquivo | O que muda |
|---------|------------|
| `Backend/src/server.ts` (ou bootstrap equivalente) | Registrar `app.use(dashboardRouter)` |

**Nenhuma migration.** Todas as queries rodam sobre tabelas existentes.

### Queries principais

**Host Dashboard** (schema tenant resolvido a partir de `anfitriao.schema_name`):

```sql
-- reservasHoje
SELECT COUNT(*) FROM <schema>.reserva
WHERE data_checkin = CURRENT_DATE;

-- ocupacaoPercentual (no momento da consulta)
SELECT
  COUNT(*) FILTER (WHERE NOT disponivel) AS ocupados,
  COUNT(*) AS total
FROM <schema>.quarto
WHERE deleted_at IS NULL;
-- percent = ocupados / total * 100 (app-side; 0 se total = 0)

-- receitaPeriodo
SELECT COALESCE(SUM(valor_total), 0) FROM <schema>.reserva
WHERE status IN ('APROVADA', 'CONCLUIDA')
  AND criado_em >= $1 AND criado_em < $2;

-- avaliacaoMedia + totalAvaliacoes
SELECT AVG(nota_total) AS media, COUNT(*) AS total
FROM <schema>.avaliacao;

-- proximosCheckins (limit 5)
SELECT r.id, r.codigo_publico, COALESCE(r.nome_hospede, h.nome_completo) AS nome_hospede,
       q.numero AS quarto_numero, r.tipo_quarto, r.data_checkin
FROM <schema>.reserva r
LEFT JOIN <schema>.quarto q ON q.id = r.quarto_id
LEFT JOIN <master>.usuario h ON h.user_id = r.user_id
WHERE r.data_checkin >= CURRENT_DATE AND r.status IN ('APROVADA', 'AGUARDANDO_PAGAMENTO')
ORDER BY r.data_checkin ASC
LIMIT 5;

-- reservasPorStatus
SELECT status, COUNT(*) AS count
FROM <schema>.reserva
WHERE criado_em >= $1 AND criado_em < $2
GROUP BY status;
```

**Admin Dashboard** (100% no master):

```sql
-- totalUsuarios
SELECT COUNT(*) FROM usuario WHERE papel = 'usuario' AND ativo = true;

-- totalHoteis
SELECT COUNT(*) FROM anfitriao WHERE ativo = true;

-- reservasHoje
SELECT COUNT(*) FROM historico_reserva_global
WHERE data_checkin = CURRENT_DATE;

-- receitaPeriodo
SELECT COALESCE(SUM(valor_total), 0) FROM historico_reserva_global
WHERE status IN ('APROVADA', 'CONCLUIDA')
  AND criado_em >= $1 AND criado_em < $2;

-- topHoteis (Top 3 por reservas ativas no período)
SELECT hotel_id, nome_hotel, COUNT(*) AS reservas_ativas
FROM historico_reserva_global
WHERE status = 'APROVADA'
  AND data_checkin <= $2
  AND data_checkout > $1
GROUP BY hotel_id, nome_hotel
ORDER BY reservas_ativas DESC
LIMIT 3;

-- reservasPorStatus (global)
SELECT status, COUNT(*) AS count
FROM historico_reserva_global
WHERE criado_em >= $1 AND criado_em < $2
GROUP BY status;

-- novosCadastros (últimos 7 dias — fixo, independente do period)
SELECT
  (SELECT COUNT(*) FROM usuario   WHERE criado_em >= NOW() - INTERVAL '7 days') AS usuarios,
  (SELECT COUNT(*) FROM anfitriao WHERE criado_em >= NOW() - INTERVAL '7 days') AS hoteis;
```

### Resolução de período

`resolvePeriod(p: Period)` retorna `{ start: Date, end: Date }`:

- `today` → `[CURRENT_DATE, CURRENT_DATE + 1 day)`
- `last7` → `[NOW() - 7 days, NOW() + 1 second)` (fim inclusivo via `<`)
- `current_month` → `[date_trunc('month', NOW()), date_trunc('month', NOW()) + 1 month)`
- `last30` → `[NOW() - 30 days, NOW() + 1 second)`

Timezone: servidor (documentado).

---

## Fase 2 — Frontend

### Arquivos novos

**Pages:**
- `HostDashboardPage` (`Frontend/lib/features/profile/presentation/pages/host_dashboard_page.dart`) — `ConsumerStatefulWidget` com `DashboardPeriod` no state local
- `AdminDashboardPage` (`Frontend/lib/features/profile/presentation/pages/admin_dashboard_page.dart`) — idem, com métricas globais

**Widgets:**
- `DashboardHeader` (`Frontend/lib/features/profile/presentation/widgets/dashboard_header.dart`) — header curvo compartilhado (voltar + logo + título + botão refresh)
- `MetricCard` (`Frontend/lib/features/profile/presentation/widgets/metric_card.dart`) — card de métrica reutilizável (título, valor formatado, ícone, cor opcional)
- `PeriodSelector` (`Frontend/lib/features/profile/presentation/widgets/period_selector.dart`) — chips horizontais dos 4 presets
- `NextCheckinTile` (`Frontend/lib/features/profile/presentation/widgets/next_checkin_tile.dart`) — item da lista "Próximos check-ins" (Host only)
- `TopHotelTile` (`Frontend/lib/features/profile/presentation/widgets/top_hotel_tile.dart`) — item da lista "Top hotéis" (Admin only)
- `ReservaStatusBreakdown` (`Frontend/lib/features/profile/presentation/widgets/reserva_status_breakdown.dart`) — mini-barras/chips dos status (compartilhado)
- `NovosCadastrosRow` (`Frontend/lib/features/profile/presentation/widgets/novos_cadastros_row.dart`) — dupla de contadores (Admin only)

**Providers:**
- `hostDashboardProvider` (`Frontend/lib/features/profile/presentation/providers/host_dashboard_provider.dart`) — `AsyncNotifier<HostDashboardState>`; métodos `setPeriod(DashboardPeriod)` e `refresh()`
- `adminDashboardProvider` (`Frontend/lib/features/profile/presentation/providers/admin_dashboard_provider.dart`) — `AsyncNotifier<AdminDashboardState>`; mesma assinatura

**Service:**
- `DashboardService` (`Frontend/lib/features/profile/data/services/dashboard_service.dart`) — wrapper `DioClient`: `getHostDashboard(period)`, `getAdminDashboard(period)`

**Models:**
- `Frontend/lib/features/profile/domain/models/dashboard/dashboard_period.dart` — `enum DashboardPeriod`
- `Frontend/lib/features/profile/domain/models/dashboard/reserva_status.dart` — `enum ReservaStatus` + `toLabel()` + `fromString()`
- `Frontend/lib/features/profile/domain/models/dashboard/reserva_status_count.dart`
- `Frontend/lib/features/profile/domain/models/dashboard/next_checkin_model.dart`
- `Frontend/lib/features/profile/domain/models/dashboard/top_hotel_model.dart`
- `Frontend/lib/features/profile/domain/models/dashboard/host_dashboard_state.dart` — inclui `HostDashboardMetrics`
- `Frontend/lib/features/profile/domain/models/dashboard/admin_dashboard_state.dart` — inclui `AdminDashboardMetrics` e `NovosCadastros`

### Arquivos modificados

| Arquivo | O que muda |
|---------|------------|
| `Frontend/lib/core/router/app_router.dart` | Trocar stub `/host/dashboard` por `HostDashboardPage`; trocar stub `/admin/dashboard` por `AdminDashboardPage`; estender `redirect` global para exigir `auth.papel == 'admin'` em `/admin/*` (se necessário) e token de anfitrião válido em `/host/*` |

---

## Decisões de Arquitetura

### Backend

| Decisão | Justificativa |
|---------|---------------|
| Endpoint único por papel (`GET /host/dashboard`, `GET /admin/dashboard`) em vez de N endpoints por métrica | Reduz round-trips; todas as métricas chegam numa única transação; state management no frontend fica trivial (um provider, um fetch). |
| Query param `?period` com 4 presets (enum string) em vez de `?from` + `?to` (datas livres) | PRD restringe a 4 presets; enum evita validação de datas arbitrárias e habilita cache futuro por chave `papel + period`. |
| Agregação on-the-fly em SQL (sem tabela pré-computada / sem cache de aplicação) | Escala da apresentação comporta; dados sempre frescos; zero complexidade adicional. |
| `modules/dashboard/` em vez de `services/` solto | Segue padrão `modules/hotel/` já existente no backend. |
| Admin Dashboard lê **apenas** do master via `historico_reserva_global` | Evita agregação cross-schema `O(N_hotels)`. O espelho já existe por design. |
| `topHoteis` calculado por "reservas ativas" em vez de "ocupação %" exata | Total de quartos vive no tenant; "reservas ativas" é proporcional à ocupação e consultável só no master. Decisão registrada no PRD (RF-2 #11). |
| Host Dashboard resolve `schema_name` inline via `hotelId` | Padrão já usado em `reserva.controller.ts`; centralizado em helper `resolveTenantSchema(hotelId)` no service. |
| Sem `hostGuard` novo — usar `hotelGuard` existente | `hotelGuard` já rejeita tokens de usuário/admin (força `hotel_id` no payload); suficiente para `/host/*`. |
| Status de reserva expostos em valor canônico do banco (`SOLICITADA`, `AGUARDANDO_PAGAMENTO`, etc.) | API sem mapping implícito; tradução UI é do frontend. |
| `novosCadastros` fixado em 7 dias (independente do `period`) | Requisito do PRD (RF-2 #13). Métrica de "momentum recente", não relativa ao filtro. |

### Frontend

| Decisão | Justificativa |
|---------|---------------|
| Dois providers separados (`hostDashboardProvider` + `adminDashboardProvider`) | Endpoints distintos, papéis distintos, ciclos de invalidação independentes. Mesmo princípio de `adminUsersProvider` + `adminHotelsProvider`. |
| `AsyncNotifier` com `DashboardPeriod` no `build(...)` | Trocar período dispara `refresh` automático do provider — padrão Riverpod idiomático. |
| `DashboardHeader` compartilhado em vez de duplicar `_buildHeader` inline | Evita duplicação; widget recebe `title` + `onRefresh` + `onBack` sem lógica condicional. |
| `LayoutBuilder` (não `MediaQuery`) para `crossAxisCount` do grid | Reage à largura disponível do ancestor, não à janela — melhor em web/desktop com painéis laterais. Breakpoints: `<600` → 1 col, `600-900` → 2, `900-1200` → 3, `>1200` → 4. |
| `MetricCard` recebe `value: String` (já formatado) em vez de `double`/`int` | Formatação (moeda, percentual, inteiro) é responsabilidade da page (tem contexto do locale). Widget fica burro e reutilizável. |
| Seletor de período como chips horizontais fixos (sem scroll) | 4 opções cabem em qualquer tela ≥ mobile; scroll é fricção desnecessária. |
| Replicar padrão visual de `admin_account_management_page.dart` + `my_rooms_page.dart` | Identidade visual já definida; zero redesenho. Tokens: `AppColors.primary`, `AppColors.secondary`, radius 11 cards, radius 27 header, border `Color(0x3F182541)`, padding `top: 60, h: 24`. |
| Sem fallback mock em runtime | Fase 1 é pré-requisito bloqueante; erros viram estado de erro com retry. Registrado no PRD. |
| Dark Mode não é escopo | Entrega em P6-A. Aqui a gente continua usando os tokens `AppColors` atuais sem forçar migração precoce. |

---

## Contratos de API

### Endpoints novos (Fase 1)

| Método | Rota | Query | Body | Response | Middleware |
|--------|------|-------|------|----------|------------|
| GET | `/host/dashboard` | `?period=today\|last7\|current_month\|last30` (default: `today`) | — | `HostDashboardResponse` | `hotelGuard` |
| GET | `/admin/dashboard` | `?period=today\|last7\|current_month\|last30` (default: `today`) | — | `AdminDashboardResponse` | `adminGuard` |

### Erros previstos

- `401` — token ausente/inválido/expirado.
- `403` — token válido mas sem autoridade (admin em `/host/*` é bloqueado pelo `hotelGuard`; hotel em `/admin/*` é bloqueado pelo `adminGuard`).
- `400` — `period` fora do enum dos 4 presets.
- `500` — falha interna (ex.: erro ao resolver `schema_name`, erro de conexão com tenant).

**Autenticação:** Bearer JWT no header. `DioClient` aplica automaticamente.

**Sem paginação** — payloads são pequenos e fechados (`proximosCheckins` limitado a 5, `topHoteis` limitado a 3).

---

## Modelos de Dados

### Backend — Schema

**Nenhuma alteração.** Tabelas já existentes:

- **Master:** `usuario`, `anfitriao`, `historico_reserva_global`.
- **Tenant:** `reserva`, `quarto`, `avaliacao`.

### Backend — Shape dos responses

```
Period = 'today' | 'last7' | 'current_month' | 'last30'

ReservaStatus = 'SOLICITADA' | 'AGUARDANDO_PAGAMENTO' | 'APROVADA' | 'CANCELADA' | 'CONCLUIDA'

ReservaStatusCount {
  status:  ReservaStatus
  count:   number
}

NextCheckin {
  reservaId:     number
  codigoPublico: string (uuid)
  nomeHospede:   string
  quartoNumero:  string | null
  tipoQuarto:    string | null
  dataCheckin:   string (ISO-8601 date)
}

TopHotel {
  hotelId:        string (uuid)
  nomeHotel:      string
  reservasAtivas: number   // reservas APROVADA com intervalo intersectando o período
}

HostDashboardResponse {
  period: Period
  metrics: {
    reservasHoje:       number
    ocupacaoPercentual: number    // 0-100; 0 se não há quartos
    receitaPeriodo:     number
    avaliacaoMedia:     number | null   // null se não há avaliações
    totalAvaliacoes:    number
  }
  proximosCheckins:  NextCheckin[]       // limit 5
  reservasPorStatus: ReservaStatusCount[]
}

AdminDashboardResponse {
  period: Period
  metrics: {
    totalUsuarios:  number
    totalHoteis:    number
    reservasHoje:   number       // agregado global
    receitaPeriodo: number       // agregado global
  }
  topHoteis:         TopHotel[]          // limit 3, desc por reservasAtivas
  reservasPorStatus: ReservaStatusCount[] // agregado global
  novosCadastros: {
    usuarios: number  // últimos 7 dias (fixo)
    hoteis:   number  // últimos 7 dias (fixo)
  }
}
```

### Frontend — Models (Dart)

```
enum DashboardPeriod { today, last7, currentMonth, last30 }
// toQueryValue() → 'today' | 'last7' | 'current_month' | 'last30'
// toLabel()       → 'Hoje' | 'Últimos 7 dias' | 'Mês corrente' | 'Últimos 30 dias'

enum ReservaStatus { solicitada, aguardandoPagamento, aprovada, cancelada, concluida }
// fromString(String) → ReservaStatus
// toLabel() → 'Pendente' | 'Aguardando pagamento' | 'Confirmada' | 'Cancelada' | 'Finalizada'

ReservaStatusCount {
  status: ReservaStatus
  count:  int
}

NextCheckinModel {
  reservaId:     int
  codigoPublico: String
  nomeHospede:   String
  quartoNumero:  String?
  tipoQuarto:    String?
  dataCheckin:   DateTime
}

TopHotelModel {
  hotelId:        String
  nomeHotel:      String
  reservasAtivas: int
}

HostDashboardMetrics {
  reservasHoje:       int
  ocupacaoPercentual: double
  receitaPeriodo:     double
  avaliacaoMedia:     double?
  totalAvaliacoes:    int
}

HostDashboardState {
  period:            DashboardPeriod
  metrics:           HostDashboardMetrics
  proximosCheckins:  List<NextCheckinModel>
  reservasPorStatus: List<ReservaStatusCount>
}

AdminDashboardMetrics {
  totalUsuarios:  int
  totalHoteis:    int
  reservasHoje:   int
  receitaPeriodo: double
}

NovosCadastros {
  usuarios: int
  hoteis:   int
}

AdminDashboardState {
  period:            DashboardPeriod
  metrics:           AdminDashboardMetrics
  topHoteis:         List<TopHotelModel>
  reservasPorStatus: List<ReservaStatusCount>
  novosCadastros:    NovosCadastros
}
```

### Convenções de `fromJson`

- Campos opcionais ausentes → `null` (não throw).
- `status` desconhecido → default `solicitada` + `debugPrint` de warning.
- `avaliacaoMedia` null quando `totalAvaliacoes == 0`.
- `dataCheckin` em ISO-8601; parse com `DateTime.parse(...)`; em erro, log e descarta o item.
- `receitaPeriodo` / `valor_total`: converter com `double.parse(value.toString())` — o `pg` pode entregar `DECIMAL` como string em JSON.

---

## Dependências

### Fase 1 — Backend

**Bibliotecas (já no `package.json`):**
- [x] `express` — roteamento
- [x] `jsonwebtoken` — validação JWT (via guards existentes)
- [x] `pg` — queries agregadas

**Nenhuma lib nova.**

**Infra / pré-condições:**
- [ ] **Validar que `historico_reserva_global` está sendo alimentado corretamente** pelo fluxo de reservas (double-write em `reserva.controller.ts`). **Bloqueante.** Se falhar: fix do double-write + script de backfill idempotente (`INSERT ... ON CONFLICT DO NOTHING`) antes de prosseguir.
- [x] `adminGuard` — já entregue em `admin-account-management`.
- [x] `hotelGuard` — já em uso em várias rotas.

### Fase 2 — Frontend

**Bibliotecas** (todas já no `pubspec.yaml`; nenhuma nova):
- [x] `flutter_riverpod` — `AsyncNotifier`
- [x] `go_router` — rotas + `redirect` global
- [x] `dio` (via `DioClient`) — HTTP com interceptor Bearer JWT

**Código existente reaproveitado:**
- [x] `AppColors` — tokens visuais
- [x] `PrimaryButton` — botão "Tentar novamente"
- [x] `DioClient` — fetch autenticado
- [x] `host_profile_provider.dart` / `admin_profile_provider.dart` — referência 1:1 de `AsyncNotifier`
- [x] `admin_account_management_page.dart` + `my_rooms_page.dart` — referência visual do header
- [x] `admin_user_card.dart` — referência visual de card (radius 11, border `0x3F182541`)

**Dependências de outras features:**
- [x] `authProvider.papel` — já populado via `admin-account-management` Fase 1.
- [ ] **Confirmar provider de token de anfitrião** (equivalente a `authProvider` mas para o login de hotel) — necessário para proteger `/host/*` no `redirect` global.

### Ordem de entrega

1. **Validação do double-write** em `historico_reserva_global` — item zero.
2. **Fase 1 completa** em staging (curl com admin e com hotel reais retornando 200 com payload válido).
3. **Fase 2** só inicia depois que (2) estiver verde.

---

## Riscos Técnicos

### Fase 1 — Backend

| Risco | Mitigação |
|-------|-----------|
| `historico_reserva_global` desatualizado (reservas sem espelho ou status divergente) | Validar manualmente antes de codar: criar reserva → verificar INSERT no master; mudar status → verificar UPDATE no master. Se falhar, corrigir o double-write (item zero) + backfill idempotente. |
| Queries agregadas lentas com volume alto | Usar índices existentes (`idx_reserva_datas`, `idx_reserva_status`, `idx_historico_user`); adicionar `idx_historico_criado_em` e `idx_historico_hotel_status` se necessário (migration menor). Dívida registrada caso as queries virem gargalo. |
| Conexão com schema tenant errado no Host Dashboard | Centralizar resolução `hotelId → schema_name` em `resolveTenantSchema(hotelId)` no service, seguindo o padrão de `reserva.controller.ts`. Teste manual com 2 hotéis distintos em staging antes do merge. |
| Divisão de período com timezone diferente do esperado | Usar `NOW()` / `CURRENT_DATE` do Postgres (timezone do servidor). Documentar no README que métricas são em timezone do servidor (provavelmente `America/Sao_Paulo`). |
| Endpoint `/host/dashboard` acessado por admin (ou vice-versa) | `hotelGuard` rejeita tokens de usuário (`403 — token não pertence a anfitrião`); `adminGuard` rejeita tokens de hotel. Isolamento natural pelos guards. |
| SQL injection via `period` query param | Validar `period` contra enum whitelist antes de usar; fora da whitelist → `400`. SQL usa placeholders parametrizados (`$1`, `$2`) — nunca string interpolation. |
| `ocupacaoPercentual` com divisão por zero | App-side: `total = 0 → ocupacaoPercentual = 0`. |

### Fase 2 — Frontend

| Risco | Mitigação |
|-------|-----------|
| Divergência entre token de admin (`authProvider.papel`) e token de anfitrião (`hotel_id`, sem `papel`) | `redirect` global trata os dois: `/admin/*` requer `authProvider.papel == 'admin'`; `/host/*` requer provider de token de hotel presente. Mapear o provider equivalente antes de codar. |
| `DashboardHeader` compartilhado acoplar Host ↔ Admin | Widget recebe apenas `title`, `onRefresh`, `onBack` como params; zero lógica condicional interna. Se divergir, refatorar é barato. |
| Troca rápida de período disparar múltiplos fetches em race condition | `setPeriod()` invalida a request anterior via `ref.invalidate` + debounce curto (150ms). |
| Fase 1 atrasar e travar a Fase 2 | Gate explícito: PR da Fase 2 só abre depois que curl em staging retornar 200 nos dois endpoints. Sem mock de conveniência. |
| `ReservaStatus` no frontend com label divergente do backend | `ReservaStatus.toLabel()` centralizado no model; revisão de PR valida tradução contra a lista canônica (`SOLICITADA → "Pendente"`, `AGUARDANDO_PAGAMENTO → "Aguardando pagamento"`, `APROVADA → "Confirmada"`, `CANCELADA → "Cancelada"`, `CONCLUIDA → "Finalizada"`). |
| Grid responsivo quebrar em desktop ultrawide | Breakpoints com limite superior: `<600` → 1 col, `600-900` → 2, `900-1200` → 3, `>1200` → 4. Acima disso mantém 4 para evitar cards gigantes. |
| Usuário ficar em `/admin/dashboard` após logout (estado residual) | `redirect` global reage a mudança em `authProvider` (padrão já existente no `app_router.dart`); ao `clear()` do auth, próximo rebuild redireciona para `/auth/login`. |
| Número grande de reservas poluir visualmente os cards | `MetricCard` formata valores (ex.: `1.234` em vez de `1234`; `R$ 15,3k` em vez de `R$ 15.340,00` acima de 10k). Formatação feita na page, com helper local. |
| Conflito visual entre o `DashboardHeader` e o `CustomBottomNav` (quando existir) | Testar em todas as larguras. Header tem padding top 60 (SafeArea-friendly); body em `SingleChildScrollView` evita overflow com bottom nav. |
