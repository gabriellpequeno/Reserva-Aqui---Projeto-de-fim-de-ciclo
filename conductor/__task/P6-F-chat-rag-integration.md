# P6-F — Chat RAG Integration

## Tela
`lib/features/chat/presentation/pages/chat_page.dart`

## Prioridade
**P6 — Features Avançadas (diferencial de apresentação)**

## Branch sugerida
`res-66-p6-f-chat-rag-integration`

## Rota
`/chat` (com queryParam opcional `?hotelId=xxx`)

---

## Estado Atual
Tela de chat com layout visual pronto (header, ListView de ChatBubble, input + botão enviar), mas 100% estática — mensagens hardcoded, input desconectado, botão enviar sem ação.

## O que integrar

### Backend

- [ ] Criar endpoint REST `POST /api/v1/chat/message`:
  - Body: `{ "message": "string", "hotelId"?: "string", "deviceId": "string" }`
  - Auth: Pública (sem `authGuard`), mas enriquece com `userId` se JWT presente
  - Response: `{ "reply": "string", "sessionId": "string" }`
  - Internamente: gerencia sessão (canal `APP`), persiste mensagens, chama `AgentOrchestratorService.processMessage()`

- [ ] Registrar rota em `app.ts`

### Frontend

- [ ] Criar `ChatNotifier` (StateNotifier) com:
  - `List<ChatMessage>` — estado local da conversa
  - `bool isLoading` — enquanto aguarda resposta do bot
  - `sendMessage(String text)` — adiciona mensagem do usuário, chama API, adiciona resposta do bot
  - Geração/recuperação de `deviceId` via SharedPreferences

- [ ] Converter `ChatPage` para `ConsumerStatefulWidget`:
  - `ListView.builder` consumindo provider
  - `TextEditingController` conectado ao `sendMessage`
  - Auto-scroll para última mensagem
  - Indicador de digitação enquanto `isLoading`
  - Header "Assistente ReservAqui"
  - SnackBar para erros de rede

- [ ] Rota `/chat` aceita `?hotelId=xxx` (opcional)

---

## Endpoints usados

| Método | Rota                   | Auth | Descrição                    |
|--------|------------------------|------|------------------------------|
| POST   | `/chat/message`        | ❌*  | Enviar mensagem ao bot       |

> *JWT opcional: se presente, enriquece a sessão com `userId`.

---

## Dependências
- **Requer:** Nenhuma outra task de P6
- **Backend existente:** `AgentOrchestratorService`, `ContextResolverService`, `RagService`, `IntentClassifierService` — todos prontos

## Bloqueia
- Demo do chatbot integrado diretamente no app (hoje só via WhatsApp)

---

## Observações
- O histórico de conversa fica em memória no frontend (sem persistência local por ora)
- Não recriar o motor de IA — apenas expor o `AgentOrchestratorService` existente via REST
- Se o backend não tiver `hotelId` no contexto, o orquestrador já lida com isso (re-roteia para busca de hotel)
- Sessões do app são separadas das do WhatsApp (canal `APP` vs `WHATSAPP`)
