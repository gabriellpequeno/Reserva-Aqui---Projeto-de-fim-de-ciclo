# Context: CRUD API

> Last updated: 2026-04-15T08:00:00Z
> Version: 8

## Purpose
Rastreamento das implementações de CRUD realizadas no backend ReservAqui via skill `crud-api`.

## Architecture / How It Works
- Camadas: Entity (validação pura) → Service (lógica + DB) → Controller (HTTP) → Routes (middleware chain)
- DB master: `masterPool` para tabelas globais (`anfitriao`, `usuario`, etc.)
- DB tenant: `withTenant(schemaName, client => ...)` para tabelas por hotel
- Auth: `authGuard` (usuário hóspede) | `hotelGuard` (hotel anfitrião)
- Pattern de service: funções exportadas são wrappers que chamam `_privateFunction()` com a lógica real
- Helper interno `_getSchemaName(hotelId)` centraliza o lookup de `schema_name` no master DB
- Soft delete: `UPDATE SET deleted_at = NOW()` + filtros `WHERE deleted_at IS NULL`

## Affected Project Files

| File | Uses this system? | Relationship |
|------|:-----------------:|--------------|
| `Backend/src/app.ts` | Yes | Registra `catalogoRoutes` em `/api/hotel` |
| `Backend/src/routes/catalogo.routes.ts` | Yes | Define endpoints e middleware chain |
| `Backend/src/controllers/catalogo.controller.ts` | Yes | Handlers HTTP → service calls |
| `Backend/src/services/catalogo.service.ts` | Yes | Lógica de negócio + queries tenant |
| `Backend/src/entities/Catalogo.ts` | Yes | Validação pura de input |
| `Backend/database/scripts/init_tenant.sql` | Read-only | Schema da tabela `catalogo` |
| `Backend/src/entities/HotelFavorito.ts` | Yes | Validação de hotel_id (UUID) |
| `Backend/src/services/favorito.service.ts` | Yes | Lógica de favoritos no master DB |
| `Backend/src/controllers/favorito.controller.ts` | Yes | Handlers HTTP → service calls |
| `Backend/src/routes/usuario.routes.ts` | Yes | Rotas de favoritos adicionadas |
| `Backend/src/entities/ConfiguracaoHotel.ts` | Yes | Validação pura (TIME format, int > 0, boolean) |
| `Backend/src/services/configuracao.service.ts` | Yes | Lógica de configuração no tenant DB |
| `Backend/src/controllers/configuracao.controller.ts` | Yes | Handlers HTTP → service calls |
| `Backend/src/routes/configuracao.routes.ts` | Yes | GET público + POST/PATCH com hotelGuard |
| `Backend/src/entities/CategoriaQuarto.ts` | Yes | Valida nome, preco_base, capacidade_pessoas e itens |
| `Backend/src/services/categoriaQuarto.service.ts` | Yes | CRUD de categoria + gestão de categoria_item |
| `Backend/src/controllers/categoriaQuarto.controller.ts` | Yes | Handlers para categoria e sub-recurso itens |
| `Backend/src/routes/categoriaQuarto.routes.ts` | Yes | GET público + escrita com hotelGuard, sub-rotas de itens |
| `Backend/src/entities/Quarto.ts` | Yes | Valida numero, categoria_quarto_id, valor_override, itens inline |
| `Backend/src/services/quarto.service.ts` | Yes | CRUD + _syncItens + setQuartoDisponivel para uso interno |
| `Backend/src/controllers/quarto.controller.ts` | Yes | Handlers HTTP → service calls |
| `Backend/src/routes/quarto.routes.ts` | Yes | Todos os endpoints com hotelGuard |
| `Backend/src/entities/Reserva.ts` | Yes | Validação de criação (usuário e walk-in), status e atribuição de quarto |
| `Backend/src/services/reserva.service.ts` | Yes | CRUD de reserva + side effects (hospede, reserva_routing, historico_reserva_global, setQuartoDisponivel) |
| `Backend/src/controllers/reserva.controller.ts` | Yes | 11 handlers HTTP para hotel, usuário e público |
| `Backend/src/routes/reserva.routes.ts` | Yes | 3 routers: hotelReservaRouter, usuarioReservaRouter, publicReservaRouter |
| `Backend/src/entities/Avaliacao.ts` | Yes | Valida 5 notas (1-5), comentário, partial update; calcularTotal() estático |
| `Backend/src/services/avaliacao.service.ts` | Yes | Criar, editar (merge + recalculo nota_total), listar por hotel |
| `Backend/src/controllers/avaliacao.controller.ts` | Yes | 3 handlers: criar, editar, listar |
| `Backend/src/routes/avaliacao.routes.ts` | Yes | usuarioAvaliacaoRouter + publicAvaliacaoRouter (mergeParams) |

## Code Reference

### `Backend/src/services/catalogo.service.ts` — `_getSchemaName(hotelId)`

```typescript
async function _getSchemaName(hotelId: string): Promise<string> {
  const { rows } = await masterPool.query<{ schema_name: string }>(
    `SELECT schema_name FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  if (!rows[0]) throw new Error('Hotel não encontrado');
  return rows[0].schema_name;
}
```

**How it works:** Toda função privada de catalogo chama este helper antes de usar `withTenant`. Evita duplicação do lookup em cada operação.
**Coupling / side-effects:** Depende do master DB. Se o hotel estiver inativo (`ativo = FALSE`), lança 404.

### `Backend/src/services/catalogo.service.ts` — `_deleteCatalogo(hotelId, catalogoId)`

```typescript
async function _deleteCatalogo(hotelId: string, catalogoId: number): Promise<void> {
  const schemaName = await _getSchemaName(hotelId);
  await withTenant(schemaName, async (client) => {
    const { rowCount } = await client.query(
      `UPDATE catalogo SET deleted_at = NOW() WHERE id = $1 AND deleted_at IS NULL`,
      [catalogoId],
    );
    if (!rowCount) throw new Error('Item do catálogo não encontrado');
  });
}
```

**How it works:** Soft delete sempre — mesmo se o item está referenciado em `categoria_item` ou `itens_do_quarto`. O registro físico permanece (integridade referencial preservada pela constraint ON DELETE RESTRICT).
**Coupling / side-effects:** Itens deletados ficam ocultos nas listagens mas continuam existindo nas tabelas de relacionamento. Queries de `categoria_item` e `itens_do_quarto` precisam fazer JOIN com `catalogo WHERE deleted_at IS NULL` para filtrar itens removidos.

## Key Design Decisions

- **Soft delete sempre (mesmo se referenciado):** Comportamento escolhido pelo usuário. A unique constraint `(nome, categoria)` só verifica `deleted_at IS NULL`, então um nome pode ser reutilizado após soft delete.
- **Categoria imutável após criação:** Apenas `nome` é editável via PATCH. Mudança de categoria quebraria a semântica dos itens já associados a quartos.
- **Listagem pública por `hotel_id` nos params:** `GET /api/hotel/:hotel_id/catalogo` não requer auth — app do hóspede pode exibir comodidades do hotel sem login.
- **Helper `_getSchemaName`:** Centraliza o lookup de `schema_name` no master DB para evitar repetição nas 4 funções privadas.
- **`validate` aceita `unknown`:** Entity methods aceitam `unknown` e fazem cast interno, permitindo chamar tanto com `req.body` (any) quanto com tipos já estruturados.

## Changelog

### v7 — 2026-04-15
- CRUD de `avaliacao` implementado (tenant DB via reserva_routing)
- 3 endpoints: `POST /api/usuarios/avaliacoes`, `PATCH /api/usuarios/avaliacoes/:codigo_publico`, `GET /api/hotel/:hotel_id/avaliacoes` (público)
- `nota_total` calculado automaticamente via `Avaliacao.calcularTotal()` — nunca recebido no body
- PATCH parcial: mescla valores enviados com valores atuais do banco antes de recalcular total
- Roteamento via `codigo_publico` → `reserva_routing` → tenant (mesmo padrão do cancelamento)
- Walk-ins (user_id = null) bloqueados por verificação de ownership da reserva
- TypeScript compilando sem erros

### v6 — 2026-04-15
- CRUD de `reserva` implementado (tenant DB + side effects no master)
- 11 endpoints: 7 hotelGuard (`/api/hotel/reservas`), 3 authGuard (`/api/usuarios/reservas`), 1 público (`/api/reservas/:codigo_publico`)
- Walk-in criado como `APROVADA`; usuário como `SOLICITADA`
- Checkin/checkout físicos: `PATCH /:id/checkin` e `PATCH /:id/checkout` (checkout → status CONCLUIDA)
- Side effects automáticos: `hospede` (ensure first reservation), `reserva_routing` (routing público), `historico_reserva_global` (UPSERT em criação e mudança de status), `setQuartoDisponivel` (aprovação/cancelamento/checkout)
- `listReservasUsuario` lê de `historico_reserva_global` (master) — não itera tenants
- `cancelarReservaUsuario` usa `codigo_publico` para lookup via `reserva_routing`
- `HistoricoReservaSafe` exportado como tipo separado (diferente de `ReservaSafe`)
- TypeScript compilando sem erros

### v5 — 2026-04-15
- CRUD de `quarto` implementado (tenant DB, todos os endpoints com hotelGuard)
- Itens inline: POST/PATCH aceitam array `itens[]`; PATCH com itens substitui todos (_syncItens)
- `setQuartoDisponivel(hotelId, quartoId, disponivel)` exportado para uso interno pelo service de reservas
- `valor_override: null` no PATCH remove o override do preço
- Soft delete: cascade em itens_do_quarto e quarto_foto pelo DB
- TypeScript compilando sem erros

### v4 — 2026-04-15
- CRUD de `categoria_quarto` + gestão de `categoria_item` implementados (tenant DB)
- Endpoints em `/api/hotel`: GET público por `:hotel_id`, POST/PATCH/DELETE com hotelGuard
- Sub-rotas de itens: `POST /categorias/:id/itens`, `DELETE /categorias/:id/itens/:catalogo_id`
- GET retorna itens agregados em JSON (json_agg) — uma única query sem N+1
- DELETE bloqueado com 409 se existirem quartos ativos vinculados
- TypeScript compilando sem erros

### v3 — 2026-04-15
- CRUD de `configuracao_hotel` implementado (tenant DB, 1 row por hotel)
- Endpoints em `/api/hotel`: `GET /:hotel_id/configuracao` (público), `POST /configuracao`, `PATCH /configuracao` (hotelGuard)
- `telefone_recepcao` omitido intencionalmente da API (campo existe no DB mas não exposto)
- POST insere com defaults da aplicação para campos não informados (matching DB defaults)
- PATCH dinâmico — só atualiza campos presentes no body; `politica_cancelamento` aceita `null` explícito
- TypeScript compilando sem erros

### v2 — 2026-04-15
- CRUD de `hotel_favorito` implementado (Master DB, sem tenant)
- Endpoints em `/api/usuarios`: `GET /favoritos`, `POST /favoritos`, `DELETE /favoritos/:hotel_id`
- Listagem faz JOIN com `anfitriao` retornando dados completos do hotel
- Validação de UUID no entity, verificação de hotel ativo no service
- TypeScript compilando sem erros

### v1 — 2026-04-15
- CRUD completo de `catalogo` implementado (Entity + Service + Controller + Routes)
- Endpoints: `GET /:hotel_id/catalogo` (público), `POST /catalogo`, `PATCH /catalogo/:id`, `DELETE /catalogo/:id` (todos em `/api/hotel`)
- Soft delete, validação de categoria imutável, unique check por `(nome, categoria)`
- TypeScript compilando sem erros (`tsc --noEmit`)
