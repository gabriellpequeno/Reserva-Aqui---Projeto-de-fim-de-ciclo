---
name: crud-api
description: Implementação de CRUD completo para a API do ReservAqui. Especializada na arquitetura do projeto (Entity → Service → Controller → Routes) com multi-tenant PostgreSQL. Use esta skill sempre que precisar criar ou modificar endpoints REST, entidades, rotas, serviços ou controllers no backend — especialmente ao adicionar novos recursos a tabelas do master DB (usuario, anfitriao) ou ao schema tenant (hotel). Aciona automaticamente quando o usuário menciona: "criar endpoint", "novo recurso", "CRUD", "rota", "controller", "service", "adicionar ao backend", "preciso de uma API para", ou quando descreve uma necessidade de negócio que claramente requer novos endpoints ou entidades.
---

# CRUD API — ReservAqui Backend

Especialista em implementar operações CRUD no backend do ReservAqui, aplicando a arquitetura em camadas do projeto, o padrão de funções privadas/públicas dos services, e as regras de segurança e escalabilidade já estabelecidas.

## Context Load (MANDATORY — run this first)

Antes de qualquer análise, pesquisa ou implementação, verifique se existe um arquivo de contexto salvo:

1. Procure `.context/crud-api_context.md` na raiz do projeto.
2. Se o arquivo **existir**: leia-o na íntegra. Use as seções de Arquitetura, Arquivos Afetados, Referências de Código e Decisões de Design para restaurar o contexto de trabalho. Pule qualquer exploração de codebase que já esteja documentada lá. Informe ao usuário:
   > "Contexto restaurado de `.context/crud-api_context.md` (v\<N>, atualizado em \<data>). Continuando da sessão anterior."
3. Se o arquivo **não existir**: prossiga normalmente — explore o codebase, colete contexto e documente ao final via Context Storage.

> **Regra:** Nunca ignore um arquivo de contexto existente. Ele existe exatamente para evitar reanalise. Confie nele e atualize se a implementação mudar.

---

## Fase 0 — Discovery de Negócio (OBRIGATÓRIA antes de qualquer código)

Antes de escrever uma linha de código, conduza estas duas trilhas **em paralelo**. Elas devem ser respondidas antes de avançar.

### Track A — Regras de Negócio

Pergunte ao usuário (ou extraia de `regras de negócio.txt` se existir):

1. **Qual entidade estamos criando/modificando?** (nome, propósito, dono — usuário, hotel ou sistema)
2. **Onde vive no banco?** Master DB (dados globais) ou schema tenant (dados por hotel)?
3. **Quem pode acessar?** Usuário autenticado (`authGuard`), hotel autenticado (`hotelGuard`), público, ou combinação?
4. **Quais operações são necessárias?** Listar, criar, ler por ID, atualizar (parcial/total), deletar (hard/soft)?
5. **Existem restrições de unicidade, ownership ou relacionamento?** (ex: "um usuário só pode ter uma reserva ativa por hotel")
6. **Há regras de validação específicas?** Formatos, limites, campos obrigatórios vs. opcionais.
7. **Existem operações que precisam de rate limiting?** (login, upload, pagamento — ações com risco de abuso)

### Track B — Análise de Schema

Leia os arquivos de schema relevantes:
- `Backend/database/scripts/init_master.sql` — para entidades globais
- `Backend/database/scripts/init_tenant.sql` — para schema por hotel

Identifique e documente:
- **Tabelas envolvidas** e seus campos (tipos, constraints, NOT NULL, UNIQUE, FK)
- **Índices existentes** — especialmente `WHERE deleted_at IS NULL` para soft deletes
- **Relacionamentos** — FKs e comportamento CASCADE vs. RESTRICT
- **Checks e enums** já definidos no banco
- **Campos de auditoria** — `criado_em`, `atualizado_em`, `deleted_at`

Apresente um resumo do schema antes de propor a implementação.

---

## Fase 1 — Proposta de Arquitetura

Após o Discovery, apresente ao usuário um **resumo das decisões** cobrindo:

```
Entidade: [nome]
Banco: [master | tenant: {schema_name}]
Acesso: [público | authGuard | hotelGuard | combinado]
Operações: [GET /... | POST /... | PATCH /... | DELETE /...]
Validações: [campos e regras]
Rate limiting: [sim/não — qual endpoint]
Soft delete: [sim/não]
```

Aguarde aprovação explícita antes de implementar.

---

## Fase 2 — Implementação por Camadas

Implemente sempre na ordem: **Entity → Service → Controller → Routes → app.ts**. Cada camada tem responsabilidade estrita.

### Camada 1 — Entity (Validação Pura)

Arquivo: `Backend/src/entities/[NomeEntidade].ts`

- A Entity é responsável **apenas** por validação de input. Nunca acessa banco de dados.
- Implemente métodos estáticos: `validate()` para criação, `validatePartial()` para updates (todos os campos opcionais), e métodos específicos se necessário (ex: `validateNovaSenha()`).
- Retorne objetos tipados ou lance `Error` com mensagem descritiva em português.
- Defina e exporte as interfaces de input (`RegisterXInput`, `UpdateXInput`) e output seguro (`XSafe` — sem campos sensíveis como senhas ou hashes).

```typescript
// Padrão de Entity
export interface RegisterXInput { /* campos requeridos */ }
export interface UpdateXInput { /* todos opcionais */ }
export interface XSafe { /* campos seguros para retornar ao cliente */ }

export class NomeEntidade {
  static validate(input: unknown): RegisterXInput { /* ... */ }
  static validatePartial(input: unknown): UpdateXInput { /* ... */ }
}
```

### Camada 2 — Service (Lógica de Negócio)

Arquivo: `Backend/src/services/[nomeEntidade].service.ts`

**Regra Fundamental — Wrapper Pattern:**
- Toda função **pública exportada** deve ser um wrapper fino que chama a função privada correspondente.
- A lógica real fica na função privada com prefixo `_` (underscore).
- Nunca exporte diretamente a implementação completa.

```typescript
// ✅ CORRETO — Wrapper Pattern
async function _registerX(input: RegisterXInput): Promise<XSafe> {
  // toda a lógica aqui: validação, query, transformação
}

export async function registerX(input: RegisterXInput): Promise<XSafe> {
  return _registerX(input);
}

// ❌ ERRADO — Não faça isso
export async function registerX(input: RegisterXInput): Promise<XSafe> {
  // lógica direta aqui
}
```

**Por que esse padrão?** Permite adicionar logging, caching, métricas ou decorators no wrapper público sem tocar na lógica de negócio, e facilita mocking em testes.

**Regras do Service:**
- Lance `Error` com mensagens em português claras (ex: `"Email já cadastrado"`, `"Recurso não encontrado"`, `"Credenciais inválidas"`)
- Para master DB: use `pool` diretamente do `database/connection.ts`
- Para tenant DB: use `withTenant(schemaName, async (client) => { ... })` para garantir isolamento de schema
- Nunca retorne campos sensíveis (senhas, hashes, tokens) — use o tipo `XSafe`
- Para soft deletes: use `UPDATE ... SET deleted_at = NOW()` ao invés de DELETE
- Para buscas: sempre filtre `WHERE deleted_at IS NULL` quando a tabela tiver esse campo

### Camada 3 — Controller (HTTP Mapping)

Arquivo: `Backend/src/controllers/[nomeEntidade].controller.ts`

- O controller não contém lógica de negócio — apenas traduz HTTP ↔ Service.
- Implemente `mapError()` para traduzir mensagens de erro do service em status codes adequados.
- Nunca exponha stack traces ou mensagens internas ao cliente.

```typescript
function mapError(message: string): number {
  if (message.includes('já cadastrado') || message.includes('já existe')) return 409;
  if (message.includes('inválid') || message.includes('obrigatório')) return 400;
  if (message.includes('não encontrado')) return 404;
  if (message.includes('Credenciais') || message.includes('não autorizado')) return 401;
  if (message.includes('sem permissão') || message.includes('proibido')) return 403;
  return 500;
}

export async function createXController(req: Request, res: Response): Promise<void> {
  try {
    const input = NomeEntidade.validate(req.body);
    const result = await registerX(input);
    res.status(201).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}
```

**Padrão de resposta:**
- Sucesso criação: `201 { data: {...} }`
- Sucesso leitura/update: `200 { data: {...} }`
- Sucesso sem corpo: `204` (delete)
- Erro: `{ error: "mensagem humana" }` — nunca stack trace

### Camada 4 — Routes (Middleware Chain)

Arquivo: `Backend/src/routes/[nomeEntidade].routes.ts`

- Monte os middlewares na ordem correta: **validação → rate limiting → autenticação → controller**
- Reutilize middlewares existentes sempre que possível.

```typescript
import { Router } from 'express';
import { authGuard } from '../middlewares/authGuard';
import { hotelGuard } from '../middlewares/hotelGuard';
import { requireFields } from '../middlewares/validateBody';
// import { loginRateLimiter } from '../middlewares/rateLimiter'; // apenas em endpoints de login

const router = Router();

// POST /recurso — criação
router.post('/', requireFields(['campo1', 'campo2']), authGuard, createXController);

// GET /recurso/me — leitura própria
router.get('/me', authGuard, getXController);

// PATCH /recurso/me — atualização parcial
router.patch('/me', authGuard, updateXController);

// DELETE /recurso/:id — deleção
router.delete('/:id', authGuard, deleteXController);

export default router;
```

**Decisão de guard:**
- `authGuard` → endpoint para usuários hóspedes (valida `user_id` no token)
- `hotelGuard` → endpoint para hotéis anfitriões (valida `hotel_id` no token, rejeita tokens de usuário)
- Sem guard → endpoint público (ex: busca de disponibilidade)

### Camada 5 — Registro em app.ts

Verifique `Backend/src/app.ts` e adicione a rota se ainda não estiver lá:

```typescript
import xRoutes from './routes/x.routes';
app.use(`${API_PREFIX}/recurso`, xRoutes);
```

---

## Checklist de Segurança (revise antes de concluir)

Antes de entregar a implementação, verifique:

- [ ] **Validação de input** na Entity para todos os campos de entrada
- [ ] **Guard correto** nos endpoints protegidos (authGuard vs. hotelGuard vs. sem guard)
- [ ] **Nenhum campo sensível** retornado (senha, hash, token_hash)
- [ ] **Queries parametrizadas** — nunca interpolação de string em SQL (prevenção de SQL Injection)
- [ ] **Isolamento multi-tenant** — operações tenant sempre dentro de `withTenant()`
- [ ] **Soft delete** respeitado nas buscas (`WHERE deleted_at IS NULL`)
- [ ] **Mensagens de erro genéricas** no controller — nada de stack traces
- [ ] **Rate limiting** em endpoints que podem ser abusados (login, registro, upload)
- [ ] **Ownership validado** — usuário/hotel só acessa seus próprios recursos

---

## Checklist de Escalabilidade

- [ ] Índices adequados para as queries mais frequentes (especialmente filtros por `user_id`, `hotel_id`, `deleted_at`)
- [ ] Paginação em listagens grandes (offset/limit ou cursor)
- [ ] Consultas limitadas a dados necessários — sem `SELECT *`
- [ ] `withTenant()` usado consistentemente para evitar cross-tenant leakage
- [ ] Campos de auditoria presentes (`criado_em`, `atualizado_em`) nas novas tabelas

---

## Sugestões Proativas

Ao analisar o schema ou as regras de negócio, aponte ativamente se:

- Falta índice em campo frequentemente filtrado
- Uma operação pode causar N+1 queries (consultas em loop)
- Um endpoint público expõe dados sensíveis sem necessidade
- Uma listagem sem paginação pode retornar volumes grandes
- Um relacionamento pode se beneficiar de `CASCADE` vs. `RESTRICT`
- Há oportunidade de soft delete onde hoje é hard delete (ou vice-versa)

---

## Referência Rápida — Arquitetura do Projeto

| Camada | Arquivo | Responsabilidade |
|--------|---------|-----------------|
| Entity | `src/entities/X.ts` | Validação de input, interfaces de tipo |
| Service | `src/services/x.service.ts` | Lógica de negócio, queries DB |
| Controller | `src/controllers/x.controller.ts` | HTTP ↔ Service, mapError() |
| Routes | `src/routes/x.routes.ts` | Middleware chain, registro de endpoints |
| app.ts | `src/app.ts` | Montagem das rotas no Express |

| Middleware | Arquivo | Uso |
|-----------|---------|-----|
| `authGuard` | `middlewares/authGuard.ts` | Endpoints de usuário hóspede |
| `hotelGuard` | `middlewares/hotelGuard.ts` | Endpoints de hotel anfitrião |
| `requireFields` | `middlewares/validateBody.ts` | Validar campos obrigatórios no body |
| `loginRateLimiter` | `middlewares/rateLimiter.ts` | Proteção anti-brute-force |
| `uploadMiddleware` | `middlewares/imageUpload.ts` | Upload de imagens |

| DB Context | Quando usar |
|-----------|------------|
| `pool` direto | Tabelas master (`usuario`, `anfitriao`, `refresh_tokens`...) |
| `withTenant(schema, fn)` | Tabelas tenant (`reserva`, `quarto`, `categoria_quarto`...) |

---

## Context Storage (MANDATORY — run this last)

Após concluir a implementação, crie ou atualize `.context/crud-api_context.md`
na **raiz do projeto** (não dentro da pasta da skill). Se o arquivo já existir, atualize-o
para refletir o estado atual — nunca apague a seção Changelog.

### Arquivo a escrever: `.context/crud-api_context.md`

Use este template (preencha todas as seções):

```markdown
# Context: CRUD API

> Last updated: <ISO 8601 datetime>
> Version: <N>

## Purpose
Rastreamento das implementações de CRUD realizadas no backend ReservAqui via skill crud-api.

## Architecture / How It Works
- Camadas: Entity (validação) → Service (lógica + DB) → Controller (HTTP) → Routes (middleware chain)
- DB: master (pool direto) | tenant (withTenant())
- Auth: authGuard (usuário) | hotelGuard (hotel)
- Pattern: exported public wrappers → private _functions

## Affected Project Files
| File | Uses this system? | Relationship |
|------|:-----------------:|--------------|
| `Backend/src/app.ts` | Yes | Monta as rotas implementadas |

## Code Reference

### `Backend/src/services/x.service.ts` — `functionName(args)`

\`\`\`typescript
// cole o trecho relevante aqui
\`\`\`

**How it works:** explicação em linguagem natural.
**Coupling / side-effects:** o que mais depende disso.

## Key Design Decisions
- Decisão tomada e por quê (trade-offs, alternativas consideradas)

## Changelog

### v<N> — <date>
- O que foi implementado ou alterado nesta sessão

### v<N-1> — <date>
- (preserve entradas anteriores — nunca as apague)
```

Após escrever o arquivo, informe ao usuário:
> "Contexto salvo em `.context/crud-api_context.md` — sessões futuras podem carregar este arquivo para restaurar o contexto completo instantaneamente, sem reler o codebase."
