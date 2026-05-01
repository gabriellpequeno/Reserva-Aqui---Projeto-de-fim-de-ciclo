# PRD — Tickets Page

## Contexto
A tela de tickets (`tickets_page.dart`) existe no app mas exibe apenas dados mockados com 5 registros fixos. Com o checkout real implementado (P5-C), o usuário já consegue criar reservas — mas não tem onde acompanhá-las.

## Problema
Falta de visibilidade do histórico de reservas para o usuário — a tela atual exibe apenas dados mockados, sem refletir reservas reais feitas pelo app.

## Público-alvo
Usuários finais autenticados que realizaram ou querem acompanhar suas reservas.

## Requisitos Funcionais
1. Ao entrar na tela, buscar histórico real via `GET /usuarios/reservas`
2. Exibir lista de tickets com: foto do quarto, hotel, tipo de quarto, datas de check-in/out, valor total e status
3. Mapear status do backend (`SOLICITADA`, `AGUARDANDO_PAGAMENTO`, `APROVADA`, `CANCELADA`, `CONCLUIDA`) para labels visuais do front
4. Suportar pull-to-refresh para atualizar a lista
5. Exibir estado vazio quando o usuário não tem reservas
6. Filtrar tickets pela barra de status já existente na tela ("Todos", "Aguardo", "Aprovado", "Hospedado", "Cancelado", "Finalizado"), mapeada para os status reais do backend (`SOLICITADA`/`AGUARDANDO_PAGAMENTO`, `APROVADA`, `CONCLUIDA`, `CANCELADA`)
7. Navegar para `ticket_details_page` ao tocar em um ticket, passando o `codigo_publico`

## Requisitos Não-Funcionais
- [ ] Segurança: endpoint requer autenticação JWT de usuário
- [ ] Performance: lista deve renderizar com skeleton/loading state enquanto carrega
- [ ] Responsividade: funcionar em diferentes tamanhos de tela mobile

## Critérios de Aceitação
- Dado que o usuário está autenticado e tem reservas, quando abrir a tela, então a lista real é exibida com status e dados corretos
- Dado que o usuário não tem reservas, quando abrir a tela, então um estado vazio é exibido
- Dado que a lista está carregada, quando o usuário arrastar para baixo, então a lista é atualizada
- Dado que o usuário seleciona um filtro na barra de status, então apenas os tickets com aquele status são exibidos
- Dado que o usuário seleciona "Todos", então todos os tickets são exibidos independente do status
- Dado que o usuário toca em um ticket, então é navegado para `ticket_details_page` com o `codigo_publico`

## Fora de Escopo
- Detalhes do ticket (`ticket_details_page` — P5-E)
- Cancelamento de reserva pela tela

- Geração ou exibição de link de pagamento
