# Spec — Chat RAG Integration (In-App)

## Referência
- **PRD:** conductor/features/chat-rag-integration.prd.md
- **Task:** conductor/__task/P6-F-chat-rag-integration.md

## Abordagem Técnica
Criar um endpoint REST público `POST /api/v1/chat/message` que recebe a mensagem do usuário, gerencia sessões de chat (canal `APP`) e delega ao `AgentOrchestratorService.processMessage()` existente. No frontend, criar um `ChatNotifier` (StateNotifier) que mantém o histórico em memória e se comunica com o endpoint. A `ChatPage` é convertida para `ConsumerStatefulWidget` com `ListView.builder` dinâmico.

## Componentes Afetados

### Backend
- **Novo:** `chat.controller.ts` (`Backend/src/controllers/chat.controller.ts`) — handler `sendMessage`
- **Novo:** `chat.routes.ts` (`Backend/src/routes/chat.routes.ts`) — `POST /message`
- **Modificado:** `app.ts` (`Backend/src/app.ts`) — registrar `chatRoutes`

### Frontend
- **Novo:** `chat_provider.dart` (`lib/features/chat/presentation/providers/chat_provider.dart`) — `ChatMessage` model + `ChatNotifier` + `chatProvider`
- **Modificado:** `chat_page.dart` (`lib/features/chat/presentation/pages/chat_page.dart`) — converter para `ConsumerStatefulWidget`, conectar ao provider
- **Modificado:** `app_router.dart` (`lib/core/router/app_router.dart`) — passar `hotelId` como queryParam na rota `/chat`

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|--------------|
| Endpoint público (sem `authGuard` obrigatório) | Espelha o fluxo WhatsApp: qualquer pessoa pode conversar. O bot pede CPF/nome quando necessário |
| JWT opcional: se presente, enriquece sessão com `userId` | Permite associar conversas a usuários logados sem bloquear anônimos |
| `identificador_externo = UUID do dispositivo` | Persiste em SharedPreferences; identifica sessões anônimas entre aberturas do app |
| Canal `APP` na tabela `sessao_chat` | Separa sessões do app das do WhatsApp; evita mistura de histórico e metadados |
| `StateNotifier` em vez de `AsyncNotifier` | Controle mais fino: o estado é uma lista de mensagens + flag `isLoading`, não um Future |
| Persistência de mensagens no banco (controller) | O `AgentOrchestratorService.getChatHistory()` lê de `mensagem_chat`; sem persistir, o bot perde contexto |
| Histórico in-memory no frontend | Simplifica; sem necessidade de SQLite/SharedPreferences para mensagens nesta fase |

## Contratos de API

### `POST /api/v1/chat/message`

**Request:**
```json
{
  "message": "Oi, quero reservar um hotel em Recife",
  "hotelId": "uuid-opcional",
  "deviceId": "uuid-dispositivo-local"
}
```

**Headers (opcional):**
```
Authorization: Bearer <jwt-token>
```

**Response 200:**
```json
{
  "reply": "Olá! 👋 Seja bem-vindo(a) à ReservAqui...",
  "sessionId": "uuid-da-sessao"
}
```

**Response 400:**
```json
{
  "error": "Mensagem não pode ser vazia"
}
```

**Response 500:**
```json
{
  "error": "Erro interno ao processar mensagem"
}
```

## Fluxo Backend Detalhado

```
1. Recebe POST /chat/message { message, hotelId?, deviceId }
2. Valida: message não vazia, deviceId presente
3. Extrai userId do JWT (se header Authorization presente) — fallback null
4. Busca sessão aberta: SELECT FROM sessao_chat WHERE canal='APP' AND identificador_externo=deviceId AND status='ABERTA'
   - Se existe e ativa (< 24h): reutiliza
   - Se existe mas inativa (> 24h): fecha e cria nova
   - Se não existe: cria nova
5. Se userId presente e sessão não tem user_id: UPDATE sessao_chat SET user_id
6. Se hotelId presente e sessão não tem hotel_id: UPDATE sessao_chat SET hotel_id
7. Persiste mensagem do usuário em mensagem_chat (origem='CLIENTE', tipo='TEXT')
8. Resolve ChatContext via ContextResolverService.getContext(sessionId)
   - Fallback: { sessionId, userId, hotelId, schemaName: null }
9. Chama AgentOrchestratorService.processMessage(sessionId, message, context)
10. Persiste resposta do bot em mensagem_chat (origem='BOT_SISTEMA', tipo='TEXT')
11. Retorna { reply, sessionId }
```

## Modelos de Dados

### Frontend — ChatMessage
```dart
class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
}
```

### Frontend — ChatState
```dart
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? sessionId;
  final String? error;
}
```

## Dependências

**Bibliotecas:**
- [x] `dio` — chamadas HTTP (já no projeto)
- [x] `flutter_riverpod` — gerenciamento de estado (já no projeto)
- [x] `go_router` — navegação (já no projeto)
- [x] `shared_preferences` — armazenar `deviceId` local (já no projeto)
- [x] `uuid` — gerar `deviceId` na primeira abertura (já no projeto via `crypto`)

**Serviços Backend:**
- [x] `AgentOrchestratorService` — motor de IA (já implementado)
- [x] `ContextResolverService` — resolução de contexto (já implementado)
- [x] `persistChatMessage` — persistência no banco (já implementado em `whatsappWebhook.service.ts`, será extraído/reutilizado)
- [x] `getOrCreateOpenSession` — gestão de sessões (padrão já implementado em `whatsappWebhook.service.ts`, será adaptado)

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| Latência do LLM (5-15s) pode parecer que o app travou | Indicador de "digitando" + timeout de 30s no Dio com mensagem amigável |
| Sessão sem `userId` perde vínculo com dados de reserva | O bot já pede CPF/nome via conversa quando necessário para criar reserva |
| `deviceId` perdido (reinstalação/limpeza de dados) | Nova sessão criada automaticamente; histórico anterior persiste no banco mas não é recuperado no app |
| Chamada ao LLM falha (API Gemini/Groq fora do ar) | `AgentOrchestratorService` já retorna fallback "assistente indisponível" |
