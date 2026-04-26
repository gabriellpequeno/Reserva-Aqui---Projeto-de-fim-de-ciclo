# Plan — Search Room Endpoint (EXT-1)

> Derivado de: `conductor/specs/search-room-endpoint.spec.md`
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [EM ANDAMENTO]

> Sem novas dependências npm. Apenas habilitação da extensão `unaccent` no Postgres master.

- [x] **Modificar** `Backend/database/scripts/init_master.sql` — adicionar `CREATE EXTENSION IF NOT EXISTS unaccent;` (idempotente)
- [ ] Validar que a extensão foi criada na master DB local (`docker-compose up --build` + `\dx` no psql)
- [ ] Atualizar README de setup do backend mencionando dependência de `unaccent`

---

## Backend [EM ANDAMENTO]

### 1. Reuso da query de quartos

- [x] **Modificar** `Backend/src/services/quarto.service.ts` — promover `SELECT_QUARTO_COM_ITENS` (linhas 58-81) de `const` privada para `export const`, permitindo reuso em `searchRoom.service.ts` sem duplicar SQL

### 2. Service

- [x] **Criar** `Backend/src/services/searchRoom.service.ts`
  - Helper `escapeLikePattern(q: string)` — escapa `\`, `%`, `_` em userland antes de compor o pattern `%q%`
  - Query master em `anfitriao` com `unaccent(coluna) ILIKE unaccent($1)` sobre `nome_hotel`, `cidade`, `uf`; filtro `ativo = TRUE`; ordenação por relevância via `CASE` (exact > prefix > contains); `LIMIT 20`
  - Fan-out com `Promise.all` sobre `withTenant(schema_name, ...)` reutilizando `SELECT_QUARTO_COM_ITENS` com `WHERE q.deleted_at IS NULL`
  - `try/catch` individual por tenant — erro de um hotel é logado como `warn` e não derruba a busca
  - Enrich em memória com `nome_hotel`, `cidade`, `uf` do mapa de hotéis (master)
  - Expor `searchRooms(q: string, refinos?: { checkin?, checkout?, hospedes? }): Promise<SearchRoomResult[]>` — refinos são aceitos e ignorados nesta versão
  - Log estruturado com `tempo_total_ms` e `hoteis_iterados`

### 3. Controller

- [x] **Criar** `Backend/src/controllers/searchRoom.controller.ts`
  - Valida `q` obrigatório → `400 { error: "Parâmetro q é obrigatório" }`
  - Valida `q` com mínimo 2 caracteres após `trim()` → `400 { error: "Parâmetro q deve ter no mínimo 2 caracteres" }`
  - Repassa `checkin`, `checkout`, `hospedes` como refinos opcionais para o service
  - `try/catch` → `500 { error: "Erro interno" }` em caso de falha inesperada

### 4. Routes

- [x] **Criar** `Backend/src/routes/searchRoom.routes.ts` — registra `GET /busca` público, sem `hotelGuard` nem middleware de auth
- [x] **Modificar** `Backend/src/app.ts` — registrar `app.use(\`${API_PREFIX}/quartos\`, searchRoomRoutes)` em namespace público separado de `/api/hotel`

### 5. Documentação da API

- [x] **Modificar** `Backend/swagger.yaml` — documentar `GET /quartos/busca` com query params (`q`, `checkin?`, `checkout?`, `hospedes?`), response schema `SearchRoomResult[]` e erros `400`/`500`. Anotar explicitamente que `rating` **não** faz parte do payload desta versão (fica para EXT-2)

### 6. Testes

- [x] **Criar** `Backend/src/services/__tests__/searchRoom.service.test.ts`
  - Escape de wildcards: `q="50%"` trata `%` como literal
  - Acento-insensitive: `q="São Paulo"` casa hotel cadastrado como `"Sao Paulo"`
  - Filtro `ativo = FALSE` na master exclui hotéis inativos
  - Filtro `deleted_at IS NOT NULL` exclui quartos deletados
  - Fan-out paralelo sobre múltiplos tenants (mock de `withTenant`)
  - Tenant que lança erro não derruba os outros — resultado omite o hotel com falha
- [x] **Criar** `Backend/src/routes/__tests__/searchRoom.routes.test.ts`
  - `400` para `q` ausente
  - `400` para `q` com menos de 2 chars após trim
  - `200 []` quando nenhum hotel casa
  - `200` com payload esperado contendo `quarto_id`, `hotel_id`, `nome_hotel`, `cidade`, `uf`, `valor_diaria`, `descricao`, `itens[]`

---

## Frontend [N/A]

> Spec backend-only. A integração da tela de busca é entregue pela feature P4-B (`search-page-integration`), com plan próprio.

---

## Validação [PENDENTE]

- [ ] `npm run lint` sem erros no backend
- [ ] `npm test` passa com todos os testes novos verdes
- [ ] **AC1 — Busca por cidade:** `GET /api/quartos/busca?q=salvador` retorna `200` com array de quartos contendo todos os campos esperados
- [ ] **AC2 — `q` ausente:** `GET /api/quartos/busca` retorna `400` com mensagem `"Parâmetro q é obrigatório"`
- [ ] **AC3 — Acento-insensitive:** `q="São Paulo"` e `q="Sao Paulo"` retornam o mesmo conjunto de hotéis
- [ ] **AC4 — Wildcard injection:** `q="%"` e `q="_"` são tratados como literais e não retornam matches espúrios
- [ ] **AC5 — Hotel inativo:** hotel com `ativo = FALSE` não aparece mesmo quando `nome_hotel` casa
- [ ] **AC6 — Quarto deletado:** quarto com `deleted_at IS NOT NULL` é excluído do resultado
- [ ] **AC7 — Fan-out paralelo:** busca que casa 15 hotéis dispara 15 `withTenant` em paralelo (confirmar via log `hoteis_iterados=15` e `tempo_total_ms` aceitável)
- [ ] **AC8 — Lista vazia:** busca que não casa nenhum hotel retorna `200 []`
- [ ] **RNF — Performance:** p95 abaixo de 500ms para `q` casando até 20 hotéis (medir manualmente via log `tempo_total_ms`)
- [ ] **Observabilidade:** logs de busca contêm `tempo_total_ms` e `hoteis_iterados`

---

## Regra de Atualização de Status

- Todas `[ ]` → `[PENDENTE]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`

Quando todas as seções estiverem `[CONCLUÍDO]`, atualizar o **Status geral** para `[CONCLUÍDO]`
e sincronizar com `conductor/plan.md`:
- Localizar o bloco correspondente à feature EXT-1 (ou criar nova fase ao final se não existir)
- Atualizar o header para `[CONCLUÍDO]` e marcar todas as tasks como `[x]`
