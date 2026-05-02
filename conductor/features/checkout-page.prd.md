# PRD — Checkout Page

## Contexto
A tela de checkout (`lib/features/booking/presentation/pages/checkout_page.dart`) existe no app mas opera com dados mockados. Para completar o fluxo de reserva do usuário é necessário integrá-la ao backend, permitindo confirmar reservas e gerar links de pagamento reais.

## Problema
O usuário não consegue confirmar reservas nem gerar link de pagamento, pois a tela de checkout exibe apenas dados mockados sem integração real com o backend.

## Público-alvo
Usuários finais autenticados que desejam reservar um quarto em um hotel.

## Requisitos Funcionais
1. Exibir resumo da reserva (quarto, datas, hóspedes, subtotal, impostos e total) com base no `roomId` e parâmetros de navegação
2. Exibir política do hotel (cancelamento, check-in)
3. Verificar disponibilidade do quarto antes de confirmar
4. Criar a reserva via `POST /usuarios/reservas`
5. Gerar link/QR Code de pagamento via `POST /hotel/reservas/:reserva_id/pagamentos`
6. Redirecionar para `tickets_page` após confirmação bem-sucedida
7. Tratar estados de loading e erros (indisponibilidade, autenticação)

## Requisitos Não-Funcionais
- [ ] Segurança: criação de reserva e pagamento exigem autenticação JWT
- [ ] Performance: resposta de criação de reserva em menos de 3s
- [ ] Responsividade: funcionar em dispositivos móveis (Android/iOS)
- [ ] UX: feedback visual claro em todos os estados (loading, erro, sucesso)

## Critérios de Aceitação
- Dado que o usuário chega na tela com `roomId` e datas, quando a tela carrega, então exibe resumo completo com valores calculados
- Dado que o quarto está disponível, quando o usuário clica em "Confirmar reserva", então a reserva é criada e o link de pagamento é gerado
- Dado que o quarto não está disponível, quando o usuário tenta confirmar, então exibe mensagem de erro de indisponibilidade
- Dado que o usuário não está autenticado, quando tenta confirmar, então é redirecionado para o login
- Dado que a reserva foi criada com sucesso, quando o pagamento é gerado, então o usuário é redirecionado para `tickets_page`

## Fora de Escopo
- Integração real com gateway de pagamento (InfinitePay em produção) — apenas visual nesta fase
- Notificações por e-mail ou WhatsApp após reserva
- Painel administrativo de reservas
- Cancelamento de reserva pela tela de checkout
