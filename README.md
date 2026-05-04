# ReservAqui

Plataforma de reserva de quartos de hotel com chatbot de IA integrado, notificações push, pagamentos via InfinitePay e integração com WhatsApp.

Projeto de fim de ciclo — Turma T7.

---

## Sumário

- [Visão Geral](#visão-geral)
- [Stack Tecnológica](#stack-tecnológica)
- [Pré-requisitos](#pré-requisitos)
- [Configuração do Ambiente](#configuração-do-ambiente)
- [Executando o Backend](#executando-o-backend)
- [Executando o Frontend](#executando-o-frontend)
- [Seeds (Dados de Demonstração)](#seeds-dados-de-demonstração)
- [Scripts Disponíveis](#scripts-disponíveis)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Variáveis de Ambiente](#variáveis-de-ambiente)
- [Colaboradores](#colaboradores)

---

## Visão Geral

O **ReservAqui** é composto por:

- **Backend** — API REST em Node.js/TypeScript com arquitetura multi-tenant (um schema PostgreSQL por hotel)
- **Frontend** — Aplicativo mobile em Flutter
- **IA (Bene)** — Chatbot com persona própria usando Gemini e Groq via LangChain, com suporte a RAG (pgvector)
- **Notificações** — Push via Firebase Cloud Messaging
- **WhatsApp** — Notificações e interação via API da Meta

---

## Stack Tecnológica

| Camada      | Tecnologia                                      |
|-------------|--------------------------------------------------|
| Backend     | Node.js 20+, TypeScript, Express                 |
| Banco       | PostgreSQL 16 + pgvector (via Docker)            |
| Auth        | JWT (access + refresh), Argon2id                 |
| IA          | LangChain, Gemini (Google AI), Groq              |
| Push        | Firebase Admin SDK (FCM)                         |
| WhatsApp    | Meta Cloud API                                   |
| Frontend    | Flutter SDK ^3.9.2                               |
| Observab.   | LangSmith                                        |

---

## Pré-requisitos

- **Node.js** 20 ou superior — [nodejs.org](https://nodejs.org)
- **Docker** e **Docker Compose** — [docs.docker.com](https://docs.docker.com/get-docker/)
- **Flutter SDK** ^3.9.2 — [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
- **Git**

---

## Configuração do Ambiente

### 1. Clone o repositório

```bash
git clone <url-do-repositório>
cd "PROJETO DE CICLO"
```

### 2. Configure as variáveis de ambiente do Backend

```bash
cd Backend
cp .env.example .env
```

Edite o arquivo `.env` e preencha ao menos as variáveis obrigatórias:

| Variável | Descrição |
|----------|-----------|
| `DB_PASSWORD` | Senha do PostgreSQL (obrigatória) |
| `JWT_SECRET` | Secret para assinar os tokens JWT (min. 32 chars) |
| `GEMINI_API_KEY` | Chave da API do Google AI Studio (para o chatbot) |
| `GROQ_API_KEY` | Chave da API do Groq (fallback do chatbot) |
| `FIREBASE_SERVICE_ACCOUNT` | JSON minificado da service account do Firebase (push notifications) |

As demais variáveis têm valores padrão definidos no `.env.example`.

---

## Executando o Backend

### Opção A — Com Docker (recomendado)

Sobe o PostgreSQL + pgvector e a API juntos:

```bash
cd Backend
docker compose up --build
```

A API ficará disponível em `http://localhost:3000`.

Para resetar completamente o banco (apaga todos os dados):

```bash
docker compose down -v && docker compose up --build
```

### Opção B — Sem Docker (banco externo)

Necessário ter um PostgreSQL 16 com a extensão `pgvector` instalada e rodando localmente.

```bash
cd Backend

# Instala as dependências
npm install

# Executa em modo desenvolvimento (hot-reload)
npm run dev
```

A API ficará disponível em `http://localhost:3000` (ou na porta definida em `PORT`).

---

## Executando o Frontend

```bash
cd Frontend

# Instala as dependências
flutter pub get

# Lista os dispositivos disponíveis
flutter devices

# Executa no dispositivo/emulador desejado
flutter run
```

> O app se conecta à API pela URL configurada no código. Para desenvolvimento local com emulador Android, use `http://10.0.2.2:3000` como base URL.

---

## Seeds (Dados de Demonstração)

Os seeds populam o banco com dados realistas para testes e apresentação.

```bash
cd Backend

# Roda todos os seeds em ordem
npm run db:seed
```

Após executar, os seguintes acessos estarão disponíveis:

### Admin

| Campo | Valor |
|-------|-------|
| Email | `admin@reservaqui.dev` |
| Senha | `Admin@2026` |

### Usuários (hóspedes)

| Nome | Email | Senha |
|------|-------|-------|
| Carlos Mendes | `carlos.mendes@email.com` | `Carlos@2026` |
| Ana Paula | `ana.paula@email.com` | `AnaP@2026` |
| Roberto Ferreira | `roberto.ferreira@email.com` | `Roberto@2026` |
| Fernanda | `fernanda.oliveira@email.com` | `Fer@2026` |
| Marcos | `marcos.souza@email.com` | `Marcos@2026` |
| Juliana | `juliana.costa@email.com` | `Juli@2026` |

### Hotéis

| Hotel | Cidade/UF | Email | Senha |
|-------|-----------|-------|-------|
| Grand Hotel Paulista | São Paulo/SP | `contato@grandpaulista.com.br` | `Hotel@2026` |
| Atlântico Palace | Rio de Janeiro/RJ | `reservas@atlanticopalace.com.br` | `Hotel@2026` |
| Solar da Bahia | Salvador/BA | `contato@solardabahia.com.br` | `Hotel@2026` |
| Vinícola Boutique Hotel | Bento Gonçalves/RS | `reservas@vinicolaboutique.com.br` | `Hotel@2026` |
| Amazon Jungle Lodge | Manaus/AM | `contato@amazonjunglelodge.com.br` | `Hotel@2026` |

### Imagens mock

As seeds inserem caminhos de imagens no padrão:

```
hotels/{hotel_id}/cover/portrait/seed-cover-portrait.jpg
hotels/{hotel_id}/cover/landscape/seed-cover-landscape.jpg
hotels/{hotel_id}/rooms/{quarto_id}/seed-foto-1.jpg
```

Para substituir por imagens reais, coloque os arquivos no diretório `Backend/storage/` seguindo exatamente essa estrutura de pastas. O `hotel_id` e o `quarto_id` podem ser consultados diretamente no banco após rodar os seeds.

---

## Scripts Disponíveis

Execute dentro da pasta `Backend/`:

| Script | Comando | Descrição |
|--------|---------|-----------|
| Desenvolvimento | `npm run dev` | Inicia com hot-reload (ts-node-dev) |
| Build | `npm run build` | Compila TypeScript → `dist/` |
| Produção | `npm run start` | Executa o build compilado |
| Seeds (todos) | `npm run db:seed` | Executa todos os seeds em ordem |
| Seeds (hotéis) | `npm run db:seed:hotels` | Executa apenas o seed de hotéis |
| Reset do banco | `npm run db:reset` | Apaga e recria o banco |
| Testes | `npm test` | Executa os testes com Jest |

---

## Estrutura do Projeto

```
PROJETO DE CICLO/
├── Backend/
│   ├── src/
│   │   ├── app.ts               # Entry point da API
│   │   ├── entities/            # Entidades com validação (Usuario, Anfitriao...)
│   │   ├── services/            # Lógica de negócio
│   │   ├── routes/              # Rotas da API
│   │   ├── middlewares/         # Auth, upload, error handling
│   │   ├── ai/                  # Chatbot Bene (LangChain + RAG)
│   │   └── database/
│   │       ├── masterDb.ts      # Pool de conexão do banco master
│   │       ├── tenantDb.ts      # Pool por tenant (hotel)
│   │       ├── migrations/      # Migrations SQL
│   │       └── seeds/           # Seeds de dados de demonstração
│   ├── storage/                 # Imagens carregadas pelos hotéis
│   ├── docker-compose.yml       # PostgreSQL + API em containers
│   ├── Dockerfile
│   ├── .env.example             # Template de variáveis de ambiente
│   └── package.json
└── Frontend/
    ├── lib/
    │   ├── main.dart
    │   ├── screens/             # Telas do app
    │   ├── widgets/             # Componentes reutilizáveis
    │   └── services/            # Comunicação com a API
    └── pubspec.yaml
```

---

## Variáveis de Ambiente

O arquivo completo com documentação de cada variável está em `Backend/.env.example`.

Resumo das obrigatórias para subir o projeto:

```env
DB_PASSWORD=sua_senha_aqui
JWT_SECRET=substitua_por_secret_seguro_de_64_bytes

# IA (ao menos uma é necessária para o chatbot funcionar)
GEMINI_API_KEY=
GROQ_API_KEY=

# Push notifications (opcional — app funciona sem, com aviso no console)
FIREBASE_SERVICE_ACCOUNT=
```

---

## Colaboradores

| Nome | GitHub |
|------|--------|
| Gabriel Pequeno Saraiva Tavares | [@gabriellpequeno](https://github.com/gabriellpequeno) |
| Lucas Gomes | [@fcolucascosta](https://github.com/fcolucascosta) |
| Bianca G | [@biagonzag-hue](https://github.com/biagonzag-hue) |
| Kellvin Correia Alves | [@kellvin-correia](https://github.com/kellvin-correia) |
| Levi Matias | [@Levi-Matias](https://github.com/Levi-Matias) |
