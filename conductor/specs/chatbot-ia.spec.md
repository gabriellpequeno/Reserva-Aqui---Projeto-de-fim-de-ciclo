# Spec - Chatbot IA com RAG (`pgvector`)

## Visão Geral
O chatbot recebe uma conversa que nasceu em um único número de WhatsApp da plataforma. Antes de usar conhecimento hotel-scoped, a camada de IA precisa resolver o `hotel_id` da sessão por contexto, reserva, seleção explícita ou continuidade da conversa. Depois disso, o fluxo combina consultas estruturadas no banco relacional com busca vetorial em `pgvector`, e substitui a resposta provisória por uma resposta gerada via Gemini + LangChain.

## Fluxo Técnico
1. O webhook do WhatsApp mantém a sessão global em `sessao_chat`, com `hotel_id` opcional.
2. Um resolvedor de contexto identifica o hotel da conversa por reserva existente, código público, seleção explícita ou contexto já salvo na sessão.
3. O classificador de intenção decide entre:
   - dúvida sobre o hotel
   - intenção de reserva
   - pedido de roteiro
4. Para consultas estruturadas do hotel:
   - usar serviços da aplicação sobre o banco relacional para preço, disponibilidade, regras transacionais e reservas
5. Para dúvida documental do hotel:
   - gerar embedding da pergunta
   - buscar top-k trechos do hotel com `pgvector`
   - montar prompt com contexto e histórico mínimo da conversa
   - gerar resposta com Gemini
6. Combinar o resultado estruturado e/ou documental em uma resposta final.
7. Persistir a resposta final em `mensagem_chat` como `BOT_SISTEMA`.

## Modelo de Dados

### `documento_hotel` (tenant schema do hotel)
- `id UUID PK`
- `hotel_id UUID`
- `fonte VARCHAR(100)` - ex.: FAQ, política, serviço
- `conteudo TEXT`
- `embedding vector(768)`
- `criado_em TIMESTAMPTZ`

### Índices
- índice vetorial no campo `embedding`
- índice auxiliar por `hotel_id`/`fonte` conforme necessidade

## Endpoints e Serviços

### Webhook WhatsApp existente
- Continua como ponto de entrada do canal
- Troca a resposta provisória pelo serviço de IA quando a feature estiver ativa

### `HotelContextResolver`
- Responsabilidade: resolver ou solicitar o `hotel_id` da conversa antes do uso do conhecimento hotel-scoped
- Entrada mínima: `sessionId`, `messageText`, contexto de reserva quando existir
- Saída: `hotelId | null` e sinal de necessidade de desambiguação

### `StructuredHotelDataService`
- Responsabilidade: consultar dados canônicos do produto no banco relacional
- Casos mínimos: preço, disponibilidade, regras operacionais e reserva existente

### `RagService`
- Responsabilidade: gerar embedding, consultar documentos do hotel, montar contexto e pedir a resposta do LLM
- Entrada mínima: `hotelId`, `sessionId`, `messageText`
- Saída: texto final da resposta

### Script de ingestão
- Lê documentos de cada hotel
- Faz chunking simples
- Gera embeddings
- Salva/atualiza `documento_hotel`

## Dependências
- `pgvector` no PostgreSQL
- SDK Gemini
- LangChain / LangGraph

## Decisões Técnicas
- `pgvector` fica no mesmo PostgreSQL do projeto para reduzir complexidade operacional.
- A base de conhecimento é segregada por hotel.
- Dados canônicos e transacionais não vão para o vetor; permanecem como fonte de verdade no banco relacional.
- O histórico do WhatsApp permanece no master, enquanto os documentos do hotel ficam no contexto tenant.
- A primeira versão do classificador de intenção pode ser leve e heurística, desde que a interface permita troca posterior.

## Riscos
- Documentos pobres ou mal formatados reduzem qualidade do RAG.
- Embeddings e busca vetorial podem exigir ajuste de chunk size e top-k.
- Se o hotel não for corretamente resolvido na conversa, a resposta pode usar a base errada ou exigir desambiguação adicional.

## A Implementar Depois
- Refinamento iterativo de roteiro
- Tools para reserva automática
- Observabilidade de tokens, latência e falhas do RAG
