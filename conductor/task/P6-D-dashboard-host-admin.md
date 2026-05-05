# P6-D — dashboard-host-admin
> Derivada de: `host_profile_page.dart` (rota `/host/dashboard` stub) + `admin_profile_page.dart` (rota `/admin/dashboard` stub)

## Objetivo
Implementar as telas de Dashboard para Host e Admin. Ambas exibem métricas do sistema em cards/gráficos simples — estrutura visual semelhante, mas com dados diferentes. Host vê métricas do próprio hotel; Admin vê métricas globais da plataforma.

## Prioridade
**Alta** — ambas as rotas existem mas entregam `Text('Página: *Dashboard')` — aparece diretamente na demo.

---

## Pré-condições (o que já existe, não refazer)

- Rota `/host/dashboard` registrada no `app_router.dart` (stub com `Text`)
- Rota `/admin/dashboard` registrada no `app_router.dart` (stub com `Text`)
- `host_profile_page.dart` e `admin_profile_page.dart` já navegam para essas rotas

---

## O que precisa ser feito

### 1. Criar `host_dashboard_page.dart`
Caminho: `lib/features/profile/presentation/pages/host_dashboard_page.dart`

#### Métricas do Host
- [ ] **Reservas hoje** — total de check-ins do dia
- [ ] **Ocupação atual** — quartos ocupados / total (percentual)
- [ ] **Receita do mês** — soma das reservas confirmadas no mês corrente
- [ ] **Avaliação média** — média de estrelas do hotel
- [ ] **Próximos check-ins** — lista resumida (nome do hóspede, quarto, data)
- [ ] **Reservas por status** — cards ou mini gráfico (pendente, confirmada, em andamento, finalizada, cancelada)

#### Layout sugerido
- [ ] `AppBar` com título "Dashboard" e data atual
- [ ] Grid de `MetricCard` (2 colunas) para métricas principais
- [ ] Seção "Próximos check-ins" com lista de até 5 itens
- [ ] Seção "Reservas por status" com chips ou mini-barras

### 2. Criar `admin_dashboard_page.dart`
Caminho: `lib/features/profile/presentation/pages/admin_dashboard_page.dart`

#### Métricas do Admin (plataforma global)
- [ ] **Total de usuários** — hóspedes cadastrados
- [ ] **Total de hotéis** — hotéis ativos na plataforma
- [ ] **Reservas hoje** — total na plataforma
- [ ] **Receita da plataforma no mês** — soma global
- [ ] **Hotéis com maior ocupação** — top 3 (nome + percentual)
- [ ] **Reservas por status** — visão global (mesmos status do Host)
- [ ] **Novos cadastros** — usuários e hotéis criados nos últimos 7 dias

#### Layout sugerido
- [ ] Mesmo padrão visual do `HostDashboardPage` para consistência
- [ ] Grid de `MetricCard` (2 colunas) para métricas principais
- [ ] Seção "Top Hotéis" com lista de cards compactos
- [ ] Seção "Novos cadastros" com contadores

### 3. Widget compartilhado `MetricCard`
Caminho: `lib/features/profile/presentation/widgets/metric_card.dart`
- [ ] Recebe: `title`, `value`, `icon`, `color` (opcional)
- [ ] Usado em ambos os dashboards

### 4. Atualizar rotas no `app_router.dart`
- [ ] Substituir stub `/host/dashboard` por `HostDashboardPage`
- [ ] Substituir stub `/admin/dashboard` por `AdminDashboardPage`

### 5. Integração com backend
- [ ] `GET /host/dashboard` (ou endpoints individuais) — métricas do hotel autenticado
- [ ] `GET /admin/dashboard` (ou endpoints individuais) — métricas globais
- [ ] Se endpoints não estiverem prontos: usar dados mock para a demonstração

### 6. Validação
- [ ] Métricas carregam sem erro (loading state tratado)
- [ ] Estado vazio tratado (ex: hotel sem reservas)
- [ ] Dark Mode aplicado
- [ ] Responsivo em web e tablet (cards se reorganizam em coluna única no mobile)

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `lib/features/profile/presentation/pages/host_dashboard_page.dart` | **Criar** |
| `lib/features/profile/presentation/pages/admin_dashboard_page.dart` | **Criar** |
| `lib/features/profile/presentation/widgets/metric_card.dart` | **Criar** |
| `lib/core/router/app_router.dart` | Substituir stubs pelos widgets reais |

---

## Dependências
- **Pode usar mock** se endpoints de métricas não estiverem implementados no backend
- **P6-A (Dark Mode)** — aplicar tokens semânticos ao criar os widgets novos
- **P6-B (Responsividade)** — `MetricCard` deve adaptar grid para `crossAxisCount` responsivo
