# Plan — notifications-system

> Derivado de: conductor/specs/notifications-system.spec.md
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [EM ANDAMENTO]

- [x] Adicionar `firebase_messaging`, `firebase_core` e `url_launcher` ao `pubspec.yaml`
- [x] Criar `lib/firebase_options.dart` com valores placeholder (app compila e sobe sem Firebase real)
- [ ] ⚠️ Rodar `flutterfire configure` para substituir placeholders com credenciais reais — **bloqueado por setup externo do projeto Firebase**
- [x] Criar `Frontend/web/firebase-messaging-sw.js` — service worker para FCM em background no browser (preencher config após flutterfire)
- [x] Atualizar `AndroidManifest.xml` com queries de https para url_launcher

---

## Backend [CONCLUÍDO]

> Toda a infraestrutura já existe — nenhuma task necessária.
> Endpoints de token FCM, inbox do hotel e FCM service estão implementados.

---

## Frontend [CONCLUÍDO]

- [x] Criar `FcmTokenService` (`lib/features/notifications/data/services/fcm_token_service.dart`) — registra e remove token FCM por role via REST
- [x] Criar `NotificacoesHostService` (`lib/features/notifications/data/services/notificacoes_host_service.dart`) — wraps REST inbox do hotel
- [x] Criar `GuestNotificationsStorage` (`lib/features/notifications/data/services/guest_notifications_storage.dart`) — persiste notificações do hóspede via SharedPreferences
- [x] Criar `NotificationService` (`lib/features/notifications/data/services/notification_service.dart`) — inicializa FCM, solicita permissão, escuta mensagens em foreground e background
- [x] Atualizar `app_notification.dart` — adicionar campos `tipo` e `payload`, fromJson, toJson
- [x] Atualizar `auth_notifier.dart` — chamar `FcmTokenService.register` no login e `FcmTokenService.remove` no logout por role
- [x] Atualizar `notifications_provider.dart` — AsyncNotifier com estado real (host REST, hóspede SharedPreferences) + `unreadNotificationsCountProvider`
- [x] Atualizar `custom_bottom_nav.dart` — badge vermelho no ícone de perfil quando há não lidas
- [x] Atualizar `main_layout.dart` — passa `unreadCount` ao CustomBottomNavBar
- [x] Atualizar `notifications_page.dart` — AsyncNotifier + navegação por `tipo` + `payload` no "ver detalhes"
- [x] Atualizar `main.dart` — inicializa Firebase, registra background handler, setup interaction handlers

---

## Validação [PENDENTE]

> ⚠️ Validação de push end-to-end bloqueada até `flutterfire configure` ser executado com projeto Firebase real.

- [ ] Host autenticado recebe push quando hóspede cria reserva e notificação aparece na lista carregada via REST
- [ ] Hóspede autenticado recebe push quando hotel aprova reserva; se `checkout_url` presente abre browser, senão abre ticket
- [ ] Tocar em notificação com `tipo = RESERVA_CANCELADA` navega para `/tickets/details/:codigo_publico`
- [ ] Badge do navbar exibe contagem correta de não lidas ao abrir o app
- [ ] Logout remove token FCM do backend
