# Plan — admin-account-management

> Derivado de: `conductor/specs/admin-account-management.spec.md`
> PRD: `conductor/features/admin-account-management.plan.md` *(ver `conductor/features/admin-account-management.prd.md`)*
> Bundle: P6-C (Admin Account Management) + P6-E (Admin Profile Integration)
> Status geral: [PENDENTE]
>
> **Ordem de execução:** Setup → Backend (Fase 1 completa em staging) → Frontend (Fase 2) → Validação.
> **Gate bloqueante:** nenhuma task de Frontend pode iniciar antes de o admin seedado conseguir logar e chamar `GET /admin/users` via curl em staging.

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Criar arquivo de migration `Backend/database/scripts/migrations/001_add_papel_to_usuario.sql` (`ALTER TABLE usuario ADD COLUMN papel VARCHAR(20) NOT NULL DEFAULT 'usuario' CHECK (papel IN ('usuario', 'admin'))` + índice parcial em `papel='admin'`).
- [x] Atualizar `Backend/database/scripts/init_master.sql` para incluir a coluna `papel` + índice na criação inicial da tabela `usuario`.
- [x] Criar `Backend/src/database/seeds/seed.admin.ts` idempotente (`ON CONFLICT (email) DO NOTHING`) com hash argon2. Inclui promoção automática se email já existir com papel diferente. Registrado no orquestrador `seeds/index.ts` como primeiro seed.
- [x] Documentar credenciais do admin seedado no `.env.example` (`ADMIN_SEED_EMAIL`, `ADMIN_SEED_SENHA`, etc.) marcadas como credencial de apresentação/desenvolvimento.
- [x] Migration aplicada em dev local (via `psql -f 001_add_papel_to_usuario.sql`) — coluna, CHECK e índice parcial confirmados em `\d usuario`.
- [x] `seed.admin.ts` executado — admin `admin@reservaqui.dev` criado com `papel='admin'`.
- [x] Registrar o `admin.routes.ts` no bootstrap do Express (`Backend/src/app.ts`) via `app.use(\`${API_PREFIX}/admin\`, adminRoutes)` — endpoint final: `/api/v1/admin/*`.

---

## Backend [CONCLUÍDO]

### Autorização (base para tudo)

- [x] Atualizar `Backend/src/middlewares/authGuard.ts`: adicionado `userPapel?: UserPapel` em `AuthRequest`; extrai `papel` do payload com fallback seguro `'usuario'` para tokens antigos.
- [x] Criar `Backend/src/middlewares/adminGuard.ts`: chama `authGuard` internamente, verifica `req.userPapel === 'admin'`, retorna `403` caso contrário.
- [x] Testes unitários em `src/middlewares/__tests__/adminGuard.test.ts` — 5 cenários cobertos (sem token → 401, token inválido → 401, papel usuario → 403, token legado sem papel → 403, papel admin → next). **5/5 passando.**

### Login, refresh e `/me`

- [x] `signAccessToken` em `usuario.service.ts` agora aceita/inclui `papel` no payload JWT.
- [x] Response do login (`loginUsuarioController`) inclui `papel` via `UsuarioSafe.papel` retornado pelo service.
- [x] `refreshUsuarioToken` relê `papel` do DB e o inclui no novo token emitido (abordagem: sempre fonte de verdade no DB, não no payload antigo).
- [x] `getUsuarioById` (usado pelo `getMeController`) retorna `papel` via `UsuarioSafe`.

### Módulo admin — service layer

- [x] Criar `Backend/src/services/admin.service.ts` com `listUsers`, `listHotels`, `setUserStatus`, `setHotelStatus` + DTOs `AdminUserDTO`/`AdminHotelDTO` + paginação `?limit`/`?offset` (default 100, max 500). Seguindo padrão `src/services/` do projeto (não `modules/`).
- [x] Serialização Opção A: `ativo=true ↔ 'ativo'`, `ativo=false ↔ 'suspenso'` (usuário) / `'inativo'` (hotel).
- [x] Bonus: `setUserStatus/setHotelStatus` revoga refresh tokens ativos quando a conta é suspensa/inativada (invalidação de sessão imediata).

### Módulo admin — controllers

- [x] Criar `Backend/src/controllers/admin.controller.ts` com `listUsersController`, `updateUserStatusController`, `listHotelsController`, `updateHotelStatusController`.
- [x] Validação do body: `requireFields('status')` + whitelist por tipo (`VALID_USER_STATUS`/`VALID_HOTEL_STATUS`). `PATCH /users/:id { status: 'inativo' }` → 400.
- [x] Responses no shape da spec: `{ users }`, `{ user }`, `{ hotels }`, `{ hotel }`.

### Módulo admin — routes

- [x] `Backend/src/routes/admin.routes.ts` com as 4 rotas protegidas por `adminGuard` + `requireFields('status')` nos PATCH.
- [x] Montado no `app.ts` como `app.use(\`${API_PREFIX}/admin\`, adminRoutes)` → endpoints finais: `/api/v1/admin/users`, `/api/v1/admin/hotels` (com `API_PREFIX=/api/v1`).

### Testes de integração

- [x] `src/routes/__tests__/admin.routes.test.ts` — 14 testes cobrindo: 401 sem token, 403 com usuário comum, 200 com admin, forward de `limit/offset`, 400 sem body, 400 status inválido, 200 PATCH válido, 404 "não encontrado", simétrico para `/hotels`. **14/14 passando.**

**Verificação final:** suíte completa — `Tests: 43 passed, 5 failed, 48 total`. Os 5 failures são pré-existentes em `whatsappWebhook.service.test.ts` e `searchRoom.routes.test.ts` (confirmado via `git stash`), não relacionados a este trabalho.

---

## Frontend [PENDENTE]

> ⛔ **Gate:** só iniciar após staging confirmar: migration aplicada, seed executado, admin loga com `papel: 'admin'` no JWT, e `GET /admin/users` retorna 200 via curl.

### Auth integration

- [ ] Verificar/atualizar `lib/core/auth/auth_notifier.dart` para expor `papel` no estado de auth, consumindo o campo vindo do response do login e de `/usuarios/me`.

### Domain layer (models)

- [ ] Criar `lib/features/profile/domain/models/admin_account_status.dart` com `enum AdminAccountStatus { ativo, suspenso, inativo }`.
- [ ] Criar `lib/features/profile/domain/models/admin_user_model.dart` com `AdminUserModel` + `fromJson` tolerante (campos opcionais → null; status desconhecido → default `ativo` + log).
- [ ] Criar `lib/features/profile/domain/models/admin_hotel_model.dart` com `AdminHotelModel` + `fromJson` tolerante.
- [ ] Criar `lib/features/profile/domain/models/admin_profile_state.dart` com `AdminProfileState` + `copyWith`.

### Data layer (service)

- [ ] Criar `lib/features/profile/data/services/admin_accounts_service.dart` com `getUsers()`, `getHotels()`, `updateUserStatus(id, status)`, `updateHotelStatus(id, status)` — usando `DioClient` via `dioProvider`.

### Providers

- [ ] Criar `lib/features/profile/presentation/providers/admin_profile_provider.dart` espelhando 1:1 o padrão de `host_profile_provider.dart` (`AsyncNotifier<AdminProfileState>` + `Completer` + `updateProfile(diff)`).
- [ ] Criar `lib/features/profile/presentation/providers/admin_users_provider.dart` — `AsyncNotifier<List<AdminUserModel>>` com `updateStatus(id, newStatus)` usando atualização otimista + rollback em caso de erro.
- [ ] Criar `lib/features/profile/presentation/providers/admin_hotels_provider.dart` — análogo para hotéis.

### Widgets reutilizáveis

- [ ] Criar `lib/features/profile/presentation/widgets/admin_account_status_chip.dart` — chip colorido por status (tokens semânticos do theme).
- [ ] Criar `lib/features/profile/presentation/widgets/admin_user_card.dart` — avatar/initials fallback, nome, e-mail, chip de status, botão "Editar".
- [ ] Criar `lib/features/profile/presentation/widgets/admin_hotel_card.dart` — thumbnail de capa, nome do hotel, e-mail/responsável, chip de status, botão "Editar".
- [ ] Criar `lib/features/profile/presentation/widgets/admin_edit_account_sheet.dart` — bottom sheet com alternar status, botões cancelar/confirmar.

### Página principal — P6-C

- [ ] Criar `lib/features/profile/presentation/pages/admin_account_management_page.dart` como `ConsumerStatefulWidget` com `TabController` (2 abas) e `TextEditingController` compartilhado.
- [ ] Implementar filtro in-memory por nome/e-mail com debounce de 300ms; termo persiste ao trocar de aba.
- [ ] Implementar estados de loading, erro (com retry) e vazio (distinguir lista vazia de filtro vazio).
- [ ] Integrar `AdminEditAccountSheet` ao toque no botão "Editar" de cada card.

### Integração do perfil admin — P6-E

- [ ] Refatorar `lib/features/profile/presentation/pages/admin_profile_page.dart` para `ConsumerWidget`; consumir `adminProfileProvider` no `ProfileHeader`; ligar item "Clientes" → `context.push('/admin/accounts')`.
- [ ] Corrigir botão "sair" em `admin_profile_page.dart`: `ref.read(authProvider.notifier).clear()` seguido de `context.go('/auth/login')`.
- [ ] Substituir `AppColors.backgroundLight` fixo em `admin_profile_page.dart` por `Theme.of(context).colorScheme.surface/background` (tokens semânticos).
- [ ] Refatorar `lib/features/profile/presentation/pages/edit_admin_profile_page.dart` para `ConsumerStatefulWidget`; pré-preencher campos via `adminProfileProvider`.
- [ ] Substituir `Future.delayed` mock em `edit_admin_profile_page.dart` por chamada real `PATCH /api/usuarios/me`; invalidar `adminProfileProvider` após save bem-sucedido.
- [ ] Remover validação mock de senha (`value != '123456'`) em `edit_admin_profile_page.dart`.
- [ ] Auditar e substituir qualquer uso residual de `AppColors.*Light` nas páginas admin por tokens semânticos.

### Roteamento

- [ ] Atualizar `lib/core/router/app_router.dart`: registrar `GoRoute('/admin/accounts')` dentro do `ShellRoute` apontando para `AdminAccountManagementPage`.
- [ ] Estender `redirect` do `app_router.dart` para proteger `/admin/*` exigindo `auth.papel == 'admin'`; redirecionar para `/auth/login` (não autenticado) ou `/home` (autenticado com papel errado).

---

## Validação [PENDENTE]

### Fase 1 — Backend (gate antes da Fase 2) [CONCLUÍDO]

- [x] `SELECT papel FROM usuario WHERE email = 'admin@reservaqui.dev'` retorna `'admin'`.
- [x] `POST /api/v1/usuarios/login` com credenciais do admin → response contém `papel: 'admin'` e JWT decodificado contém `{ user_id, email, papel: 'admin' }`.
- [x] `GET /api/v1/usuarios/me` autenticado como admin → response contém `papel: 'admin'`.
- [x] `GET /api/v1/admin/users` autenticado como admin → **200** + lista real com `status` serializado (ativo/suspenso).
- [x] `GET /api/v1/admin/users` sem token → **401**.
- [x] `GET /api/v1/admin/users` autenticado como usuário comum → **403** (coberto pelos testes de integração; não testado via curl por não ter senha de usuário comum em dev).
- [x] `PATCH /api/v1/admin/users/:id` com `{ status: 'suspenso' }` → 200 + response com `status: 'suspenso'`; restaurado depois com `{ status: 'ativo' }`.
- [x] `PATCH /api/v1/admin/users/:id` com `{ status: 'inativo' }` → 400 (`inativo` só vale para hotel — whitelist funcionando).
- [x] `GET /api/v1/admin/hotels` autenticado como admin → 200 + lista real de hotéis com `status: 'ativo'`.
- [x] Testes unitários de `adminGuard` passam (5 cenários — suíte 5/5).
- [x] Testes de integração dos endpoints admin passam (14 testes — suíte 14/14).

### Fase 2a — Frontend: Gerenciamento de contas

- [ ] Admin logado em `AdminProfilePage` toca "Clientes" → navega para `/admin/accounts`.
- [ ] Aba "Usuários" exibe a lista real de hóspedes carregada via `GET /admin/users`.
- [ ] Aba "Hotéis" exibe a lista real de hotéis carregada via `GET /admin/hotels`.
- [ ] Digitar no campo de busca filtra em tempo real por nome e e-mail.
- [ ] Termo de busca persiste ao trocar de aba e a nova aba já aparece filtrada.
- [ ] Toque em "Editar" em um card abre bottom sheet; confirmar mudança de status → `PATCH` chamado, chip atualiza otimisticamente, lista é refletida.
- [ ] Forçar erro 500 no backend → UI exibe estado de erro com botão "Tentar novamente" — zero dados fictícios.
- [ ] Lista vazia → estado vazio claro (não erro).
- [ ] Filtro sem resultado → estado "Nenhum resultado" (não erro).
- [ ] Usuário comum tentando acessar `/admin/accounts` via deep link → redirect para `/home`.
- [ ] Usuário não autenticado tentando acessar `/admin/accounts` via deep link → redirect para `/auth/login`.

### Fase 2b — Frontend: Perfil admin

- [ ] Admin logado vê nome e e-mail reais no `ProfileHeader` (não `admin@admin.com`).
- [ ] Admin edita perfil em `EditAdminProfilePage` → `PATCH /api/usuarios/me` chamado; ao voltar, `AdminProfilePage` mostra dados atualizados.
- [ ] Toque em "Sair" → `authProvider` limpo + redirect para `/auth/login`; entrar de novo não mostra dados do usuário anterior.
- [ ] Validação mock `value != '123456'` removida (testar com qualquer senha válida).

### Validação transversal

- [ ] Dark mode: todas as páginas admin (`AdminProfilePage`, `EditAdminProfilePage`, `AdminAccountManagementPage`) usam apenas tokens semânticos — nenhum `AppColors.*Light` fixo visível no modo escuro.
- [ ] Responsividade: telas funcionam em mobile (Android/iOS) e desktop.
- [ ] Acessibilidade: chips de status, cards e campos de formulário navegáveis via leitor de tela com labels semânticas.
- [ ] Lista com até ~500 contas ainda responde fluidamente ao filtro in-memory (acima disso, registrar dívida técnica de busca server-side).

---

## Regra de Atualização de Status

- Todas `[ ]` → `[PENDENTE]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`

Quando todas as seções estiverem `[CONCLUÍDO]`, atualize o **Status geral** para `[CONCLUÍDO]` e sincronize com `conductor/plan.md` (localizar bloco da feature ou criar nova fase ao final com status `[CONCLUÍDO]`).
