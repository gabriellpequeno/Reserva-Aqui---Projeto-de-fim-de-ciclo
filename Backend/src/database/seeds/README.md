# Seeds

Seeds populam o banco com dados de desenvolvimento e teste. Nunca executar em produção — todos os arquivos possuem guard `NODE_ENV !== 'production'`.

---

## Seeds disponíveis

| Script npm | Arquivo | O que cria |
|---|---|---|
| `db:seed` | `index.ts` | Executa todos os seeds na ordem correta |
| `db:seed:hotels` | `seed.hotels.ts` | Hotéis, categorias, quartos, comodidades, avaliações |
| `db:seed:recommended` | `seed.recommendedRooms.ts` | Quartos recomendados (requer hotéis criados) |
| `db:seed:my-rooms` | `seed.my-rooms-page.ts` | Hotel dedicado a cenários de teste da my-rooms-page |
| `db:seed:reservas` | `seed.reservas.ts` | ~15 reservas por hotel distribuídas para popular dashboards |
| `db:seed:push` | `seed.push-fcm.ts` | Hotel + hóspede de teste para validar pipeline de push notification FCM |
| `db:seed:catalogo` | `seed.catalogo-default.ts` | Catálogo padrão de comodidades em todos os schemas de tenant |
| *(sem script individual)* | `seed.admin.ts` | Admin inicial da plataforma |
| `db:seed:completo` | `seed.completo.ts` | 1 admin + 6 usuários + 5 hotéis completos com quartos, fotos e avaliações |

---

## Rodando localmente (sem Docker)

```bash
# Todos os seeds de uma vez
npm run db:seed

# Seeds individuais
npm run db:seed:hotels
npm run db:seed:recommended
npm run db:seed:my-rooms
npm run db:seed:reservas
npm run db:seed:push
npm run db:seed:catalogo
npm run db:seed:completo

# Fluxo completo do zero
npm run db:reset && npm run db:seed
```

---

## Rodando dentro do Docker

O container da API se chama `reservaqui-api`. Use `docker exec` para rodar os seeds sem precisar sair do contêiner:

```bash
# Todos os seeds
docker exec reservaqui-api npm run db:seed

# Seeds individuais
docker exec reservaqui-api npm run db:seed:hotels
docker exec reservaqui-api npm run db:seed:recommended
docker exec reservaqui-api npm run db:seed:my-rooms
docker exec reservaqui-api npm run db:seed:reservas
docker exec reservaqui-api npm run db:seed:push
docker exec reservaqui-api npm run db:seed:catalogo
docker exec reservaqui-api npm run db:seed:completo

# Fluxo completo do zero (dentro do Docker)
docker exec reservaqui-api npm run db:reset && docker exec reservaqui-api npm run db:seed
```

> **Atenção:** certifique-se de que o container `reservaqui-db` já está saudável antes de rodar os seeds. Você pode verificar com `docker ps` — a coluna STATUS deve mostrar `(healthy)`.

---

## Ordem de execução

Os seeds têm dependências entre si. O `index.ts` já respeita essa ordem automaticamente:

| Ordem | Nome | Arquivo | Depende de |
|---|---|---|---|
| 1 | `admin` | `seed.admin.ts` | — |
| 2 | `hotels` | `seed.hotels.ts` | `admin` |
| 3 | `recommendedRooms` | `seed.recommendedRooms.ts` | `hotels` |
| 4 | `myRoomsPage` | `seed.my-rooms-page.ts` | `hotels` |
| 5 | `reservas` | `seed.reservas.ts` | `hotels` |
| 6 | `pushFcm` | `seed.push-fcm.ts` | `hotels` |
| 7 | `completo` | `seed.completo.ts` | `admin`, `hotels` |

---

## Como criar um novo seed

### 1. Crie o arquivo

```ts
// src/database/seeds/seed.{dominio}.ts

import 'dotenv/config';
import { masterPool } from '../masterDb';

if (process.env.NODE_ENV === 'production') {
  console.log('[seed/{dominio}] Seed ignorado em produção');
  process.exit(0);
}

export async function seed{Dominio}(): Promise<void> {
  console.log('--- Iniciando Seed {Dominio} ---');

  // ... lógica do seed ...

  console.log('--- Seed {Dominio} Finalizado ---');
}

// Auto-execução apenas quando rodado diretamente
if (require.main === module) {
  seed{Dominio}()
    .catch((err) => {
      console.error('[seed/{dominio}] Erro fatal:', err);
      process.exit(1);
    })
    .finally(() => masterPool.end());
}
```

### 2. Registre no orquestrador

Abra `index.ts` e adicione uma entrada no array `SEEDS` respeitando a ordem de dependência:

```ts
{
  name: '{dominio}',
  run: async () => {
    const { seed{Dominio} } = await import('./seed.{dominio}');
    await seed{Dominio}();
  },
},
```

### 3. Adicione o script no `package.json`

```json
"db:seed:{dominio}": "ts-node --transpile-only src/database/seeds/seed.{dominio}.ts"
```

---

## Boas práticas

- **Idempotência:** use `ON CONFLICT DO NOTHING` ou `ON CONFLICT DO UPDATE` para que o seed possa ser re-executado sem erros
- **Guard de produção:** sempre inclua o bloco `if (process.env.NODE_ENV === 'production')` no topo
- **Usuário de seed:** para avaliações e reservas de teste, reutilize um usuário de teste criado pelos seeds anteriores (ex: criado em `seed.hotels.ts`)
- **Logs:** use o prefixo `[seed/{dominio}]` nos logs para facilitar rastreamento
- **Sem auto-execução ao importar:** exporte a função principal e proteja a chamada com `if (require.main === module)`
