# P4-G — notifications_page - feat/notifications-system

## Tela
`lib/features/notifications/presentation/pages/notifications_page.dart`

## Prioridade
**P4 — Listagens (Feature interna)**

## Branch sugerida
`feat/notifications-system-integration`

---

## Estado Atual

> **Implementado em** `llucasgoomes/res-20-p4-g-notifications-page`

**Frontend — implementado:**
- `AppNotification` estendido com `tipo`, `payload`, `fromJson`, `toJson`
- `FcmTokenService` — registra/remove token FCM por role via REST
- `NotificacoesHostService` — wraps inbox REST do hotel
- `GuestNotificationsStorage` — persiste notificações do hóspede via SharedPreferences
- `NotificationService` — escuta FCM foreground/background, setup interaction handlers, solicita permissão
- `NotificationsNotifier` migrado para `AsyncNotifier` — host via REST, hóspede via SharedPreferences
- `unreadNotificationsCountProvider` — badge derivado do estado
- `auth_notifier` — registra/remove token FCM no login/logout (fire-and-forget)
- `custom_bottom_nav` — badge vermelho no ícone de perfil
- `notifications_page` — AsyncNotifier + navegação por `tipo`+`payload` no "ver detalhes"
- `main.dart` — Firebase init + background handler + interaction handlers

**Bloqueado por setup externo:**
- `firebase_options.dart` criado com valores placeholder — precisa de `flutterfire configure` com projeto Firebase real para push end-to-end funcionar
- `web/firebase-messaging-sw.js` criado — precisa preencher config Firebase e VAPID key após flutterfire

**Backend — o que já existe e funciona:**
- FCM service completo (`sendPush`, `getUserTokens`, `getHotelTokens`)
- Triggers de push já disparando para cada evento de negócio (ver tabela abaixo)
- Inbox REST **somente para hotel** (`notificacao_hotel` table, com CRUD completo)
- FCM data payload já carrega: `tipo`, `codigo_publico`, `checkout_url`, `reserva_id`

**Backend — o que NÃO existe:**
- Inbox REST para hóspede (`GET /usuarios/notificacoes`) — **EXT-2**
- Trigger de FCM para mensagem de chat — **EXT-3** (`MENSAGEM_CHAT` está definido mas nunca disparado)

---

## Mapa completo de notificações

| Tipo | Quem recebe | Quando dispara | Deep-link (para onde vai) | FCM data disponível |
|------|-------------|----------------|---------------------------|---------------------|
| `NOVA_RESERVA` | Hotel | Hóspede cria reserva via app | `/tickets/details/:codigo_publico` | `reserva_id`, `codigo_publico` |
| `APROVACAO_RESERVA` | Hóspede | Hotel aprova OR link de pagamento gerado | link de pagamento via `checkout_url` (abre browser) OU `/tickets/details/:codigo_publico` se já pago | `codigo_publico`, `checkout_url?` |
| `PAGAMENTO_CONFIRMADO` | Hotel + Hóspede | Webhook InfinitePay confirma | Hóspede → `/tickets/details/:codigo_publico` \| Hotel → notificação interna | `codigo_publico`, `recibo_url` |
| `RESERVA_CANCELADA` | Hotel + Hóspede | Hóspede cancela reserva | `/tickets/details/:codigo_publico` | `codigo_publico` |
| `MENSAGEM_CHAT` | Hóspede | Mensagem recebida no chat *(EXT-3)* | `/chat` | *(a definir)* |

> **Regra de deep-link para `APROVACAO_RESERVA`:** se o FCM data tiver `checkout_url`, abrir URL de pagamento. Se não, abrir ticket (`codigo_publico`).

---

## Arquitetura de dados por role

### Hotel
- Fonte de dados: **REST** (`GET /hotel/notificacoes`)
- FCM serve como **trigger em tempo real** para atualizar a lista (não como única fonte)
- Dados persistidos no banco (`notificacao_hotel` table por schema do hotel)
- Badge de não lidas: campo `lida_em = null`

### Hóspede
- Fonte de dados: **FCM local** (sem REST inbox — EXT-2 seria criá-lo)
- Notifications FCM chegam com data suficiente para montar o card localmente
- Persistir recebidas no `shared_preferences` ou SQLite local
- OU aguardar EXT-2 (endpoint REST de inbox do usuário)

> **Recomendação:** implementar armazenamento local de FCM para o hóspede enquanto EXT-2 não existe. Quando EXT-2 for criado, migrar para REST.

---

## O que precisa ser feito

### 1. Estender o modelo `AppNotification`
- [x] Adicionar campo `tipo`
- [x] Adicionar campo `payload` (`Map<String, dynamic>?`)
- [x] `fromJson` / `toJson` implementados

### 2. Integrar `firebase_messaging` no Flutter
- [x] Adicionar dependência `firebase_messaging` no `pubspec.yaml`
- [x] Configurar `FirebaseMessaging.onMessage` (foreground) → adiciona ao notifier
- [x] Configurar `FirebaseMessaging.onMessageOpenedApp` (background) → deep-link
- [x] Configurar `FirebaseMessaging.instance.getInitialMessage()` (terminated) → deep-link no startup
- [x] Solicitar permissão de notificações ao usuário
- [ ] ⚠️ Push end-to-end bloqueado — aguarda `flutterfire configure` com projeto Firebase real

### 3. Registro e remoção de token FCM
- [x] No login: `FirebaseMessaging.instance.getToken()` → POST por role
- [x] No logout: DELETE por role

### 4. NotificationsNotifier — substituir mock
- [x] Host: `GET /hotel/notificacoes` + `PATCH lida` + `PATCH lida-todas`
- [x] Hóspede: FCM local + SharedPreferences

### 5. Deep-link ao tocar em notificação
- [x] Navegação por `tipo` + `payload` no "ver detalhes"
- [x] Handlers de background/terminated implementados

### 6. Badge de não lidas no navbar
- [x] `unreadNotificationsCountProvider` derivado do estado
- [x] Badge vermelho no ícone de perfil do `CustomBottomNav`

---

## Endpoints usados

| Método | Rota                                       | Auth | Descrição                           |
|--------|--------------------------------------------|------|-------------------------------------|
| GET    | `/hotel/notificacoes`                      | ✅   | Listar notificações (hotel)         |
| GET    | `/hotel/notificacoes?nao_lidas=true`       | ✅   | Filtrar não lidas (hotel)           |
| PATCH  | `/hotel/notificacoes/:id/lida`             | ✅   | Marcar como lida (hotel)            |
| PATCH  | `/hotel/notificacoes/lida-todas`           | ✅   | Marcar todas como lidas (hotel)     |
| POST   | `/dispositivos-fcm/usuario`                | ✅   | Registrar token FCM (guest)         |
| DELETE | `/dispositivos-fcm/usuario`                | ✅   | Remover token FCM (guest)           |
| POST   | `/dispositivos-fcm/hotel`                  | ✅   | Registrar token FCM (host)          |
| DELETE | `/dispositivos-fcm/hotel`                  | ✅   | Remover token FCM (host)            |
| GET    | `/usuarios/notificacoes` *(EXT-2)*         | ✅   | Inbox REST hóspede (a criar)        |

---

## Tasks de backend necessárias

| ID    | O que criar | Urgência |
|-------|-------------|----------|
| EXT-2 | `GET /usuarios/notificacoes` — inbox REST para hóspede com tabela `notificacao_usuario` equivalente à `notificacao_hotel` | Necessário para paridade com hotel. Sem isso o hóspede só tem FCM local. |
| EXT-3 | Trigger `MENSAGEM_CHAT`: quando mensagem WhatsApp chegar em `whatsappWebhook.service.ts`, disparar `sendPush` para o hóspede com `tipo: 'MENSAGEM_CHAT'` | Necessário para notificação de chat funcionar |

---

## Dependências
- **Requer:** P0 (AuthNotifier com role), P2-A (token obtido no login)
- **Requer para deep-link completo:** P5-D (`tickets_page`) e P5-E (`ticket_details_page`)
- **Requer parcialmente:** EXT-2 (inbox REST para hóspede), EXT-3 (chat notifications)
- **Pode iniciar** a parte do hotel sem EXT-2/EXT-3

## Bloqueia
— (folha)

---

## Observações
- Esta é a task com mais camadas: envolve FCM nativo (iOS/Android), REST, persistência local, deep-linking e múltiplos roles. Recomenda-se dividir em sub-tarefas: (1) setup FCM + registro de token, (2) inbox hotel, (3) inbox hóspede local, (4) deep-link.
- O backend já tem toda a infra de triggers funcionando — o frontend é quem precisa ser construído do zero aqui.
- O campo `ChatPage` tem um sino de notificação que ainda está não funcional — pode ser conectado ao badge do notifier nesta task.
