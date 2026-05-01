# Spec — firebase-fcm-setup

## Referência
- **PRD:** conductor/features/firebase-fcm-setup.prd.md
- **Task:** conductor/__task/INFRA-1-firebase-setup.md
- **Manual de credenciais:** conductor/__task/INFRA-1-credenciais-firebase.md
- **Desbloqueia:** conductor/plans/notifications-system.plan.md (seção Validação)

## Abordagem Técnica

Configuração puramente externa — nenhuma lógica de negócio muda. O código Flutter e o backend já estão prontos (P4-G); o que precisa acontecer é substituir 4 locais com PLACEHOLDERs por credenciais reais geradas no Firebase Console, e garantir que o `.gitignore` protege esses arquivos. A VAPID key aparece em dois lugares no Flutter (`notification_service.dart` e `firebase_options.dart`) e precisa ser a mesma em ambos.

---

## Componentes Afetados

### Backend

| Arquivo | O que muda |
|---------|-----------|
| `Backend/.env` | Preencher `FIREBASE_SERVICE_ACCOUNT` com JSON minificado da service account |

Nenhum arquivo de código muda — `fcm.service.ts` já lê `FIREBASE_SERVICE_ACCOUNT` do processo.

### Frontend

| Arquivo | O que muda | Método |
|---------|-----------|--------|
| `lib/firebase_options.dart` | Substituir todos os PLACEHOLDERs + adicionar `vapidKey` nas opções web | `flutterfire configure` (preferencial) ou edição manual |
| `lib/features/notifications/data/services/notification_service.dart:38` | Substituir `'REPLACE_WITH_YOUR_VAPID_KEY'` pela VAPID key real | Edição manual |
| `web/firebase-messaging-sw.js` | Substituir os 6 campos `REPLACE_WITH_YOUR_*` pelo `firebaseConfig` real | Edição manual |
| `android/app/google-services.json` | **Criar** — baixar do Firebase Console | Firebase Console |
| `.gitignore` (Flutter) | Adicionar `android/app/google-services.json` se não estiver presente | Edição manual |

---

## Detalhe por arquivo

### `lib/firebase_options.dart`

Após `flutterfire configure`, o arquivo é sobrescrito automaticamente com todos os valores. Se feito manualmente, a seção web precisa incluir o campo `vapidKey` que **não existe no template atual**:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: '...',
  appId: '...',
  messagingSenderId: '...',
  projectId: '...',
  authDomain: '...',
  storageBucket: '...',
  vapidKey: '...',   // ← ADICIONAR — obrigatório para getToken() no browser funcionar
);
```

### `notification_service.dart:38`

```dart
// Antes
vapidKey: 'REPLACE_WITH_YOUR_VAPID_KEY',

// Depois
vapidKey: DefaultFirebaseOptions.web.vapidKey,  // referência ao firebase_options.dart
// ou diretamente:
vapidKey: '<VAPID_KEY_REAL>',
```

> Preferir referenciar `DefaultFirebaseOptions.web.vapidKey` para manter a VAPID key em um único lugar.

### `web/firebase-messaging-sw.js`

```js
// Antes
firebase.initializeApp({
  apiKey: "REPLACE_WITH_YOUR_API_KEY",
  authDomain: "REPLACE_WITH_YOUR_AUTH_DOMAIN",
  projectId: "REPLACE_WITH_YOUR_PROJECT_ID",
  storageBucket: "REPLACE_WITH_YOUR_STORAGE_BUCKET",
  messagingSenderId: "REPLACE_WITH_YOUR_MESSAGING_SENDER_ID",
  appId: "REPLACE_WITH_YOUR_APP_ID",
});

// Depois — valores do Firebase Console → Project Settings → Web app
firebase.initializeApp({
  apiKey: "<real>",
  authDomain: "<real>",
  projectId: "<real>",
  storageBucket: "<real>",
  messagingSenderId: "<real>",
  appId: "<real>",
});
```

> A versão do SDK no service worker (`firebasejs/10.7.1`) deve ser compatível com a do `firebase_core` no `pubspec.yaml` (`^3.15.2` → Firebase JS SDK 10.x). Já está correto — não alterar a linha `importScripts`.

### `.gitignore` do Flutter

O `.gitignore` atual **não inclui** `google-services.json`. Adicionar:

```
# Firebase credentials — nunca comitar
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

> `lib/firebase_options.dart` pode ser commitado (opção mais prática para equipe) desde que o projeto Firebase seja de uso exclusivo do grupo e o repositório seja privado. Se o repositório for público, adicionar ao `.gitignore` e distribuir via manual de credenciais.

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| VAPID key referenciada via `DefaultFirebaseOptions.web.vapidKey` | Evita duplicação — um único lugar para atualizar se o projeto Firebase mudar |
| Service account como JSON minificado em variável de ambiente | Padrão do projeto — Backend já lê `FIREBASE_SERVICE_ACCOUNT` do `process.env` |
| `flutterfire configure` como método preferencial | Gera `firebase_options.dart` corretamente incluindo `vapidKey` e `google-services.json` no lugar certo |
| Escopo: Android + Web apenas | iOS não está no ambiente de apresentação — APNs certificate exigiria conta Apple Developer |

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| `flutterfire configure` não encontrado no PATH | Adicionar `~/.pub-cache/bin` ao PATH — ver manual de credenciais |
| Versão do Firebase JS SDK no service worker incompatível | Já está em `10.7.1` compatível com `firebase_core ^3.15.2` — não alterar |
| `google-services.json` acidentalmente commitado | Adicionar ao `.gitignore` antes de fazer `git add` — checklist no manual |
| VAPID key em dois lugares diferentes causando dessincronização | Resolver na implementação: `notification_service.dart` referencia `DefaultFirebaseOptions.web.vapidKey` |
| Backend não recarrega `.env` após edição | Reiniciar o processo do backend após preencher `FIREBASE_SERVICE_ACCOUNT` |
| Push web não funciona em HTTP | Service worker requer HTTPS ou `localhost` — em dev local, usar `localhost` |

---

## Ordem de execução recomendada

1. Um membro executa o **manual de credenciais** (gera e distribui tudo)
2. Cada membro: coloca `google-services.json` em `android/app/`
3. Cada membro: atualiza `.gitignore`
4. Cada membro: roda `flutterfire configure` — ou edita manualmente os arquivos Flutter
5. Cada membro: edita `notification_service.dart:38` com a VAPID key
6. Cada membro: preenche `web/firebase-messaging-sw.js`
7. Cada membro que roda o backend: preenche `FIREBASE_SERVICE_ACCOUNT` no `.env` e reinicia
8. Validação — cheklist em `INFRA-1-firebase-setup.md`

---

## Contratos de Ambiente

```
# Backend/.env
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"...","private_key":"..."}

# Não há variáveis de ambiente novas no Flutter — credenciais ficam nos arquivos de config
```
