# Context: Auth Flow — ReservAqui Backend

> Last updated: 2026-04-14T18:25:00
> Version: 1.2

## Purpose
Login and registration system for usuarios (global guests) and anfitrioes (hotels).
Multi-tenant PostgreSQL architecture: master DB for global entities, tenant DB per hotel.

## Architecture / How It Works
- Entities: `src/entities/` — classes with static validation methods (pure logic, no DB).
- Services: `src/services/` — business logic + Argon2id hash + DB queries + JWT generation + Refresh Token Db Storage.
- Controllers: `src/controllers/` — HTTP layer, error mapping (no stacktraces).
- Middlewares: `src/middlewares/` — authGuard (JWT validation), rateLimiter (5 req/min), validateBody.
- Database: `masterPool` used for all operations on `usuario` and `anfitriao`.
- JWT Strategy: 1h access token + 7d refresh token. Refresh tokens are stored in `refresh_tokens` in the master DB, allowing explicit revocation.

## Affected Project Files
| File | Uses this system? | Relationship |
|------|:-----------------:|--------------| 
| `src/entities/Usuario.ts` | Yes | Validation class |
| `src/services/usuario.service.ts` | Yes | Register + login + CRUD + JWT |
| `src/controllers/usuario.controller.ts` | Yes | HTTP layer for Usuario |
| `src/middlewares/authGuard.ts` | Yes | Protects auth-required routes |
| `src/middlewares/rateLimiter.ts` | Yes | Prevents brute force on login (now uses .env) |
| `src/middlewares/validateBody.ts` | Yes | Validates payload shape |
| `src/middlewares/httpsEnforcer.ts` | Yes | Enforces HTTPS proxy headers in production |
| `src/routes/usuario.routes.ts` | Yes | Express router definition |
| `src/app.ts` | Yes | Express app entry point & default route setup |
| `.env.example` & `.env` | Yes | Environment configuration (JWT, Argon2, Routes) |
| `Backend/database/scripts/init_master.sql` | Yes | Added `refresh_tokens` table |
| `Backend/database/scripts/init_tenant.sql` | Yes | `hospede` simplified (no senha/criado_em) |
| `regras de negócio.txt` | Yes | Rules updated, `hospede` defined as derived |

## Code Reference
- `Usuario.validate(input)` - static synchronous validations.
- `registerUsuario(input: RegisterUsuarioInput)` - creates and hashes user.
- `loginUsuario(email, senha)` - timing-safe login logic, Argon2 verification.
- `refreshUsuarioToken(token)` - rotating refresh tokens explicitly with DB.
- `logoutUsuario(token)` - deletes the refresh token from DB.

## Key Design Decisions
- Hasher: `Argon2id` dynamically configured via `.env` (`ARGON2_MEMORY_COST=65536`, `t=3`, `p=1`) for resistance to GPU cracking without hardcoding limits.
- Security: Timing-safe attacks prevented in login using fallback dummy hash when user not found.
- Access: JWT sent in `AuthorizationHeader`. TTL 1 hour.
- Refresh Token Storage: Stored hashes in `refresh_tokens` instead of raw tokens.
- `hospede` simplification: Hospede does NOT have a password. It's a derived record automatically bound to the master `usuario` by the hotel tenant.
- Anfitrião Update: Removed `telefone_recepcao` from auth layer (belongs to `configuracao_hotel`).
- Main App Initialization: `src/app.ts` securely mounts `API_PREFIX` explicitly from environment variables allowing for flexible API versioning.

## Changelog

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
- Applied Argon2, JWT token issuance + rotation logic, and full Express routing layout (`me`, `logout`, `change-password`).
