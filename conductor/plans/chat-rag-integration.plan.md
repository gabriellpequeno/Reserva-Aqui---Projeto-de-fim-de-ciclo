# Plan — Chat RAG Integration (In-App)

> Derivado de: conductor/specs/chat-rag-integration.spec.md
> Status geral: [PENDENTE]

---

## Setup & Infraestrutura [PENDENTE]

Nenhuma migration, variável de ambiente ou dependência nova necessária.
O pacote `uuid` do Dart será usado para gerar o `deviceId`; verificar se já está no `pubspec.yaml`.

---

## Backend [PENDENTE]

- [ ] Criar `chat.controller.ts` com handler `sendMessage`:
  - Validar `message` não vazia e `deviceId` presente
  - Extrair `userId` do JWT opcionalmente (sem `authGuard`, parse manual)
  - Buscar/criar sessão aberta (canal `APP`, `identificador_externo = deviceId`)
  - Enriquecer sessão com `userId` e `hotelId` se disponíveis
  - Persistir mensagem do usuário em `mensagem_chat`
  - Resolver `ChatContext` via `ContextResolverService`
  - Chamar `AgentOrchestratorService.processMessage()`
  - Persistir resposta do bot em `mensagem_chat`
  - Retornar `{ reply, sessionId }`

- [ ] Criar `chat.routes.ts` com `POST /message` (sem authGuard)

- [ ] Registrar rota em `app.ts`: `app.use(\`${API_PREFIX}/chat\`, chatRoutes)`

---

## Frontend [PENDENTE]

- [ ] Criar `chat_provider.dart`:
  - `ChatMessage` model (`text`, `isMe`, `timestamp`)
  - `ChatState` (`messages`, `isLoading`, `sessionId`, `error`)
  - `ChatNotifier` (StateNotifier) com `sendMessage(text)`:
    - Gera/recupera `deviceId` de SharedPreferences
    - Adiciona mensagem do usuário à lista
    - Seta `isLoading = true`
    - Chama `POST /chat/message` com `{ message, hotelId?, deviceId }`
    - Adiciona resposta do bot à lista
    - Seta `isLoading = false`
    - Em caso de erro: seta `error` com mensagem amigável
  - `chatProvider` exposto como `StateNotifierProvider`

- [ ] Converter `ChatPage` para `ConsumerStatefulWidget`:
  - Aceitar `hotelId` como parâmetro opcional (de queryParams)
  - `TextEditingController` no input
  - `ScrollController` com auto-scroll após nova mensagem
  - `ListView.builder` consumindo `chatProvider.messages`
  - Botão enviar chama `ref.read(chatProvider.notifier).sendMessage(text)`
  - Indicador de "digitando" (animação de `...`) quando `isLoading == true`
  - SnackBar de erro quando `error != null`
  - Header: substituir "Bo Turista" por "Assistente ReservAqui"
  - Mensagem de boas-vindas inicial ao abrir a tela pela primeira vez

- [ ] Atualizar `app_router.dart`:
  - Rota `/chat` passa `hotelId` de `state.uri.queryParameters['hotelId']` para `ChatPage`

---

## Validação [PENDENTE]

- [ ] Enviar "Oi" e receber mensagem de boas-vindas do bot
- [ ] Enviar "hotéis em Recife" e verificar que o bot busca hotéis no banco
- [ ] Indicador de "digitando" aparece e desaparece corretamente
- [ ] Auto-scroll funciona após cada nova mensagem
- [ ] Erro de rede exibe SnackBar (testar com backend offline)
- [ ] Sessão persiste entre aberturas do app (mesmo `deviceId`)
- [ ] Se logado, sessão associada ao `userId`
- [ ] Se `hotelId` passado via rota, bot já tem contexto do hotel
