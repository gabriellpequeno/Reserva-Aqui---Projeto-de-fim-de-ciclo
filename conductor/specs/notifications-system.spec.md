# Spec — notifications-system

## Referência
- **PRD:** conductor/features/notifications-system.prd.md

## Abordagem Técnica

Integrar `firebase_messaging` no Flutter para receber pushes FCM em foreground, background e com app fechado. Chamar os endpoints de token FCM existentes no login/logout por role. Host consome inbox REST já pronta no backend. Hóspede persiste notificações localmente via `shared_preferences`. Badge de não lidas derivado via Riverpod do estado das notificações, sem estado duplicado.

## Componentes Afetados

### Backend
Nenhum arquivo novo — toda a infraestrutura já existe (FCM service, token management, hotel inbox). Verificar se triggers FCM estão sendo chamados nos controllers de reserva/pagamento está fora do escopo desta task.

### Frontend

**Novos:**
- `NotificationService` (`lib/features/notifications/data/services/notification_service.dart`) — inicializa FCM, solicita permissão, escuta mensagens em foreground/background
- `FcmTokenService` (`lib/features/notifications/data/services/fcm_token_service.dart`) — registra e remove token FCM via REST por role

**Modificados:**
- `notifications_provider.dart` — substituir mocks por estado real (host via REST, hóspede via SharedPreferences)
- `app_notification.dart` — adicionar campos `tipo` e `payload` para suporte à navegação
- `auth_notifier.dart` — chamar registro/remoção de token FCM no login e logout
- `custom_bottom_nav.dart` — exibir badge com contagem de notificações não lidas
- `app_router.dart` — mapear `tipo` + `payload` para rotas de navegação ao tocar em notificação

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| SharedPreferences para hóspede | Inbox REST para hóspede não existe no backend (EXT-2 — task separada) |
| Token FCM registrado no `auth_notifier`, não na UI | Garante registro mesmo em login silencioso por refresh de token |
| Badge derivado via `Provider` do estado de notificações | Evita estado duplicado e mantém consistência automática |
| Navegação centralizada no `app_router` via `tipo` + `payload` | Desacopla o handler de push das telas individuais |

## Contratos de API

Todos os endpoints já existem no backend.

| Método | Rota | Body | Response |
|--------|------|------|----------|
| POST | `/api/dispositivos-fcm/usuario` | `{ fcm_token, origem }` | `201` |
| POST | `/api/dispositivos-fcm/hotel` | `{ fcm_token, origem }` | `201` |
| DELETE | `/api/dispositivos-fcm/usuario` | `{ fcm_token }` | `200` |
| DELETE | `/api/dispositivos-fcm/hotel` | `{ fcm_token }` | `200` |
| GET | `/api/hotel/notificacoes?nao_lidas=true` | — | `Notificacao[]` |
| PATCH | `/api/hotel/notificacoes/:id/lida` | — | `200` |
| PATCH | `/api/hotel/notificacoes/lida-todas` | — | `200` |

## Modelos de Dados

```
// Modelo local Flutter — app_notification.dart (estendido)
AppNotification {
  id: String
  title: String
  subtitle: String
  timestamp: DateTime
  isRead: bool
  tipo: String                      // ex: NOVA_RESERVA, RESERVA_CANCELADA
  payload: Map<String, dynamic>?    // ex: { codigo_publico, checkout_url }
}

// Modelo da resposta REST — host (já existe no backend)
NotificacaoHotel {
  id: int
  tipo: enum(NOVA_RESERVA, APROVACAO_RESERVA, PAGAMENTO_CONFIRMADO, RESERVA_CANCELADA, MENSAGEM_CHAT)
  payload: jsonb
  lida: bool
  created_at: timestamp
}
```

## Dependências

**Bibliotecas Flutter (adicionar no pubspec.yaml):**
- [ ] `firebase_messaging` — receber pushes FCM
- [ ] `firebase_core` — inicializar Firebase no Flutter

**Serviços externos:**
- [ ] Firebase Cloud Messaging — já configurado no backend; requer `google-services.json` (Android) e `GoogleService-Info.plist` (iOS) no projeto Flutter

**Outras features:**
- [ ] Auth (login/logout) — ponto de integração para registro e remoção do token FCM
- [ ] Tickets (`/tickets/details/:codigo_publico`) — destino de navegação ao tocar em notificação de reserva

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Token FCM expirado ou inválido | Backend já remove tokens inválidos em background no `fcm.service.ts` |
| Permissão de notificação negada pelo usuário | Solicitar permissão antes de registrar token; degradar graciosamente sem travar o login |
| Notificações do hóspede perdidas com reinstalação do app | Limitação aceita — inbox REST para hóspede é EXT-2 (task separada de backend) |
| App fechado no iOS sem background mode configurado | Adicionar `UIBackgroundModes` no `Info.plist` e habilitar push nas Xcode capabilities |
| Conflito de token entre múltiplos dispositivos | Backend usa UPSERT por device — já tratado no `dispositivoFcm.service.ts` |
