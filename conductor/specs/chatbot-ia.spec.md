# Spec — chatbot-ia

## Referência
- **PRD:** conductor/features/chatbot-ia.prd.md

## Abordagem Técnica
A IA será orquestrada via **LangChain.js** rodando Node.js, utilizando as APIs do Google Gemini (modelos textuais e multimodais). 
Adotaremos uma arquitetura de roteamento inicial (Semantic Router/Intent Classifier) usando um padrão Strategy (Heurística leve ou LLM focada) para classificar a intenção e disparar o fluxo de "Dúvida" (somente RAG), "Reserva" (Agente com Tools de negócio) ou tratar conversas corriqueiras diretamente.
O tempo limite do Webhook da Meta exige um design assíncrono: sempre retornaremos `200 OK` imediatamente, e qualquer processamento pesado, incluindo análise de áudio ou imagem, retornará primeiro uma mensagem rápida "Analisando..." ao usuário antes de iniciar o job principal.
O fluxo determinístico em grafo (LangGraph) fica anotado como débito futuro, e utilizaremos um Agent tradicional (createToolCallingAgent) fortemente ancorado com zod schemas para o MVP.

## Componentes Afetados

### Backend
- **Novo:** `IntentClassifierService` (`src/services/ai/intentClassifier.service.ts`)
- **Novo:** `RagService` (`src/services/ai/rag.service.ts`)
- **Novo:** `AgentOrchestratorService` (`src/services/ai/agentOrchestrator.service.ts`) — Injeção de Tools Zod e LangChain
- **Novo:** `ContextResolverService` (`src/services/ai/contextResolver.service.ts`) — Descobre de qual hotel o guest está falando.
- **Novo (ADICIONADO):** `LLMFactory` (`src/services/ai/llmFactory.ts`) — Camada de abstração multi-provider (Gemini + Groq) com fallback automático em erros recuperáveis e retry respeitando `retry-after`.
- **Novo (ADICIONADO):** `DynamicIngestionService` (`src/services/ai/dynamicIngestion.service.ts`) — Lê dados canônicos do tenant (hotel + categorias + quartos) e materializa chunks em `documento_hotel` com embeddings Gemini.
- **Novo (ADICIONADO):** `tools.ts` (`src/services/ai/tools.ts`) — Agrega as 4 tools LangChain com Zod: `buscar_hoteis`, `selecionar_hotel`, `checar_disponibilidade`, `criar_reserva`.
- **Novo (ADICIONADO):** `MediaProcessorService` (`src/services/ai/mediaProcessor.service.ts`) — Download de mídia da Meta Graph API + transcrição de áudio (Groq Whisper `whisper-large-v3-turbo`) + descrição/OCR de imagem (Groq Llama 4 Scout `meta-llama/llama-4-scout-17b-16e-instruct`). Texto resultante é roteado pelo `AgentOrchestrator` como se fosse mensagem de texto comum.
- **Modificado:** `whatsappWebhook.service.ts` — Alterar para disparar o pipeline de IA assincronamente e intercalar mensagens de "Analisando áudio/imagem...".

### Frontend
- **Modificado:** Nenhuma tela nova no MVP. O app já está estruturado para consumir o chat; toda inteligência atua via backend.

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|--------------|
| **Classificador de Intenções Leve** | Reduzir custos e tempo de resposta, desviando dúvidas simples sem invocar o Agente com todas as tools ativas. |
| **Bypass de Pagamento via `.env`** | Permitir fluxo de ponta a ponta sem atritos com APIs externas até que a feature do adquirente esteja robusta. |
| **Separação RAG vs Banco Relacional** | Evita a sobrecarga de regerar embeddings vetoriais toda vez que um preço de quarto flutua. O RAG foca apenas em texto estável. |
| **Defer de LangGraph** | Simplificação inicial; focaremos na precisão das tools do Agente antes de implementar um *state machine* completo em loop fechado. |

## Contratos de API

A funcionalidade toda opera no backend encapsulando chamadas de WhatsApp; não há novos endpoints públicos REST criados para os aplicativos.

| Método | Rota | Body | Response |
|--------|------|------|----------|
| POST | /whatsapp/webhook | { object, entry: [...] } | 200 OK (Imediato) |

## Modelos de Dados

```
DocumentoHotel {
  id: uuid
  hotel_id: uuid
  metadata: jsonb
  content: text
  embedding: vector
}
```

## Dependências

**Bibliotecas:**
- [x] `@langchain/google-genai` — Chamadas à API Gemini
- [x] `@langchain/core` — Orquestração e agent abstractions
- [x] `zod` — Schema rigoroso para input e tools

**Serviços externos:**
- [x] Google Gemini API — Provedor das LLMs de texto e multimodal
- [x] Meta Graph API — Envio de mensagens e download de mídia do WhatsApp

**Outras features:**
- [x] Integração Webhook WhatsApp (Fase 4, base da recepção das mensagens)

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| **SLA de 5s da Meta** | Processamento pós-ACK; Disparo imediato de texto "Processando..." para áudios/imagens para acalmar o usuário e ganhar tempo seguro de retry. |
| **Alucinações de dados** | Tools de "Criação de Reserva" aplicarão as validações da regra de negócio (TypeScript) independente do bot. System prompt forte. |
| **Mudança indesejada de contexto de hotel** | O `ContextResolver` deve travar o usuário num único hotel caso ele inicie um fluxo longo, usando o `sessao_chat`. |

## Guardrails e Robustez [ADICIONADO]

Camada construída durante a validação para blindar o produto contra falhas de provider, alucinação de LLM e bugs de tool-calling observados em produção.

### Multi-provider com fallback
- **Primário configurável** via `AI_PRIMARY_PROVIDER=gemini|groq`. O outro vira fallback automático.
- **Trigger de fallback:** erros HTTP 429/503/500 ou mensagens contendo `quota`, `rate limit`, `resource_exhausted`, `fetch failed`.
- **Retry respeitando `retry-after`**: se o provider indica delay curto (típico TPM burst do Groq, 1-3s), aguarda antes de desistir. Cap em 5s para preservar SLA.
- **Resiliência operacional**: basta uma das chaves estar preenchida; se ambas, há redundância automática.

### Fast-path sem LLM
- **Saudações detectadas por regex** no `IntentClassifier` (`oi|olá|bom dia|tchau|...`) → retorna `OUTROS` sem chamar rede.
- **Welcome pitch fixo** no `handleOutros` → resposta de apresentação do ReservAqui (capacidades do bot) sem invocar LLM.
- **`handleDuvida` sem hotel selecionado** → resposta fixa pedindo cidade/nome do hotel.
- **`handleDuvida` com RAG vazio** → resposta fixa "não tenho essa info registrada".

### Roteamento contextual
- **Classifier recebe histórico** (últimas 4 mensagens) para desambiguar respostas curtas do usuário (ex: bot perguntou cidade → usuário respondeu "recife" → classifica como `RESERVA`).
- **Re-rotação de segurança**: se classifier retornou `DUVIDA`/`OUTROS` mas não há `hotel_id` na sessão e a mensagem parece busca, o orchestrator força `RESERVA` (única rota com tools de banco).

### Guardrails anti-alucinação
- **Cidades reais injetadas no prompt de `RESERVA`** via `SELECT DISTINCT cidade, uf FROM anfitriao`. Proíbe sugerir cidades fora da lista.
- **Prompts rígidos** em cada handler proibindo usar conhecimento do treinamento, inventar preços/nomes/políticas, ou citar hotéis não selecionados.
- **Validação Zod** em todas as tools é intransponível (mesmo que o LLM aluja argumentos, o runtime bloqueia).

### Agent loop robusto
- **Até 3 iterações** de tool-calling por mensagem (antes: 1) — permite sequências como `buscar_hoteis → selecionar_hotel → checar_disponibilidade`.
- **Fallback de content vazio**: se o LLM terminar o loop retornando apenas tool_calls sem texto (bug comum no Llama), o orchestrator monta resposta a partir do último tool result. Evita erro `text.body is required` da Meta API.
- **Fallback global**: se o motor de IA em background explodir, o webhook envia mensagem amigável em vez de silêncio.

### Orçamento de tokens
- **Histórico limitado a 6 mensagens** (antes: 10) — reduz tokens por chamada mantendo contexto útil.
- **System prompt de `RESERVA` enxuto** — consolidou 8 regras prolixas em 7 linhas diretivas.

## Multimodal (áudio e imagem) [ADICIONADO]

### Pipeline unificado
Áudio e imagem seguem o mesmo esqueleto assíncrono no webhook:

1. **Ack imediato** em <1s: `"🎧 Analisando seu áudio..."` ou `"🖼️ Analisando sua imagem..."` — preserva SLA de 5s da Meta.
2. **Background job** (`Promise.resolve().then`): baixa o binário da Meta Graph API, interpreta, registra no histórico, invoca o agent.
3. **Texto interpretado** é persistido como `mensagem_chat` com `origem='CLIENTE'` e `tipo_mensagem='AUDIO'|'IMAGE'`. O conteúdo é a transcrição/descrição; o binário/fonte original fica em `metadata_json`.
4. **Roteamento idêntico ao texto**: `AgentOrchestratorService.processMessage(sessionId, textoInterpretado, context)` — fluxos de RESERVA/DUVIDA/OUTROS aplicam sem mudança.
5. **Fallback amigável** se download/Whisper/vision falhar: bot pede pra reformular em texto.

### Provider e modelos
- **STT (áudio):** Groq `whisper-large-v3-turbo`, `language='pt'`, `response_format='text'`. Aceita `audio/ogg` (voice note padrão WhatsApp) + mp3/m4a/wav/webm.
- **Vision (imagem):** Groq `meta-llama/llama-4-scout-17b-16e-instruct`. System prompt orienta a transcrever literalmente qualquer texto legível (CPF/RG/datas/comprovante).
- Ambos usam o mesmo `GROQ_API_KEY`.

### Observabilidade — LangSmith
- Ativação 100% via env: `LANGCHAIN_TRACING_V2=true` + `LANGCHAIN_API_KEY` + `LANGCHAIN_PROJECT`.
- LangChain auto-instrumenta cada invocação (classifier, orchestrator, tools, vision). Sem mudanças de código.
- Painel web: https://smith.langchain.com (não há CLI). Cada run mostra prompt, resposta, tokens, latência e custo estimado.
