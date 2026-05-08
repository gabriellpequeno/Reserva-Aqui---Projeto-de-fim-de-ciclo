# PRD — Profile Pages Nav Fixes

## Contexto
As telas de perfil (usuário e host) estão incompletas e apresentam problemas de navegação. Fotos de perfil e de capa não são exibidas nem editáveis, botões de voltar duplicados aparecem em telas secundárias e algumas rotas quebram o stack de navegação ao usar `context.go()` em vez de `context.pop()`.

## Problema
Telas de perfil (usuário e host) carecem de foto de perfil/capa, botões de voltar duplicados aparecem em telas secundárias (Termos, Privacidade, Sobre) e algumas rotas usam `context.go()` quebrando o stack de navegação.

## Público-alvo
Usuários finais (perfil de usuário) e hosts (perfil de estabelecimento).

## Requisitos Funcionais
1. Exibir avatar circular na tela de perfil do usuário (foto ou initials fallback)
2. Permitir troca de foto de perfil do usuário na tela de edição (galeria/câmera) via `POST /uploads/usuarios/:id/avatar`
3. Exibir avatar circular na tela de perfil do host
4. Permitir troca de foto de perfil do host na tela de edição; a mesma imagem deve refletir na `hotel_details_page`
5. Permitir troca de foto de capa do hotel na edição do host via `POST /uploads/hotels/:hotel_id/cover`
6. Remover botão de voltar duplicado nas telas Termos, Privacidade e Sobre; o botão restante deve voltar para Configurações
7. Garantir que `edit_profile_page` usa `context.pop()` e volta para perfil, não para home
8. Substituir qualquer `context.go()` em botões de voltar customizados por `context.pop()`

## Requisitos Não-Funcionais
- [ ] Performance: upload de imagem deve ter feedback visual (loading state)
- [ ] Segurança: endpoints de upload exigem autenticação
- [ ] Acessibilidade: avatar com `semanticsLabel` adequado
- [ ] Responsividade: preview de foto funcionar em mobile (Android/iOS)

## Critérios de Aceitação
- Dado que o usuário tem foto cadastrada, quando abre a tela de perfil, então vê o avatar circular com sua foto
- Dado que o usuário não tem foto, quando abre a tela de perfil, então vê um avatar com suas iniciais
- Dado que o usuário está na edição de perfil, quando seleciona nova foto e salva, então o avatar é atualizado na tela de perfil
- Dado que o host salva uma foto de perfil, quando acessa `hotel_details_page`, então a mesma foto aparece
- Dado que o host está na edição de perfil, quando faz upload de foto de capa e salva, então `hotel_details_page` exibe a nova capa
- Dado que o usuário está em Termos/Privacidade/Sobre, quando pressiona voltar, então retorna para Configurações sem botão duplicado
- Dado que o usuário está em `edit_profile_page`, quando pressiona voltar, então retorna para perfil (não para home)

## Fora de Escopo
- Implementação do botão voltar global (coberto pelo BUG-9)
- Notificações de confirmação de upload por e-mail
- Crop/edição de imagem dentro do app
- Se endpoint `POST /uploads/usuarios/:id/avatar` não existir: documentar como EXT e exibir apenas avatar estático
