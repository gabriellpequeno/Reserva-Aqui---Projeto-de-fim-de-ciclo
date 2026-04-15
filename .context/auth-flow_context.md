# Context: Auth Flow — ReservAqui Backend

> Last updated: 2026-04-15T18:00:00
> Version: 1.3

## Purpose
Login and registration system for usuarios (global guests) and anfitrioes (hotels).
Multi-tenant PostgreSQL architecture: master DB for global entities, tenant DB per hotel.

## Architecture / How It Works
- Entities: `src/entities/` — classes with static validation methods (pure logic, no DB).
- Services: `src/services/` — business logic + Argon2id hash + DB queries + JWT generation + Refresh Token Db Storage.
- Controllers: `src/controllers/` — HTTP layer, error mapping (no stacktraces).
- Middlewares: `src/middlewares/` — authGuard (usuario JWT), hotelGuard (anfitriao JWT), rateLimiter (5 req/min), validateBody.
- Database: `masterPool` used for all operations on `usuario` and `anfitriao`.
- JWT Strategy: 1h access token + 7d refresh token. Refresh tokens stored in separate tables per actor (`refresh_tokens` for usuarios, `hotel_refresh_tokens` for anfitrioes), enabling explicit revocation.
- Context isolation: `authGuard` and `hotelGuard` are SEPARATE middlewares. A hotel token cannot access usuario routes and vice-versa. hotelGuard verifies that `hotel_id` is present in JWT payload (absence means it's a usuario token → 403).

## Affected Project Files
| File | Uses this system? | Relationship |
|------|:-----------------:|--------------|
| `src/entities/Usuario.ts` | Yes | Validation class for usuario |
| `src/entities/Anfitriao.ts` | Yes | Validation class for anfitriao (NOVO) |
| `src/services/usuario.service.ts` | Yes | Register + login + CRUD + JWT for usuario |
| `src/services/anfitriao.service.ts` | Yes | Register + login + CRUD + JWT for anfitriao (NOVO) |
| `src/controllers/usuario.controller.ts` | Yes | HTTP layer for Usuario |
| `src/controllers/anfitriao.controller.ts` | Yes | HTTP layer for Anfitriao (NOVO) |
| `src/middlewares/authGuard.ts` | Yes | Protects usuario routes |
| `src/middlewares/hotelGuard.ts` | Yes | Protects anfitriao routes (NOVO) |
| `src/middlewares/rateLimiter.ts` | Yes | Shared loginRateLimiter (5 req/min via .env) |
| `src/middlewares/validateBody.ts` | Yes | Validates payload shape |
| `src/middlewares/httpsEnforcer.ts` | Yes | Enforces HTTPS proxy headers in production |
| `src/routes/usuario.routes.ts` | Yes | Express router for usuario |
| `src/routes/anfitriao.routes.ts` | Yes | Express router for anfitriao (NOVO) |
| `src/app.ts` | Yes | Mounts /api/usuarios + /api/hotel + /api/uploads |
| `.env.example` & `.env` | Yes | Environment configuration (JWT, Argon2, Routes) |
| `Backend/database/scripts/init_master.sql` | Yes | Added `hotel_refresh_tokens` table (after anfitriao) |

## Endpoints — Anfitriao (hotel)

| Method | Route | Auth | Description |
|--------|-------|:----:|-------------|
| POST | `/api/hotel/register` | ❌ | Cadastro do hotel |
| POST | `/api/hotel/login` | ❌ | Login (rate limited) |
| POST | `/api/hotel/refresh` | ❌ | Refresh token rotation |
| POST | `/api/hotel/logout` | hotelGuard | Revoga refresh token |
| GET | `/api/hotel/me` | hotelGuard | Perfil do hotel |
| PATCH | `/api/hotel/me` | hotelGuard | Atualiza dados do hotel |
| POST | `/api/hotel/change-password` | hotelGuard | Troca senha + revoga tokens |
| DELETE | `/api/hotel/me` | hotelGuard | Desativa conta (soft delete) |

## Code Reference
- `Anfitriao.validate(input)` — valida CNPJ, CEP, UF, email, senha.
- `registerAnfitriao(input)` — hash Argon2 + gera schema_name (hotel_{cnpj_digits}) + INSERT.
- `loginAnfitriao(email, senha)` — timing-safe login, stores in `hotel_refresh_tokens`.
- `refreshAnfitriaoToken(token)` — rotation: DELETE old → INSERT new.
- `logoutAnfitriao(token)` — deletes from `hotel_refresh_tokens`.

## Key Design Decisions
- `schema_name` derivado do CNPJ: `hotel_<14_digits>` — determinístico, sem colisão.
- `hotel_refresh_tokens` — tabela separada de `refresh_tokens` para evitar cruzamento de contextos.
- `hotelGuard` rejeita tokens sem `hotel_id` no payload (payload de usuario teria `user_id`).
- CNPJ, CEP e UF são normalizados (digits-only, uppercase) antes do INSERT.
- Campos imutáveis via PATCH: `cnpj`, `schema_name`, `saldo`, `cover_storage_path`.

## Changelog

### v1.3 — 2026-04-15
- Implementado CRUD completo de autenticação para `anfitriao`.
- Criado `src/entities/Anfitriao.ts` com validadores de CNPJ, CEP, UF, email, senha.
- Criado `src/services/anfitriao.service.ts` (padrão exported wrapper → private function).
- Criado `src/controllers/anfitriao.controller.ts`.
- Criado `src/middlewares/hotelGuard.ts` — guard separado do authGuard de usuario.
- Criado `src/routes/anfitriao.routes.ts` — montado em /api/hotel.
- Adicionado `hotel_refresh_tokens` em `init_master.sql` (após anfitriao).
- `src/app.ts` atualizado para montar `/api/hotel`.

### v1.2 — 2026-04-14
- Reestruturada a camada de serviço `usuario.service.ts`: as lógicas de negócio agora vivem em funções privadas `_functionName()` para isolamento, sendo expostas apenas via wrappers.
- `Usuario` Entity validator methods transformados em `private static` mantendo apenas a interface root `validate`.
- Adicionada proteção com suporte à `.env`: `RATE_LIMIT_LOGIN_MAX` e `RATE_LIMIT_LOGIN_WINDOW_MS` no middleware de rate limiting nativo e criado force proxy check com `httpsEnforcer.ts`.

### v1.1 — 2026-04-11
- Extracted cryptographic constraints (`Argon2` memory cost, time cost, and parallelism) to `.env`.
- Added dynamic route resolution with `API_PREFIX` directly loaded via dotenv.
- Created `src/app.ts` server entrypoint.

### v1 — 2026-04-10
- Initial auth implementation for `usuario` entity explicitly.
- Defined explicit rules and architecture 3-layer.
- Applied Argon2, JWT token issuance + rotation logic, and full Express routing layout.
