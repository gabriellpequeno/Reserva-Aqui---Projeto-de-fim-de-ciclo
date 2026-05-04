# PRD — dashboard-host-admin

> Ticket Linear: **RES-64**
> Escopo: implementação das telas de Dashboard para os papéis **Host** e **Admin**, ambas hoje existentes apenas como stubs (`Text('Página: Dashboard')`) nas rotas `/host/dashboard` e `/admin/dashboard`.
> Entrega em **duas fases sequenciais**: **Fase 1 — Backend** (endpoints `GET /host/dashboard` e `GET /admin/dashboard`, pré-requisito bloqueante) → **Fase 2 — Frontend** (telas, providers, widget `MetricCard`). Nenhum trabalho de Fase 2 começa antes de a Fase 1 estar mergeada e disponível em staging.

---

## Contexto

As rotas `/host/dashboard` e `/admin/dashboard` já estão registradas no `app_router.dart` e são navegáveis a partir de `host_profile_page.dart` e `admin_profile_page.dart`, respectivamente. Porém, ambas entregam apenas um `Text('Página: Dashboard')` — não há painel de métricas, nenhuma integração com backend e nenhuma visibilidade real do estado operacional do sistema.

Sem um dashboard funcional:

- O **host** não consegue acompanhar a saúde operacional do próprio hotel — não vê quantas reservas tem hoje, qual a ocupação atual, qual a receita do mês, próximos check-ins nem a distribuição de reservas por status.
- O **admin** não tem visão agregada da plataforma — não enxerga total de usuários cadastrados, total de hotéis ativos, receita global, top performers ou novos cadastros recentes.

Esta feature entrega **as duas telas** de uma vez, com estrutura visual consistente (mesmo grid de `MetricCard`, mesmas seções auxiliares), dados diferentes por papel, filtros por período e refresh manual.

---

## Problema

1. **Stubs em rotas críticas da demo:** tanto `/host/dashboard` quanto `/admin/dashboard` são pontos de entrada principais dos respectivos papéis, e hoje entregam conteúdo zero.
2. **Falta de visibilidade operacional (host):** sem dashboard, o host precisa navegar por múltiplas páginas (reservas, quartos) para montar mentalmente o estado do hotel — sem nenhuma agregação.
3. **Falta de visibilidade de plataforma (admin):** o admin não tem ferramenta para avaliar saúde do sistema como um todo; o `AdminProfilePage` foca em gestão de contas, não em métricas.
4. **Ausência de widget reutilizável de métrica:** não existe um `MetricCard` no projeto; cada tela que precise exibir indicadores numéricos hoje precisaria construir do zero.

---

## Público-alvo

Dois perfis distintos, ambos autenticados via JWT (`papel` no payload, introduzido em `admin-account-management`):

- **Host** — proprietário/gestor de hotel que usa o dashboard para monitoramento operacional diário do próprio estabelecimento. Vê apenas métricas do hotel associado ao usuário autenticado.
- **Admin** — administrador da plataforma Reserva Aqui, que usa o dashboard para monitoramento agregado de todos os hotéis e usuários. Vê dados globais.

Não é público final (hóspede/usuário comum). As rotas são protegidas por `authGuard` + `roleGuard`.

---

## Requisitos Funcionais

### RF-1 — Host Dashboard (`/host/dashboard`)

1. A tela deve exibir `AppBar` com título "Dashboard", data atual e botão de refresh manual.
2. A tela deve exibir um seletor de período com os presets: **Hoje**, **Últimos 7 dias**, **Mês corrente**, **Últimos 30 dias**. Todas as métricas reagem à mudança do período.
3. A tela deve exibir um grid de `MetricCard` com as métricas principais do hotel autenticado:
   - **Reservas hoje** — total de check-ins do dia
   - **Ocupação atual** — quartos ocupados / total, em percentual
   - **Receita do mês** — soma das reservas confirmadas no mês corrente
   - **Avaliação média** — média de estrelas do hotel
4. A tela deve exibir a seção "Próximos check-ins" com lista de até 5 itens (nome do hóspede, número do quarto, data).
5. A tela deve exibir a seção "Reservas por status" com chips ou mini-barras representando os status: `pendente`, `confirmada`, `em andamento`, `finalizada`, `cancelada`.
6. A tela deve consumir `GET /host/dashboard` (endpoint único agregando todas as métricas do hotel do host autenticado), aceitando query param `?period=today|last7|current_month|last30` correspondente ao preset selecionado.

### RF-2 — Admin Dashboard (`/admin/dashboard`)

8. A tela deve exibir `AppBar` com título "Dashboard", data atual e botão de refresh manual.
9. A tela deve exibir o mesmo seletor de período do Host Dashboard, com os mesmos presets.
10. A tela deve exibir um grid de `MetricCard` com as métricas globais da plataforma:
    - **Total de usuários** — hóspedes cadastrados
    - **Total de hotéis** — hotéis ativos na plataforma
    - **Reservas hoje** — total agregado da plataforma
    - **Receita da plataforma no mês** — soma global
11. A tela deve exibir a seção "Hotéis com mais reservas ativas" (Top 3), com nome do hotel + número de reservas ativas no período (reservas com `status = 'APROVADA'` cujo intervalo `data_checkin`–`data_checkout` intersecta o período selecionado). **Nota:** métrica adaptada da ideia original "maior ocupação %" porque o cálculo de ocupação exata exigiria iteração por todos os schemas tenants; "reservas ativas" é consultável diretamente em `historico_reserva_global` no master e é proporcional à ocupação.
12. A tela deve exibir a seção "Reservas por status" (visão global), com os mesmos status do Host Dashboard.
13. A tela deve exibir a seção "Novos cadastros" com contadores de usuários e hotéis criados nos últimos 7 dias.
14. A tela deve consumir `GET /admin/dashboard` (endpoint único agregando todas as métricas globais), aceitando o mesmo query param `?period=today|last7|current_month|last30`.

### RF-3 — Widget `MetricCard` (compartilhado)

15. Criar o widget `MetricCard` em `Frontend/lib/features/profile/presentation/widgets/metric_card.dart`, reutilizável por ambos os dashboards.
16. O `MetricCard` deve receber: `title: String`, `value: String`, `icon: IconData`, `color: Color?` (opcional; default `AppColors.secondary` para o ícone).
17. O `MetricCard` deve seguir o padrão visual dos cards existentes (ex.: `AdminUserCard`): `Colors.white`, `borderRadius: 11`, `border: Color(0x3F182541)`, tipografia `color: AppColors.primary, size: 15, weight: 700` para o valor e `color: AppColors.greyText, size: 12` para o título.
18. O layout do grid de cards deve ser responsivo (P6-B): 2 colunas em mobile, 3-4 em tablet/desktop; em telas muito estreitas pode colapsar para coluna única.

### RF-4 — Integração com rotas

19. Substituir o stub da rota `/host/dashboard` em `Frontend/lib/core/router/app_router.dart` pela `HostDashboardPage` real.
20. Substituir o stub da rota `/admin/dashboard` em `Frontend/lib/core/router/app_router.dart` pela `AdminDashboardPage` real.
21. Ambas as rotas devem estar protegidas por `authGuard` + verificação de papel (`host` ou `admin` via `auth.papel`), redirecionando caso contrário.

### RF-5 — Interações

22. Ao tocar no botão de refresh (AppBar) ou fazer pull-to-refresh (mobile), todas as métricas da tela devem ser recarregadas para o período atualmente selecionado.
23. A troca de período no seletor deve disparar refetch automático das métricas.

---

## Requisitos Não-Funcionais

- [ ] **Segurança:** rotas `/host/dashboard` e `/admin/dashboard` protegidas por `authGuard` + verificação de papel no frontend (`redirect` global do `app_router.dart`) e por `authGuard` + `adminGuard` (ou verificação de `req.userPapel`) no backend — autoridade final é o servidor. Host só acessa métricas do próprio hotel; admin tem acesso global.
- [ ] **Performance:** evitar rebuilds desnecessários (usar `select` do Riverpod quando fizer sentido); reaproveitar cache do provider ao simplesmente renavegar para a tela. Queries de agregação no backend devem usar índices já existentes em `reserva.id_hotel`, `reserva.criado_em` e `quarto.id_hotel`.
- [ ] **Acessibilidade:** `Semantics` descritivo nos elementos interativos (botão de refresh, seletor de período); `Semantics` em cada `MetricCard` com label composto (ex.: "Reservas hoje: 12"). Uso dos tokens de `AppColors` garante contraste consistente com o restante do app — sem prometer nível AA específico (não testado).
- [ ] **Responsividade (P6-B):** grid adapta `crossAxisCount` conforme largura disponível (`LayoutBuilder`); seções de lista (próximos check-ins, top hotéis) se reorganizam sem overflow.
- [ ] **Consistência visual:** seguir o padrão visual já estabelecido em `admin_account_management_page.dart` e `my_rooms_page.dart` — header curvo com `AppColors.primary` e `BorderRadius.only(bottomLeft: 27, bottomRight: 27)`, cards brancos com `borderRadius: 11` e borda `Color(0x3F182541)`. **Sem introduzir estética nova.** Dark Mode não é escopo desta feature (entrega em P6-A).
- [ ] **Resiliência:** estados de `loading` (`CircularProgressIndicator(color: AppColors.secondary)`), `empty` (hotel/plataforma sem dados no período) e `error` (falha de rede) tratados explicitamente — com `PrimaryButton('Tentar novamente')` no estado de erro, igual `host_profile_page.dart`.
- [ ] **Consistência de código:** seguir o padrão Riverpod já estabelecido em `host_profile_provider.dart` / `admin_profile_provider.dart` / `user_profile_provider.dart`.

---

## Critérios de Aceitação

### Host Dashboard

- Dado que um host autenticado acessa `/host/dashboard`, quando a página carrega, então todas as métricas do próprio hotel (reservas hoje, ocupação, receita do mês, avaliação média, próximos check-ins, reservas por status) são exibidas em cards/listas.
- Dado que o hotel do host não tem reservas no período selecionado, quando a página carrega, então os cards mostram `0` (ou `—`) e a seção "Próximos check-ins" exibe empty state com mensagem clara — sem erro.
- Dado que o fetch das métricas falha (rede ou servidor), quando a página carrega, então um estado de erro é exibido com botão "Tentar novamente" (nunca dados fictícios).
- Dado que um usuário não-host tenta acessar `/host/dashboard`, quando a rota é resolvida, então o `redirect` do `app_router.dart` o envia para `/home` ou `/auth/login`.
- Dado que o host troca o período selecionado (ex.: de "Hoje" para "Últimos 30 dias"), quando a seleção é feita, então todas as métricas da tela são refetched e atualizadas.
- Dado que o host toca no botão de refresh, ou faz pull-to-refresh, quando a ação é disparada, então as métricas são recarregadas.

### Admin Dashboard

- Dado que um admin autenticado acessa `/admin/dashboard`, quando a página carrega, então todas as métricas globais (usuários, hotéis, reservas hoje, receita, top 3 hotéis por reservas ativas, reservas por status, novos cadastros) são exibidas.
- Dado que a plataforma está sem dados no período selecionado, quando a página carrega, então cards mostram `0` e listas exibem empty state.
- Dado que o backend retorna erro ou timeout, quando a página tenta carregar, então um estado de erro com botão "Tentar novamente" é exibido (nunca dados fictícios).
- Dado que um usuário não-admin tenta acessar `/admin/dashboard`, quando a rota é resolvida, então o `redirect` do `app_router.dart` o envia para `/home` ou `/auth/login`.
- Dado que o admin troca o período, quando a seleção é feita, então todas as métricas da tela são refetched.
- Dado que o admin toca em refresh ou faz pull-to-refresh, quando a ação é disparada, então as métricas são recarregadas.

### Compartilhado

- Dado o `MetricCard`, quando recebe `title`, `value` e `icon`, então renderiza o card seguindo o padrão visual de `AdminUserCard` (branco, radius 11, borda `0x3F182541`, tipografia do `AppColors`).
- Dado o grid de métricas, quando a largura da tela é menor que ~600px, então os cards se reorganizam em 1–2 colunas; em telas maiores, usam 3–4 colunas sem overflow.
- Dado o header de ambas as páginas, quando renderizado, então segue o padrão de `my_rooms_page.dart` / `admin_account_management_page.dart` (container `AppColors.primary`, `BorderRadius.only(bottomLeft: 27, bottomRight: 27)`, padding top 60, botões circulares translúcidos).

---

## Fora de Escopo

- Gráficos avançados (line charts, area charts, timeseries com eixos) — uso restrito a cards, chips e mini-barras simples.
- Custom date range no filtro de período (apenas os 4 presets: Hoje, Últimos 7 dias, Mês corrente, Últimos 30 dias).
- Exportação de relatórios (PDF, CSV, Excel).
- Drill-down interativo (clicar num card e abrir detalhe expandido com breakdown).
- Real-time updates via WebSocket/SSE — refresh é manual ou por pull-to-refresh.
- Configuração de métricas customizadas pelo host/admin.
- Alertas e notificações baseadas em thresholds (ex.: "ocupação abaixo de X%").
- Comparativos históricos entre períodos (ex.: mês atual vs mês anterior com deltas).
- Criação de dashboard customizado (reordenar cards, esconder métricas).
- Internacionalização (strings em PT-BR apenas, padrão do projeto).
- Dark Mode (entrega em P6-A, feature separada).
- Dados mock como fallback — a feature depende 100% dos endpoints reais (Fase 1 é pré-requisito da Fase 2).
- Tabelas de agregação pré-computadas / cache de métricas no backend (queries agregam on-the-fly a partir das tabelas operacionais e do espelho `historico_reserva_global`).
- Cálculo de ocupação percentual exata no Admin Dashboard (substituído por "reservas ativas" — ver RF-2 #11).
- Sincronização de `historico_reserva_global` não coberta pelo código atual: esta feature **depende** do double-write já existente em `reserva.controller.ts`; se esse espelho estiver desatualizado, a apuração é trabalho de outra task.
