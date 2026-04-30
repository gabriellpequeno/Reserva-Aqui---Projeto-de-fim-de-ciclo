# Manual de Credenciais Firebase — ReservAqui
> Complemento de: `INFRA-1-firebase-setup.md`
> Distribuir à equipe por canal seguro (WhatsApp, Discord privado, etc.) — **nunca comitar no git**

---

## Quem executa este manual

Um único membro da equipe executa os passos 1–6 e distribui os arquivos/valores gerados aos demais via canal seguro. Os outros membros só precisam dos passos 7–8 (colocar os arquivos nos lugares certos).

---

## Passo 1 — Criar o projeto Firebase

1. Acessar [console.firebase.google.com](https://console.firebase.google.com)
2. Clicar em **Add project**
3. Nome: `reservaqui-dev` (ou o nome que o grupo definir)
4. Google Analytics: pode desabilitar (não é necessário)
5. Aguardar criação e clicar em **Continue**
6. Em **Project Settings → General**, anotar o **Project ID** (ex: `reservaqui-dev-ab123`)

---

## Passo 2 — Registrar o app Android e baixar `google-services.json`

1. Em **Project Settings → Your apps**, clicar em **Add app → Android**
2. Preencher:
   - **Android package name:** `com.grupo4.reservaqui.reservaqui`
   - **App nickname:** `Reservaqui Android`
   - SHA-1: deixar em branco (não é necessário para FCM)
3. Clicar em **Register app**
4. **Baixar o `google-services.json`** na tela seguinte
5. Clicar em **Next** até finalizar (não precisa seguir as instruções do wizard — o projeto já está configurado)

**Distribuir:** arquivo `google-services.json` para cada membro da equipe.

---

## Passo 3 — Registrar o app Web e anotar `firebaseConfig`

1. Em **Project Settings → Your apps**, clicar em **Add app → Web** (`</>`)
2. Preencher:
   - **App nickname:** `Reservaqui Web`
   - Firebase Hosting: **não habilitar**
3. Clicar em **Register app**
4. Na tela seguinte, copiar o objeto `firebaseConfig` completo:
   ```js
   const firebaseConfig = {
     apiKey: "...",
     authDomain: "...",
     projectId: "...",
     storageBucket: "...",
     messagingSenderId: "...",
     appId: "..."
   };
   ```
5. Clicar em **Continue to console**

**Distribuir:** os valores do `firebaseConfig` para cada membro.

---

## Passo 4 — Gerar a VAPID key (Web Push)

> Necessária para que o navegador aceite push notifications via FCM.

1. Em **Project Settings → Cloud Messaging**
2. Rolar até a seção **Web configuration → Web Push certificates**
3. Clicar em **Generate key pair**
4. Copiar a **VAPID key** gerada (string longa em base64)

**Distribuir:** a VAPID key junto com o `firebaseConfig`.

---

## Passo 5 — Gerar a service account para o backend (Admin SDK)

1. Em **Project Settings → Service accounts**
2. Verificar que **Firebase Admin SDK** está selecionado
3. Clicar em **Generate new private key**
4. Confirmar no dialog
5. Baixar o arquivo JSON gerado (ex: `reservaqui-dev-firebase-adminsdk-xxxx.json`)
6. **Minificar** o JSON (remover espaços e quebras de linha):
   ```bash
   # Linux / macOS
   cat reservaqui-dev-firebase-adminsdk-xxxx.json | python3 -m json.tool --compact
   # ou
   cat reservaqui-dev-firebase-adminsdk-xxxx.json | tr -d '\n'
   ```
   O resultado é uma única linha começando com `{"type":"service_account",...}`

**Distribuir:** o JSON minificado (string única) para cada membro que rodar o backend.

> **ATENÇÃO:** o arquivo JSON original da service account tem permissões de administrador no projeto Firebase. Trate como senha — não comitar, não postar em chats públicos.

---

## Passo 6 — Instalar `flutterfire_cli` (quem vai rodar `flutterfire configure`)

```bash
# Instalar (necessário apenas uma vez por máquina)
dart pub global activate flutterfire_cli

# Verificar instalação
flutterfire --version

# Autenticar com Google (necessário para acessar o projeto Firebase)
firebase login
# ou
flutterfire login
```

> Se `flutterfire` não for encontrado no PATH, adicionar `~/.pub-cache/bin` ao PATH:
> ```bash
> export PATH="$PATH:$HOME/.pub-cache/bin"
> ```

---

## Passo 7 — Configurar o projeto Flutter (cada membro da equipe)

### 7a. Colocar `google-services.json` no lugar certo
```
Frontend/
  android/
    app/
      google-services.json   ← colocar aqui
```

### 7b. Gerar `firebase_options.dart` via CLI

```bash
cd "Frontend"

flutterfire configure \
  --project=<PROJECT_ID> \
  --platforms=android,web
```

Substituir `<PROJECT_ID>` pelo Project ID do passo 1 (ex: `reservaqui-dev-ab123`).

O comando vai sobrescrever `lib/firebase_options.dart` com os valores reais.

**Alternativa manual** (se não tiver acesso ao Firebase CLI):
Editar `lib/firebase_options.dart` diretamente e substituir cada `PLACEHOLDER` com os valores do `firebaseConfig` (passo 3). Para a opção web, adicionar também:
```dart
vapidKey: '<VAPID_KEY_DO_PASSO_4>',
```

### 7c. Preencher `web/firebase-messaging-sw.js`

Abrir `Frontend/web/firebase-messaging-sw.js` e substituir o bloco `firebaseConfig` com os valores do passo 3:
```js
const firebaseConfig = {
  apiKey: "...",        // ← valor real do passo 3
  authDomain: "...",
  projectId: "...",
  storageBucket: "...",
  messagingSenderId: "...",
  appId: "..."
};
```

---

## Passo 8 — Configurar o backend (cada membro que rodar o backend)

1. Abrir `Backend/.env`
2. Localizar a linha:
   ```
   FIREBASE_SERVICE_ACCOUNT=
   ```
3. Colar o JSON minificado do passo 5 logo após o `=`:
   ```
   FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"reservaqui-dev-ab123",...}
   ```
4. Salvar — **não comitar o `.env`**

---

## Checklist de segurança antes de qualquer `git push`

```bash
# Verificar se credenciais estão no .gitignore
grep "google-services.json" Frontend/.gitignore
grep "*.env" Backend/.gitignore        # ou .env especificamente
grep "firebase-adminsdk" .gitignore    # o JSON da service account

# Verificar se não há credenciais staged
git diff --cached | grep -i "service_account\|apiKey\|PLACEHOLDER"
```

Se `google-services.json` não estiver no `.gitignore` do Flutter, adicionar:
```
# Firebase
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
lib/firebase_options.dart
```

> `firebase_options.dart` pode ou não estar no gitignore dependendo da política do grupo — se commitado, todos compartilham as mesmas credenciais via git (mais prático, mas menos seguro para projetos públicos).

---

## Resumo do que distribuir

| Arquivo / Valor | Para quem | Como distribuir |
|-----------------|-----------|-----------------|
| `google-services.json` | Todos que rodam o app Android | Canal seguro (WhatsApp/Discord privado) |
| `firebaseConfig` (objeto JS) | Todos que rodam o app Web | Canal seguro |
| VAPID key | Todos que rodam o app Web | Canal seguro |
| `FIREBASE_SERVICE_ACCOUNT` (JSON minificado) | Todos que rodam o backend | Canal seguro |
