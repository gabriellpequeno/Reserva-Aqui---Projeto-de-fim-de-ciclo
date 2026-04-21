# Tech Stack - ReservAqui

## Architecture
- **Model:** Client-server
- **Communication:** REST API + WhatsApp Cloud API webhook
- **Realtime Strategy:** webhook for inbound WhatsApp, polling/WebSocket as needed for app updates

## Backend
- **Runtime:** Node.js
- **Language:** TypeScript
- **Framework:** Express
- **Database:** PostgreSQL via `pg`
- **Vector Search:** `pgvector` on the same PostgreSQL instance
- **Auth:** JWT access token + refresh token
- **Security & Utilities:** `argon2`, `bcrypt`, `uuid`, `dotenv`

## Frontend
- **Framework:** Flutter
- **Language:** Dart
- **Targets:** Mobile (iOS/Android) and Web

## AI
- **LLM:** Google Gemini Flash
- **Orchestration:** LangChain / LangGraph
- **Embeddings:** Gemini embedding model
- **Knowledge Sources:** dados canônicos no PostgreSQL relacional + documentos e políticas em `pgvector`
- **Conversation Routing:** um único número de WhatsApp da plataforma; `hotel_id` é resolvido depois por contexto, reserva ou seleção explícita
- **Pipeline:** inbound message -> validação do canal global -> user/guest linkage + histórico -> resolução do hotel -> intent classification -> consulta estruturada e/ou RAG -> reply

## External Integrations
- **WhatsApp Cloud API (Meta):** primary guest communication channel
- **InfinitePay:** payment processing
- **Google OAuth:** social login

## Tooling & Infrastructure
- **Containers:** Backend + PostgreSQL (`pgvector/pgvector`)
- **Package Management:** `npm` (Backend), `flutter pub` (Frontend)
- **Environment Configuration:** `.env` files per environment
- **Testing:** Jest + Supertest

## Documented Decisions
- **`pgvector` over external vector DB:** keep the MVP operationally simple and colocate hotel knowledge with the existing database stack.
- **Single platform WhatsApp number:** Meta `phone_number_id` validates the official inbound channel, but does not identify the hotel.
- **Hybrid retrieval:** preços, disponibilidade e reservas ficam no banco relacional; FAQ, regras e políticas ficam indexadas em `pgvector`.
- **Chat session ownership:** each WhatsApp session can start without `hotel_id` and be enriched later when the conversation identifies the hotel.
