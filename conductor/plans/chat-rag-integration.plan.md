# Plan — Chat RAG Integration (In-App)

> Derivado de: conductor/specs/chat-rag-integration.spec.md
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [CONCLUÍDO]

Nenhuma migration, variável de ambiente ou dependência nova necessária.
O `deviceId` é gerado com `Random.secure()` + timestamp (sem pacote `uuid`).

---

## Backend [CONCLUÍDO]

- [x] Criar `chat.controller.ts` com handler `sendMessage`:
  - Validar `message` não vazia e `deviceId` presente
  - Extrair `userId` do JWT opcionalmente (sem `authGuard`, parse manual)
  - Buscar/criar sessão aberta (canal `APP`, `identificador_externo = deviceId`)
  - Enriquecer sessão com `userId` e `hotelId` se disponíveis
  - Persistir mensagem do usuário em `mensagem_chat`
  - Resolver `ChatContext` via `ContextResolverService`
  - Chamar `AgentOrchestratorService.processMessage()`
  - Persistir resposta do bot em `mensagem_chat`
  - Retornar `{ reply, sessionId }`

- [x] Criar `chat.routes.ts` com `POST /message` (sem authGuard)

- [x] Registrar rota em `app.ts`: `app.use(\`${API_PREFIX}/chat\`, chatRoutes)`

---

## Frontend [CONCLUÍDO]

- [x] Criar `chat_provider.dart`:
  - `ChatMessage` model (`text`, `isMe`, `timestamp`)
  - `ChatState` (`messages`, `isLoading`, `sessionId`, `error`)
  - `ChatNotifier` (Riverpod `Notifier`) com `sendMessage(text)`:
    - Gera/recupera `deviceId` de SharedPreferences
    - Adiciona mensagem do usuário à lista
    - Seta `isLoading = true`
    - Chama `POST /chat/message` com `{ message, hotelId?, deviceId }`
    - Adiciona resposta do bot à lista
    - Seta `isLoading = false`
    - Em caso de erro: seta `error` com mensagem amigável
  - `chatProvider` exposto como `NotifierProvider`

- [x] Converter `ChatPage` para `ConsumerStatefulWidget`:
  - Aceitar `hotelId` como parâmetro opcional (de queryParams)
  - `TextEditingController` no input
  - `ScrollController` com auto-scroll após nova mensagem
  - `ListView.builder` consumindo `chatProvider.messages`
  - Botão enviar chama `ref.read(chatProvider.notifier).sendMessage(text)`
  - Indicador de "digitando" (animação de `...`) quando `isLoading == true`
  - SnackBar de erro quando `error != null`
  - Header: substituir "Bo Turista" por "Assistente ReservAqui"
  - Empty state com instruções ao abrir a tela pela primeira vez

- [x] Atualizar `app_router.dart`:
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
