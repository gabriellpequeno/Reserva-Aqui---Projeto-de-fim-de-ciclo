# PRD — Back Button Navigation

## Contexto
O app utiliza GoRouter para navegação, com um `ShellRoute` que envolve a maioria das telas via `MainLayout`. Existe um `CustomAppBar` compartilhado (`lib/core/widgets/custom_app_bar.dart`) que implementa o botão de voltar corretamente com `context.pop()`, mas não era usado em todas as telas. Parte das telas tinha `context.go()` hardcoded no botão de voltar; outras tinham headers customizados com texto "RESERVAQUI" em vez do logo SVG ou padding inconsistente.

## Problema
1. O botão de voltar em diversas telas ignorava a pilha de navegação real, redirecionando para destinos fixos (geralmente Home)
2. O botão de voltar na tela de perfil não fazia nada (sem `fallbackRoute` configurado)
3. A interface era inconsistente: algumas telas não tinham header, outras tinham AppBar genérico, outras tinham o logo em texto em vez de SVG
4. Headers customizados usavam padding variável (`SafeArea + 8px`, `MediaQuery + 10px`, `top: 16px`) em vez do padrão `top: 60px`, causando gaps inconsistentes entre telas
5. A tela de intro da Home aparecia em toda navegação de volta, mesmo após a primeira visita
6. A imagem de fundo da Home no modo claro estava em baixa resolução (1170×780px), causando pixelação em dispositivos modernos

## Público-alvo
Todos os usuários do app (hóspedes e administradores) que navegam por qualquer tela com botão de voltar ou que percebem inconsistências visuais no header.

## Requisitos Funcionais
1. O botão de voltar deve sempre retornar para a tela imediatamente anterior na pilha de navegação
2. Substituir `context.go()` por `context.push()` nas navegações empilháveis (ex: hotel_details → login)
3. Botões de voltar customizados devem usar `context.pop()` — centralizado no `CustomAppBar`
4. Manter `context.go()` apenas para trocas de seção principal (bottom nav, redirect pós-login/logout)
5. Aplicar o `CustomAppBar` nas telas sem header padronizado: login, about, privacy, terms, ticket_details
6. Telas dentro do `ShellRoute` usam o `CustomAppBar` injetado pelo `MainLayout` — não definem appBar próprio
7. Substituir texto `'RESERVAQUI'` por logo SVG nos headers customizados de: dashboard, my_rooms, edit_room, add_room
8. Padronizar padding dos headers customizados para `top: 60px` em todas as telas
9. Botão de voltar da tela de perfil deve navegar para Home quando não há tela anterior na pilha
10. A tela de intro da Home deve aparecer apenas na primeira visita; nas seguintes ir direto para os hotéis
11. Substituir imagem de fundo da Home (modo claro) por versão em alta resolução

## Requisitos Não-Funcionais
- [ ] Responsividade: comportamento consistente em Android e iOS
- [ ] Sem regressão: fluxos de autenticação (redirect pós-login/logout) não devem ser alterados
- [ ] Sem freeze: navegação entre settings e telas legais (terms/privacy/about) não deve travar o app

## Critérios de Aceitação
- Dado que o usuário está na Busca e navega para Login, quando pressionar voltar, então retorna para Busca
- Dado que o usuário percorre Home → Hotel Details → Room Details → Checkout, quando pressionar voltar 3x, então percorre Room Details → Hotel Details → Home sem redirecionamentos inesperados
- Dado que o usuário percorre Perfil → Settings → Termos, quando pressionar voltar 2x, então percorre Settings → Perfil
- Dado que o usuário está na tela de login sem histórico na pilha, quando pressionar voltar, então navega para Home
- Dado que o usuário abre qualquer tela que recebeu o `CustomAppBar`, então o header exibe o logo SVG (não texto)
- Dado que o usuário alterna entre telas com header customizado dark, o gap do header é visualmente consistente
- Dado que o usuário está na tela de perfil e pressiona voltar sem histórico na pilha, então navega para Home
- Dado que o usuário já visitou a Home antes, quando navegar para Home novamente, então vai direto para a tela de hotéis sem ver a intro
- Dado que a imagem de fundo da Home é exibida, então aparece nítida em dispositivos com alta densidade de tela

## Fora de Escopo
- Redesign da estrutura de rotas do GoRouter
- Alteração dos redirects de autenticação (pós-login → Home, pós-logout → Login)
- Implementação de histórico de navegação persistente
- Uniformização do estilo visual entre headers transparentes (CustomAppBar) e headers dark (Container curved)
