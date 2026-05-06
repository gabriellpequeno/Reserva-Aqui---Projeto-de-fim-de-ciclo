# BUG-9 — navegação global - Botão Voltar Sempre Retorna à Tela Anterior

## Escopo
Todas as telas do app que possuem botão de voltar

## Prioridade
**Alta** — impacta toda a experiência de navegação do usuário

## Branch sugerida
`fix/back-button-navigation`

---

## Problema

O botão de voltar em várias telas não respeita a pilha de navegação anterior — em vez de retornar para a tela que originou a navegação, retorna para um destino fixo (geralmente Home).

**Exemplos do comportamento errado:**
- Tela de busca → tela de login → apertar voltar → vai para Home (deveria voltar para busca)
- Tela de login → tela de busca → apertar voltar → vai para login (deveria voltar para busca)

**Regra:**
> O botão de voltar deve **sempre** retornar para a tela imediatamente anterior na pilha de navegação, independente de qual tela seja.

---

## Causa raiz provável

O uso de `context.go('/rota')` substitui o stack de navegação inteiro. O correto para navegação empilhável é `context.push('/rota')`.

- `context.go()` → reseta o stack → voltar vai para a raiz
- `context.push()` → empilha → voltar vai para a tela anterior

---

## O que verificar e corrigir

- [ ] **Auditar todos os `context.go()` no app** — identificar quais deveriam ser `context.push()`
  - Regra: usar `context.go()` apenas para trocas de "seção principal" (ex: trocar a aba do bottom nav, redirecionar após logout/login)
  - Usar `context.push()` para toda navegação que deve ser reversível com o botão voltar

- [ ] **Telas prioritárias a verificar:**
  - Tela de login (`auth/login_page.dart`) — ao navegar da busca para login, o voltar deve voltar para busca
  - Tela de perfil → settings → perfil: back deve voltar para settings, não para home
  - Termos de uso, Privacidade, Sobre o App — back deve voltar para settings
  - Tela de editar perfil — back deve voltar para perfil
  - Tela de detalhe do quarto — back deve voltar para hotel details
  - Tela de checkout — back deve voltar para room details

- [ ] **Botão de voltar customizado (AppBar leading):**
  - Se a tela usa `leading: IconButton(onPressed: () => context.go('/x'))`, substituir por `context.pop()` ou remover o `leading` customizado e deixar o `AppBar` usar o back automático do GoRouter

- [ ] **Telas que usam `ShellRoute` ou `StatefulShellRoute`:**
  - Verificar que a navegação dentro dos shells usa `push` e não `go`

---

## Critério de aceitação

Percorrer o seguinte fluxo sem nenhum redirecionamento inesperado:

1. Home → Busca → Login → ← (voltar) → Busca
2. Login → Busca → ← (voltar) → Login
3. Home → Hotel Details → Room Details → Checkout → ← → Room Details → ← → Hotel Details
4. Perfil → Settings → Termos → ← → Settings → ← → Perfil

---

## Arquivos a modificar

- Todos os arquivos de página que contêm `context.go()` em botões de voltar ou em navegações que deveriam ser empilháveis
- Executar: `grep -r "context.go" lib/` para listar todos os usos e revisar um a um

---

## Observações
- Esta task tem escopo amplo — estimar tempo antes de iniciar
- Priorizar as telas do fluxo principal (login, busca, room details, checkout) para a apresentação
- Não alterar `context.go()` nos redirects de autenticação (ex: após login bem-sucedido ir para home, após logout ir para login) — esses são corretos
