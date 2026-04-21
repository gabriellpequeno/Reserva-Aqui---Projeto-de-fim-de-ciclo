# Plan - ReservAqui

> Living execution tracker. Tasks come from approved specs in `conductor/specs/`.

---

## Fase 0 - Infraestrutura e Setup [PENDENTE]
- [ ] Configurar docker-compose para backend e PostgreSQL com `pgvector`
- [ ] Consolidar variaveis de ambiente de backend, IA e WhatsApp
- [ ] Garantir script de reset/setup do banco para ambiente local
- [ ] Definir estrategia de seeds para demo

## Fase 1 - Autenticacao [PENDENTE]
- [ ] Finalizar fluxo de autenticacao de hospedes
- [ ] Finalizar fluxo de autenticacao de hoteis
- [ ] Revisar refresh token e logout server-side

## Fase 2 - Gestao de Hoteis e Quartos [PENDENTE]
- [ ] Consolidar CRUD de hotel
- [ ] Consolidar CRUD de quartos e categorias
- [ ] Revisar configuracao operacional do hotel

## Fase 3 - Reservas [PENDENTE]
- [ ] Consolidar criacao de reserva
- [ ] Consolidar alteracao de status
- [ ] Garantir sincronizacao entre reserva tenant e historico global

## Fase 4 - Integracao WhatsApp [EM ANDAMENTO]
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

## Fase 5 - Chatbot IA (RAG + Intencao) [PENDENTE]
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

## Fase 6 - Roteiro Turistico [PENDENTE]
- [ ] Criar endpoint `/itinerario`
- [ ] Gerar roteiro estruturado com Gemini
- [ ] Integrar solicitacao de roteiro ao fluxo conversacional

## Fase 7 - Pagamentos [PENDENTE]
- [ ] Consolidar integracao InfinitePay
- [ ] Integrar pagamento ao fluxo de reserva no WhatsApp
- [ ] Gerar comprovante/PDF pos-pagamento

## Fase 8 - Notificacoes [PENDENTE]
- [ ] Consolidar infraestrutura de notificacoes
- [ ] Disparar notificacoes de reserva e mensagens relevantes

## Fase 9 - Avaliacoes [PENDENTE]
- [ ] Consolidar fluxo de avaliacao pos-estadia
- [ ] Exibir avaliacoes nas telas relevantes

## Fase 10 - Seed e Polimento Final [PENDENTE]
- [ ] Popular hoteis, quartos, hospedes e reservas de demonstracao
- [ ] Popular documentos RAG por hotel
- [ ] Revisar o fluxo fim a fim da demo
