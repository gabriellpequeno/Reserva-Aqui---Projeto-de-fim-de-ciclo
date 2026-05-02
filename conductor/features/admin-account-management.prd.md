# PRD — admin-account-management

> Bundle: P6-C (Admin Account Management) + P6-E (Admin Profile Integration)
> Entrega em **duas fases sequenciais**: **Fase 1 — Backend** (pré-requisito bloqueante) → **Fase 2 — Frontend** (P6-C + P6-E). Nenhum trabalho de Fase 2 começa antes da Fase 1 estar mergeada e disponível em staging com admin seedado.

---

## Contexto

O papel de **admin** existe nominalmente no frontend (`AuthNotifier` reconhece o campo `papel`, há uma `AdminProfilePage` navegável), mas **não existe no backend**: nem a tabela `usuario` tem coluna de papel, nem o JWT carrega essa informação, nem há rotas/middleware/endpoints específicos para admin. Todo o fluxo admin que aparece hoje é ficção — inclusive o `admin@admin.com` hardcoded na UI.

Além disso, mesmo no frontend a feature está incompleta:

- O item "Clientes" da `AdminProfilePage` é um `onTap: () {}` vazio — não há tela para gerenciar cadastros de hóspedes e hotéis.
- `AdminProfilePage` e `EditAdminProfilePage` exibem dados hardcoded, com save por `Future.delayed`.
- O botão "sair" do admin usa `context.go('/auth')` sem limpar `authProvider`, deixando estado residual após logout.

Esta feature entrega o papel admin **funcional de ponta a ponta** para a apresentação final, construindo primeiro o backend que falta (Fase 1) e em seguida combinando a tela de gerenciamento de contas (P6-C) com a integração real do perfil admin (P6-E) no frontend (Fase 2).

---

## Problema

1. **Backend sem conceito de admin:** não há coluna `papel`, middleware `adminGuard`, rotas `/admin/*`, nem admin seedado. Qualquer funcionalidade admin no frontend fica sem correspondente real no servidor.
2. **Gestão de cadastros inexistente no frontend:** sem UI, o admin não consegue visualizar, buscar ou ajustar contas de hóspedes e hotéis — impossibilitando moderação/suporte.
3. **Perfil admin mock:** o admin autenticado não vê seus próprios dados reais, quebrando a credibilidade do fluxo de autenticação.
4. **Logout inconsistente:** o estado de auth não é limpo ao sair, divergindo do comportamento já corrigido em host/user.

---

## Público-alvo

**Administradores da plataforma Reserva Aqui** — operadores internos com papel `admin`, responsáveis por:

- Moderar/suportar contas de hóspedes (usuários finais).
- Moderar/suportar cadastros de hotéis (hosts).
- Gerenciar o próprio perfil administrativo.

Não é público final nem host — é o papel interno previsto em `AuthNotifier`, mas que hoje não existe de fato no backend.

---

## Fases de Implementação

### Fase 1 — Backend (pré-requisito bloqueante)

Entrega tudo que é pré-requisito para o papel admin existir de verdade no servidor:

- Schema e migration do campo `papel` em `usuario` + seed de admin inicial.
- Inclusão do `papel` no payload JWT e no response de `/usuarios/me` e login.
- Middleware `adminGuard`.
- Decisão e implementação do modelo de status de conta (`ativo` / `suspenso` / `inativo`).
- Criação de todos os endpoints `/admin/*` (usuários e hotéis) com autorização via `adminGuard`.

Sem a Fase 1 mergeada, **a Fase 2 não começa**.

### Fase 2 — Frontend

Assim que a Fase 1 estiver disponível em staging com admin seedado e endpoints operacionais, começa a Fase 2:

- **Fase 2a — P6-C:** tela `/admin/accounts` com abas Usuários/Hotéis, busca, cards com status e ação de editar.
- **Fase 2b — P6-E:** integração real do perfil admin (`adminProfileProvider`), correção do logout, remoção dos mocks residuais.

---

## Requisitos Funcionais

### Fase 1 — Backend

**RF-B1 — Conceito de papel (role)**

1. Adicionar coluna `papel VARCHAR(20) NOT NULL DEFAULT 'usuario'` em `usuario` com `CHECK (papel IN ('usuario', 'admin'))`.
2. Seedar pelo menos um admin inicial (email + senha documentados no repo, marcados como credencial de apresentação).
3. Incluir `papel` no payload do JWT (alterar `jwt.sign(...)` em `usuario.controller.ts`) e no response do login.
4. Incluir `papel` no response de `GET /api/usuarios/me`.
5. Expor `req.userPapel` no `AuthRequest` do `authGuard.ts` a partir do payload do JWT.

**RF-B2 — Middleware de autorização admin**

6. Criar `Backend/src/middlewares/adminGuard.ts` que: executa `authGuard`, verifica `req.userPapel === 'admin'`, retorna `403 Forbidden` caso contrário.

**RF-B3 — Status de conta**

7. Decidir e implementar a estratégia de status (pendência de decisão do produto antes da implementação):
   - **Opção A (MVP):** reutilizar `ativo BOOLEAN` existente, mapeando na serialização (`true → 'ativo'`, `false → 'suspenso'` para usuário / `'inativo'` para hotel).
   - **Opção B (extensível):** adicionar coluna `status VARCHAR(20)` em `usuario` e `anfitriao` com CHECK constraint + backfill a partir de `ativo`.
8. O `PATCH` de status deve refletir imediatamente nas queries de listagem.

**RF-B4 — Endpoints admin**

9. `GET /admin/users` — lista todos os hóspedes. Response: `{ users: AdminUser[] }`. Protegido por `adminGuard`.
10. `PATCH /admin/users/:id` — atualiza status de um hóspede. Body: `{ status: 'ativo' | 'suspenso' }`. Response: `{ user: AdminUser }`. Protegido por `adminGuard`.
11. `GET /admin/hotels` — lista todos os hotéis. Response: `{ hotels: AdminHotel[] }`. Protegido por `adminGuard`.
12. `PATCH /admin/hotels/:id` — atualiza status de um hotel. Body: `{ status: 'ativo' | 'inativo' }`. Response: `{ hotel: AdminHotel }`. Protegido por `adminGuard`.
13. Todas as rotas registradas via `Backend/src/routes/admin.routes.ts` e montadas no bootstrap do Express.

### Fase 2a — Frontend: Gerenciamento de contas (P6-C)

14. O admin deve acessar a tela de gerenciamento via item "Clientes" da `AdminProfilePage`, navegando para `/admin/accounts`.
15. A tela deve exibir `AppBar` com título "Gerenciamento de Contas" + botão voltar e uma `TabBar` com duas abas: **Usuários** (hóspedes) e **Hotéis** (hosts).
16. O admin deve conseguir buscar por nome ou e-mail, com filtro em tempo real; o termo buscado deve ser preservado ao trocar de aba.
17. Cada card de usuário deve exibir avatar/initials fallback, nome completo, e-mail, chip de status (ativo/suspenso) e botão "Editar".
18. Cada card de hotel deve exibir thumbnail de capa, nome do hotel, e-mail/responsável, chip de status (ativo/inativo) e botão "Editar".
19. A listagem deve vir de `GET /admin/users` e `GET /admin/hotels`, com tratamento de loading e estado vazio.
20. O admin deve conseguir ajustar o status de usuários e hotéis via `PATCH /admin/users/:id` e `PATCH /admin/hotels/:id`.
21. A rota `/admin/accounts` deve ser registrada em `app_router.dart` apontando para `AdminAccountManagementPage` e protegida para `auth.papel == 'admin'`.

### Fase 2b — Frontend: Integração do perfil admin (P6-E)

22. Criar `adminProfileProvider` (Riverpod `AsyncNotifier`) em `lib/features/profile/presentation/providers/admin_profile_provider.dart`, com `AdminProfileState` contendo `nome`, `email`, `telefone` (opcionais: `departamento`, `permissoes`), consumindo `GET /api/usuarios/me`.
23. Converter `AdminProfilePage` de `StatelessWidget` para `ConsumerWidget`, consumindo `adminProfileProvider` para exibir nome e e-mail reais no `ProfileHeader`, com tratamento de loading, erro e retry.
24. Converter `EditAdminProfilePage` para `ConsumerStatefulWidget`, pré-preenchendo campos com dados do provider e persistindo via `PATCH /api/usuarios/me`; invalidar `adminProfileProvider` após save bem-sucedido.
25. Corrigir o botão "sair" para chamar `ref.read(authProvider.notifier).clear()` e redirecionar para `/auth/login`.
26. Remover validação mock de senha (`value != '123456'`) e `Future.delayed` do save.

---

## Requisitos Não-Funcionais

- [ ] **Segurança:** todas as rotas `/admin/*` protegidas por `adminGuard` no backend e por redirect/guard no frontend; chamadas autenticadas via Bearer JWT (interceptor `DioClient` já configurado).
- [ ] **Isolamento de autorização:** verificação de papel acontece em **duas camadas** — servidor (autoridade final) e cliente (UX); nunca só uma.
- [ ] **Performance (front):** busca com debounce (~300ms) para não disparar filtro a cada tecla; listas com `ListView.builder` lazy.
- [ ] **Performance (back):** queries de listagem com `LIMIT` default aceitando `?limit` e `?offset` (mesmo que a UI do MVP não use, o contrato prevê).
- [ ] **Acessibilidade:** chips de status com contraste adequado e labels semânticas; campos de formulário com `Semantics` e suporte a leitores de tela.
- [ ] **Responsividade:** funcionar em mobile e desktop (Flutter multiplataforma).
- [ ] **Dark Mode:** uso exclusivo de tokens semânticos do theme — zero uso de `AppColors.backgroundLight` fixo.
- [ ] **Consistência:** seguir o padrão Riverpod de `host_profile_provider.dart` / `user_profile_provider.dart` e a estrutura visual de `my_rooms_page.dart`.

---

## Critérios de Aceitação

### Fase 1 — Backend

- Dado que a migration do campo `papel` foi aplicada, quando `SELECT papel FROM usuario WHERE email = '<admin-seed>'` é executado, então retorna `'admin'`.
- Dado que o admin faz login em `POST /usuarios/login`, quando o token retornado é decodificado, então contém `{ user_id, email, papel: 'admin' }`.
- Dado que um usuário comum (papel `'usuario'`) chama qualquer rota `/admin/*`, então recebe `403 Forbidden`.
- Dado que um admin autenticado chama `GET /admin/users`, então recebe a lista real de hóspedes com `id`, `nome`, `email`, `status` e `criado_em`.
- Dado que um admin autenticado chama `PATCH /admin/users/:id` com `{ status: 'suspenso' }`, então a conta é marcada como suspensa e o retorno reflete o novo status.
- Dado que um admin autenticado chama `GET /admin/hotels`, então recebe a lista real de hotéis com `id`, `nome`, `email`, `status` e `criado_em`.
- Dado que um admin autenticado chama `PATCH /admin/hotels/:id` com `{ status: 'inativo' }`, então o hotel é marcado como inativo.
- Dado que um admin chama `GET /api/usuarios/me`, então o response contém `papel: 'admin'`.

### Fase 2a — Frontend: Gerenciamento de contas

- Dado que o admin está na `AdminProfilePage`, quando toca em "Clientes", então é navegado para `/admin/accounts`.
- Dado que a tela `/admin/accounts` abriu, quando o backend responde, então a aba "Usuários" exibe a lista de hóspedes e a aba "Hotéis" exibe a lista de hotéis — dados 100% reais.
- Dado que o admin digita no campo de busca, quando há correspondência em nome ou e-mail, então apenas os cards correspondentes permanecem visíveis em tempo real.
- Dado que o admin aplicou um filtro de busca, quando troca de aba, então o termo buscado persiste e a nova aba já é filtrada.
- Dado que o admin toca em "Editar" em um card, quando confirma uma mudança de status, então o `PATCH` correspondente é chamado e a lista é atualizada.
- Dado que a listagem retorna vazia, quando a tela renderiza, então um estado vazio claro é exibido (não erro).
- Dado que o backend retorna erro ou timeout, quando a tela tenta carregar, então um estado de erro com botão "Tentar novamente" é exibido — nunca dados fictícios.

### Fase 2b — Frontend: Perfil admin

- Dado que o admin está autenticado, quando acessa `AdminProfilePage`, então o `ProfileHeader` exibe o nome e e-mail reais (não `admin@admin.com`).
- Dado que o admin está em `EditAdminProfilePage`, quando submete o formulário com dados válidos, então `PATCH /api/usuarios/me` é chamado, o provider é invalidado e os novos dados aparecem ao voltar.
- Dado que o admin toca em "Sair", quando confirma, então `authProvider` é limpo e o app navega para `/auth/login`.
- Dado o tema do sistema em dark mode, quando as telas admin são renderizadas, então todas as cores vêm de tokens semânticos e não há cor fixa de modo claro.

---

## Fora de Escopo

- Criação de novas contas admin via UI (o admin seed da Fase 1 é suficiente para a apresentação; criação de novos admins fica para fase futura).
- Exclusão permanente de contas (apenas ativar/suspender via status).
- Logs de auditoria de ações do admin.
- Filtros avançados além de busca por nome/e-mail (ex: por data de criação, por status, por cidade).
- Paginação com cursor infinito (query params `?limit`/`?offset` existem no contrato, mas UI do MVP usa lista simples).
- Notificações push/e-mail para o usuário/hotel quando o status for alterado.
- Exportação de relatórios (CSV, PDF).
- Gestão de permissões granulares do admin (roles múltiplos).
- Rota `POST /admin/login` dedicada (admin reutiliza `POST /usuarios/login` diferenciado por `papel`).
- Uso de dados mockados em qualquer momento (decisão explícita do produto: todos os dados exibidos vêm do backend real).
