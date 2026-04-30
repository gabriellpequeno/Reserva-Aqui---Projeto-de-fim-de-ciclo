# INFRA-1 — firebase-setup
> Derivada de: P4-G (notifications-system) — desbloqueia push end-to-end

## Objetivo
Configurar o projeto Firebase (Android + Web) e o backend para que as push notifications FCM funcionem no emulador, no navegador e em device físico via USB.

## Prioridade
**Bloqueador de P4-G** — sem isso push não chega ao app.

---

## Pré-condições (o que já existe, não refazer)

- `pubspec.yaml` já tem `firebase_core` e `firebase_messaging`
- `lib/firebase_options.dart` existe com PLACEHOLDERs — **será sobrescrito por `flutterfire configure`**
- `web/firebase-messaging-sw.js` existe como esqueleto — **será preenchido nesta task**
- Todo o código Flutter que escuta FCM já está implementado (P4-G)
- Backend já tem o `FcmService` (`sendPush`, etc.) — só falta a credencial

---

## O que precisa ser feito

### 1. Criar o projeto Firebase
- [ ] Acessar [console.firebase.google.com](https://console.firebase.google.com) e criar um novo projeto
  - Nome sugerido: `reservaqui-dev` (ou o nome do projeto do grupo)
  - Pode desabilitar Google Analytics se não precisar
- [ ] Em **Project Settings → General**, anotar o **Project ID** (ex: `reservaqui-dev-xxxxx`)

---

### 2. Registrar app Android
- [ ] Em **Project Settings → Your apps**, adicionar app Android
  - **Android package name:** `com.grupo4.reservaqui.reservaqui`
  - Apelido: `Reservaqui Android`
  - SHA-1/SHA-256: opcional para FCM, obrigatório só se usar Google Auth
- [ ] Baixar o `google-services.json` gerado
- [ ] Colocar em `Frontend/android/app/google-services.json`

---

### 3. Registrar app Web
- [ ] Em **Project Settings → Your apps**, adicionar app Web
  - Apelido: `Reservaqui Web`
  - **Não** habilitar Firebase Hosting (não é necessário)
- [ ] Anotar o objeto `firebaseConfig` exibido após criar (será usado no service worker)

---

### 4. Gerar VAPID key (Web Push)
- BFkRVCvk5gAEa7QH6xDTR-epwqSniL5ME7S0xISNfCHhzRnZspYOTsEpUATWfxEu9A_TifhqVNVavYD43g9Fm6I 

---

### 5. Instalar `flutterfire_cli` e gerar `firebase_options.dart`
```bash
# Instalar CLI (caso não tenha)
dart pub global activate flutterfire_cli

# Na raiz do projeto Flutter
cd "Frontend"
flutterfire configure \
  --project=<PROJECT_ID> \
  --platforms=android,web
```
- [ ] Confirmar que `lib/firebase_options.dart` agora tem valores reais (não PLACEHOLDER)
- [ ] O `google-services.json` do passo 2 precisa estar em `android/app/` antes de rodar

**Alternativa manual** (se o `flutterfire configure` falhar ou não tiver acesso ao Firebase CLI):
- Preencher manualmente `firebase_options.dart` com os valores do `firebaseConfig` da console
- Adicionar o campo `vapidKey` nas opções de web

---

### 6. Preencher `web/firebase-messaging-sw.js`
Abrir `Frontend/web/firebase-messaging-sw.js` e substituir os PLACEHOLDERs com os valores do `firebaseConfig` do app Web (passo 3):

```js
// Valores do firebaseConfig copiados do Firebase Console → app Web
const firebaseConfig = {
  apiKey: "<real_value>",
  authDomain: "<real_value>",
  projectId: "<real_value>",
  storageBucket: "<real_value>",
  messagingSenderId: "<real_value>",
  appId: "<real_value>",
};
```

---

### 7. Configurar credencial do backend (Admin SDK)
- [ ] Em **Project Settings → Service accounts**, clicar em **Generate new private key**
- [ ] Baixar o JSON gerado (ex: `reservaqui-dev-firebase-adminsdk-xxxx.json`)
- [ ] Minificar o JSON (remover espaços/quebras de linha):
  ```bash
  cat <arquivo>.json | tr -d '\n ' | pbcopy  # macOS
  cat <arquivo>.json | tr -d '\n '            # Linux — copiar manualmente
  ```
- [ ] Colar o JSON minificado no `Backend/.env`:
  ```
  FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"..."}
  ```
- [ ] **Não comitar o `.env` nem o arquivo JSON da service account no git**

---

### 8. Validação

#### Android (emulador ou device via USB)
- [ ] `flutter run -d <device>` sem erros de Firebase
- [ ] Login como hóspede → badge sem erros no console
- [ ] Login como hotel → mesmo
- [ ] Disparar evento que gera notificação (ex: criar reserva) → push chega no device

#### Web (navegador)
- [ ] `flutter run -d chrome` sem erros de Firebase
- [ ] Aceitar permissão de notificação quando solicitado
- [ ] Notificação aparece quando o app está em background/outra aba

#### Badge e lista
- [ ] Badge vermelho aparece no ícone de perfil (navbar) quando há notificações não lidas
- [ ] Lista de notificações carrega via REST (host) ou SharedPreferences (hóspede)

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `Frontend/lib/firebase_options.dart` | Sobrescrever PLACEHOLDERs com valores reais (via `flutterfire configure`) |
| `Frontend/android/app/google-services.json` | **Criar** — baixar do Firebase Console |
| `Frontend/web/firebase-messaging-sw.js` | Preencher `firebaseConfig` real + VAPID key |
| `Backend/.env` | Preencher `FIREBASE_SERVICE_ACCOUNT` com JSON minificado |

---

## Referências
- Firebase Console: https://console.firebase.google.com
- FlutterFire docs: https://firebase.flutter.dev/docs/overview
- FCM Web: https://firebase.google.com/docs/cloud-messaging/js/client

## Dependências
- **Desbloqueia:** P4-G validação (push end-to-end), EXT-3 (trigger MENSAGEM_CHAT)
- **Não depende de** nenhuma outra task de código — é 100% configuração externa

## Observações
- O arquivo `google-services.json` e o JSON da service account **não devem ir para o git** — verificar `.gitignore`
- iOS não está no escopo desta task (app sendo testado em Android + Web)
- Se o projeto Firebase for compartilhado entre membros do grupo, um membro gera as credenciais e distribui internamente (nunca via git público)
