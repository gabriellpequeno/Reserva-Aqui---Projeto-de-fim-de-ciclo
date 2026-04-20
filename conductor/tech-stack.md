# Tech Stack — ReservAqui

## Arquitetura
- **Modelo:** Client-Server
- **Comunicação:** RESTful API + WebSocket (notificações em tempo real)

---

## Backend

| Camada | Tecnologia |
|--------|-----------|
| Runtime | Node.js |
| Linguagem | TypeScript |
| Framework | Express |
| Banco de dados | PostgreSQL (via `pg` driver) |
| Autenticação | JWT com refresh token |
| Hashing de senha | `bcrypt` |
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
| RAG — Vector Store | Qdrant (container Docker) |
| Embeddings | Modelo de embeddings do Gemini |
| Pipeline | Recebimento de mensagem → classificação de intenção → RAG ou geração de roteiro → resposta |

---

## Integrações Externas

| Serviço | Finalidade |
|---------|-----------|
| WhatsApp Cloud API (Meta) | Canal principal de comunicação com o hóspede |
| InfinitePay | Processamento de pagamentos (app + WhatsApp) |
| Google OAuth | Login social do hóspede |

---

## Infraestrutura e DevOps

| Camada | Tecnologia |
|--------|-----------|
| Containerização | Docker + docker-compose |
| Containers | Backend (Node.js), PostgreSQL, Qdrant |
| Gerenciamento de pacotes | `npm` (Backend), `flutter pub` (Frontend) |
| Variáveis de ambiente | Arquivos `.env` por ambiente (dev / prod) |

---

## Decisões Documentadas

| Decisão | Motivo |
|---------|--------|
| Qdrant separado do PostgreSQL | Isola a responsabilidade de busca vetorial; mais simples de escalar que pgvector no prazo do projeto |
| GoRouter no Flutter | Suporte nativo a deep links, shell routes e navegação declarativa para web e mobile |
| Gemini Flash | Free tier generoso, latência baixa, suficiente para RAG e geração de roteiros no MVP |
| Polling vs WebSocket | WebSocket para notificações em tempo real (reservas); polling simples para chat se WebSocket travar |

> **Regra:** qualquer mudança de tecnologia deve ser documentada aqui com data e justificativa antes de ser implementada.
