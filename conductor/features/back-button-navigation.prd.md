# PRD — Back Button Navigation

## Contexto
O app utiliza GoRouter para navegação. Existe um `CustomAppBar` compartilhado (`lib/core/widgets/custom_app_bar.dart`) que já implementa o botão de voltar corretamente com `context.pop()`, mas ele não é usado em todas as telas. Parte das telas possui AppBars próprios com `context.go()` hardcoded no botão de voltar, e outras telas não possuem header nenhum.

## Problema
O botão de voltar em diversas telas ignora a pilha de navegação real, redirecionando para destinos fixos (geralmente Home). Além disso, a interface é inconsistente: algumas telas usam o `CustomAppBar` compartilhado, outras possuem AppBars próprios sem botão de voltar ou com comportamento incorreto.

## Público-alvo
Todos os usuários do app (hóspedes e administradores) que navegam por qualquer tela com botão de voltar.

## Requisitos Funcionais
1. O botão de voltar deve sempre retornar para a tela imediatamente anterior na pilha de navegação
2. Substituir `context.go()` por `context.push()` em todas as navegações empilháveis
3. Botões de voltar customizados no `AppBar` devem usar `context.pop()` — já implementado no `CustomAppBar`
4. Manter `context.go()` apenas para trocas de seção principal (bottom nav, redirect pós-login/logout)
5. Aplicar o `CustomAppBar` nas telas que atualmente possuem AppBar próprio sem comportamento padronizado (ex: tela de suporte)

## Requisitos Não-Funcionais
- [ ] Responsividade: comportamento consistente em Android e iOS
- [ ] Sem regressão: fluxos de autenticação (redirect pós-login/logout) não devem ser alterados

## Critérios de Aceitação
- Dado que o usuário está na Busca e navega para Login, quando pressionar voltar, então retorna para Busca
- Dado que o usuário está no Login e navega para Busca, quando pressionar voltar, então retorna para Login
- Dado que o usuário percorre Home → Hotel Details → Room Details → Checkout, quando pressionar voltar 3x, então percorre Room Details → Hotel Details → Home sem redirecionamentos inesperados
- Dado que o usuário percorre Perfil → Settings → Termos, quando pressionar voltar 2x, então percorre Settings → Perfil
- Dado que o usuário abre qualquer tela que recebeu o `CustomAppBar`, então o header é visualmente idêntico ao das demais telas

## Fora de Escopo
- Redesign da estrutura de rotas do GoRouter
- Alteração dos redirects de autenticação (pós-login → Home, pós-logout → Login)
- Implementação de histórico de navegação persistente
- Criação de um novo componente de AppBar (o `CustomAppBar` existente será reutilizado)
