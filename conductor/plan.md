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
- [x] Tela de login no app (e-mail/senha + Google)
  - [x] Login page integrada (P2-A) — plan: plans/login-page.plan.md
- [x] Tela de cadastro no app
  - [x] Tela de cadastro de anfitrião (P1-C) — plan: plans/host-signup-page.plan.md
  - [x] CEP autofill no cadastro de hotel (cep-autofill) — plan: plans/cep-autofill.plan.md
- [ ] Tela de esqueci minha senha
- [ ] Sessão persistente no app (armazenar token localmente)
- [ ] Tela de perfil do hóspede (P3-A) — plan: plans/user-profile-page.plan.md

---

## Fase P3-B — Host Profile Page [EM ANDAMENTO]

> Spec: `specs/host-profile-page.spec.md`
> Plan detalhado: `plans/host-profile-page.plan.md`

- [ ] Criar `HostProfileNotifier` + provider
- [ ] Converter `HostProfilePage` para `ConsumerWidget`
- [ ] Integrar `GET /hotel/me` no notifier
- [ ] Integrar `GET /uploads/hotels/:hotel_id/cover` no notifier
- [ ] Mapear dados para os widgets e exibir foto de capa
- [ ] Tratar loading, erro e lista de fotos vazia

---

## Fase P3-E — Settings Page [CONCLUÍDO]

> Spec: `specs/settings-page.spec.md`
> Plan detalhado: `plans/settings-page.plan.md`

- [x] Criar `ThemeNotifier` em `lib/core/theme/theme_notifier.dart`
- [x] Conectar `ThemeNotifier` ao `MaterialApp` no `main.dart`
- [x] Conectar toggle Dark Mode ao `ThemeNotifier`
- [x] Conectar toggle Notificações ao `shared_preferences`
- [x] Criar telas estáticas legais e implementar navegação nos tiles

---

## Fase P4-E — Favorites Page [PENDENTE]

> Spec: `specs/favorites-page.spec.md`
> Plan detalhado: `plans/favorites-page.plan.md`

- [ ] Auditar referências ao modelo `FavoriteRoom` em todo o projeto
- [ ] Renomear e adaptar `FavoriteRoom` → `FavoriteHotel` com campos do backend
- [ ] Migrar `FavoritesNotifier` para `AsyncNotifier` com chamadas reais à API
- [ ] Atualizar `FavoriteCard` com novo modelo, placeholder de imagem e navegação correta
- [ ] Conectar botão de favorito na `RoomDetailsPage` via `favoritesProvider`

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

## Fase P4-B — Search Page Integration [EM ANDAMENTO]

> Spec: `specs/search-page-integration.spec.md`
> Plan detalhado: `plans/search-page-integration.plan.md`

- [x] Criar `SearchRoomResult` model + `SearchService` + Riverpod provider
- [x] Criar `GuestsPickerSheet` (bottom sheet com contador)
- [x] Atualizar `SearchNotifier.performSearch()` — trocar mock por chamada real + mapping → `FavoriteRoom`
- [x] Implementar `onTap` de datas (`showDateRangePicker`) e hóspedes (`showModalBottomSheet`) em `search_page.dart`
- [x] Substituir `Image.asset` hardcoded por `Image.network` com fallback em `_buildHotelCard`
- [ ] Validar fluxo ponta a ponta (busca, pickers, loading, vazio, imagens, navegação)

---

## Fase P4-C — Hotel Details Page [PENDENTE]

> Plan: `plans/hotel-details-page.plan.md`
> Spec: `specs/hotel-details-page.spec.md`

- [ ] Verificar endpoint `GET /hotel/:hotel_id` sem autenticação
- [ ] Criar `HotelDetailsState` com loading/error por seção
- [ ] Criar modelos: `HotelModel`, `AvaliacaoModel`, `ComodidadeModel`, `PoliticasModel`, `CategoriaModel`
- [ ] Criar `HotelDetailsNotifier` com `Future.wait` e tratamento individual por seção
- [ ] Auditar e atualizar `hotel_details_page.dart` (substituir mocks, adicionar comodidades, filtro de camas)
- [ ] Validar renderização ponta a ponta com dados reais

---

## Fase P4-E — My Rooms Page [EM ANDAMENTO]

> Plan: `plans/my-rooms-page.plan.md`
> Spec: `specs/my-rooms-page.spec.md`
> PRD: `features/my-rooms-page.prd.md`

- [ ] Ajustar backend: enum `CanalOrigem` + `Reserva.validateWalkin` aceitar `canal_origem: "manual"` sem identificação de hóspede
- [x] Criar modelos: `QuartoModel`, `RoomCategoryCardModel`, `ReservaHotelModel` (reutiliza `CategoriaHotelModel`)
- [x] Criar `AvailabilityCalculator` (utility puro) — testes unitários pendentes
- [x] Criar `MyRoomsState` + `MyRoomsNotifier` com load paralelo, delete via N chamadas `DELETE` e reserva manual
- [x] Criar `DeleteRoomDialog` (modal + quantity picker) e `ManualReservationDialog` (calendário de range com dias indisponíveis)
- [x] Atualizar `my_rooms_page.dart` (remover mock, consumir notifier, busca/filtro, estados, navegação para add/edit room)
- [ ] Validar fluxos: listagem, delete parcial/total, reserva manual, disponibilidade agregada, busca e filtro

---

## Fase P5-A — Add Room Page [PENDENTE]

> Plan: `plans/add-room-page.plan.md`
> Spec: `specs/add-room-page.spec.md`
> PRD: `features/add-room-page.prd.md`

- [ ] Criar `CatalogoItemModel`
- [ ] Criar `AddRoomState` + `AddRoomNotifier` com `loadCatalogo()` e `submit()` (fluxo encadeado: categoria → itens → quartos → fotos)
- [ ] Converter `add_room_page.dart` para `ConsumerStatefulWidget`: multi-select de comodidades (chips), campo numérico de valor, stepper de capacidade, progresso de submit, reload `MyRoomsNotifier` ao sucesso

---

## Fase P5-B — Edit Room Page [PENDENTE]

> Plan: `plans/edit-room-page.plan.md`
> Spec: `specs/edit-room-page.spec.md`
> PRD: `features/edit-room-page.prd.md`

- [ ] Criar `FotoExistente` model
- [ ] Criar `EditRoomState` + `EditRoomNotifier` com `load()` (carrega quarto, categoria, fotos, catálogo) e `save()` (fluxo encadeado: PATCH categoria → diff comodidades → PATCH quarto → DELETE fotos → POST fotos)
- [ ] Converter `edit_room_page.dart` para `ConsumerStatefulWidget`: pré-popular campos, seção de comodidades com chips, gestão real de fotos (carregar/remover/adicionar), progresso de save, reload `MyRoomsNotifier` ao sucesso, remover campos "Camas" e "Banheiros"

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

## Fase 5 — Chatbot IA (RAG + Intenção) [EM VALIDAÇÃO]

> Spec: `specs/chatbot-ia.spec.md`

- [x] Configurar LangChain + Gemini Flash
- [x] Implementar resolucao de hotel na conversa e enriquecer `sessao_chat.hotel_id` antes do RAG hotel-scoped
- [x] Consultar dados canonicos no banco relacional (preco, disponibilidade, reserva)
- [x] Criar estrutura de documentos do hotel com embeddings em `pgvector`
- [x] Criar script de ingestao e reindexacao de documentos do hotel
- [x] Implementar `RagService` com busca vetorial por hotel
- [x] Implementar classificador de intencao (duvida / reserva / roteiro)
- [x] Integrar o fluxo RAG ao webhook do WhatsApp
- [x] Substituir a resposta provisoria pelo fluxo de IA
- [x] Garantir persistencia das respostas do bot no historico

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

> Spec: `specs/notifications-system.spec.md`
> Plan detalhado: `plans/notifications-system.plan.md`

- [ ] Setup Firebase (firebase_messaging, firebase_core, flutterfire configure, service worker web)
- [ ] Criar `FcmTokenService` — registra/remove token por role via REST
- [ ] Criar `NotificationService` — inicializa FCM, solicita permissão, escuta mensagens
- [ ] Atualizar `app_notification.dart` — adicionar `tipo` e `payload`
- [ ] Atualizar `auth_notifier.dart` — registrar/remover token FCM no login/logout
- [ ] Atualizar `notifications_provider.dart` — estado real (host REST, hóspede SharedPreferences)
- [ ] Atualizar `custom_bottom_nav.dart` — badge de não lidas
- [ ] Atualizar `app_router.dart` — navegação por `tipo` + `payload`

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
