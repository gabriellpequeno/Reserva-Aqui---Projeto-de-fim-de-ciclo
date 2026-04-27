# Spec — Search Room Endpoint (EXT-1)

## Referência
- **PRD:** `conductor/features/search-room-endpoint.prd.md`

## Abordagem Técnica

Criar uma rota pública `GET /api/quartos/busca` **fora** do módulo `quartoRoutes` atual (que vive sob `/api/hotel` com `hotelGuard`). Implementar em 3 arquivos dedicados (`searchRoom.routes.ts`, `searchRoom.controller.ts`, `searchRoom.service.ts`), seguindo o padrão existente (Routes → Controller → Service).

O service executa em duas etapas:

1. **Descoberta na master DB** — query única em `anfitriao` com `unaccent(coluna) ILIKE unaccent($1)` sobre `nome_hotel`, `cidade`, `uf`; filtra `ativo = TRUE`; escapa wildcards `%`, `_`, `\` do `q` em userland antes de montar o padrão; ordena por relevância (exact > prefix > contains via `CASE`); `LIMIT 20`.
2. **Fan-out nos tenants** — `Promise.all` iterando `withTenant(schema_name, ...)` para cada hotel encontrado, executando a query `SELECT_QUARTO_COM_ITENS` (reaproveitada de `quarto.service.ts`) com `WHERE q.deleted_at IS NULL`. Cada `withTenant` é envolto em `try/catch` individual — falha de um tenant não derruba a busca inteira. Flatten do array de arrays + enrich em memória com `nome_hotel`, `cidade`, `uf` do mapa de hotéis.

Habilitar extensão `unaccent` na master DB via script de init (idempotente). Logs estruturados com `tempo_total_ms` e `hoteis_iterados` para observabilidade.

## Componentes Afetados

### Backend

- **Novo:** `searchRoom.service.ts` (`Backend/src/services/searchRoom.service.ts`) — orquestra master query + fan-out de tenants; expõe `searchRooms(q, refinos)`.
- **Novo:** `searchRoom.controller.ts` (`Backend/src/controllers/searchRoom.controller.ts`) — valida query string, chama service, trata erros em `400`/`200`.
- **Novo:** `searchRoom.routes.ts` (`Backend/src/routes/searchRoom.routes.ts`) — registra `GET /busca` público, sem middlewares de auth.
- **Modificado:** `Backend/src/app.ts` — adicionar `app.use(\`${API_PREFIX}/quartos\`, searchRoomRoutes)` (novo namespace público, separado de `/api/hotel`).
- **Modificado:** `Backend/src/services/quarto.service.ts` — **exportar** `SELECT_QUARTO_COM_ITENS` (hoje é const privada, linhas 58-81) para reuso.
- **Modificado:** `Backend/database/scripts/init_master.sql` — adicionar `CREATE EXTENSION IF NOT EXISTS unaccent;` (idempotente).
- **Modificado:** `Backend/swagger.yaml` — documentar `GET /quartos/busca` com parâmetros e response schema.
- **Novo:** `Backend/src/services/__tests__/searchRoom.service.test.ts` — cobre escape de wildcards, acento-insensitive, filtro `ativo`, `deleted_at`, fan-out paralelo, tenant com erro não derruba os outros.
- **Novo:** `Backend/src/routes/__tests__/searchRoom.routes.test.ts` — cobre `400` para `q` ausente, `400` para `q` com menos de 2 chars, `200 []` para sem match, `200` com payload esperado.

### Frontend

- **N/A** — esta spec é backend-only. O consumo é feito pela feature P4-B (`search-page-integration`), com spec própria.

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|---------------|
| Controller e service dedicados em vez de estender `quarto.service.ts` | Semântica distinta: rota pública, cross-tenant, sem `hotel_id` do JWT. Evita poluir a service de gerenciamento interno com lógica de descoberta. |
| Exportar `SELECT_QUARTO_COM_ITENS` de `quarto.service.ts` em vez de duplicar o SQL | Reaproveita agregação de itens + `COALESCE(valor_override, preco_base)` já testada. Reduz risco de divergência. |
| Rota em `/api/quartos` (não `/api/hotel/quartos`) | `/api/hotel` é o namespace do anfitrião autenticado. Rota pública merece namespace próprio — consistente com `/api/reservas` (público) vs `/api/hotel/reservas` em `app.ts:43-45`. |
| `unaccent(coluna) ILIKE unaccent($1)` em vez de `pg_trgm` | Atende o requisito acento-insensitive com uma extensão leve, nativa do Postgres. `pg_trgm` fica como dívida técnica. |
| Escape de wildcards em userland (não via função SQL) | Simples, testável por unit test, alinhado com parametrização `$1`. |
| Ordenação por `CASE` (exact > prefix > contains) | Relevância razoável sem depender de `similarity()` do `pg_trgm`. |
| `Promise.all` sobre `withTenant` sem pool dedicado | 20 tenants máximo; o `masterPool` atual suporta. Monitorar via logs. |
| `try/catch` individual por tenant | Tenant com schema inconsistente (ex: recém-criado durante a query) não derruba a busca; erro é logado e o hotel é omitido. |
| Não filtrar `quarto.disponivel` | `disponivel` reflete ocupação atual; filtrar esconderia quartos ocupados de buscas futuras — contra o escopo "disponibilidade é refino, não filtro" do PRD. |
| `q` mínimo de 2 caracteres após trim | Mitiga busca com padrão `%%` ou string única sem semântica; controller valida antes de ir ao service. |
| Params `checkin`/`checkout`/`hospedes` são aceitos e ignorados nesta versão | PRD explicita "fora de escopo"; aceitar sem erro mantém contrato estável para quando o refino real for implementado. |

## Contratos de API

| Método | Rota | Query Params | Response |
|--------|------|--------------|----------|
| GET | `/api/quartos/busca` | `q` (string, obrigatório, min 2 chars); `checkin?` (ISO date); `checkout?` (ISO date); `hospedes?` (int ≥ 1) | `200` → `SearchRoomResult[]` · `400` → `{ error: "Parâmetro q é obrigatório" }` ou `{ error: "Parâmetro q deve ter no mínimo 2 caracteres" }` · `500` → `{ error: "Erro interno" }` |

Body: nenhum (GET). Auth: nenhuma (rota pública).

## Modelos de Dados

**Nenhuma tabela nova. Sem migration de schema.**

Alteração no bootstrap da master:

```sql
-- Backend/database/scripts/init_master.sql
CREATE EXTENSION IF NOT EXISTS unaccent;
```

Shape do payload de resposta (TypeScript):

```
SearchRoomResult {
  quarto_id:    number
  hotel_id:     string  // uuid
  numero:       string
  descricao:    string | null
  valor_diaria: string  // numeric do Postgres — cliente faz parse
  itens:        QuartoItem[]
  nome_hotel:   string
  cidade:       string
  uf:           string  // 2 chars
}

QuartoItem {
  catalogo_id: number
  nome:        string
  categoria:   string
  quantidade:  number
}
```

Tipo interno de suporte (no service):

```
HotelMatch {
  hotel_id:    string
  nome_hotel:  string
  cidade:      string
  uf:          string
  schema_name: string
}
```

Dívida técnica documentada (fora de escopo desta entrega):

```sql
-- Quando o volume exigir: pg_trgm + GIN
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_anfitriao_nome_hotel_trgm
  ON anfitriao USING GIN (unaccent(nome_hotel) gin_trgm_ops);
CREATE INDEX idx_anfitriao_cidade_trgm
  ON anfitriao USING GIN (unaccent(cidade) gin_trgm_ops);
```

## Dependências

**Bibliotecas:**
- [x] `express` — já presente
- [x] `pg` — já presente (driver Postgres, `masterPool`)
- [ ] **Nenhuma nova dependência npm**

**Serviços externos:**
- [ ] Postgres com extensão `unaccent` habilitada (built-in no Postgres; requer `CREATE EXTENSION` uma vez)

**Outras features:**
- [x] Arquitetura multi-tenant já em produção (`Backend/src/database/schemaWrapper.ts`, `Backend/src/database/tenantManager.ts`) — reutilizada
- [x] Tabela `anfitriao` na master e `quarto`/`categoria_quarto`/`catalogo`/`itens_do_quarto` nos tenants — já existem
- [ ] Nenhuma feature interna bloqueante — é folha

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Extensão `unaccent` não habilitada no ambiente | Incluir `CREATE EXTENSION IF NOT EXISTS unaccent` em `Backend/database/scripts/init_master.sql` (idempotente); documentar no README de setup. Teste de integração valida. |
| Fan-out esgotando `masterPool` | Limite de 20 hotéis/query; `Promise.all` único sem recursão. Observabilidade: log `hoteis_iterados` + `tempo_total_ms` para diagnosticar contenção. Ajustar `masterPool.max` se métrica indicar. |
| Tenant com schema inconsistente (ex: recém-provisionado, migration pendente) | `try/catch` individual por `withTenant` no service — erro é logado como `warn`, o hotel é omitido do resultado, busca continua. |
| `ILIKE '%q%'` lento sob escala | Dívida técnica registrada: migrar para `pg_trgm` + GIN. Monitorar p95 via logs; acionar migração quando ultrapassar o limite de 500ms do RNF. |
| **Wildcard injection** via `%` ou `_` no `q` | Escape de `\`, `%`, `_` em helper dedicado antes de compor o padrão (`'%' + escaped + '%'`). Cobertura obrigatória em teste unitário do service. |
| **SQL injection** via `q` | Parametrização via `$1` — nunca interpolar em template literal. Lint rule / code review. |
| Race entre master read e tenant read (hotel desativado no meio) | Aceitável — tenant devolve `[]` ou erro capturado pelo `try/catch`. `ativo = TRUE` no master já é o gate primário. |
| Tenant com centenas de quartos infla payload | Dívida: 20 × ~50 quartos = 1000 linhas (aceitável). Caso apareça hotel com 500+ quartos, avaliar `LIMIT` por tenant. |
| Rota pública sujeita a DoS por `q` curto/genérico | Mitigação dupla: `q` mínimo 2 chars + limite rígido de 20 hotéis por query. Rate limiting global é desejável mas fica fora do escopo (middleware cross-cutting). |
| `rating` ausente no response quebra consumer | Documentar no swagger que `rating` **não** faz parte do payload desta versão (vem na EXT-2). Frontend já tem mitigação na spec P4-B. |
| Resposta sem paginação cresce demais | Limite hard-coded de 20 hotéis + teto implícito de quartos por hotel. Scroll infinito fica para iteração futura. |
