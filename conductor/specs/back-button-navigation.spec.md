# Spec — Back Button Navigation

## Referência
- **PRD:** conductor/features/back-button-navigation.prd.md

## Abordagem Técnica
Auditoria de todos os `context.go()` no app via grep, substituindo por `context.push()` nas navegações empilháveis. Em paralelo, auditoria de todos os headers customizados para identificar e corrigir inconsistências visuais (texto RESERVAQUI vs logo SVG, padding inconsistente). Descoberta crítica durante implementação: o `MainLayout` já injeta `CustomAppBar` em todas as rotas do `ShellRoute` — adicionar `appBar` diretamente nas páginas causava double header e dois botões de voltar.

## Componentes Afetados

### Backend
N/A

### Frontend
- **Modificado:** `CustomAppBar` (`lib/core/widgets/custom_app_bar.dart`) — parâmetro `fallbackRoute: String?`; quando `canPop = false`, navega para `fallbackRoute` antes do fallback por role
- **Modificado:** `MainLayout` (`lib/core/layouts/main_layout.dart`) — `/auth/login` adicionado ao `hideAppBar` para login gerenciar o próprio AppBar com `fallbackRoute`
- **Modificado:** `login_page.dart` — `CustomAppBar(fallbackRoute: '/home')` próprio; `SizedBox(height: 120)` reduzido para 24
- **Modificado:** `hotel_details_page.dart` — `context.go('/auth/login')` → `context.push('/auth/login')`
- **Modificado:** `settings_page.dart` — `Navigator.push(MaterialPageRoute(...))` → `context.push('/profile/terms|privacy|about')` (eliminava freeze)
- **Modificado:** `about_page.dart`, `privacy_page.dart`, `terms_page.dart` — substituído `AppBar` genérico por `CustomAppBar`; agora são rotas GoRouter fora do ShellRoute
- **Modificado:** `ticket_details_page.dart` — removido `_buildHeader` e `_headerButton` customizados; adicionado `CustomAppBar`; removidos imports `flutter_svg`, `auth_notifier`, `auth_state`
- **Modificado:** `app_router.dart` — novas rotas fora do ShellRoute: `/profile/terms`, `/profile/privacy`, `/profile/about`
- **Modificado:** `app_colors.dart` — adicionados `greyText` (`0xFF9E9E9E`) e `strokeLight` (`0xFFE0E0E0`)
- **Modificado:** `dashboard_header.dart` — texto `'RESERVAQUI'` → `SvgPicture.asset(logoDark.svg)`
- **Modificado:** `my_rooms_page.dart` — texto `'RESERVAQUI'` → `SvgPicture.asset(logoDark.svg)`
- **Modificado:** `edit_room_page.dart` — texto `'RESERVAQUI'` → `SvgPicture.asset(logoDark.svg)`
- **Modificado:** `add_room_page.dart` — texto `'RESERVAQUI'` → `SvgPicture.asset(logoDark.svg)`; padding `fromLTRB(16,16,...)` → `only(top:60,...)`
- **Modificado:** `agendamentos_page.dart` — removeu `SafeArea + fromLTRB(17,8,...)` → `padding: only(top:60,...)`
- **Modificado:** `agendamento_detail_page.dart` — mesma correção de padding
- **Modificado:** `chat_page.dart` — `MediaQuery.of(context).padding.top + 10` → `top: 60`
- **Modificado:** `tickets_page.dart` — removeu `SafeArea + fromLTRB(17,8,...)` → `padding: only(top:60,...)`
- **Modificado:** `checkout_page.dart` — mesma correção de padding
- **Sem alteração (já corretos):** `edit_room_page`, `my_rooms_page`, `dashboard_header` — padding já em `top: 60`; `admin_account_management_page` — padding já em `top: 60`

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|---------------|
| `context.push()` em vez de `context.go()` para navegações reversíveis | Preserva a pilha do GoRouter, permitindo `context.pop()` nativo |
| Páginas dentro do ShellRoute não definem `appBar` próprio | `MainLayout` já injeta `CustomAppBar` — appBar duplicado gerava double header e dois botões de voltar |
| Login excluído do `hideAppBar` do MainLayout | Precisa de `CustomAppBar(fallbackRoute: '/home')` específico; sem essa exclusão ficaria sem header |
| Rotas GoRouter para terms/privacy/about fora do ShellRoute | `Navigator.push` + `GoRouterState.of(context)` no `CustomAppBar` causava freeze por loop de rebuild |
| Parâmetro `fallbackRoute` no `CustomAppBar` | Resolve o fallback específico do login sem lógica especial fora do componente |
| `top: 60` como padrão de padding nos headers dark | Alinha visualmente com `my_rooms` e `dashboard_header` já existentes; substitui SafeArea inconsistente |
| Logo SVG em vez de texto `'RESERVAQUI'` | Consistência com a identidade visual do app; texto não refletia a logomarca real |
| Manter `context.go()` nos redirects de autenticação | Esses redirecionamentos devem resetar a pilha intencionalmente |

## Contratos de API
N/A

## Modelos de Dados
N/A

## Dependências

**Bibliotecas:**
- `go_router` — já configurado no projeto
- `flutter_svg` — já no projeto; adicionado import em `dashboard_header`, `my_rooms_page`, `edit_room_page`, `add_room_page`

**Outras features:**
- `CustomAppBar` (`lib/core/widgets/custom_app_bar.dart`) — widget base estendido com `fallbackRoute`
- `MainLayout` (`lib/core/layouts/main_layout.dart`) — responsável pelo `CustomAppBar` de todas as rotas do ShellRoute

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| `GoRouterState.of(context)` em páginas abertas via `Navigator.push` causa freeze | Converter para rotas GoRouter em vez de Navigator.push — aplicado em terms/privacy/about |
| Adicionar `appBar` em páginas dentro do ShellRoute gera double header | Verificar se a página está no ShellRoute antes de definir `appBar` próprio |
| Alterar padding de headers pode desalinhar conteúdo em dispositivos com notch grande | Testar em dispositivos com status bar alta; considerar SafeArea se necessário |
