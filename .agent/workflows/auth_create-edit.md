---
description: Implementa ou edita o esquema de autenticação do projeto. Guia o dev pelas opções de segurança e delega a implementação para a skill `auth-flow`.
---

# /auth_create-edit — Auth Flow

$ARGUMENTS

---

## Purpose

This command orchestrates the full lifecycle of the authentication system (login, registration, session, middleware) for the ReservAqui platform.

It **does not implement code directly** — it guides the developer through security decisions first, then delegates the implementation to the `auth-flow` skill with all decisions already resolved.

---

## Behavior

### Phase 1 — Context Discovery (Silent)

Before showing anything to the user:

1. Check for `.context/auth-flow_context.md` at the project root.
   - If it **exists**: Read it and inform the user:
     > "🔄 Context restored from `.context/auth-flow_context.md` (v\<N\>, last updated \<date\>). Continuing from previous session."
   - If it **does not exist**: Read the reference files below to understand the current state:
     - `Backend/database/scripts/init_master.sql` — schema for `usuario` and `anfitriao`
     - `Backend/database/scripts/init_tenant.sql` — schema for `hospede`
     - `regras de negócio.txt` — field validation rules

2. Identify the **scope** of the request from `$ARGUMENTS`:
   - Is this a **new** auth implementation or an **edit** to an existing one?
   - Which entity is in scope? (`usuario`, `anfitriao`, `hospede`, or all)
   - Which layer is being changed? (Entity, Service, Controller, Middleware, Routes — or full flow)

---

### Phase 2 — Security Discovery (Interactive Gate)

> 🛑 **MANDATORY: Do NOT write any code before this phase is complete and the user has responded.**

Present two parallel tracks to the user. Format each clearly with tables and options.

---

#### Track A — Business Rules Confirmation

Read `regras de negócio.txt`. Present the relevant rules for the entities in scope as a table:

```markdown
## 📋 Regras de Negócio — Confirmação

Encontrei as seguintes regras para **[Entidade]** em `regras de negócio.txt`:

| Campo | Regra atual |
|-------|-------------|
| `email` | deve conter `@` e `.com` |
| `senha` | maiúscula, minúscula, `@` e número |
| `cpf` | 11 dígitos |
| … | … |

**Essas regras estão corretas e completas, ou precisa ajustar algo antes de eu começar a implementação?**
```

Wait for confirmation or corrections. If rules are updated, note them — they will be passed to the skill.

---

#### Track B — Security Options

Present each security concern with clear trade-off tables. The developer **must choose** before any code is written.

```markdown
## 🔐 Decisões de Segurança — Aguardando sua escolha

---

### 1. Hash de Senha

| Opção | Segurança | Velocidade | Recomendado (OWASP 2025) |
|-------|-----------|------------|--------------------------|
| `bcrypt` (cost 12) | Alta | ~250ms | ✅ Padrão atual |
| `bcrypt` (cost 14) | Muito Alta | ~1s | ⚠️ Lento para login |
| `Argon2id` (m=64MB, t=3) | Muito Alta | ~300ms | ✅ Melhor resistência a GPU |
| `scrypt` | Alta | Variável | ⚠️ Menos suporte em libs Node |

> 💡 **Recomendação**: Argon2id é o vencedor do Password Hashing Competition e o mais
> indicado pelo OWASP 2025 para novos sistemas. bcrypt cost 12 é sólido se já está em uso.

**Qual prefere?** → `bcrypt (12)` / `bcrypt (14)` / `Argon2id` / Outra

---

### 2. Estratégia de Sessão / Token

| Opção | Stateless | Revogável | Risco CSRF | Complexidade |
|-------|-----------|-----------|------------|--------------|
| `JWT` (Authorization header) | ✅ Sim | ❌ Não (até expirar) | ✅ Não | Baixa |
| `JWT` (HTTP-only cookie) | ✅ Sim | ❌ Não | ⚠️ Sim | Média |
| Sessão server-side + cookie | ❌ Não | ✅ Sim (instantâneo) | ⚠️ Sim | Alta |
| Opaque token + DB lookup | ❌ Não | ✅ Sim | ✅ Não | Média |

> 💡 Para um sistema multi-tenant com clientes mobile + web, **JWT no header** é mais simples
> e evita CSRF. Sessão server-side é mais revogável mas requer armazenamento extra.

**Qual prefere?** → `JWT (header)` / `JWT (cookie)` / `Sessão server-side` / `Opaque token`

Se escolher JWT: qual TTL? (padrão: 1h access + 7d refresh)

---

### 3. Proteções Adicionais (opcional — marque o que quer ativar)

- [ ] **Rate limiting** no endpoint de login (ex: 5 tentativas / 1 min por IP)
- [ ] **Account lockout** após N falhas consecutivas (ex: bloquear por 15 min após 5 falhas)
- [ ] **Verificação de email** no cadastro (enviar link de confirmação)
- [ ] **Log de tentativas** de login (audit trail por user_id)
- [ ] **HTTPS enforcement** (rejeitar requisições HTTP — útil se o Express está atrás de proxy)

**Quais dessas proteções quer implementar agora?** (pode dizer "nenhuma por enquanto")
```

> **Gate Rule**: Only proceed to Phase 3 after the user has answered both tracks.
> If the user says "usa o padrão" or "pode decidir você", adopt OWASP 2025 recommendations
> (`Argon2id` + `JWT no header`, TTL 1h/7d, rate limiting ativo) and document the choice.

---

### Phase 3 — Implementation Brief

After the user responds, compile a brief summary of all decisions and present it for final confirmation:

```markdown
## ✅ Resumo das Decisões — Pronto para implementar

| Decisão | Escolha |
|---------|---------|
| Entidade(s) em escopo | [usuario / anfitriao / hospede] |
| Hash de senha | [Argon2id / bcrypt cost 12 / …] |
| Estratégia de sessão | [JWT header / cookie / server-side] |
| TTL do token | [access: X / refresh: Y] |
| Rate limiting | [Sim / Não] |
| Account lockout | [Sim / Não] |
| Verificação de email | [Sim / Não] |
| Regras de negócio | Confirmadas / Ajustadas: [lista de mudanças] |

**Posso começar a implementação com essas configurações?** (sim / ajustar X)
```

Wait for the final "sim" before invoking the skill.

---

### Phase 4 — Skill Delegation

Once the user approves:

1. State clearly:
   > "🚀 Delegando implementação para a skill `auth-flow` com as configurações confirmadas..."

2. **Invoke the `auth-flow` skill** (`c:\Users\Noah\Desktop\ReservAqui\.agent\skills\auth-flow\SKILL.md`).
   Pass the full implementation context as instructions:
   - Entities in scope
   - Confirmed business rules (including any user corrections)
   - Password hashing algorithm and parameters
   - Session/token strategy and TTL
   - Which hardening options to implement
   - Whether this is a new implementation or an edit (and which files already exist)

3. The skill will execute Steps 1–5 (Entity → Service → Controller → Middleware → Routes)
   and run the Security Verification Checklist at the end.

4. After the skill completes, confirm:
   > "✅ Implementação concluída. Context salvo em `.context/auth-flow_context.md`."

---

## Usage Examples

```
/auth_create-edit registrar usuario
/auth_create-edit implementar login de anfitriao com JWT
/auth_create-edit adicionar rate limiting no endpoint de login
/auth_create-edit hospede login com sessão server-side
/auth_create-edit atualizar validação de senha
```

---

## Key Principles

- **Never write code before the Gate is cleared** — both tracks must be answered
- **Always present options** — the developer decides on security, not the AI
- **Honest trade-offs** — don't hide complexity or risks
- **Defer to OWASP 2025** when the user says "use the default"
- **Pass full context to the skill** — the skill should not need to re-ask questions