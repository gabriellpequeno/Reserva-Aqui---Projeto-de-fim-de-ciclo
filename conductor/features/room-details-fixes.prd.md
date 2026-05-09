# PRD — room-details-fixes

## Contexto

A tela `room_details_page.dart` possui três problemas que degradam a experiência do usuário e bloqueiam o fluxo de reserva: o header não identifica claramente a hierarquia hotel/categoria, a lógica de disponibilidade diverge da tela de checkout (gerando inconsistência), e o botão de favoritar está ausente.

## Problema

1. **Título da tela:** o header atual não exibe a hierarquia visual "nome do hotel / categoria do quarto", dificultando a identificação do contexto pelo usuário.
2. **Disponibilidade inconsistente:** a tela de detalhes pode exibir o quarto como disponível mesmo quando o checkout retorna indisponível, quebrando a confiança no fluxo de reserva.
3. **Favoritar ausente:** não há como o usuário favoritar um quarto/hotel diretamente na tela de detalhes, obrigando-o a navegar para outra tela.

## Público-alvo

Usuários finais (guests e usuários autenticados) que acessam a tela de detalhes do quarto para avaliar e iniciar uma reserva.

## Requisitos Funcionais

1. O header da tela deve exibir o nome do hotel em fonte maior (peso normal ou bold) e a categoria do quarto em fonte menor (peso leve ou cor secundária), usando uma `Column` no topo da tela ou no AppBar.
2. A verificação de disponibilidade deve considerar **todas as unidades** do quarto no intervalo de datas selecionado: o quarto só é marcado como disponível se pelo menos 1 unidade estiver livre em **todos os dias** do período.
3. Se em qualquer dia do intervalo todas as unidades estiverem ocupadas, a tela de detalhes deve exibir o quarto como indisponível (mesmo comportamento do checkout).
4. A tela de detalhes e a tela de checkout devem estar em sincronia: se disponível em uma, disponível na outra.
5. Um botão de favoritar deve ser adicionado no canto superior direito da tela (oposto ao botão de voltar).
6. O ícone do botão de favoritar deve ser preenchido (`Icons.favorite`) se o hotel já estiver favoritado, e vazio (`Icons.favorite_border`) caso contrário.
7. Ao tocar no botão de favoritar: chamar `POST /usuarios/favoritos` (adicionar) ou `DELETE /usuarios/favoritos/:hotel_id` (remover), com atualização otimista do estado local.
8. Em caso de erro ao favoritar/desfavoritar, o estado deve ser revertido para o valor anterior.
9. Se o usuário não estiver autenticado e tentar favoritar, deve ser redirecionado para a tela de login.

## Requisitos Não-Funcionais

- [ ] Performance: a verificação de disponibilidade deve reutilizar o mesmo endpoint já utilizado no `AvailabilityChecker`, sem chamadas adicionais.
- [ ] Segurança: as chamadas de favoritar exigem token de autenticação; usuários não autenticados devem ser redirecionados antes da chamada.
- [ ] Consistência: a lógica de interpretação da resposta de disponibilidade deve ser centralizada em um único ponto (evitar duplicação entre `availability_checker.dart` e `checkout_page.dart`).
- [ ] Responsividade: o botão de favoritar deve funcionar visualmente mesmo offline (optimistic update), persistindo apenas com conexão.

## Critérios de Aceitação

- Dado que o usuário está na tela de detalhes do quarto, quando a tela carregar, então o header deve exibir o nome do hotel em destaque e a categoria do quarto abaixo, visualmente menor.
- Dado que o usuário selecionou datas em que o quarto está indisponível, quando a tela de detalhes exibir o resultado do `AvailabilityChecker`, então deve mostrar "Indisponível" (consistente com o que o checkout retornaria).
- Dado que o usuário selecionou datas em que o quarto está disponível na tela de detalhes, quando navegar para o checkout com essas mesmas datas, então o checkout também deve exibir disponível.
- Dado que o usuário está autenticado e o hotel não está favoritado, quando tocar no botão de favoritar, então o ícone deve mudar imediatamente para preenchido e a API deve ser chamada.
- Dado que o usuário está autenticado e o hotel está favoritado, quando tocar no botão de favoritar, então o ícone deve mudar imediatamente para vazio e a API deve ser chamada para remover.
- Dado que a chamada de favoritar falha, quando o erro ocorrer, então o ícone deve reverter para o estado anterior.
- Dado que o usuário não está autenticado, quando tocar no botão de favoritar, então deve ser redirecionado para a tela de login.

## Fora de Escopo

- Alteração da lógica de disponibilidade no backend (se o endpoint já retornar a resposta correta por unidade, apenas o front é corrigido).
- Notificações push ao favoritar.
- Listagem de favoritos ou tela dedicada de favoritos (já existe em `lib/features/favorites/`).
- Refatoração do fluxo de pagamento ou da tela de checkout além da sincronização de disponibilidade.
- Suporte a múltiplos idiomas.
