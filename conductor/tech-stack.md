# Tech Stack — ReservAqui

## Arquitetura

| Item | Valor |
|------|-------|
| Modelo | Client-Server |
| Comunicação | REST API + WhatsApp Cloud API webhook |
| Estratégia Realtime | Webhook para mensagens WhatsApp, polling/WebSocket para atualizações no app |

---

## Backend

| Camada | Tecnologia |
|--------|-----------|
| Runtime | Node.js |
| Linguagem | TypeScript |
| Framework | Express |
| Banco de dados | PostgreSQL (via `pg` driver) |
| Busca vetorial | `pgvector` na mesma instância PostgreSQL |
| Autenticação | JWT com access token + refresh token |
| Hashing de senha | `argon2id` |
| IDs únicos | `uuid` |
| Variáveis de ambiente | `dotenv` |

---

## Frontend

| Camada | Tecnologia |
|--------|-----------|
| Framework | Flutter |
| Linguagem | Dart |
| Navegação | GoRouter |
| Plataformas-alvo | Mobile (iOS/Android), Web, Tablet |
| Temas | Light mode + Dark mode (obrigatório) |

---

## Inteligência Artificial

| Camada | Tecnologia |
|--------|-----------|
| LLM | Google Gemini (Flash) via API |
| Orquestração | LangChain / LangGraph |
| RAG — Vector Store | `pgvector` (extensão PostgreSQL) |
| Embeddings | Modelo de embeddings do Gemini |
| Fontes de conhecimento | Dados canônicos no PostgreSQL relacional + documentos e políticas indexados em `pgvector` |
| Roteamento de conversa | Número único de WhatsApp da plataforma; `hotel_id` resolvido por contexto, reserva ou seleção explícita |
| Pipeline | Mensagem inbound → validação do canal → linkagem user/guest + histórico → resolução do hotel → classificação de intenção → consulta estruturada e/ou RAG → resposta |

---

## Integrações Externas

| Serviço | Finalidade |
|---------|-----------|
| WhatsApp Cloud API (Meta) | Canal principal de comunicação com o hóspede |
| InfinitePay | Processamento de pagamentos |
| Google OAuth | Login social do hóspede |

---

## Infraestrutura e DevOps

| Camada | Tecnologia |
|--------|-----------|
| Containerização | Docker + docker-compose |
| Containers | Backend (Node.js) + PostgreSQL (`pgvector/pgvector`) |
| Gerenciamento de pacotes | `npm` (Backend), `flutter pub` (Frontend) |
| Variáveis de ambiente | Arquivos `.env` por ambiente (dev / prod) |
| Testes | Jest + Supertest |

---

## Decisões Documentadas

| Decisão | Motivo |
|---------|--------|
| `pgvector` ao invés de Qdrant externo | Mantém o MVP operacionalmente simples; coloca o conhecimento do hotel junto ao banco existente, sem container extra |
| Número único de WhatsApp na plataforma | O `phone_number_id` da Meta valida o canal oficial, mas não identifica o hotel — o `hotel_id` é resolvido no fluxo da conversa |
| Recuperação híbrida | Preços, disponibilidade e reservas ficam no banco relacional; FAQ, regras e políticas ficam indexadas em `pgvector` |
| Sessão de chat sem hotel fixo | Cada sessão WhatsApp pode iniciar sem `hotel_id` e ser enriquecida quando a conversa identificar o hotel |
| GoRouter no Flutter | Suporte nativo a deep links, shell routes e navegação declarativa para web e mobile |
| Gemini Flash | Free tier generoso, latência baixa, suficiente para RAG e geração de roteiros no MVP |

> **Regra:** qualquer mudança de tecnologia deve ser documentada aqui com data e justificativa antes de ser implementada.