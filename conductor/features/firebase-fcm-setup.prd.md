# PRD — firebase-fcm-setup

## Contexto
O ReservAqui já possui todo o sistema de notificações push implementado no Flutter (P4-G): código FCM, handlers de foreground/background/terminated, registro de token por role, inbox REST para host e armazenamento local para hóspede. O backend tem FCM service completo com triggers para todos os eventos de negócio. Porém, o projeto Firebase nunca foi configurado — `firebase_options.dart` contém PLACEHOLDERs, não existe `google-services.json` no Android, o service worker web está vazio e o backend tem `FIREBASE_SERVICE_ACCOUNT` em branco. Nenhum push chega ao app.

## Problema
Apesar de toda a implementação Flutter e backend estar pronta, nenhuma notificação push é entregue porque as credenciais Firebase não foram geradas e distribuídas. O sistema de notificações — badge de não lidas, deep-link ao tocar, inbox do hotel — é completamente inerte sem a configuração do projeto Firebase.

## Público-alvo
Desenvolvedores da equipe que precisam subir e demonstrar o ambiente (local, emulador, device físico via USB ou navegador web). A configuração é interna — o benefício final é desbloqueado para hóspedes e hotéis que passam a receber notificações reais de eventos críticos (reserva criada, aprovada, cancelada, pagamento confirmado).

## Requisitos Funcionais
1. Projeto Firebase criado no Firebase Console com apps Android e Web registrados para o ReservAqui
2. `google-services.json` com credenciais reais presente em `Frontend/android/app/`
3. `firebase_options.dart` gerado via `flutterfire configure` — sem nenhum valor PLACEHOLDER
4. `web/firebase-messaging-sw.js` preenchido com `firebaseConfig` real e VAPID key para web push
5. Backend com `FIREBASE_SERVICE_ACCOUNT` preenchido no `.env` (Admin SDK habilitado para envio de push)
6. Token FCM registrado corretamente no login por role (hóspede e hotel) e removido no logout
7. Push notification entregue e visível em: emulador Android, device físico via USB e navegador web (Chrome)

> **VAPID key:** necessária para push no navegador (Web Push). Gerada em **Project Settings → Cloud Messaging → Web Push certificates → Generate key pair** no Firebase Console. Quem configurar o projeto gera e distribui à equipe via canal seguro — ver `conductor/__task/INFRA-1-credenciais-firebase.md`.

## Requisitos Não-Funcionais
- [ ] Segurança: `google-services.json` e o JSON da service account **nunca** commitados no git — verificar `.gitignore` antes de qualquer push
- [ ] Segurança: credenciais distribuídas à equipe por canal seguro (não por repositório público) — ver manual de credenciais
- [ ] Confiabilidade: se permissão de notificação for negada pelo SO, o app não deve travar — continuar funcionando sem badge e sem push, sem crashes
- [ ] Compatibilidade: Android API 21+ e browsers modernos (Chrome, Edge, Firefox)
- [ ] Rastreabilidade: um único membro da equipe é responsável por gerar as credenciais e distribuí-las internamente

## Critérios de Aceitação
- Dado que o app roda no emulador ou device Android, quando um hóspede cria uma reserva, então o hotel recebe push notification com o conteúdo correto
- Dado que o app roda no navegador (Chrome), quando está em aba em background, então a push notification aparece na área de notificações do sistema operacional
- Dado que o usuário faz logout, quando o logout é concluído, então o token FCM é removido do backend (sem token órfão)
- Dado que permissão de notificação é negada pelo SO, quando o usuário faz login, então o app continua funcionando normalmente sem crash
- Dado que o app está **fechado** (terminated state — processo encerrado pelo SO, não apenas em background), quando o usuário toca em uma notificação push recebida, então o app é iniciado e navega diretamente para a tela correspondente ao `tipo` da notificação (ex: `RESERVA_CANCELADA` → `/tickets/details/:codigo_publico`)

> **Nota sobre terminated state:** diferente do background (app pausado, processo vivo), o terminated state significa que o SO encerrou o processo do app. Firebase Messaging entrega a notificação via sistema operacional mesmo assim. Ao tocar, o app faz cold start e precisa recuperar a mensagem via `FirebaseMessaging.instance.getInitialMessage()` para executar o deep-link — esse handler já está implementado em `main.dart` (P4-G) e será validado aqui.

## Fora de Escopo
- Configuração iOS (APNs certificate, Xcode capabilities, `GoogleService-Info.plist`) — não está no ambiente de apresentação
- Firebase Hosting
- Google Analytics e Crashlytics
- Ambiente de produção — escopo: dev/apresentação apenas
- EXT-2 (inbox REST para hóspede) e EXT-3 (trigger de notificação de chat)
- Múltiplos projetos Firebase (dev vs. prod) — um único projeto para esta entrega
