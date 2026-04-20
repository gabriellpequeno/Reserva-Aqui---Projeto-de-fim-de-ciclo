# Tutorial Completo: Pipeline de Desenvolvimento

> Cada etapa explicada com quantidade, localização, exemplo real e regras.

---

## O Fluxo Completo

```
1. Project Brief         (1 por projeto)
   │                     Exemplo: "ReservAqui — plataforma de gestão hoteleira com IA"
   │                     Arquivo: conductor/product.md
   │
   ▼
2. PRD do Produto        (1 por produto)
   │                     Exemplo: "Tudo que o ReservAqui faz: reservas, chat, roteiros, pagamentos"
   │                     Arquivo: conductor/prd.md
   │
   ▼
3. PRD de Feature        (1 por feature grande)
   │                     Exemplo: "PRD do Chatbot IA", "PRD do Sistema de Reservas"
   │                     Arquivo: conductor/features/chatbot-ia.prd.md
   │
   ▼
4. Spec                  (1 por PRD de Feature)
   │                     Exemplo: "Como o RAG funciona tecnicamente"
   │                     Arquivo: conductor/specs/chatbot-ia.spec.md
   │
   ▼
5. Plan                  (1 por projeto, com seções por feature)
   │                     Exemplo: "Fase 1: Infra [x] → Fase 4: IA [ ]"
   │                     Arquivo: conductor/plan.md
   │
   ▼
6. Implement             (1 por task do plan)
   │                     Exemplo: "Criar RagService com LangChain"
   │                     Arquivo: código-fonte no Backend/src/
   │
   ▼
7. Commit                (1 por task concluída)
   │                     Exemplo: "feat(rag): criar RagService com LangChain"
   │                     Arquivo: nenhum — é o git commit
   │
   ▼
8. PR                    (1 por feature ou fase completa)
                         Exemplo: "PR: Integração WhatsApp Cloud API"
                         Arquivo: nenhum — é no GitHub
```

---

## Estrutura de pastas resultante

```
conductor/
├── product.md                    ← 1. Project Brief
├── product-guidelines.md         ← 1. (complemento visual/tom)
├── prd.md                        ← 2. PRD do Produto
├── features/                     ← 3. PRDs de Feature
│   ├── chatbot-ia.prd.md
│   ├── sistema-reservas.prd.md
│   ├── integracao-whatsapp.prd.md
│   └── roteiro-turistico.prd.md
├── specs/                        ← 4. Specs
│   ├── chatbot-ia.spec.md
│   ├── sistema-reservas.spec.md
│   ├── integracao-whatsapp.spec.md
│   └── roteiro-turistico.spec.md
├── plan.md                       ← 5. Plan (único)
├── workflow.md                   ← Regras do processo
└── tech-stack.md                 ← Tecnologias usadas
```

---

## Etapa 1 — Project Brief

### Regras
| Item | Valor |
|------|-------|
| **Quantidade** | 1 por projeto |
| **Quando criar** | No dia zero, antes de tudo |
| **Quem escreve** | O fundador / líder do projeto |
| **Tamanho** | 1/2 página (máximo 1 página) |
| **Arquivo** | `conductor/product.md` |

### Propósito
Responde a pergunta: **"Se alguém te perguntar o que é esse projeto em 30 segundos, o que você diz?"**

Não tem detalhes técnicos. Não tem lista de features. É o **elevador pitch** do projeto.

### Exemplo real — ReservAqui

```markdown
# Project Brief — ReservAqui

## O que é
Plataforma multi-tenant de gestão hoteleira que conecta hóspedes 
e hotéis através de WhatsApp, apps mobile e inteligência artificial.

## Problema que resolve
Hotéis de pequeno/médio porte perdem reservas e gastam tempo 
respondendo perguntas repetitivas. Hóspedes querem respostas 
rápidas e experiências personalizadas.

## Público-alvo
- Hóspedes que buscam hotéis e querem atendimento rápido
- Gerentes de hotel que querem automatizar atendimento

## Plataformas
- App mobile (Flutter) para hóspede e fornecedor
- Backend Node.js com Express
- Integração WhatsApp Business API
- IA com Google Gemini + RAG

## Contexto
Projeto acadêmico de fim de ciclo — Turma T7
Prazo: ~1 mês para MVP funcional
```

### O que NÃO colocar aqui
- ❌ Endpoints de API
- ❌ Modelos de banco de dados
- ❌ Nomes de bibliotecas
- ❌ Lista detalhada de features

---

## Etapa 2 — PRD do Produto

### Regras
| Item | Valor |
|------|-------|
| **Quantidade** | 1 por produto |
| **Quando criar** | Logo após o Project Brief |
| **Quem escreve** | Product Owner + time |
| **Tamanho** | 3-10 páginas |
| **Arquivo** | `conductor/prd.md` |

### Propósito
Responde: **"Tudo que o produto faz, listado e priorizado."**

É o mapa completo — lista TODAS as features, separadas em MVP e Nice to Have. Ainda é linguagem de negócio, não técnica.

### Exemplo real — ReservAqui
O seu `escopo-projeto.md` **já é isso**. Ele lista:

- Frontend Cliente (login, explorar hotéis, reservas, chat, roteiro)
- Frontend Fornecedor (reservas, inbox, visualização de roteiros)
- Backend (REST, WhatsApp, IA, tools)
- Banco de Dados
- Infraestrutura

Cada item marcado como MVP ou Nice to Have. **Esse arquivo é o PRD do Produto.**

### Diferença do Project Brief

| Project Brief | PRD do Produto |
|---|---|
| "O ReservAqui conecta hóspedes e hotéis" | "Feature 1: Tela de login com JWT. Feature 2: Lista de hotéis com filtros. Feature 3: Chat via WhatsApp..." |
| Visão geral | Lista completa |
| 1/2 página | 3-10 páginas |

---

## Etapa 3 — PRD de Feature

### Regras
| Item | Valor |
|------|-------|
| **Quantidade** | 1 por feature grande |
| **Quando criar** | Quando o time decidir implementar aquela feature |
| **Quem escreve** | PO + dev líder da feature |
| **Tamanho** | 1-2 páginas |
| **Arquivo** | `conductor/features/{nome-da-feature}.prd.md` |

### Propósito
Responde: **"O que ESSA feature específica faz, do ponto de vista do USUÁRIO?"**

Pega UMA feature do PRD do Produto e detalha com User Stories e Critérios de Aceite.

### Quando criar um novo PRD de Feature?
**Sempre que for implementar algo que envolve:**
- Mais de 3 arquivos de código
- Interação com serviço externo (Meta, Gemini, etc.)
- Mudança no banco de dados
- Nova tela no app

**NÃO precisa de PRD de Feature para:**
- Corrigir um bug
- Refatorar código existente
- Adicionar um campo simples

### Quantos o ReservAqui teria?

| # | Feature | Arquivo |
|---|---------|---------|
| 1 | Autenticação (Login/Cadastro) | `auth.prd.md` |
| 2 | Gestão de Hotéis e Quartos (CRUD) | `gestao-hotel.prd.md` |
| 3 | Sistema de Reservas | `reservas.prd.md` |
| 4 | Integração WhatsApp | `integracao-whatsapp.prd.md` |
| 5 | Chatbot com IA (RAG) | `chatbot-ia.prd.md` |
| 6 | Roteiro Turístico | `roteiro-turistico.prd.md` |
| 7 | Pagamentos (InfinitePay) | `pagamentos.prd.md` |
| 8 | Notificações Push | `notificacoes.prd.md` |

### Exemplo real — ReservAqui: PRD do Chatbot IA

```markdown
# PRD de Feature: Chatbot Inteligente via WhatsApp

## Origem
PRD do Produto → Seção "Backend MVP" → Item 3 (Pipeline de IA com LangChain)

## Problema
Hóspedes enviam mensagens pelo WhatsApp com perguntas sobre o hotel 
(tem piscina? qual o horário do café? aceita pet?). Hoje não tem 
ninguém respondendo automaticamente.

## Objetivo
O bot deve responder automaticamente perguntas frequentes usando 
as informações cadastradas do hotel como base de conhecimento.

## Personas
- Maria (hóspede): Manda "tem café da manhã incluso?" às 23h. 
  Espera resposta imediata.
- João (gerente): Quer que perguntas simples sejam respondidas 
  sem precisar de atendente.

## User Stories
1. Como hóspede, quero enviar uma pergunta sobre o hotel pelo 
   WhatsApp e receber resposta automática em até 10 segundos.
2. Como hóspede, quero pedir um roteiro turístico da cidade 
   e receber sugestões organizadas por dia.
3. Como gerente, quero que o bot diga "vou transferir para 
   um atendente" quando não souber responder.

## Critérios de Aceite
- [ ] Bot responde perguntas sobre o hotel usando RAG
- [ ] Bot gera roteiros turísticos personalizados
- [ ] Respostas ficam salvas no histórico da conversa
- [ ] Tempo de resposta < 10 segundos
- [ ] Bot informa quando não sabe a resposta

## Fora de Escopo
- Bot criar reservas automaticamente
- Entender áudios (speech-to-text)
- Responder com imagens
```

### O que NÃO colocar aqui
- ❌ Nome de bibliotecas (LangChain, pgvector)
- ❌ Estrutura de tabelas
- ❌ Formato de JSON
- ❌ Endpoints

> **Regra:** Se tem código ou nome de tecnologia, não é PRD — é Spec.

---

## Etapa 4 — Spec (Especificação Técnica)

### Regras
| Item | Valor |
|------|-------|
| **Quantidade** | 1 por PRD de Feature |
| **Quando criar** | Depois que o PRD de Feature é aprovado |
| **Quem escreve** | Dev líder da feature |
| **Tamanho** | 2-5 páginas |
| **Arquivo** | `conductor/specs/{nome-da-feature}.spec.md` |

### Propósito
Responde: **"COMO vamos construir isso tecnicamente?"**

Traduz cada User Story do PRD em endpoints, tabelas, fluxos de dados e decisões de arquitetura.

### Relação PRD → Spec

```
features/chatbot-ia.prd.md          specs/chatbot-ia.spec.md
─────────────────────────           ─────────────────────────
"Hóspede manda mensagem       →    POST /api/v1/whatsapp/webhook
 e recebe resposta"                 → RagService.query()
                                    → WhatsAppService.sendText()

"Respostas ficam salvas        →    INSERT INTO mensagem_chat
 no histórico"                      (origem='BOT', conteudo=resposta)

"Bot gera roteiros"            →    POST /api/v1/itinerario
                                    → GeminiService.generate()
                                    → response: { dias: [...] }
```

### Conteúdo obrigatório de uma Spec

| Seção | Pergunta que responde |
|-------|----------------------|
| **Visão Geral** | Resumo técnico em 3 frases |
| **Diagrama/Fluxo** | "Dados entram aqui → passam por aqui → saem ali" |
| **Endpoints** | Método, rota, request body, response body |
| **Modelos de Dados** | Tabelas novas/modificadas com tipos |
| **Dependências** | Libs, SDKs, serviços externos |
| **Decisões Técnicas** | "Escolhemos X porque Y" |
| **Riscos** | "Pode dar errado se Z" |
| **A Implementar** | Débitos técnicos que ficam pro futuro |

### Exemplo resumido

```markdown
# Spec: Chatbot IA — RAG + WhatsApp

## Visão Geral
Serviço que intercepta mensagens recebidas pelo webhook do WhatsApp, 
consulta base vetorizada (pgvector) com informações do hotel e gera
respostas usando Google Gemini via LangChain.

## Endpoints

### POST /api/v1/whatsapp/webhook (modificar)
- Substituir echo por chamada ao RagService
- Request: payload da Meta (inalterado)
- Lógica: RagService.query(texto) → WhatsAppService.sendText(resposta)

### POST /api/v1/itinerario (novo)
- Request: { destino, datas, interesses, orcamento }
- Response: { dias: [{ atividades: [...] }] }

## Modelo de Dados

### documento_hotel (NOVA)
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid PK | Identificador |
| hotel_id | uuid FK | Qual hotel |
| conteudo | text | Texto do documento |
| embedding | vector(768) | Vetor para busca |

## Dependências
- @langchain/google-genai, pgvector

## Decisões
- pgvector ao invés de Qdrant → já temos PostgreSQL, menos infra
```

---

## Etapa 5 — Plan

### Regras
| Item | Valor |
|------|-------|
| **Quantidade** | 1 por projeto (arquivo ÚNICO) |
| **Quando criar** | Depois que a primeira Spec é aprovada |
| **Quem atualiza** | Todo dev, ao começar/terminar uma task |
| **Tamanho** | Cresce com o projeto |
| **Arquivo** | `conductor/plan.md` |

### Propósito
Responde: **"Qual task eu faço agora e o que já foi feito?"**

É o **checklist vivo** do projeto inteiro. Cada feature tem uma seção. Cada task tem um status.

### Como funciona?
- Cada **Fase** agrupa tasks de uma feature
- Cada **task** é uma unidade de trabalho de 1-4 horas
- Os status são:
  - `[ ]` → pendente
  - `[~]` → em progresso (alguém está fazendo)
  - `[x]` → concluída
  - `[sha: abc1234]` → hash do commit (opcional mas rastreável)

### De onde vêm as tasks?
**Da Spec.** Você lê a spec e quebra em pedaços menores:

```
Spec diz:                              Plan fica:
"Criar tabela documento_hotel"    →    [ ] Criar tabela documento_hotel com embedding
"Instalar pgvector"               →    [ ] Adicionar extensão pgvector no Docker
"Criar RagService"                →    [ ] Criar RagService com LangChain
"Integrar no controller"         →    [ ] Substituir echo por RagService no webhook
```

### Exemplo real — ReservAqui

```markdown
# Plan — ReservAqui

## Fase 1 — Infraestrutura [CONCLUÍDA]
- [x] Configurar Docker (PostgreSQL + Backend) [sha: d87148b]
- [x] Criar schema do banco Master [sha: 212736e]
- [x] Implementar CRUD de hotéis, quartos, usuários [sha: 22ad53c]

## Fase 2 — Autenticação [CONCLUÍDA]
- [x] Login com JWT + Argon2
- [x] Middleware de autenticação
- [x] Refresh token

## Fase 3 — Integração WhatsApp [CONCLUÍDA]
- [x] Controller GET (verificação webhook)
- [x] Controller POST (recebimento de mensagens)
- [x] Service de envio (sendText, sendTemplate)
- [x] Persistência em sessao_chat + mensagem_chat
- [x] Documentação (whatsapp_context.md)

## Fase 4 — Chatbot IA (RAG) [PRÓXIMA]
- [ ] Adicionar extensão pgvector no PostgreSQL
- [ ] Criar tabela documento_hotel com campo embedding
- [ ] Script de ingestão de documentos (chunk + embed)
- [ ] Criar RagService com LangChain (retriever + Gemini)
- [ ] Substituir echo por RagService no WhatsAppController
- [ ] Salvar respostas do bot como origem='BOT'
- [ ] Criar endpoint POST /itinerario
- [ ] Testes de integração com mensagens reais

## Fase 5 — App Flutter Cliente [FUTURO]
- [ ] Tela de explorar hotéis
- [ ] Tela de detalhes do quarto
- [ ] Fluxo de reserva
- [ ] Tela de chat com histórico
- [ ] Tela de roteiro turístico
```

### O Plan NÃO é
- ❌ Uma spec (não tem detalhes técnicos)
- ❌ Um PRD (não tem user stories)
- ❌ Múltiplos arquivos (é sempre UM só)

---

## Etapa 6 — Implement

### Regras
| Item | Valor |
|------|-------|
| **Quantidade** | 1 por task do plan |
| **Quando acontece** | Ao pegar a próxima task `[ ]` do plan |
| **O que gera** | Código + testes |
| **Arquivo** | Código no `Backend/src/`, `Frontend/lib/`, etc. |

### Como funciona na prática

```
1. Abro o plan.md → encontro: "[ ] Criar RagService com LangChain"
2. Marco como: "[~] Criar RagService com LangChain"
3. Abro a spec: specs/chatbot-ia.spec.md → leio a seção do RagService
4. Codifico: Backend/src/services/rag.service.ts
5. Testo: mando mensagem real pelo WhatsApp
6. Marco como: "[x] Criar RagService com LangChain"
7. Faço o commit
```

---

## Etapa 7 — Commit

### Regras
| Item | Valor |
|------|-------|
| **Quantidade** | 1 por task concluída (ou grupo pequeno de tasks relacionadas) |
| **Formato** | Conventional Commits |
| **Arquivo** | Nenhum — é o `git commit` |

### Formato

```
<tipo>(<escopo>): <descrição curta>

<corpo opcional — o que e por que>

<footer opcional — breaking changes, issues>
```

### Tipos

| Tipo | Quando usar | Exemplo ReservAqui |
|------|-------------|-------------------|
| `feat` | Feature nova | `feat(rag): criar RagService com LangChain` |
| `fix` | Correção de bug | `fix(webhook): corrigir timeout no POST` |
| `docs` | Só documentação | `docs(whatsapp): adicionar setup guide` |
| `refactor` | Melhoria sem mudar comportamento | `refactor(service): remover any do WhatsAppService` |
| `chore` | Infra, configs | `chore(docker): adicionar pgvector ao compose` |
| `test` | Só testes | `test(rag): adicionar testes de integração` |

---

## Etapa 8 — PR (Pull Request)

### Regras
| Item | Valor |
|------|-------|
| **Quantidade** | 1 por feature completa ou fase do plan |
| **Quando criar** | Ao terminar todas as tasks de uma fase |
| **Arquivo** | Nenhum — é no GitHub |

### Template

```markdown
## Descrição
<2-3 frases sobre o que essa PR entrega>

## Arquivos alterados
| Arquivo | Tipo | O que faz |
|---------|------|-----------|
| `src/services/rag.service.ts` | NEW | Serviço RAG com LangChain |
| `src/controllers/whatsapp.controller.ts` | MOD | Integra RagService |

## Como testar
1. `docker-compose up --build`
2. Mandar mensagem pelo WhatsApp
3. Verificar que o bot responde com base no FAQ do hotel

## Checklist
- [ ] Testes passando
- [ ] Sem `any` no TypeScript
- [ ] Documentação atualizada
- [ ] Spec seguida fielmente
```

---

## Resumo — O Mapa Completo

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   1. PROJECT BRIEF (1 por projeto)                               │
│   "ReservAqui — plataforma de gestão hoteleira com IA"           │
│   📄 conductor/product.md                                        │
│                          │                                       │
│                          ▼                                       │
│   2. PRD DO PRODUTO (1 por produto)                              │
│   "Tudo: reservas + chat + roteiros + pagamentos"                │
│   📄 conductor/prd.md                                            │
│                          │                                       │
│            ┌─────────────┼─────────────┐                         │
│            ▼             ▼             ▼                          │
│   3. PRD DE FEATURE   PRD DE FEATURE   PRD DE FEATURE            │
│   (1 por feature)    (1 por feature)   (1 por feature)           │
│   "Chatbot IA"       "Reservas"        "WhatsApp"                │
│   📄 features/       📄 features/      📄 features/              │
│            │             │             │                          │
│            ▼             ▼             ▼                          │
│   4. SPEC            SPEC             SPEC                       │
│   (1 por PRD feat)   (1 por PRD feat)  (1 por PRD feat)          │
│   "Como o RAG        "Como o CRUD      "Como o webhook           │
│    funciona"          de reservas       recebe msgs"              │
│   📄 specs/           funciona"        📄 specs/                  │
│            │          📄 specs/         │                          │
│            │             │             │                          │
│            └─────────────┼─────────────┘                         │
│                          ▼                                       │
│   5. PLAN (1 por projeto — ÚNICO)                                │
│   "Fase 1 [x] → Fase 2 [x] → Fase 3 [x] → Fase 4 [ ]"         │
│   📄 conductor/plan.md                                           │
│                          │                                       │
│                    ┌─────┼─────┐                                 │
│                    ▼     ▼     ▼                                  │
│   6. IMPLEMENT   IMPL   IMPL   IMPL                             │
│   (1 por task)                                                   │
│   "Criar RagService" "Criar tabela" "Integrar no controller"    │
│   📄 Backend/src/                                                │
│                    │     │     │                                  │
│                    ▼     ▼     ▼                                  │
│   7. COMMIT      COMMIT  COMMIT  COMMIT                         │
│   (1 por task)                                                   │
│   "feat(rag): ..." "chore(db): ..." "feat(webhook): ..."        │
│                    │     │     │                                  │
│                    └─────┼─────┘                                 │
│                          ▼                                       │
│   8. PR (1 por fase/feature completa)                            │
│   "PR: Chatbot IA com RAG"                                       │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Cheat Sheet — Quantidade de cada coisa

| Etapa | Quantidade | Arquivo |
|-------|-----------|---------|
| Project Brief | **1** por projeto | `conductor/product.md` |
| PRD do Produto | **1** por produto | `conductor/prd.md` |
| PRD de Feature | **1** por feature grande | `conductor/features/*.prd.md` |
| Spec | **1** por PRD de Feature | `conductor/specs/*.spec.md` |
| Plan | **1** por projeto (único!) | `conductor/plan.md` |
| Implement | **1** por task do plan | código-fonte |
| Commit | **1** por task concluída | git |
| PR | **1** por fase/feature completa | GitHub |
