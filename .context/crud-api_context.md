# Context: CRUD API

> Last updated: 2026-04-15T01:00:00Z
> Version: 2

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
