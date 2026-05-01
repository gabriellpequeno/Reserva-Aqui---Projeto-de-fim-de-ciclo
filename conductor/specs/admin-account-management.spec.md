# Spec — admin-account-management

> Bundle: P6-C (Admin Account Management) + P6-E (Admin Profile Integration)
> Entrega em **duas fases sequenciais**: **Fase 1 — Backend** (pré-requisito bloqueante) → **Fase 2 — Frontend**. A Fase 2 não inicia antes de a Fase 1 estar mergeada e disponível em staging com admin seedado.

## Referência

- **PRD:** [`conductor/features/admin-account-management.prd.md`](../features/admin-account-management.prd.md)
- **Tasks de origem:** `conductor/__task/P6-C-admin-account-management.md`, `conductor/__task/P6-E-admin-profile-integration.md`
- **Referências de padrão — Backend:**
  - `Backend/src/middlewares/authGuard.ts` — base para o novo `adminGuard`
  - `Backend/src/controllers/usuario.controller.ts` — padrão de controller + JWT sign
  - `Backend/src/routes/usuario.routes.ts` — padrão de registro de rotas com middleware
  - `Backend/database/scripts/init_master.sql` — schema atual das tabelas `usuario` e `anfitriao`
- **Referências de padrão — Frontend:**
  - `Frontend/lib/features/profile/presentation/providers/host_profile_provider.dart` — padrão Riverpod `AsyncNotifier` + `Completer`
  - `Frontend/lib/features/rooms/presentation/pages/my_rooms_page.dart` — layout de busca + lista de cards com status e ações
  - `Frontend/lib/core/router/app_router.dart` — padrão de `GoRoute` dentro do `ShellRoute`
  - `Frontend/lib/core/auth/auth_notifier.dart` — `authProvider` com token e papel

---

## Abordagem Técnica

**Entrega em duas fases sequenciais**, com a Fase 1 sendo condição obrigatória para o início da Fase 2.

### Fase 1 — Backend (pré-requisito bloqueante)

O backend atual não tem nenhum conceito de papel admin (verificado via `grep` em `Backend/src/` e `Backend/database/`). Essa fase constrói todo o pré-requisito:

1. **Schema:** adicionar campo `papel` em `usuario` via migration SQL, com CHECK constraint e default `'usuario'`. Seedar um admin inicial.
2. **JWT:** alterar `jwt.sign(...)` nos controllers de login (`usuario.controller.ts`) para incluir `papel` no payload; alterar `authGuard.ts` para expor `req.userPapel`.
3. **Middleware:** criar `adminGuard.ts` que encadeia `authGuard` + verificação de papel.
4. **Status:** decidir entre reutilizar `ativo BOOLEAN` (Opção A — MVP) ou adicionar coluna `status VARCHAR(20)` com enum (Opção B — extensível). Recomendação: **Opção A** para minimizar migrations, mapeando na serialização. Decisão precisa ser confirmada pelo produto antes da implementação.
5. **Endpoints admin:** criar `admin.controller.ts`, `admin.routes.ts` e service/module seguindo o padrão de `modules/` do projeto. Rotas: `GET /admin/users`, `PATCH /admin/users/:id`, `GET /admin/hotels`, `PATCH /admin/hotels/:id`, todas protegidas por `adminGuard`.
6. **`/usuarios/me`:** incluir `papel` no response.

### Fase 2 — Frontend

Consome os endpoints e o JWT da Fase 1.

**Frente 2a — Tela `/admin/accounts`:**
`ConsumerStatefulWidget` com `TabController` de 2 abas (Usuários / Hotéis) e um único `TextEditingController` compartilhado para busca (garantindo que o termo persiste ao trocar de aba — requisito #16 do PRD). Cada aba consome seu próprio `AsyncNotifier`:

- `adminUsersProvider` → `AsyncNotifier<List<AdminUserModel>>`
- `adminHotelsProvider` → `AsyncNotifier<List<AdminHotelModel>>`

Filtro por nome/e-mail in-memory, com debounce de 300ms local. Alterações de status disparam `PATCH` via `AdminAccountsService` e invalidam apenas o provider correspondente, com **estratégia otimista + rollback** em caso de erro.

**Frente 2b — Integração do perfil admin:**
Seguindo **exatamente** o padrão de `host_profile_provider.dart` (`AsyncNotifier<AdminProfileState>` + `ref.read(dioProvider)` + `Completer` para adaptar callbacks de service). `AdminProfilePage` vira `ConsumerWidget`; `EditAdminProfilePage` vira `ConsumerStatefulWidget` com pré-preenchimento via provider e `PATCH /api/usuarios/me` no save.

**Correções bundled na Fase 2:**
- Logout do admin: `ref.read(authProvider.notifier).clear()` + `context.go('/auth/login')` (alinhar ao fix já aplicado em user/host — commit `e32c6c0`).
- Dark Mode: substituir `AppColors.backgroundLight` fixo por tokens semânticos do `Theme.of(context).colorScheme`.
- Guard de rota: estender `redirect` do `app_router.dart` para proteger `/admin/*` exigindo `auth.papel == 'admin'`.

**Sem fallback mock em nenhum ponto:** erros em runtime (404/500/timeout) viram estado de erro com retry, nunca dados fictícios.

---

## Fase 1 — Backend

### Arquivos novos

| Arquivo | Responsabilidade |
|---------|------------------|
| `Backend/database/scripts/migrations/NNN_add_papel_to_usuario.sql` | Adicionar coluna `papel` em `usuario` + backfill `'usuario'` + seed de admin |
| `Backend/src/middlewares/adminGuard.ts` | Middleware que encadeia `authGuard` + verificação `req.userPapel === 'admin'` → 403 se falhar |
| `Backend/src/controllers/admin.controller.ts` | Controllers: `listUsers`, `updateUserStatus`, `listHotels`, `updateHotelStatus` |
| `Backend/src/routes/admin.routes.ts` | Router Express com as 4 rotas admin, todas com `adminGuard` |
| `Backend/src/modules/admin/admin.service.ts` | Queries SQL (listar usuários, listar hotéis, atualizar status) seguindo padrão `modules/` |
| `Backend/src/scripts/seed.admin.ts` | Script de seed idempotente do admin inicial (executado uma vez em staging) |

### Arquivos modificados

| Arquivo | O que muda |
|---------|------------|
| `Backend/src/middlewares/authGuard.ts` | Adicionar `userPapel?: string` no `AuthRequest`; extrair `papel` do payload JWT e anexar em `req.userPapel` |
| `Backend/src/controllers/usuario.controller.ts` | `jwt.sign(...)` no login deve incluir `papel`; `getMeController` deve retornar `papel` no response |
| `Backend/src/server.ts` (ou bootstrap equivalente) | Registrar `admin.routes.ts` em `app.use('/admin', adminRouter)` |
| `Backend/database/scripts/init_master.sql` | Refletir a nova coluna `papel` na criação inicial da tabela `usuario` (para ambientes novos) |

### Estratégia de status (decisão do produto — default Opção A)

**Opção A (recomendada para MVP):** reutilizar `ativo BOOLEAN` existente. Na serialização do controller:
- `usuario.ativo === true` → `status: 'ativo'`; `false` → `status: 'suspenso'`.
- `anfitriao.ativo === true` → `status: 'ativo'`; `false` → `status: 'inativo'`.

No `PATCH`, inverter: `'ativo' → true`, `'suspenso'/'inativo' → false`. Zero migrations adicionais além do `papel`.

**Opção B (extensível):** migrations adicionais com `ALTER TABLE usuario ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (status IN ('ativo', 'suspenso'))` e análoga para `anfitriao`. Reservar para quando "suspenso temporário" tiver semântica distinta de "deletado soft".

---

## Fase 2 — Frontend

### Arquivos novos

- **Página:** `AdminAccountManagementPage` (`lib/features/profile/presentation/pages/admin_account_management_page.dart`)
- **Widgets:**
  - `AdminUserCard` (`lib/features/profile/presentation/widgets/admin_user_card.dart`) — avatar/initials, nome, email, chip de status, botão editar
  - `AdminHotelCard` (`lib/features/profile/presentation/widgets/admin_hotel_card.dart`) — thumbnail, nome, email/responsável, chip de status, botão editar
  - `AdminAccountStatusChip` (`lib/features/profile/presentation/widgets/admin_account_status_chip.dart`) — chip reutilizável com tokens semânticos
  - `AdminEditAccountSheet` (`lib/features/profile/presentation/widgets/admin_edit_account_sheet.dart`) — bottom sheet de edição (alternar status)
- **Providers:**
  - `adminUsersProvider` (`lib/features/profile/presentation/providers/admin_users_provider.dart`) — `AsyncNotifier<List<AdminUserModel>>` + `updateStatus(id, status)`
  - `adminHotelsProvider` (`lib/features/profile/presentation/providers/admin_hotels_provider.dart`) — `AsyncNotifier<List<AdminHotelModel>>` + `updateStatus(id, status)`
  - `adminProfileProvider` (`lib/features/profile/presentation/providers/admin_profile_provider.dart`) — `AsyncNotifier<AdminProfileState>` espelhando `host_profile_provider.dart`
- **Models:** `AdminUserModel`, `AdminHotelModel`, `AdminProfileState`, `enum AdminAccountStatus` (`lib/features/profile/domain/models/`)
- **Service:** `AdminAccountsService` (`lib/features/profile/data/services/admin_accounts_service.dart`) — wrapper `DioClient` com `getUsers()`, `getHotels()`, `updateUserStatus(id, status)`, `updateHotelStatus(id, status)`

### Arquivos modificados

- `lib/core/router/app_router.dart` — adicionar `GoRoute('/admin/accounts')` no `ShellRoute`; estender `redirect` para proteger `/admin/*` (exigir `auth.papel == 'admin'`)
- `lib/features/profile/presentation/pages/admin_profile_page.dart` — converter de `StatelessWidget` para `ConsumerWidget`; consumir `adminProfileProvider` no `ProfileHeader`; ligar "Clientes" → `context.push('/admin/accounts')`; corrigir "sair" (`authProvider.notifier.clear()` + `context.go('/auth/login')`); trocar `AppColors.backgroundLight` por tokens semânticos
- `lib/features/profile/presentation/pages/edit_admin_profile_page.dart` — converter para `ConsumerStatefulWidget`; pré-preencher via `adminProfileProvider`; substituir `Future.delayed` por `PATCH /api/usuarios/me`; invalidar provider após save; remover validação mock `value != '123456'`

---

## Decisões de Arquitetura

### Backend

| Decisão | Justificativa |
|---------|---------------|
| Coluna `papel` em `usuario` (não tabela `admin` separada) | Admin é variação de usuário, não entidade distinta; mantém JOIN zero na autorização e simplifica o login (rota única `POST /usuarios/login`). |
| Reutilizar `POST /usuarios/login` para admin (não criar `POST /admin/login`) | Evita duplicação de lógica (rate limiter, refresh token, argon2). Diferenciação acontece pelo `papel` no payload JWT. |
| `adminGuard` encadeando `authGuard` (não como guard independente) | Reaproveita validação de token já testada; admin precisa **também** ser um usuário autenticado válido. |
| Opção A de status (reutilizar `ativo BOOLEAN`) como default | Zero migrations além do `papel`; menor risco de quebrar dados em produção. Opção B fica registrada como caminho se a semântica exigir. |
| `/admin/users` lista **todos** os hóspedes (sem filtro de status na query) | UI se encarrega do filtro visual e da busca; API mantém-se simples. Paginação via `?limit`/`?offset` opcional. |
| Seed de admin via script dedicado (não inline no `init_master.sql`) | Permite executar em qualquer ambiente sem recriar o DB; idempotente via `ON CONFLICT DO NOTHING`. |

### Frontend

| Decisão | Justificativa |
|---------|---------------|
| Dois providers separados (`adminUsersProvider` + `adminHotelsProvider`) em vez de um unificado | Endpoints distintos e ciclos de invalidação independentes — alterar status de um usuário não reinvalida lista de hotéis. Mesmo princípio de `my_rooms` e `host_profile`. |
| `AsyncNotifier` com `Completer` adaptando callbacks do service | Manter consistência 1:1 com `host_profile_provider.dart` facilita code review e evita divergência de padrão Riverpod entre features. |
| Busca com debounce de 300ms in-memory (sem endpoint `?q=`) | Escala da apresentação comporta lista local; evita requisições por tecla. Dívida técnica registrada (ver Riscos). |
| `TextEditingController` compartilhado no `State` da page | Requisito #16 do PRD: termo de busca persiste entre abas. |
| **Sem fallback mock — dependência dura do backend (Fase 1)** | Mocks mascaram falhas reais e criam risco de código fake em produção. Feature só entra em produção quando Fase 1 estiver em staging; erros em runtime viram estado de erro com retry. |
| Bottom sheet para "Editar" em vez de página dedicada | Ação limitada (alternar status) não justifica rota nova; bottom sheet mantém contexto da lista. |
| Rota `/admin/accounts` dentro do `ShellRoute` | Padrão das outras rotas admin (`/profile/admin`, `/profile/admin/edit`) — mantém `MainLayout` e bottom nav consistentes. |
| Reutilizar `GET /api/usuarios/me` (com `papel` adicionado na Fase 1) | Endpoint já retorna dados do usuário autenticado; criar `/admin/me` duplicaria lógica sem ganho. |
| Atualização otimista + rollback em `PATCH` de status | Evita "freeze" visual após clique; reverte chip + snackbar de erro se `PATCH` falhar. |
| Guard de papel no `redirect` global (não por rota) | Centraliza a regra `auth.papel == 'admin'` em um único ponto, como já é feito para rotas protegidas via lista `protectedRoutes`. |

---

## Contratos de API

### Fase 1 — Endpoints novos

| Método | Rota | Body | Response | Middleware |
|--------|------|------|----------|------------|
| GET | `/admin/users` | — | `{ users: AdminUser[] }` | `adminGuard` |
| PATCH | `/admin/users/:id` | `{ status: 'ativo' \| 'suspenso' }` | `{ user: AdminUser }` | `adminGuard` |
| GET | `/admin/hotels` | — | `{ hotels: AdminHotel[] }` | `adminGuard` |
| PATCH | `/admin/hotels/:id` | `{ status: 'ativo' \| 'inativo' }` | `{ hotel: AdminHotel }` | `adminGuard` |

### Fase 1 — Endpoints modificados

| Método | Rota | Mudança |
|--------|------|---------|
| POST | `/usuarios/login` | Payload JWT passa a incluir `papel`; response passa a incluir `papel` |
| GET | `/api/usuarios/me` | Response passa a incluir `papel` |
| POST | `/usuarios/refresh` | Novo token emitido mantém `papel` no payload |

### Parâmetros de paginação (opcional, recomendado)

Endpoints `GET /admin/users` e `GET /admin/hotels` aceitam `?limit=<int>` (default 100, max 500) e `?offset=<int>` (default 0). UI do MVP ignora, mas contrato reserva.

**Autenticação:** todas via Bearer JWT no header (interceptor `DioClient` aplica automaticamente).
**Autorização:** `adminGuard` → `403 Forbidden` para papel ≠ `admin`; `authGuard` → `401` para token ausente/inválido/expirado.
**Erros previstos no front:** `401` (token expirado → interceptor força logout), `403` (papel inválido → exibe erro + botão voltar), `404`/`500`/timeout (exibe estado de erro na UI com botão "Tentar novamente" — nunca cai em dados fictícios).

---

## Modelos de Dados

### Backend — Schema

```sql
-- Migration: NNN_add_papel_to_usuario.sql
ALTER TABLE usuario
  ADD COLUMN papel VARCHAR(20) NOT NULL DEFAULT 'usuario'
  CHECK (papel IN ('usuario', 'admin'));

-- Seed idempotente (script separado)
INSERT INTO usuario (nome_completo, email, senha, cpf, data_nascimento, papel, ativo)
VALUES ('Admin Reserva Aqui', '<email-admin>', '<hash-argon2>', '<cpf>', '<data>', 'admin', true)
ON CONFLICT (email) DO NOTHING;
```

Campo `status` **não** é coluna nova no schema (Opção A). A serialização traduz `ativo BOOLEAN` para os valores esperados pelo contrato.

### Backend — Shape dos responses

```
AdminUser (shape do JSON retornado por GET /admin/users)
{
  id: string (uuid)
  nome: string
  email: string
  telefone: string | null
  fotoUrl: string | null
  status: 'ativo' | 'suspenso'
  criadoEm: string (ISO-8601)
}

AdminHotel (shape do JSON retornado por GET /admin/hotels)
{
  id: string (uuid)
  nome: string
  emailResponsavel: string
  capaUrl: string | null
  status: 'ativo' | 'inativo'
  totalQuartos: number | null
  criadoEm: string (ISO-8601)
}

JWT payload (após Fase 1)
{
  user_id: string
  email: string
  papel: 'usuario' | 'admin'
}
```

### Frontend — Models (Dart)

```
enum AdminAccountStatus { ativo, suspenso, inativo }

AdminUserModel {
  id: String
  nome: String
  email: String
  telefone: String?
  fotoUrl: String?
  status: AdminAccountStatus   // ativo | suspenso
  criadoEm: DateTime
}

AdminHotelModel {
  id: String
  nome: String
  emailResponsavel: String
  capaUrl: String?
  status: AdminAccountStatus   // ativo | inativo
  totalQuartos: int?
  criadoEm: DateTime
}

AdminProfileState {
  nome: String
  email: String
  telefone: String?
  departamento: String?        // opcional — só se backend retornar
  permissoes: List<String>?    // opcional — só se backend retornar
}
```

**Convenções de `fromJson`:**
- Campos opcionais ausentes → `null` (não throw).
- `status` com valor desconhecido → default `ativo` + log de warning.
- `criadoEm` aceita ISO-8601; fallback `DateTime.now()` em caso de parse error + log.

---

## Dependências

### Fase 1 — Backend

**Bibliotecas (já no `package.json` do backend):**

- [x] `express` — roteamento
- [x] `jsonwebtoken` — JWT sign/verify
- [x] `argon2` — hash de senha do admin seedado
- [x] `pg` — queries ao Postgres

**Infra:**

- [ ] Migration do campo `papel` aplicada em staging e produção
- [ ] Script de seed executado em staging antes do início da Fase 2
- [ ] Credencial do admin seedado documentada no repo (arquivo `.env.example` ou README de staging)

### Fase 2 — Frontend

**Bibliotecas** (todas já no `pubspec.yaml` — nenhuma nova):

- [x] `flutter_riverpod` — providers e estado reativo
- [x] `go_router` — navegação e rotas protegidas
- [x] `dio` (via `DioClient`) — HTTP com interceptor Bearer

**Dependências de outras features / código existente:**

- [x] `auth_notifier.dart` — fornece token e papel do admin autenticado (consumirá o novo campo `papel` vindo do JWT da Fase 1)
- [x] `DioClient` / `dioProvider` — interceptor de auth já configurado
- [x] `host_profile_provider.dart` — referência 1:1 para `adminProfileProvider`
- [x] `my_rooms_page.dart` — referência de layout (busca + lista + cards com status)
- [x] `profile_header.dart` e `profile_menu_item.dart` — widgets já usados pela `AdminProfilePage`
- [ ] Guard de papel admin no `redirect` do `app_router.dart` — atualmente só protege `/profile`, `/tickets`, `/favorites`; precisa estender para `/admin/*`

### Ordem de entrega

1. **Fase 1 completa em staging** — migration aplicada, seed executado, endpoints respondendo, login do admin emitindo JWT com `papel`.
2. Só então a Fase 2 (frontend) pode começar a ser implementada e testada contra o staging.

---

## Riscos Técnicos

### Fase 1 — Backend

| Risco | Mitigação |
|-------|-----------|
| Migration do campo `papel` quebrar dados existentes | Default `'usuario'` garante que todos os usuários atuais continuem válidos; CHECK constraint impede valores inválidos. Testar migration em cópia do staging antes de aplicar. |
| Credencial do admin seedado vazar para repositório público | Documentar o admin como credencial de apresentação/desenvolvimento no `.env.example`; usar email e senha não reutilizáveis em outros contextos; rotacionar se necessário. |
| JWT antigos (sem `papel`) circulando após deploy | `authGuard` deve aceitar JWT sem `papel` tratando como `'usuario'` (fallback seguro — admin sempre requer token novo após migration). Refresh token emite payload novo automaticamente. |
| Decisão A vs B de status não tomada a tempo | Default documentado (Opção A); se produto não se manifestar, implementar Opção A. Opção B fica registrada como caminho de evolução. |
| `adminGuard` deixar passar request sem `authGuard` por engano | `adminGuard` deve **chamar `authGuard` internamente** (encadeamento explícito), não assumir que o chamador fez antes; teste unitário cobre o caso de bypass. |

### Fase 2 — Frontend

| Risco | Mitigação |
|-------|-----------|
| Fase 1 não estar completa quando Fase 2 for iniciada | Gate explícito: PR da Fase 2 só abre depois que a Fase 1 estiver em staging e um admin conseguir logar e chamar `GET /admin/users` com sucesso via curl. |
| Admin não autenticado ou com papel errado acessando `/admin/accounts` por deep-link | Estender `redirect` global do `app_router.dart` exigindo `auth.papel == 'admin'` em `/admin/*`; redireciona para `/auth/login` ou `/home`. Autoridade real fica no `adminGuard` do backend. |
| Backend cair ou demorar a responder durante a demonstração | Loading com timeout, estado de erro com "Tentar novamente". Garantir staging estável antes da apresentação. |
| Listas crescerem demais para filtro in-memory | Limite pragmático MVP: ~500 contas. Acima disso migrar para busca server-side com `?q=`. Dívida técnica registrada. |
| Estado visual do chip divergir do real após `PATCH` falhar | Estratégia otimista: atualiza localmente antes do `PATCH`; reverte + snackbar em caso de erro. |
| `Future.delayed` mock esquecido em produção no `EditAdminProfilePage` | Checklist explícito de "remover mocks" no PR da Fase 2b; critério de aceitação cobre persistência real. |
| Inconsistência de dark mode (repetir `AppColors.backgroundLight` fixo) | Revisão específica de todos os usos de `AppColors.*Light` nas páginas admin; substituir por `Theme.of(context).colorScheme.surface/background`. |
| Logout do admin com estado residual (bug atual: `context.go('/auth')` sem limpar `authProvider`) | Corrigir no mesmo PR da Fase 2b: `ref.read(authProvider.notifier).clear()` antes de `context.go('/auth/login')` — alinha ao fix já aplicado em user/host (commit `e32c6c0`). |
| Divergência futura entre `admin_profile_provider` e `host_profile_provider` | PR da Fase 2b deve ser revisado com `host_profile_provider.dart` aberto lado a lado para garantir paridade de estrutura. |
