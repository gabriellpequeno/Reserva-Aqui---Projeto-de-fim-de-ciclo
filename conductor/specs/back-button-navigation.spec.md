# Spec — Back Button Navigation

## Referência
- **PRD:** conductor/features/back-button-navigation.prd.md

## Abordagem Técnica
Auditoria de todos os `context.go()` no app via grep, substituindo por `context.push()` nas navegações empilháveis. Em paralelo:
- Telas que já possuem AppBar próprio: corrigir apenas o `context.go()` → `context.pop()` no botão de voltar, sem substituir a estrutura do AppBar
- Telas sem AppBar nenhum (ex: suporte): adicionar o `CustomAppBar` existente para uniformizar o design
- Adicionar parâmetro `fallbackRoute` ao `CustomAppBar` para tratar o caso da tela de login, onde `canPop = false` e o botão deve navegar para `/home`

## Componentes Afetados

### Backend
N/A

### Frontend
- **Modificado:** `CustomAppBar` (`lib/core/widgets/custom_app_bar.dart`) — adicionar parâmetro opcional `fallbackRoute: String?`; quando `canPop = false`, navegar para `fallbackRoute` se fornecido, senão manter comportamento atual
- **Modificado:** `login_page.dart` — usar `CustomAppBar(fallbackRoute: '/home')` e corrigir navegações `context.go()` empilháveis para `context.push()`
- **Modificado:** telas de settings, termos de uso, privacidade, sobre o app — corrigir `context.go()` → `context.pop()` nos botões de voltar existentes
- **Modificado:** `room_details_page.dart`, `checkout_page.dart` — corrigir navegação empilhável: `context.go()` → `context.push()`
- **Modificado:** tela de suporte (`support_page.dart`) — adicionar `CustomAppBar` (atualmente sem header)
- **Auditado:** todos os demais arquivos com `context.go()` — revisar um a um e corrigir os que deveriam ser `context.push()`

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|---------------|
| `context.push()` em vez de `context.go()` para navegações reversíveis | Preserva a pilha do GoRouter, permitindo `context.pop()` nativo no botão de voltar |
| Corrigir back button em AppBars existentes sem substituí-los | Menor risco de quebrar layout; mesmo resultado funcional e visual |
| Adicionar `CustomAppBar` apenas em telas sem AppBar | Uniformiza o design onde não há estrutura prévia, sem risco de regressão |
| Parâmetro `fallbackRoute` no `CustomAppBar` | Resolve o caso da tela de login sem criar lógica especial fora do componente |
| Manter `context.go()` nos redirects de autenticação | Esses redirecionamentos devem resetar a pilha intencionalmente (ex: pós-login → home, pós-logout → login) |

## Contratos de API
N/A

## Modelos de Dados
N/A

## Dependências

**Bibliotecas:**
- [ ] `go_router` — já configurado no projeto

**Outras features:**
- [ ] `CustomAppBar` (`lib/core/widgets/custom_app_bar.dart`) — widget base a ser estendido com `fallbackRoute`

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| Telas dentro de `ShellRoute`/`StatefulShellRoute` podem ter comportamento inesperado com `push` | Verificar cada tela dentro de shells individualmente antes de alterar |
| Alterar por engano um `context.go()` de redirect de autenticação | Manter lista explícita dos `go()` que devem ser preservados; documentar no PR |
| Telas sem AppBar com layout sensível a padding podem desalinhar ao receber `CustomAppBar` | Testar visualmente side-by-side antes e depois em cada tela afetada |
