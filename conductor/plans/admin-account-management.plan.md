# Plan — admin-account-management

> Derivado de: `conductor/specs/admin-account-management.spec.md`
> PRD: `conductor/features/admin-account-management.plan.md` *(ver `conductor/features/admin-account-management.prd.md`)*
> Bundle: P6-C (Admin Account Management) + P6-E (Admin Profile Integration)
> Status geral: [EM ANDAMENTO] — Setup, Backend e Frontend prontos; Validação transversal pendente de teste manual em navegador/device.
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

## Frontend [CONCLUÍDO]

> ✅ **Gate passou:** migration aplicada, seed executado, admin loga com `papel: 'admin'` no JWT, `GET /admin/users` → 200 via curl. Fase 2 executada em cima disso.

### Auth foundation (gap descoberto além do escopo inicial)

- [x] **`AuthRole` estendido** para incluir `admin` em `auth_state.dart`. Até então só existiam `guest`/`host`.
- [x] `AuthResponse.fromJson` agora parseia `data.papel` do response do login.
- [x] `LoginPage` detecta `papel == 'admin'` e seta `AuthRole.admin`; redireciona admin direto para `/profile/admin` em vez de `/home`.
- [x] `MainLayout._navigateToProfile` switch-case cobrindo `AuthRole.admin` → `/profile/admin`.
- [x] `fcm_token_service`, `dio_client` (refresh) e `auth_notifier` (logout) continuam funcionando corretamente — admin cai no caminho de usuário (não host).

### Domain layer (models)

- [x] `lib/features/profile/domain/models/admin_account_status.dart` — enum com `fromString` tolerante.
- [x] `lib/features/profile/domain/models/admin_user_model.dart` + `fromJson` resiliente.
- [x] `lib/features/profile/domain/models/admin_hotel_model.dart` + `fromJson` resiliente.
- [x] `lib/features/profile/domain/models/admin_profile_state.dart` + `copyWith`.

### Data layer (service)

- [x] `lib/features/profile/data/services/admin_accounts_service.dart` — `getUsers`, `getHotels`, `updateUserStatus`, `updateHotelStatus`, com suporte a `limit`/`offset` e provider Riverpod.

### Providers

- [x] `admin_profile_provider.dart` — `AsyncNotifier<AdminProfileState>` espelhando padrão de `host_profile_provider.dart` com `Completer`; `updateProfile` e `changePassword`.
- [x] `admin_users_provider.dart` — `AsyncNotifier<List<AdminUserModel>>` com `updateStatus` otimista + rollback em caso de erro + `refresh()`.
- [x] `admin_hotels_provider.dart` — análogo para hotéis.

### Widgets reutilizáveis

- [x] `admin_account_status_chip.dart` — chip colorido por status (ativo verde, suspenso vermelho, inativo cinza) com `withValues(alpha:)`.
- [x] `admin_user_card.dart` — avatar com initials fallback, nome, email, chip, botão editar.
- [x] `admin_hotel_card.dart` — thumbnail com fallback, nome, email responsável, chip, botão editar.
- [x] `admin_edit_account_sheet.dart` — bottom sheet modal com opções de status permitidas por tipo de conta, botão Salvar desabilitado se não houver mudança.

### Página principal — P6-C

- [x] `admin_account_management_page.dart` — `ConsumerStatefulWidget` com `TabController` (2 abas), `TextEditingController` compartilhado com debounce de 300ms via `Timer`.
- [x] Filtro in-memory por nome e email; termo persiste ao trocar de aba (requisito #16 PRD).
- [x] Loading (`CircularProgressIndicator`), erro (com retry), vazio (distingue lista totalmente vazia de filtro sem resultado), pull-to-refresh.
- [x] Bottom sheet de edição dispara `updateStatus` com snackbars de sucesso/erro; rollback automático via provider em falhas.

### Integração do perfil admin — P6-E

- [x] `admin_profile_page.dart` convertido para `ConsumerWidget`, consumindo `adminProfileProvider` no `ProfileHeader`.
- [x] Item "Clientes" liga para `context.push('/admin/accounts')`.
- [x] Botão "sair" agora: `await ref.read(authProvider.notifier).clear()` + `context.go('/auth/login')`.
- [x] `AppColors.backgroundLight` substituído por `Theme.of(context).colorScheme.surface` em ambas páginas admin.
- [x] `edit_admin_profile_page.dart` convertido para `ConsumerStatefulWidget`, pré-preenchendo campos via provider (flag `_prefilled` evita sobrescrever edições).
- [x] `Future.delayed` removido — `updateProfile` chama `PATCH /api/v1/usuarios/me` via `adminProfileProvider.notifier`; troca de senha dispara `changePassword` opcionalmente.
- [x] Validação mock `value != '123456'` removida — validação real agora é server-side.

### Roteamento

- [x] `GoRoute('/admin/accounts')` registrada fora do `ShellRoute` (padrão de `MyRoomsPage` — sem bottom nav) apontando para `AdminAccountManagementPage`.
- [x] `redirect` global estendido: paths `/admin/*` e `/profile/admin*` exigem autenticação + `auth.role == AuthRole.admin`, caso contrário redireciona para `/auth/login` ou `/home`.

### Validação

- [x] `flutter analyze` — 0 errors, 0 warnings relevantes (39 infos, 2 do código novo são deprecations informativas do Flutter 3.32+ em `RadioListTile.groupValue/onChanged`, 37 são pré-existentes em outros arquivos).
- [x] `flutter build web` — compilação limpa em 42s. Zero erros de link.

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
