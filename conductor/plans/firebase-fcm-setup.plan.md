# Plan — firebase-fcm-setup

> Derivado de: conductor/specs/firebase-fcm-setup.spec.md
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Projeto Firebase criado (`reservaqui-45478`)
- [x] App Android registrado no Firebase Console
- [x] `google-services.json` baixado e colocado em `Frontend/android/app/`
- [x] App Web registrado no Firebase Console
- [x] VAPID key gerada em Project Settings → Cloud Messaging → Web Push certificates
- [x] Service account key gerada em Project Settings → Service accounts → Generate new private key
- [x] `android/app/google-services.json` adicionado ao `.gitignore` do Flutter

---

## Backend [CONCLUÍDO]

- [x] Preencher `FIREBASE_SERVICE_ACCOUNT` no `Backend/.env` com o JSON minificado da service account
- [x] Reiniciar o processo do backend para recarregar o `.env`

---

## Frontend [CONCLUÍDO]

- [x] `lib/firebase_options.dart` preenchido com valores reais (web + android) e `vapidKey`
- [x] `web/firebase-messaging-sw.js` preenchido com `firebaseConfig` real
- [x] `lib/features/notifications/data/services/notification_service.dart:38` referenciando `DefaultFirebaseOptions.web.vapidKey`

---

## Validação [PENDENTE]

- [ ] Android emulador/device: push chega ao hotel quando hóspede cria reserva
- [ ] Web (Chrome): push aparece no SO com app em aba em background
- [ ] Logout: token FCM removido do backend (sem token órfão)
- [ ] Permissão de notificação negada: app continua sem crash
- [ ] Terminated state: tocar em notificação com app fechado navega para a tela correta

---

## Mapa de credenciais — o que buscar e onde colocar

> Você já tem: **VAPID key** ✅

### 1. `firebaseConfig` Web
**Onde buscar:** Firebase Console → Project Settings → Your apps → app Web (ícone `</>`) → SDK setup and configuration

```
apiKey, authDomain, projectId, storageBucket, messagingSenderId, appId
```

**Onde colocar:**
- `lib/firebase_options.dart` — seção `web` (ou gerado automaticamente via `flutterfire configure`)
- `web/firebase-messaging-sw.js` — bloco `firebase.initializeApp({...})`

---

### 2. VAPID key ✅ (você já tem)
**Onde colocar:**
- `lib/firebase_options.dart` — campo `vapidKey` na seção `web` (adicionar manualmente após o `flutterfire configure`)
- `lib/features/notifications/data/services/notification_service.dart:38` — via referência `DefaultFirebaseOptions.web.vapidKey` ou direto como string

```dart
// firebase_options.dart — seção web
static const FirebaseOptions web = FirebaseOptions(
  apiKey: '...',
  appId: '...',
  messagingSenderId: '...',
  projectId: '...',
  authDomain: '...',
  storageBucket: '...',
  vapidKey: '<SUA_VAPID_KEY_AQUI>',  // ← adicionar aqui
);

// notification_service.dart:38
vapidKey: DefaultFirebaseOptions.web.vapidKey,  // ← referenciar daqui
```

---

### 3. Service account JSON (Admin SDK — para o backend enviar pushes)
**Onde buscar:** Firebase Console → Project Settings → Service accounts → **Generate new private key** → baixar JSON

**Minificar antes de colar:**
```bash
cat <arquivo-baixado>.json | python3 -m json.tool --compact
# resultado: uma única linha começando com {"type":"service_account",...}
```

**Onde colocar:** `Backend/.env`
```
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"reservaqui-45478",...}
```

> ⚠️ Não comitar o `.env` nem o arquivo JSON original — são credenciais de administrador do projeto Firebase.

---

### 4. Credenciais Android
**Status:** ✅ `google-services.json` já está em `android/app/` com o projeto `reservaqui-45478`.
O `flutterfire configure` lê esse arquivo automaticamente para preencher a seção `android` do `firebase_options.dart`.
