# Seeds

Seeds populam o banco com dados de desenvolvimento e teste. Nunca executar em produção — todos os arquivos possuem guard `NODE_ENV !== 'production'`.

---

## Scripts disponíveis

```bash
# Executa todos os seeds na ordem correta
npm run db:seed

# Seeds individuais
npm run db:seed:hotels        # Hotéis, categorias, quartos, comodidades, avaliações
npm run db:seed:recommended   # Quartos recomendados (requer hotéis criados)

# Limpa todo o banco (schemas de tenants + tabelas master)
npm run db:reset
```

### Fluxo completo do zero

```bash
npm run db:reset && npm run db:seed
```

---

## Ordem de execução

Os seeds têm dependências entre si e devem ser executados nesta ordem:

| Ordem | Script             | Arquivo                        | Depende de |
|-------|--------------------|--------------------------------|------------|
| 1     | `db:seed:hotels`   | `seed.hotels.ts`               | —          |
| 2     | `db:seed:recommended` | `seed.recommendedRooms.ts`  | `hotels`   |

O comando `npm run db:seed` (via `index.ts`) já respeita essa ordem automaticamente.

---

## Convenção de nomes

```
seed.{domínio}.ts
```

Exemplos válidos: `seed.hotels.ts`, `seed.users.ts`, `seed.promotions.ts`

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

Abra `src/database/seeds/index.ts` e adicione uma entrada em `SEEDS` respeitando a ordem de dependência:

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
- **Usuário de seed:** para avaliações e reservas de teste, reutilize o usuário `seed@reservaqui.dev` (criado em `seed.hotels.ts`)
- **Logs:** use o prefixo `[seed/{dominio}]` nos logs para facilitar rastreamento
- **Sem auto-execução ao importar:** exporte a função principal e proteja a chamada com `if (require.main === module)`
