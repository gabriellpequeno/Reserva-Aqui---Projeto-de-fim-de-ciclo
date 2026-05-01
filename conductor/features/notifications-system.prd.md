# PRD — notifications-system

## Contexto
O app ReservAqui já possui uma tela de notificações funcional no frontend, mas exibe apenas 3 mocks hardcoded. O backend tem toda a infraestrutura pronta: FCM service, triggers de push para todos os eventos de negócio e inbox REST para hotel. O gap está na integração: o Flutter não consome nada disso.

## Problema
Hóspedes e hosts não recebem notificações reais de eventos críticos (reserva aprovada, pagamento confirmado, cancelamento). O badge de não lidas no navbar não funciona e tocar em uma notificação não navega para lugar nenhum.

## Público-alvo
- **Hóspedes (guests):** recebem notificações via FCM, persistidas localmente enquanto inbox REST não existe
- **Administradores de hotéis (hosts):** recebem notificações via FCM + inbox REST já disponível no backend

## Requisitos Funcionais
1. Registrar token FCM no login por role (guest → `/dispositivos-fcm/usuario`, host → `/dispositivos-fcm/hotel`)
2. Remover token FCM no logout por role
3. Receber notificações push em foreground, background e com app fechado (via Firebase Messaging)
4. Host: carregar inbox via `GET /hotel/notificacoes`, marcar notificação como lida e limpar todas
5. Hóspede: criar e persistir notificações localmente a partir do FCM data (shared_preferences)
6. Ao tocar em uma notificação, navegar para a rota correta conforme `tipo` + `payload`
7. Exibir badge com contagem de não lidas sobre o ícone de notificações no `CustomBottomNav`

## Requisitos Não-Funcionais
- [ ] Segurança: token FCM registrado somente após autenticação e removido no logout
- [ ] Responsividade: UI funcional em Android e iOS
- [ ] Permissões: solicitar permissão de notificações ao usuário (obrigatório em iOS, Android 13+)
- [ ] Resiliência: notificações do hóspede persistidas localmente não perdem dados ao fechar o app

## Critérios de Aceitação
- Dado que o host está autenticado, quando uma reserva é criada por um hóspede, então recebe push e a notificação aparece na lista carregada via REST
- Dado que o hóspede está autenticado, quando o hotel aprova a reserva, então recebe push; se `checkout_url` estiver presente abre o browser, caso contrário abre o ticket
- Dado que o usuário toca em uma notificação com `tipo = RESERVA_CANCELADA`, então o app navega para `/tickets/details/:codigo_publico`
- Dado que há notificações não lidas, quando o usuário abre o app, então o badge do navbar exibe a contagem correta
- Dado que o usuário faz logout, quando o processo é concluído, então o token FCM é removido do backend

## Fora de Escopo
- Inbox REST para hóspede (EXT-2 — task separada de backend)
- Trigger FCM para mensagem de chat (EXT-3 — task separada de backend)
- Notificações por e-mail
- Painel administrativo de notificações
