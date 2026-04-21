# Plan — ReservAqui

> Checklist vivo de execução. Tasks derivam das specs em `conductor/specs/`.
> Consulte `conductor/plan-guide.md` para entender como usar este arquivo.

---

## Fase 0 — Infraestrutura e Setup [PENDENTE]

> Spec: `specs/infra.spec.md`

- [ ] Configurar docker-compose (PostgreSQL + Backend + Qdrant)
- [ ] Criar schema inicial do banco de dados
- [ ] Configurar variáveis de ambiente (.env dev e prod)
- [ ] Configurar projeto Node.js + TypeScript + Express
- [ ] Configurar projeto Flutter com GoRouter e estrutura de pastas
- [ ] Pipeline de seed: script para popular banco com dados de demonstração

---

## Fase 1 — Autenticação [PENDENTE]

> Spec: `specs/auth.spec.md`

- [ ] Endpoint POST /auth/register (e-mail + senha)
- [ ] Endpoint POST /auth/login → JWT + refresh token
- [ ] Endpoint POST /auth/refresh
- [ ] Endpoint POST /auth/forgot-password
- [ ] Integração Google OAuth
- [ ] Middleware de autenticação (validar JWT)
- [ ] Tela de login no app (e-mail/senha + Google)
- [ ] Tela de cadastro no app
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

## Fase 4 — Integração WhatsApp [PENDENTE]

> Spec: `specs/integracao-whatsapp.spec.md`

- [ ] Endpoint GET /whatsapp/webhook (verificação Meta)
- [ ] Endpoint POST /whatsapp/webhook (recebimento de mensagens)
- [ ] Identificação de usuário por número de telefone (guest vs conta vinculada)
- [ ] Serviço de envio de mensagem de texto (WhatsAppService.sendText)
- [ ] Envio de confirmação de reserva + PDF do ticket via WhatsApp
- [ ] Recepção e forwarding de áudio e imagem para a IA

---

## Fase 5 — Chatbot IA (RAG + Intenção) [PENDENTE]

> Spec: `specs/chatbot-ia.spec.md`

- [ ] Configurar LangChain + Gemini Flash
- [ ] Adicionar Qdrant ao docker-compose
- [ ] Script de ingestão de documentos do hotel (chunk + embed)
- [ ] Criar RagService (retriever + geração de resposta)
- [ ] Classificador de intenção (dúvida / reserva / roteiro)
- [ ] Integrar RagService no WhatsApp webhook
- [ ] Salvar respostas do bot no histórico de mensagens
- [ ] Tela de chat com o bot no app (app hóspede)

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
