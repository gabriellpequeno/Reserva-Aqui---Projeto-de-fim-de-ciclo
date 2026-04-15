# Guia: Configuração do Firebase — ReservAqui

> Última atualização: 2026-04-15 (atualizado: suporte web)
> Status: aguardando criação do projeto Firebase

Este guia cobre **tudo** que precisa ser feito para ativar as notificações push no ReservAqui.
O backend já está 100% implementado e pronto — basta seguir os passos abaixo.

---

## Visão Geral

```
Firebase Console
  ├── Cria projeto
  ├── Registra app Android  (package: com.grupo4.reservaqui.reservaqui)
  ├── Registra app iOS      (Bundle ID — ver Xcode)
  ├── Registra app Web      (gera firebaseConfig + VAPID key)
  └── Gera Service Account  → backend (.env)

Flutter (Frontend/)
  ├── Instala pacotes Firebase
  ├── Adiciona google-services.json        (Android)
  ├── Adiciona GoogleService-Info.plist    (iOS)
  ├── Cria firebase-messaging-sw.js        (Web — service worker obrigatório)
  └── Escreve FcmService (pega token + chama API do backend)

Backend (já pronto — só configurar .env)
```

> **Diferenças importantes da Web vs Mobile**
> - Web usa **VAPID key** — sem ela `getToken()` retorna null na web
> - Background notifications na web funcionam via **Service Worker JS** — o `onBackgroundMessage()` do Dart **não é chamado** no browser
> - Web push só funciona em **HTTPS** (ou localhost em desenvolvimento)
> - O browser pede permissão de notificação ao usuário — sem `allow`, nenhum push chega

---

## Parte 1 — Firebase Console

### 1.1 Criar o projeto

1. Acesse [console.firebase.google.com](https://console.firebase.google.com)
2. Clique em **"Adicionar projeto"**
3. Nome sugerido: `reservaqui`
4. Google Analytics: pode desativar (não é necessário para FCM)
5. Clique em **"Criar projeto"**

---

### 1.2 Registrar o app Android

1. Na tela inicial do projeto, clique no ícone **Android** ("))
2. **Android package name:** `com.grupo4.reservaqui.reservaqui`
3. Apelido do app: `ReservAqui Android` (opcional)
4. SHA-1: deixar em branco por enquanto (necessário apenas para Google Sign-In)
5. Clique em **"Registrar app"**
6. **Baixe o `google-services.json`**
7. Coloque o arquivo em: `Frontend/android/app/google-services.json`
8. Clique em **"Próximo"** (os passos de gradle serão feitos na Parte 3)

---

### 1.3 Registrar o app iOS

1. Clique em **"Adicionar app"** → ícone **Apple**
2. **Bundle ID:** abra o Xcode (`Frontend/ios/Runner.xcworkspace`) → selecione o Target `Runner` → aba `Signing & Capabilities` → copie o valor de `Bundle Identifier`
   - Provavelmente também é `com.grupo4.reservaqui.reservaqui`
3. Apelido do app: `ReservAqui iOS` (opcional)
4. Clique em **"Registrar app"**
5. **Baixe o `GoogleService-Info.plist`**
6. No Xcode: arraste o arquivo para dentro da pasta `Runner` (marque "Copy items if needed")
   - **Não** coloque via File Explorer — precisa ser pelo Xcode para o Xcode reconhecer o arquivo
7. Clique em **"Próximo"** nas telas seguintes

---

### 1.4 Registrar o app Web

1. Na tela inicial do projeto, clique em **"Adicionar app"** → ícone **Web** (`</>`)
2. Apelido do app: `ReservAqui Web`
3. **Não** marque "Firebase Hosting" (não estamos usando)
4. Clique em **"Registrar app"**
5. O Console exibirá um objeto `firebaseConfig` — **copie e guarde**:
   ```javascript
   const firebaseConfig = {
     apiKey:            "AIza...",
     authDomain:        "reservaqui.firebaseapp.com",
     projectId:         "reservaqui",
     storageBucket:     "reservaqui.appspot.com",
     messagingSenderId: "1234567890",
     appId:             "1:1234...:web:abcd..."
   };
   ```
   Você vai precisar desse objeto para o **Service Worker** (Parte 4-Web).
6. Clique em **"Continuar no console"**

---

### 1.5 Gerar VAPID Key (obrigatório para Web)

A Web Push API exige uma VAPID key para que `getToken()` funcione no browser.

1. Firebase Console → ⚙️ **Configurações do projeto** → aba **"Cloud Messaging"**
2. Role até a seção **"Configuração da Web"**
3. Em **"Certificados push da Web"** → clique em **"Gerar par de chaves"**
4. Copie a chave pública gerada (string longa começando com `B...`)
5. Guarde — será usada no `FcmService` do Flutter

---

### 1.6 Gerar a Service Account (para o backend)

1. No console Firebase → ⚙️ **Configurações do projeto** → aba **"Contas de serviço"**
2. Clique em **"Gerar nova chave privada"**
3. Confirme no popup — um arquivo `.json` será baixado (ex: `reservaqui-firebase-adminsdk-xxxx.json`)
4. **NÃO commite este arquivo no git**

#### Converter para .env

O backend precisa do JSON em uma única linha. Execute no terminal:

```bash
# Windows (PowerShell)
(Get-Content reservaqui-firebase-adminsdk-xxxx.json -Raw) -replace "`r`n|`n", "" | Set-Clipboard

# Mac/Linux
cat reservaqui-firebase-adminsdk-xxxx.json | tr -d '\n' | pbcopy
```

Ou abra o arquivo e remova manualmente todas as quebras de linha.

#### Adicionar no .env do backend

```env
# Backend/.env
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"reservaqui","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-...@reservaqui.iam.gserviceaccount.com","client_id":"...","auth_uri":"...","token_uri":"...","auth_provider_x509_cert_url":"...","client_x509_cert_url":"...","universe_domain":"googleapis.com"}
```

> Atenção: o valor de `private_key` contém `\n` literais (não quebras de linha reais). Isso é correto e esperado — o SDK do Node.js sabe interpretar.

Reinicie o servidor após adicionar a variável. O log não exibirá nenhum erro de FCM se estiver correto.

---

## Parte 2 — Flutter: instalar pacotes

### 2.1 Instalar FlutterFire CLI (uma vez por máquina)

```bash
dart pub global activate flutterfire_cli
```

### 2.2 Adicionar dependências no pubspec.yaml

Abra `Frontend/pubspec.yaml` e adicione em `dependencies:`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # Firebase
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
```

Depois rode:

```bash
cd Frontend
flutter pub get
```

### 2.3 Configurar Firebase via FlutterFire CLI

```bash
cd Frontend
flutterfire configure --project=reservaqui
```

Este comando detecta os apps Android/iOS registrados, baixa os arquivos de configuração e gera `lib/firebase_options.dart` automaticamente. Se já colocou os arquivos manualmente nos passos 1.2 e 1.3, ainda assim rode este comando — ele gera o `firebase_options.dart` necessário.

---

## Parte 3 — Android: configurar Gradle

### 3.1 `Frontend/android/build.gradle.kts` (nível de projeto)

Adicione o plugin do Google Services:

```kotlin
// No topo, dentro de plugins {}
plugins {
    // ... plugins existentes ...
    id("com.google.gms.google-services") version "4.4.1" apply false
}
```

### 3.2 `Frontend/android/app/build.gradle.kts` (nível de app)

Adicione o plugin no topo:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ← adicionar esta linha
}
```

---

## Parte 4-Web — Service Worker (obrigatório para notificações web)

Esta é a etapa mais diferente do mobile. No browser, notificações em background são gerenciadas por um **Service Worker JavaScript** — não pelo Dart. Sem este arquivo, o browser não exibe notificações quando o app está em background ou fechado.

### 4-Web.1 Criar `Frontend/web/firebase-messaging-sw.js`

Crie o arquivo com o conteúdo abaixo, substituindo o `firebaseConfig` pelos valores copiados no passo 1.4:

```javascript
// Frontend/web/firebase-messaging-sw.js

// Versão do SDK deve bater com a usada pelo flutterfire.
// Consulte firebase_options.dart após rodar flutterfire configure — o comentário
// gerado indica a versão correta. Se não tiver, use a última versão estável do
// Firebase JS SDK v10.x (ex: 10.14.0).
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-messaging-compat.js');

// Cole aqui o firebaseConfig copiado no passo 1.4 do Firebase Console
firebase.initializeApp({
  apiKey:            "AIza...",
  authDomain:        "reservaqui.firebaseapp.com",
  projectId:         "reservaqui",
  storageBucket:     "reservaqui.appspot.com",
  messagingSenderId: "1234567890",
  appId:             "1:1234...:web:abcd..."
});

const messaging = firebase.messaging();

// Tratamento de mensagens em background (app fechado ou aba em segundo plano)
// Este handler substitui o onBackgroundMessage() do Dart, que NÃO funciona na web.
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'ReservAqui';
  const body  = payload.notification?.body  ?? '';

  // Exibe a notificação nativa do browser
  self.registration.showNotification(title, {
    body:  body,
    icon:  '/icons/Icon-192.png',  // ícone já existente em Frontend/web/icons/
    badge: '/icons/Icon-192.png',
    data:  payload.data,           // contém: tipo, reserva_id, codigo_publico etc.
  });
});

// Ao clicar na notificação: foca a janela do app ou abre uma nova
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      if (clientList.length > 0) {
        return clientList[0].focus();
      }
      return clients.openWindow('/');
    }),
  );
});
```

> **Por que usar a SDK "compat"?** O Service Worker roda em um contexto isolado sem suporte a ES modules. A versão `compat` (importada via `importScripts`) é a forma correta para service workers.

### 4-Web.2 Registrar o Service Worker no Flutter

O Flutter Web registra service workers automaticamente se o arquivo estiver em `Frontend/web/`. Nenhuma alteração em `index.html` é necessária.

Para confirmar que o service worker está ativo após rodar `flutter run -d chrome`:
1. Abra DevTools → Application → Service Workers
2. Deve aparecer `firebase-messaging-sw.js` com status `activated`

---

## Parte 4-iOS — APNs (Apple Push Notification service)

O FCM no iOS usa o APNs por baixo. Sem configurar isso, notificações **não chegam em dispositivos iOS reais** (no simulador funciona sem).

### 4.1 Conta Apple Developer

1. Acesse [developer.apple.com](https://developer.apple.com) → **Certificates, IDs & Profiles**
2. Vá em **Keys** → **"+"**
3. Nome: `ReservAqui APNs`
4. Marque **"Apple Push Notifications service (APNs)"**
5. Clique em **Register** → **Download** (arquivo `.p8`)
6. Anote o **Key ID** e o **Team ID** (aparece no canto superior direito)

### 4.2 Vincular APNs ao Firebase

1. Firebase Console → Configurações do projeto → aba **"Cloud Messaging"**
2. Role até **"Configuração do app Apple"**
3. Em **"Chaves APNs"** → **"Carregar"**
4. Envie o arquivo `.p8`, Key ID e Team ID

---

## Parte 5 — Flutter: código de integração

### 5.1 Inicializar Firebase em `main.dart`

Modifique `Frontend/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // gerado pelo flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

### 5.2 Criar `Frontend/lib/services/fcm_service.dart`

Este arquivo é responsável por:
1. Pedir permissão ao usuário (iOS obrigatório, Android 13+ recomendado)
2. Obter o token FCM do dispositivo
3. Enviar o token para o backend via `POST /api/dispositivos-fcm/usuario` ou `/hotel`
4. Escutar mensagens em foreground

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // kIsWeb

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Cole aqui a VAPID key gerada no passo 1.5 do Firebase Console.
  // Necessária APENAS na web — no mobile getToken() funciona sem ela.
  static const _vapidKey = 'BExemplo_SuaChaveVapidAqui...';

  /// Chame após o login do usuário hóspede.
  Future<void> initForUsuario(String jwtToken) async {
    await _requestPermission();
    final token = await _getToken();
    if (token == null) return;

    await _registerToken(
      token:    token,
      jwtToken: jwtToken,
      endpoint: '/api/dispositivos-fcm/usuario',
      origem:   _resolveOrigem(isHotel: false),
    );

    _listenForeground();
  }

  /// Chame após o login do hotel.
  Future<void> initForHotel(String jwtToken) async {
    await _requestPermission();
    final token = await _getToken();
    if (token == null) return;

    await _registerToken(
      token:    token,
      jwtToken: jwtToken,
      endpoint: '/api/dispositivos-fcm/hotel',
      origem:   _resolveOrigem(isHotel: true),
    );

    _listenForeground();
  }

  /// Chame no logout — remove o token do backend.
  Future<void> removeToken({
    required String jwtToken,
    required bool isHotel,
  }) async {
    final token = await _getToken();
    if (token == null) return;

    final endpoint = isHotel
        ? '/api/dispositivos-fcm/hotel'
        : '/api/dispositivos-fcm/usuario';

    await _deleteToken(endpoint: endpoint, jwtToken: jwtToken, fcmToken: token);
    await _messaging.deleteToken();
  }

  // ── Privados ──────────────────────────────────────────────────────────────

  /// Obtém o token FCM.
  /// Na web: obrigatório passar vapidKey, sem ela retorna null.
  /// No mobile: vapidKey é ignorado.
  Future<String?> _getToken() async {
    if (kIsWeb) {
      return _messaging.getToken(vapidKey: _vapidKey);
    }
    return _messaging.getToken();
  }

  /// Resolve o campo `origem` conforme a plataforma atual.
  String _resolveOrigem({required bool isHotel}) {
    if (kIsWeb)              return 'DASHBOARD_WEB';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'APP_IOS';
    return 'APP_ANDROID';
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );
  }

  Future<void> _registerToken({
    required String token,
    required String jwtToken,
    required String endpoint,
    required String origem,
  }) async {
    // POST BASE_URL + endpoint
    // Headers: { Authorization: 'Bearer $jwtToken' }
    // Body:    { "fcm_token": token, "origem": origem }
    throw UnimplementedError('Implemente com seu cliente HTTP');
  }

  Future<void> _deleteToken({
    required String endpoint,
    required String jwtToken,
    required String fcmToken,
  }) async {
    // DELETE BASE_URL + endpoint
    // Headers: { Authorization: 'Bearer $jwtToken' }
    // Body:    { "fcm_token": fcmToken }
    throw UnimplementedError('Implemente com seu cliente HTTP');
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // App aberto (mobile E web) — o sistema NÃO exibe notificação automaticamente.
      // Exiba um banner/snackbar com message.notification?.title
      // message.data contém: tipo, reserva_id, codigo_publico, etc.
      //
      // Na web em background: o Service Worker (firebase-messaging-sw.js) exibe
      // a notificação nativa do browser — este handler NÃO é chamado.
    });
  }
}
```

### 5.3 Handler de background — mobile (não funciona na web)

Adicione **no nível global** (fora de qualquer classe) em `main.dart`:

```dart
import 'package:flutter/foundation.dart'; // kIsWeb

// Deve ser top-level function — NÃO funciona no browser.
// Na web, o firebase-messaging-sw.js assume esse papel.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // iOS/Android com app fechado ou em background:
  // O sistema já exibe a notificação automaticamente.
  // Use para atualizar cache local se necessário.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // onBackgroundMessage só pode ser registrado no mobile.
  // Na web o compilador aceita a chamada, mas ela é ignorada — o SW cuida disso.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  runApp(const MyApp());
}
```

---

## Parte 6 — Verificação final

### Checklist backend

- [ ] `FIREBASE_SERVICE_ACCOUNT` adicionado no `Backend/.env`
- [ ] Servidor reiniciado
- [ ] Log não exibe `[FCM] FIREBASE_SERVICE_ACCOUNT não configurado`

### Checklist Android

- [ ] `google-services.json` em `Frontend/android/app/`
- [ ] Plugin `com.google.gms.google-services` nos dois `build.gradle.kts`
- [ ] `flutter pub get` executado

### Checklist iOS

- [ ] `GoogleService-Info.plist` adicionado via Xcode (dentro de `Runner/`)
- [ ] APNs Key (`.p8`) vinculada no Firebase Console
- [ ] Capabilities: `Push Notifications` e `Background Modes → Remote notifications` ativados no Xcode

### Checklist Flutter (mobile)

- [ ] `firebase_core` e `firebase_messaging` no `pubspec.yaml`
- [ ] `firebase_options.dart` gerado via `flutterfire configure`
- [ ] `Firebase.initializeApp()` em `main()`
- [ ] `FirebaseMessaging.onBackgroundMessage()` registrado antes do `runApp()` (dentro de `if (!kIsWeb)`)
- [ ] `FcmService.initForUsuario()` chamado após login do hóspede
- [ ] `FcmService.initForHotel()` chamado após login do hotel
- [ ] `FcmService.removeToken()` chamado no logout

### Checklist Web

- [ ] App Web registrado no Firebase Console (passo 1.4)
- [ ] VAPID key gerada e colada em `FcmService._vapidKey` (passo 1.5)
- [ ] `firebase-messaging-sw.js` criado em `Frontend/web/` com o `firebaseConfig` correto
- [ ] Em DevTools → Application → Service Workers: arquivo aparece como `activated`
- [ ] Em produção: servir sob **HTTPS** (web push é bloqueado em HTTP)
- [ ] Versão do SDK no service worker (`10.x.x`) bate com a versão do `firebase_options.dart`

### Teste de ponta a ponta

**Mobile:**
1. Suba o backend com `FIREBASE_SERVICE_ACCOUNT` configurado
2. Rode o Flutter em um dispositivo físico (não simulador para iOS)
3. Faça login como hóspede → `POST /api/dispositivos-fcm/usuario` é chamado
4. Confirme no banco: `SELECT fcm_token, origem FROM dispositivo_fcm WHERE user_id = '<id>';`
5. Em outro dispositivo, faça login como hotel
6. Crie uma reserva como hóspede → hotel recebe push **"Nova reserva recebida"** em <2s
7. Aprove a reserva como hotel → hóspede recebe push **"Reserva aprovada!"**

**Web:**
1. Abra o dashboard do hotel em `http://localhost` (ou HTTPS em produção)
2. Faça login como hotel → `POST /api/dispositivos-fcm/hotel` é chamado com `origem: DASHBOARD_WEB`
3. Confirme no banco: `SELECT fcm_token, origem FROM dispositivo_fcm WHERE hotel_id = '<id>';`
4. No app mobile, crie uma reserva como hóspede
5. O browser do hotel deve exibir a notificação nativa do SO em <2s
6. Minimize o browser (background) e repita — desta vez é o Service Worker que exibe

---

## Dados enviados em cada push

O campo `data` de cada push contém os seguintes campos, que o Flutter pode usar para navegar para a tela correta:

| Evento | `tipo` | Campos extras |
|--------|--------|---------------|
| Nova reserva | `NOVA_RESERVA` | `reserva_id` |
| Aprovação | `APROVACAO_RESERVA` | `codigo_publico` |
| Cancelamento | `RESERVA_CANCELADA` | `reserva_id`, `codigo_publico` |
| Pagamento *(futuro)* | `PAGAMENTO_CONFIRMADO` | `reserva_id`, `checkout_url` |

Acesse via `message.data['tipo']`, `message.data['codigo_publico']`, etc.

---

## Arquivos que devem ser ignorados no git

Adicione ao `.gitignore` se ainda não estiver:

```gitignore
# Firebase credentials
*-adminsdk-*.json
Frontend/android/app/google-services.json
Frontend/ios/Runner/GoogleService-Info.plist
```

> `google-services.json` e `GoogleService-Info.plist` **não são secrets críticos** (são públicos por natureza), mas é boa prática não commitar para evitar dificultar a troca de projeto Firebase no futuro.
> O arquivo da service account (`.json` baixado no passo 1.4) **é um secret** e jamais deve ser commitado.
