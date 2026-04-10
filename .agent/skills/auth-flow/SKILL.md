---
name: auth-flow
description: Specialist for implementing and modifying the login and registration flow in the ReservAqui backend. Use this skill for any task involving: user (hóspede) or host (anfitrião/hotel) registration, login, password hashing with bcrypt, session/token management, input validation in entity classes, auth middlewares, or the full CRUD of auth-related entities. Trigger this skill whenever the user mentions "cadastro", "login", "registro", "autenticação", "senha", "sessão", "token", "anfitrião", "usuário", or any change to the auth flow — even if not explicitly named.
---

# Auth Flow Skill — ReservAqui Backend

Specialist for the login and registration system of the ReservAqui platform.
Covers both **usuario** (global guest) and **anfitriao** (hotel/host) flows,
using a 3-layer architecture: Entity → Service → Controller.

---

## Context Load (MANDATORY — run this first)

Before doing any analysis, research, or implementation, check for a saved context file:

1. Look for `.context/auth-flow_context.md` at the project root (`c:\Users\Noah\Desktop\ReservAqui\`).
2. If the file **exists**: read it in full. Use the Architecture, Affected Project Files, Code Reference, and Key Design Decisions sections to restore your working context. Skip any codebase exploration that would duplicate what is already documented there. Inform the user:
   > "Context restored from `.context/auth-flow_context.md` (v\<N\>, last updated \<date\>). Continuing from previous session."
3. If the file **does not exist**: read the reference files listed below to gather context, then proceed.

**Key reference files to read if no context exists:**
- `Backend/src/database/masterDb.ts` — master DB connection pool
- `Backend/src/database/tenantPool.ts` — tenant DB pool (lazy per hotel)
- `Backend/src/modules/hotel/hotel.service.ts` — only existing service (reference pattern)
- `Backend/database/scripts/init_master.sql` — schema: `usuario`, `anfitriao`
- `Backend/database/scripts/init_tenant.sql` — schema: `hospede`
- `regras de negócio.txt` — field validation rules

> **Rule:** Never ignore an existing context file. It exists to avoid re-analysis. Trust it and update it if the implementation changes.

---

## Project Architecture

### Technology Stack
- **Runtime**: Node.js + TypeScript 5
- **Framework**: Express 4
- **Database**: PostgreSQL (via `pg` pool — no ORM)
- **Hashing**: bcrypt (cost factor 12)
- **IDs**: UUID v4 (`uuid` package)
- **No JWT yet** — session strategy is TBD; implement token signing only when explicitly requested

### 3-Layer Architecture

```
Request → Controller → Service → Entity (validation) → DB
                  ↑
            Middleware (auth guard, input sanitization)
```

| Layer | Path | Responsibility |
|-------|------|----------------|
| **Entity** | `src/entities/` | Class with typed fields + validation methods |
| **Service** | `src/services/` or `src/modules/<domain>/` | Business logic, DB queries, bcrypt |
| **Controller** | `src/controllers/` | Parse request → call service → send response |
| **Middleware** | `src/middlewares/` | Auth guard, error handler, input checks |

### Multi-Tenant Database Strategy

The system uses **two databases**:

- **Master DB** (`reservaqui_master`) — managed via `masterPool` from `masterDb.ts`
  - Tables: `usuario` (global guests), `anfitriao` (hotels/hosts)
- **Tenant DB** (one per hotel) — managed via `getTenantPool(dbName)` from `tenantPool.ts`
  - Table: `hospede` (guest registered at a specific hotel)

**Routing rule**: Operations on `usuario` and `anfitriao` always use `masterPool`. Operations on `hospede` always use the hotel's tenant pool — which requires knowing the `hotel_id` first.

---

## Business Rules — Dynamic (ask before coding)

Do NOT hardcode rules from memory. Before writing any entity validator:

1. Read `regras de negócio.txt` to get the current baseline.
2. Present the relevant rules to the user as a table with a confirmation question, for example:

   > "Encontrei as seguintes regras para **Usuario** em `regras de negócio.txt`. Estão corretas/completas, ou precisa ajustar algo antes de eu implementar os validadores?"
   >
   > | Campo | Regra atual |
   > |-------|-------------|
   > | `senha` | maiúscula, minúscula, `@` e número |
   > | `email` | deve ter `@` e `.com` |
   > | `cpf` | 11 dígitos |
   > | … | … |

3. **Wait for the user's answer** — only proceed to entity implementation after confirmation.
4. If the user changes or adds rules, update `regras de negócio.txt` to reflect them before coding, so the file stays as the single source of truth.

> **Why:** Business rules evolve. Implementations that bake in outdated rules create silent bugs. The file is the contract — always sync to it, never bypass it.

---

## Implementation Workflow

When implementing or modifying the auth flow, always follow this order.
**Do NOT skip Step 0 — it is the gate that unlocks Steps 1–5.**

### Step 0 — Pre-Implementation Gate (MANDATORY)

This step has two parallel tracks. Run both before writing any code:

#### Track A — Business Rules Confirmation

Follow the protocol in the **Business Rules** section above:
- Read `regras de negócio.txt`
- Present the relevant rules to the user as a table
- Wait for confirmation or corrections

#### Track B — Security Research & Decision

Before touching any auth or session code, research the current best practices and present the options to the user. Cover at minimum:

**1. Password Hashing**
- Research the current recommended bcrypt cost factor (OWASP 2025 guidelines)
- Mention alternatives: Argon2id (winner of Password Hashing Competition), scrypt
- Present trade-offs: security strength vs. latency on this server's hardware
- Ask: *"Prefere manter bcrypt ou migrar para Argon2id, que é mais resistente a ataques de GPU?"*

**2. Session / Token Strategy**
- Research options: stateless JWT, opaque tokens (stored server-side), HTTP-only cookie sessions
- Present each with pros/cons for this use case (multi-tenant hotel platform, mobile + web clients)
- Highlight security considerations: token expiry, refresh strategy, revocation, CSRF
- Ask: *"Qual estratégia de sessão prefere para o projeto? JWT, sessões server-side, ou outra?"*

**3. Additional Hardening** (present as optional, user decides)
- Rate limiting on login endpoint (prevent brute force)
- Account lockout after N failed attempts
- Email verification on registration
- HTTPS enforcement (if applicable at this layer)

Format the security summary clearly, like:

> ## Opções de Segurança — Aguardando sua decisão
>
> ### 🔐 Hash de Senha
> | Opção | Segurança | Velocidade | Recomendado |
> |-------|-----------|------------|-------------|
> | bcrypt (cost 12) | Alta | ~250ms | ✅ Sim (atual) |
> | Argon2id | Muito Alta | ~300ms | ✅ OWASP 2025 |
> | bcrypt (cost 14) | Muito Alta | ~1s | ⚠️ Lento para login |
>
> ### 🎫 Estratégia de Sessão
> | Opção | Stateless | Revogável | CSRF Risk |
> |-------|-----------|-----------|----------|
> | JWT (Authorization header) | Sim | Não (até expirar) | Não |
> | JWT (HTTP-only cookie) | Sim | Não | Sim (precisa de CSRF token) |
> | Sessão server-side + cookie | Não | Sim (instantâneo) | Sim |
>
> **Qual prefere para cada ponto?**

#### Gate Rule

Only after the user responds to **both tracks** (rules confirmed + security decisions made) should you proceed to Steps 1–5. If the user explicitly says "pode usar o padrão" or "use o que você achar melhor", adopt OWASP 2025 recommendations and document the choice.

---

### Step 1 — Entity Class

Create or update `src/entities/<Entity>.ts`.

Each entity is a **class** that:
- Holds typed fields matching the DB schema
- Exposes `static validate(input)` methods that throw descriptive errors on failure
- Never touches the DB — pure validation

```typescript
// Pattern example (adapt to actual entity)
export class Usuario {
  constructor(
    public nome_completo: string,
    public email: string,
    public senha: string,
    public cpf: string,
    public data_nascimento: string,
    public numero_celular?: string,
  ) {}

  static validateEmail(email: string): void {
    if (!email.includes('@') || !email.includes('.com'))
      throw new Error('Email inválido: deve conter @ e .com');
  }

  static validateSenha(senha: string): void {
    const ok = /[A-Z]/.test(senha) && /[a-z]/.test(senha)
             && /@/.test(senha)    && /[0-9]/.test(senha);
    if (!ok)
      throw new Error('Senha fraca: requer maiúscula, minúscula, @ e número');
  }

  static validateCpf(cpf: string): void {
    if (!/^\d{11}$/.test(cpf.replace(/\D/g, '')))
      throw new Error('CPF inválido: deve conter 11 dígitos');
  }

  static validateCelular(cel: string): void {
    if (!/^\(\d{2}\) \d{4,5}-\d{4}$/.test(cel))
      throw new Error('Celular inválido: formato (xx) xxxxx-xxxx');
  }

  // Call all validators together before persisting
  static validate(input: Partial<Usuario>): void {
    this.validateEmail(input.email!);
    this.validateSenha(input.senha!);
    this.validateCpf(input.cpf!);
    if (input.numero_celular) this.validateCelular(input.numero_celular);
  }
}
```

### Step 2 — Service

Create or update `src/services/<entity>.service.ts` (or `src/modules/<domain>/<domain>.service.ts` for domain modules like hotel).

Service responsibilities:
- Call `Entity.validate()` first — **always before any DB operation**
- Hash passwords with `bcrypt.hash(senha, 12)` — never store plain text
- Execute parameterized queries via `masterPool` or `getTenantPool(dbName)`
- Return typed results — never expose raw DB rows with sensitive fields

```typescript
// Pattern
import bcrypt from 'bcrypt';
import { masterPool } from '../database/masterDb';
import { Usuario } from '../entities/Usuario';

export async function registerUsuario(input: RegisterUsuarioInput) {
  // 1. Validate — throws on failure
  Usuario.validate(input);

  // 2. Hash
  const senhaHash = await bcrypt.hash(input.senha, 12);

  // 3. Persist
  const { rows } = await masterPool.query(
    `INSERT INTO usuario (nome_completo, email, senha, cpf, data_nascimento, numero_celular)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING user_id, nome_completo, email, criado_em`,
    [input.nome_completo, input.email, senhaHash, input.cpf,
     input.data_nascimento, input.numero_celular ?? null],
  );
  return rows[0];
}

export async function loginUsuario(email: string, senha: string) {
  const { rows } = await masterPool.query(
    `SELECT * FROM usuario WHERE email = $1 AND ativo = TRUE`, [email]
  );
  const user = rows[0];
  if (!user) throw new Error('Credenciais inválidas');

  const match = await bcrypt.compare(senha, user.senha);
  if (!match) throw new Error('Credenciais inválidas');

  // Return safe payload (strip senha)
  const { senha: _, ...safeUser } = user;
  return safeUser;
}
```

### Step 3 — Controller

Create or update `src/controllers/<entity>.controller.ts`.

Controller responsibilities:
- Parse `req.body` — never trust raw input
- Call the service — wrap in try/catch
- Map service errors to HTTP status codes:
  - Validation error → `400`
  - Not found / bad credentials → `401` or `404`
  - Conflict (duplicate email/CPF) → `409`
  - Unexpected → `500`
- Never include stack traces in production responses

```typescript
// Pattern
import { Request, Response } from 'express';
import { registerUsuario, loginUsuario } from '../services/usuario.service';

export async function registerUsuarioController(req: Request, res: Response) {
  try {
    const result = await registerUsuario(req.body);
    res.status(201).json({ data: result });
  } catch (err: any) {
    const status = err.message.includes('já existe') ? 409
                 : err.message.includes('inválid')   ? 400 : 500;
    res.status(status).json({ error: err.message });
  }
}

export async function loginUsuarioController(req: Request, res: Response) {
  try {
    const { email, senha } = req.body;
    const user = await loginUsuario(email, senha);
    // TODO: attach session/token here when auth strategy is defined
    res.json({ data: user });
  } catch (err: any) {
    res.status(401).json({ error: 'Credenciais inválidas' });
  }
}
```

### Step 4 — Middleware

Create `src/middlewares/` files as needed:

**`authGuard.ts`** — Protects routes that require authentication. Check for session/token and attach user to `req`. Implement only after session strategy is decided.

**`validateBody.ts`** — Lightweight middleware to reject requests missing required fields before they reach the service:

```typescript
export function requireFields(...fields: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const missing = fields.filter(f => !req.body[f]);
    if (missing.length) {
      return res.status(400).json({ error: `Campos obrigatórios: ${missing.join(', ')}` });
    }
    next();
  };
}
```

### Step 5 — Register Routes

Mount routes in the Express app. Group auth routes logically:

```
POST /api/usuario/register
POST /api/usuario/login
POST /api/anfitriao/register
POST /api/anfitriao/login
```

---

## Anfitriao-Specific Rules

The anfitriao flow has an extra step: **tenant provisioning**.

When a hotel registers:
1. Validate all fields (including `cnpj`, `cep`, `uf`, `telefone`)
2. Hash `senha`
3. Call `provisionTenant(hotelId, nome)` from `tenantManager.ts` — this creates the tenant DB + folder
4. Only then insert into `anfitriao` table in master DB

This is already implemented in `hotel.service.ts` as a reference pattern. Follow it exactly.

**CNPJ validation**: 14 digits (strip non-numeric first)
**CEP validation**: 7 digits
**UF validation**: exactly 2 uppercase letters

---

## Security Verification Checklist

After completing the implementation, verify the invariants below. These apply regardless of which security options the user chose in Step 0:

- [ ] Passwords hashed with the agreed algorithm — never stored as plain text
- [ ] Login comparison uses the library's secure compare function — never string/plain comparison
- [ ] Error messages for login **never distinguish** between "user not found" and "wrong password" — always a generic message
- [ ] `senha` field is **never returned** in any API response (strip before returning)
- [ ] All DB queries use **parameterized queries** (`$1, $2...`) — never string concatenation
- [ ] `ativo = TRUE` filter applied on all login queries
- [ ] Entity `validate()` is called **before** any DB write in every service function
- [ ] Chosen session/token strategy matches what the user decided in Step 0
- [ ] Any security hardening options the user opted into (rate limiting, lockout, etc.) are implemented

---

## Context Storage (MANDATORY — run this last)

After completing the implementation, create or update `.context/auth-flow_context.md`
at the **project root** (`c:\Users\Noah\Desktop\ReservAqui\`). If the file already exists, update
it to reflect the current state — never delete the Changelog section.

### File to write: `.context/auth-flow_context.md`

Use this template (fill in all sections):

```markdown
# Context: Auth Flow — ReservAqui Backend

> Last updated: <ISO 8601 datetime>
> Version: <N>

## Purpose
Login and registration system for usuarios (global guests) and anfitrioes (hotels).
Multi-tenant PostgreSQL architecture: master DB for global entities, tenant DB per hotel.

## Architecture / How It Works
- Entities: `src/entities/` — classes with static validation methods
- Services: `src/services/` — business logic + bcrypt + DB queries
- Controllers: `src/controllers/` — HTTP layer, error mapping
- Middlewares: `src/middlewares/` — auth guard, field validation
- Database: masterPool (usuario/anfitriao) + getTenantPool(dbName) (hospede)

## Affected Project Files
| File | Uses this system? | Relationship |
|------|:-----------------:|--------------| 
| `src/entities/Usuario.ts` | Yes | Validation class |
| `src/entities/Anfitriao.ts` | Yes | Validation class |
| `src/services/usuario.service.ts` | Yes | Register + login logic |
| `src/modules/hotel/hotel.service.ts` | Yes | Register + login for hotel |
| `src/controllers/usuario.controller.ts` | Yes | HTTP layer |
| `src/controllers/anfitriao.controller.ts` | Yes | HTTP layer |
| `src/middlewares/authGuard.ts` | Indirect | Protects auth-required routes |

## Code Reference
(fill with key function signatures implemented this session)

## Key Design Decisions
- bcrypt cost factor: 12
- Validation in entity static methods (before any DB call)
- Generic error message on login (no user enumeration)
- Tenant provisioning always done before master DB insert

## Changelog

### v<N> — <date>
- What was implemented or changed in this session

### v<N-1> — <date>
- (preserve previous entries — never delete them)
```

After writing the file, tell the user:
> "Context saved to `.context/auth-flow_context.md` — future sessions can load this file to restore full context instantly, without re-reading the codebase."
