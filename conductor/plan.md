# Plan — ReservAqui

> Checklist vivo de execução. Tasks derivam das specs em `conductor/specs/`.
> Consulte `conductor/plan-guide.md` para entender como usar este arquivo.

---

## Fase 0 — Infraestrutura e Setup [EM ANDAMENTO]

> Spec: `specs/infra.spec.md`

- [ ] Configurar docker-compose (PostgreSQL + Backend + Qdrant)
- [ ] Criar schema inicial do banco de dados
- [ ] Configurar variáveis de ambiente (.env dev e prod)
- [ ] Configurar projeto Node.js + TypeScript + Express
- [x] Configurar projeto Flutter com GoRouter e estrutura de pastas
- [ ] Pipeline de seed: script para popular banco com dados de demonstração

### P0 — HTTP Client + Auth Infra [CONCLUÍDO]
> Plan detalhado: `plans/infra-http-client.plan.md`

- [x] Criar `AuthState` + `AuthNotifier` (Riverpod AsyncNotifier) com persistência via shared_preferences
- [x] Criar `DioClient` como Riverpod Provider com interceptor Bearer + auto-refresh por role
- [x] Converter `UsuarioService` para Riverpod Provider (substituiu static class)
- [x] Implementar `HotelService` Riverpod Provider
- [x] Atualizar `main.dart` com `ProviderScope` + `GoRouter`
- [x] Remover `MockAuth` do roteador e de todas as páginas — conectado ao `authProvider` real

---

## Fase 1 — Autenticação [EM ANDAMENTO]

> Spec: `specs/auth.spec.md`

- [ ] Endpoint POST /auth/register (e-mail + senha)
- [ ] Endpoint POST /auth/login → JWT + refresh token
- [ ] Endpoint POST /auth/refresh
- [ ] Endpoint POST /auth/forgot-password
- [ ] Integração Google OAuth
- [ ] Middleware de autenticação (validar JWT)
- [ ] Tela de login no app (e-mail/senha + Google)
- [x] Tela de cadastro no app
  - [x] Tela de cadastro de anfitrião (P1-C) — plan: plans/host-signup-page.plan.md
  - [x] CEP autofill no cadastro de hotel (cep-autofill) — plan: plans/cep-autofill.plan.md
- [ ] Tela de esqueci minha senha
- [ ] Sessão persistente no app (armazenar token localmente)

---

## Fase 2 — Gestão de Hotéis e Quartos [PENDENTE]

> Spec: `specs/gestao-hotel.spec.md`

- [ ] CRUD de hotéis (backend)
- [ ] CRUD de quartos (backend)
- [ ] Endpoint de busca com filtros (datas, capacidade)
- [ ] Tela de lista de hotéis/quartos (app hóspede)
- [ ] Tela de detalhes do quarto (app hóspede)
- [ ] Tela de gerenciar quartos (app fornecedor — perfil hub)

---

## Fase 3 — Sistema de Reservas [PENDENTE]

> Spec: `specs/reservas.spec.md`

- [ ] Endpoint POST /reservas (criar)
- [ ] Endpoint GET /reservas (listar por usuário / por hotel)
- [ ] Endpoint PATCH /reservas/:id/status (confirmar, cancelar, iniciar, finalizar)
- [ ] Validação de disponibilidade de quarto
- [ ] Tela de fluxo de reserva no app (datas → confirmar → pagamento)
- [ ] Tela de minhas reservas — hóspede (histórico + status)
- [ ] Seção de reservas no perfil do fornecedor (histórico + alterar status)
- [ ] Busca avançada de reservas no perfil do fornecedor

---

## Fase 4 — Integração WhatsApp [EM ANDAMENTO]

> Spec: `specs/integracao-whatsapp.spec.md`
> Todas as tasks tecnicas estao concluidas. Checkpoint de fase pendente de verificacao manual.

- [x] Endpoint GET `/whatsapp/webhook` para verificacao da Meta [sha: c90617e]
- [x] Endpoint POST `/whatsapp/webhook` para recebimento de mensagens [sha: c90617e]
- [x] Validar o inbound contra o `WHATSAPP_PHONE_ID` global da plataforma [sha: c90617e]
- [x] Vincular sessao ao hospede por numero de telefone quando houver conta [sha: c90617e]
- [x] Persistir sessao, mensagem do cliente e resposta do bot no historico [sha: c90617e]
- [x] Deduplicar inbound por `wamid` / `messages[0].id` [sha: c90617e]
- [x] Persistir `message_id` da Meta e o ultimo status outbound conhecido [sha: c90617e]
- [x] Fazer fallback para template generico fora da janela de 24 horas [sha: c90617e]
- [x] Tratar audio, imagem e documento com metadados + resposta amigavel por tipo [sha: c90617e]
- [x] Encerrar sessao por fim de fluxo ou inatividade configuravel [sha: c90617e]
- [x] Enviar confirmacao de reserva + PDF via WhatsApp [sha: c90617e]

---

## Fase 5 — Chatbot IA (RAG + Intenção) [PENDENTE]

> Spec: `specs/chatbot-ia.spec.md`

- [ ] Configurar LangChain + Gemini Flash
- [ ] Implementar resolucao de hotel na conversa e enriquecer `sessao_chat.hotel_id` antes do RAG hotel-scoped
- [ ] Consultar dados canonicos no banco relacional (preco, disponibilidade, reserva)
- [ ] Criar estrutura de documentos do hotel com embeddings em `pgvector`
- [ ] Criar script de ingestao e reindexacao de documentos do hotel
- [ ] Implementar `RagService` com busca vetorial por hotel
- [ ] Implementar classificador de intencao (duvida / reserva / roteiro)
- [ ] Integrar o fluxo RAG ao webhook do WhatsApp
- [ ] Substituir a resposta provisoria pelo fluxo de IA
- [ ] Garantir persistencia das respostas do bot no historico

---

## Fase 6 — Roteiro Turístico [PENDENTE]

> Spec: `specs/roteiro-turistico.spec.md`

- [ ] Endpoint POST /itinerario
- [ ] Função de geração de roteiro (Gemini + prompt estruturado → JSON)
- [ ] Bot oferece roteiro automaticamente após reserva confirmada
- [ ] Bot gera roteiro quando hóspede pede via WhatsApp

---

## Fase 7 — Pagamentos (InfinitePay) [PENDENTE]

> Spec: `specs/pagamentos.spec.md`
> Responsável: Kellvin | Fallback: Nice to Have se não fechar no prazo

- [ ] Integração InfinitePay no backend
- [ ] Fluxo de pagamento no app (checkout → InfinitePay → confirmação)
- [ ] Fluxo de pagamento no WhatsApp (link de pagamento gerado pelo bot)
- [ ] Geração de PDF do ticket após pagamento confirmado

---

## Fase 8 — Notificações In-App [PENDENTE]

> Spec: `specs/notificacoes.spec.md`

- [ ] Infraestrutura de notificações (WebSocket ou push)
- [ ] Notificação: reserva confirmada pelo hotel
- [ ] Notificação: reserva cancelada
- [ ] Notificação: lembrete de check-in se aproximando
- [ ] Notificação: nova mensagem no chat
- [ ] Notificação: solicitação de avaliação após check-out
- [ ] Tela de notificações no app

---

## Fase 9 — Avaliações [PENDENTE]

> Spec: `specs/avaliacoes.spec.md`

- [ ] Endpoint POST /avaliacoes
- [ ] Endpoint GET /avaliacoes?hotelId=
- [ ] Exibir avaliações na tela de detalhes do hotel
- [ ] Tela de submeter avaliação (após hospedagem finalizada)
- [ ] Trigger: notificação disparada quando fornecedor marca check-out como finalizado

---

## Fase 10 — Seed e Polimento Final [PENDENTE]

> Sem spec — execução direta

- [ ] Seed completo: 5 hotéis, 5 quartos/hotel, 6 hóspedes, 5 hosts, 1 admin
- [ ] Seed de reservas: 1 por status por hóspede
- [ ] Seed de avaliações: mínimo 1 por hóspede
- [ ] Seed de documentos RAG: 1 por hotel (FAQ + políticas)
- [ ] Revisão de responsividade (mobile, web, tablet, portrait, landscape)
- [ ] Revisão de dark/light mode em todas as telas
- [ ] Revisão do fluxo completo de demonstração ponta a ponta

---

## Nice to Have — Se Sobrar Tempo

- [ ] Tela de roteiro turístico com aba dedicada (cards por dia)
- [ ] Chat in-app com staff humano
- [ ] Inbox no perfil do fornecedor
- [ ] Refinamento iterativo do roteiro
- [ ] Exportação de dados e roteiro como PDF
- [ ] Multi-idioma (EN/ES)
