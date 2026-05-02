# PRD — ticket-details-page-integration

## Contexto
A tela de detalhes de reserva (`ticket_details_page`) já existe com estrutura visual implementada, mas opera inteiramente com dados mockados. Nenhuma chamada real à API é feita ao abrir a tela.

## Problema
O usuário não vê informações reais da reserva — horários do hotel, comodidades do quarto e política de cancelamento não são carregados. Além disso, não é possível cancelar uma reserva pelo app.

## Público-alvo
Usuários finais autenticados que possuem reservas ativas ou históricas no app.

## Requisitos Funcionais
1. Ao entrar na tela, buscar dados completos da reserva via `GET /reservas/:codigo_publico` (rota pública)
2. Exibir nome do hóspede, datas, horários padrão do hotel e horários reais de check-in/out quando disponíveis
3. Mapear status do backend para status visual do frontend (incluindo `hospedado` derivado de `APROVADA + hora_checkin_real != null`)
4. Exibir bloco "Sobre o quarto" com comodidades e capacidade via `GET /:hotel_id/categorias/:id`
5. Exibir bloco "Política do hotel" com horários padrão, política de cancelamento e aceita animais via `GET /:hotel_id/configuracao`
6. Exibir botão "Cancelar" apenas quando status for `SOLICITADA` ou `AGUARDANDO_PAGAMENTO`, com dialog de confirmação
7. Ao cancelar, chamar `PATCH /usuarios/reservas/:codigo_publico/cancelar` e atualizar estado local no `TicketsNotifier`

## Requisitos Não-Funcionais
- [ ] Segurança: cancelamento requer autenticação (JWT); busca de detalhes é pública
- [ ] Responsividade: layout adaptado para telas mobile
- [ ] UX: estados de loading e erro tratados em cada chamada de API
- [ ] Consistência: após cancelamento, lista de reservas (`tickets_page`) reflete o novo status sem reload manual

## Critérios de Aceitação
- Dado que o usuário abre a tela de detalhes, quando os dados carregam, então exibe nome do hóspede, datas, horários e status correto
- Dado que a reserva tem `hora_checkin_real` preenchido, quando exibir o horário de chegada, então mostra o horário real em vez do padrão do hotel
- Dado que a reserva está com status `SOLICITADA` ou `AGUARDANDO_PAGAMENTO`, quando o usuário toca "Cancelar", então exibe dialog de confirmação antes de prosseguir
- Dado que o usuário confirma o cancelamento, quando a API responde com sucesso, então o status da reserva é atualizado localmente e na lista de reservas
- Dado que a reserva tem status diferente de `SOLICITADA` ou `AGUARDANDO_PAGAMENTO`, quando a tela carrega, então o botão "Cancelar" não é exibido
- Dado que qualquer chamada de API falha, quando ocorre o erro, então exibe mensagem amigável sem crash

## Fora de Escopo
- Pagamento ou reativação de reservas canceladas
- Edição de dados da reserva (datas, número de hóspedes)
- Avaliação do hotel a partir desta tela
- Notificações push disparadas pelo cancelamento (responsabilidade do backend)
- Compartilhamento de voucher
