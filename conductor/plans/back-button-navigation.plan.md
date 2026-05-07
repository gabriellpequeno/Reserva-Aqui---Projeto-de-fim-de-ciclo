# Plan — Back Button Navigation

> Derivado de: conductor/specs/back-button-navigation.spec.md
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Executar `grep -r "context.go" lib/` e listar todos os usos — separar os que devem virar `context.push()` dos que devem ser mantidos como `context.go()`
- [x] Auditar todos os headers do app para identificar inconsistências visuais (padding, logo)
- [x] Identificar que `MainLayout` já injeta `CustomAppBar` em rotas do `ShellRoute` — evitou double headers

---

## Backend [PENDENTE]

N/A

---

## Frontend [EM ANDAMENTO]

### Navegação

- [x] Adicionar parâmetro opcional `fallbackRoute: String?` ao `CustomAppBar` (`lib/core/widgets/custom_app_bar.dart`) — quando `canPop = false`, usa a rota informada antes do fallback por role
- [x] Corrigir `context.go('/auth/login')` → `context.push('/auth/login')` em `hotel_details_page.dart` (preserva pilha ao ir para login)
- [x] Excluir `/auth/login` do `hideAppBar` no `MainLayout` — login gerencia o próprio `CustomAppBar` com `fallbackRoute: '/home'`

### Aplicação do CustomAppBar

- [x] Aplicar `CustomAppBar(fallbackRoute: '/home')` na `login_page.dart`
- [x] Aplicar `CustomAppBar` em `about_page.dart`, `privacy_page.dart`, `terms_page.dart` (fora do ShellRoute — gerenciam o próprio header)
- [x] Aplicar `CustomAppBar` em `ticket_details_page.dart` — removeu `_buildHeader` e `_headerButton` customizados
- [x] Páginas dentro do ShellRoute (`settings`, `edit_user_profile`, `edit_host_profile`, `edit_admin_profile`) passam a usar o `CustomAppBar` do `MainLayout` — não precisam de appBar próprio

### Rotas

- [x] Adicionar rotas GoRouter fora do ShellRoute: `/profile/terms`, `/profile/privacy`, `/profile/about`
- [x] Atualizar `settings_page.dart` para usar `context.push()` em vez de `Navigator.push(MaterialPageRoute(...))` — eliminava freeze causado por conflito `GoRouterState` + Navigator puro

### Uniformização visual dos headers

- [x] Substituir texto `'RESERVAQUI'` por `SvgPicture.asset('lib/assets/icons/logo/logoDark.svg')` em:
  - `dashboard_header.dart` (usado por `host_dashboard_page` e `admin_dashboard_page`)
  - `my_rooms_page.dart`
  - `edit_room_page.dart`
  - `add_room_page.dart`
- [x] Corrigir padding inconsistente nos headers que usavam `SafeArea + 8px` ou `MediaQuery + 10px` em vez de `top: 60` padrão:
  - `agendamentos_page.dart` — removeu SafeArea, adotou `padding: only(top: 60, ...)`
  - `agendamento_detail_page.dart` — mesma correção
  - `add_room_page.dart` — corrigido de `fromLTRB(16, 16, ...)` para `only(top: 60, ...)`
  - `chat_page.dart` — corrigido de `MediaQuery.of(context).padding.top + 10` para `top: 60`
  - `tickets_page.dart` — removeu SafeArea, adotou `padding: only(top: 60, ...)`
  - `checkout_page.dart` — removeu SafeArea, adotou `padding: only(top: 60, ...)`

### AppColors

- [x] Adicionar `greyText` e `strokeLight` ao `AppColors` (`lib/core/theme/app_colors.dart`) — referenciados em widgets do dashboard que não compilavam

### Perfil e Home

- [x] `MainLayout` passa `fallbackRoute: '/home'` ao `CustomAppBar` para rotas `/profile/*` — botão de voltar do perfil navegava para lugar nenhum quando `canPop = false`
- [x] `home_page.dart` — intro exibida apenas na primeira visita; `SharedPreferences` com chave `home_intro_seen`; pula direto para `_buildContentScreen` em visitas seguintes sem flash
- [x] Corrigir bug de navbar invisível ao pular intro — `navbarVisibleProvider.setVisible(true)` acionado no `_loadIntroPref` quando intro já foi vista
- [x] Substituir `lib/assets/images/home_page.jpeg` de 1170×780px (112 KB) por versão 4096×2730px (1986 KB) — eliminava pixelação em dispositivos com alta DPI

---

## Validação [PENDENTE]

- [x ] Testar fluxo: Home → Busca → Login → ← → Busca
- [ ] Testar fluxo: Home → Hotel Details → Room Details → Checkout → ← × 3
- [x ] Testar fluxo: Perfil → Settings → Termos → ← × 2
- [x ] Testar tela de login sem histórico na pilha: botão voltar deve ir para Home
- [ ] Verificar que redirects de autenticação (pós-login → Home, pós-logout → Login) não foram afetados
- [x ] Verificar visual das telas que receberam `CustomAppBar`: layout, padding e dark mode
- [x ] Verificar que logo SVG aparece corretamente nos headers: dashboard, my_rooms, edit_room, add_room, agendamentos
- [x ] Verificar consistência do gap do header em: agendamentos, agendamento_detail, add_room vs my_rooms e dashboard
