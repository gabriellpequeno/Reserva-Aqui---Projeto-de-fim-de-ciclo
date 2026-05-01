# PRD — Favorites Page

## Contexto
A página de favoritos existe no Frontend mas opera inteiramente com dados mockados, sem qualquer integração com o backend. O objetivo desta feature é substituir os mocks pela conexão real com a API, tornando os favoritos persistentes e vinculados à conta do usuário.

## Problema
Atualmente a página de favoritos exibe dados estáticos (mockados), o que significa que os itens salvos não persistem entre sessões, não são reais e não refletem o estado do sistema. Isso impede que o usuário utilize o recurso de forma funcional.

## Público-alvo
Usuários finais autenticados que estão pesquisando hotéis e querem salvar opções para comparar ou reservar posteriormente.

## Requisitos Funcionais
1. O usuário pode favoritar/desfavoritar um hotel ou quarto a partir da página de detalhes
2. O sistema persiste os favoritos vinculados à conta do usuário autenticado
3. A página de favoritos lista todos os itens salvos (hotéis e/ou quartos)
4. O usuário pode remover um item da lista de favoritos diretamente na página
5. Ao clicar em um favorito, o usuário é redirecionado para a página de detalhes do item

## Requisitos Não-Funcionais
- [ ] Performance: listagem de favoritos carrega em menos de 1s
- [ ] Segurança: endpoint exige autenticação JWT
- [ ] Responsividade: funciona no mobile (Flutter)
- [ ] Consistência: estado de favorito sincronizado entre telas (ex: detalhe do hotel reflete remoção feita na página de favoritos)

## Critérios de Aceitação
- Dado que o usuário está autenticado, quando acessar a página de favoritos, então deve ver a lista de hotéis/quartos que salvou
- Dado que o usuário não tem favoritos, quando acessar a página, então deve ver um estado vazio com mensagem informativa
- Dado que o usuário está na página de favoritos, quando remover um item, então ele some da lista imediatamente sem recarregar a página
- Dado que o usuário não está autenticado, quando tentar favoritar, então deve ser redirecionado para o login
- Dado que o backend retorna erro, quando carregar os favoritos, então deve exibir mensagem de erro amigável

## Fora de Escopo
- Compartilhamento de lista de favoritos com outros usuários
- Notificações de alteração de preço dos favoritos
- Ordenação ou filtragem da lista de favoritos
- Favoritos para outros tipos de entidade além de hotéis e quartos
