# Plan — chatbot-ia

> Derivado de: conductor/specs/chatbot-ia.spec.md
> Status geral: [EM VALIDAÇÃO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Criar migration para a tabela `documento_hotel` configurada para pgvector no Master DB.
- [x] Instalar dependências de IA no package.json (`@langchain/google-genai`, `@langchain/core`, `zod`).
- [x] Adicionar `GEMINI_API_KEY` e a flag `INFINITEPAY_BYPASS=true` no arquivo `.env` e `.env.example`.

---

## Backend [CONCLUÍDO]

- [x] Desenvolver `ContextResolverService` para recuperar o `hotel_id` atual da `sessao_chat`.
- [x] Desenvolver o motor de ingestão dinâmica (lê do DB do hotel e insere no pgvector).
- [x] Desenvolver `IntentClassifierService` (classificador inicial: dúvida, reserva, midia/outro).
- [x] Desenvolver as Tools com Zod Schemas (`BuscarHoteisTool`, `ChecarDisponibilidadeTool`, `CriarReservaTool`).
- [x] Refinar as Tools de Reserva para exigirem nome e CPF caso o usuário seja *walk-in* (hóspede anônimo).
- [x] Desenvolver `RagService` para invocar a busca vetorial estrita via hotel_id.
- [x] Desenvolver `AgentOrchestratorService` acoplando as Tools à LLM.
- [x] Modificar `whatsappWebhook.service.ts`: mover a IA para background e despachar "Aguarde, analisando..." imediatamente caso a payload contenha imagem ou áudio.

---

## Frontend [CONCLUÍDO]

- [x] Sem atividades no Front-end Web/Mobile nesta fase (a UI atualiza sozinha com as reservas criadas no banco, e o chat via app consome o mesmo pipeline).

---

## Resiliência & Custo [ADICIONADO - feat/chatbot-rag]

Camada de robustez/observabilidade construída durante a validação de ponta a ponta. Não estava no plan original; surgiu em resposta a problemas reais (quota zerada do Gemini, alucinações do Llama, TPM estourado, loops vazios de tool).

- [x] **Multi-provider com fallback automático** (`src/services/ai/llmFactory.ts`):
  - Suporte a Gemini (`gemini-2.5-flash-lite`) e Groq (`llama-3.3-70b-versatile`).
  - Provider primário selecionável via `AI_PRIMARY_PROVIDER=gemini|groq`.
  - Fallback automático entre providers em erros recuperáveis (429/503/500, quota, rate limit, fetch failed).
  - Retry com `retry-after` quando o provider indica delay temporário (típico TPM burst do Groq) — cap em 5s para não estourar SLA do WhatsApp.
- [x] **Fast-path de saudações** no `IntentClassifier`: regex detecta `oi|olá|bom dia|tchau|obrigado|...` e retorna `OUTROS` sem chamar LLM — latência zero, custo zero.
- [x] **Welcome pitch fixo** no `handleOutros`: saudações disparam mensagem de apresentação do ReservAqui sem LLM (previne alucinação e garante UX consistente).
- [x] **Classifier com contexto do histórico**: passa as últimas 4 mensagens ao prompt para desambiguar respostas curtas (ex: bot pergunta cidade → usuário responde "caruaru" → agora entende como `RESERVA`).
- [x] **Defesa em profundidade no roteador**: se o classifier retorna `DUVIDA`/`OUTROS` mas a sessão não tem `hotel_id` e a mensagem parece busca, re-roteia para `RESERVA` (única rota com tools para consultar o banco).
- [x] **Injeção de cidades reais no prompt de RESERVA**: `SELECT DISTINCT cidade, uf FROM anfitriao` injetado como "única fonte verdadeira" → elimina alucinação de cidades inexistentes (Recife/Olinda não aparecem mais como sugestão).
- [x] **Agent loop com até 3 iterações** (antes: 1 só). Permite sequência `buscar_hoteis → selecionar_hotel → checar_disponibilidade` numa mesma mensagem sem travar.
- [x] **Fallback em content vazio**: se o LLM terminar o loop sem produzir texto (bug comum com Llama), o orchestrator monta resposta a partir do último tool result → nunca mais cai em `"text.body is required"` da Meta API.
- [x] **Guardrails de alucinação nos handlers**:
  - `handleDuvida` sem hotel selecionado → resposta fixa, sem LLM.
  - `handleDuvida` com RAG vazio → resposta fixa "não tenho essa info".
  - `handleDuvida` com RAG populado → prompt rígido proibindo usar treinamento/inventar.
  - `handleOutros` → prompt bloqueia qualquer resposta sobre hotéis/preços/cidades (só saudações/redirecionamento).
  - `handleReserva` → prompt proíbe afirmar existência de hotel sem chamar `buscar_hoteis`.
- [x] **Fallback ao usuário em erro crítico**: se o motor de IA em background explodir, envia mensagem amigável `"assistente está instável..."` em vez de silêncio absoluto.
- [x] **Redução de tokens por call**: histórico 10→6 mensagens + prompt de RESERVA enxuto. Mantém conversa dentro do TPM 12k do Groq free tier.

---

## Validação [PENDENTE]

- [ ] Testar se RAG busca apenas dados do hotel pertinente respondendo dúvidas genéricas (ex: pets).
- [ ] Testar fluxo de reserva completo para *walk-in* garantindo que a IA peça Nome e CPF ativamente.
- [ ] Garantir bypass do InfinitePay via `.env` criando a reserva instantaneamente no banco relacional.
- [ ] Enviar áudio ou imagem simulados e garantir que o webhook devolve mensagem provisória para contornar o timeout de 5 segundos.
- [ ] Buscar hotéis via IA e garantir que os dados listados cruzam corretamente as informações do banco canônico.

---

## Multimodal & Observabilidade [CONCLUÍDO]

- [x] **Processamento real de áudio** (`MediaProcessorService.transcribeAudio`):
  - Download via Meta Graph API (`GET /{mediaId}` → URL → GET binário com Bearer).
  - Transcrição via Groq Whisper `whisper-large-v3-turbo` (`language: 'pt'`, free tier).
  - Fluxo no webhook: ack imediato `"🎧 Analisando seu áudio..."` → background download → Whisper → `AgentOrchestrator.processMessage(sessionId, textoTranscrito, context)`.
  - Transcrição persistida como mensagem `CLIENTE` no histórico com `metadata_json.audioTranscript` para auditoria.
- [x] **Processamento real de imagem** (`MediaProcessorService.describeImage`):
  - Modelo: `meta-llama/llama-4-scout-17b-16e-instruct` via Groq (multimodal, free tier).
  - System prompt orienta: descrever conteúdo; se houver texto legível (CPF, RG, datas, comprovante), transcrever literalmente.
  - Fluxo simétrico ao áudio; descrição registrada em `metadata_json.imageDescription`.
- [x] **Fallback amigável em falha de mídia**: se o download, Whisper ou vision falhar, o bot pede pra reformular em texto em vez de silenciar.
- [x] **Observabilidade com LangSmith**:
  - Variáveis configuradas em `.env.example` e `docker-compose.yml`: `LANGCHAIN_TRACING_V2`, `LANGCHAIN_API_KEY`, `LANGCHAIN_PROJECT=reservaqui-chatbot`, `LANGCHAIN_ENDPOINT`.
  - LangChain auto-instrumenta ao ver as envs — sem código adicional.
  - Painel: https://smith.langchain.com (web, não há CLI). Traces aparecem filtráveis por projeto e `run_id`.

---

## A Fazer [PENDENTE - próximas rodadas]

### P1 — Próxima iteração

- [ ] **Enriquecer tags LangSmith** — adicionar `runName` e `metadata` (sessionId, intent) em `invokeWithFallback` para filtrar traces por conversa no painel.
- [ ] **Extração automática de Nome+CPF de fotos de documento** — quando o fluxo walk-in receber imagem durante coleta de identificação, a descrição via Llama 4 Scout já transcreve texto; falta parser/regex de CPF (`\d{3}\.?\d{3}\.?\d{3}-?\d{2}`) para alimentar a tool `criar_reserva` automaticamente.

### P2 — Integração WhatsApp

- [ ] **Validação `X-Hub-Signature-256`**: middleware que valida HMAC-SHA256 do payload com `appSecret`.
- [ ] **Retry automático de envio outbound**: wrapper com exponential backoff em `WhatsAppService.sendText` (3 tentativas, 1s/2s/4s).
- [ ] **Transferência para atendimento humano**: detectar intent "falar com atendente" ou múltiplos fallbacks → marcar sessão `AGUARDANDO_HUMANO`, pausar bot.

### P3 — Evolução arquitetural

- [ ] **Migrar agent loop para LangGraph**: state machine formal em vez do `for` de 3 iterações atual.
- [ ] **RAG para pontos turísticos externos**: indexar info pública da cidade em `documento_cidade` separado.
- [ ] **Resolução automática de `hotel_id`** além da tool `selecionar_hotel`: heurísticas por nome em texto livre, reservas prévias do número, etc.

### Melhorias menores
- [ ] Cache de embeddings por pergunta em `documento_hotel`.
- [ ] Rate limit por número (anti-spam).
- [ ] Métricas: % interações resolvidas pelo bot vs fallback.
- [ ] Job de limpeza de sessões antigas (LGPD, já anotado em `.context/whatsapp_context.md`).
