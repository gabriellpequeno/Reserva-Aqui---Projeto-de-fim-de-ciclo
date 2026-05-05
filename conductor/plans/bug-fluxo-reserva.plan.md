# Plan — Bug-Fix do Fluxo de Reserva

> Derivado de: `conductor/specs/bug-fluxo-reserva.spec.md`
> Task: `conductor/task/BUG-fluxo-reserva.md`
> Branch: `res-68-bugfix-fluxo-reserva`
> Status geral: [PENDENTE]

---

## Resumo da estratégia

Ordem deliberada: **backend primeiro** (schema → services → rotas → jobs), **depois frontend** (form unificado → widgets → fluxo checkout → disponibilidade obrigatória → notificações), **depois smoke-test manual dos 4 fluxos**.

Cada item é uma unidade de 1–4h e fecha num commit. Tasks marcadas com `⚠` exigem teste manual antes do commit. Tasks com `🔗` têm dependência em outra.

---

## Fase 0 — Preparação [CONCLUÍDA]

- [x] Criar branch `res-69-bug-fluxo-de-reserva-user-guest-whatsapp-hotel` a partir de `main`
- [x] Adicionar ao `Backend/.env` (com valores de dev): SMTP + rate-limit (`FRONTEND_URL` já existia)
- [x] Documentar em `Backend/.env.example` as novas chaves

---

## Fase 1 — Backend: Schema e Migrations [CONCLUÍDA]

- [x] Criar função `_ensureReservaFluxoColumns(client)` idempotente com email_hospede + expires_at + índice
- [x] Invocar em `_createReservaUsuario`, `_createReservaWalkin` e em todos os `withTenant` de `pagamentoReserva.service.ts`
- [x] Atualizar `Reserva.ts` (APP_GUEST em CanalOrigem, email_hospede, CreateReservaGuestInput, campos opcionais em CreateReservaUsuarioInput) e `PagamentoReserva.ts` (FormaPagamento, CanalPagamento, CANCELADO, expires_at)
- [x] Typecheck limpo (`tsc --noEmit`)

---

## Fase 2 — Backend: Email Service [CONCLUÍDA]

- [x] Instalado `nodemailer` + `@types/nodemailer`
- [x] `email.service.ts` criado: singleton com lazy init, fire-and-forget, no-op silencioso quando `SMTP_HOST` vazio
- [x] `emailTemplates.ts` com 3 templates (pendente/confirmada/expirada), HTML inline
- [x] Script `testEmail.ts` para validação manual do SMTP

---

## Fase 3 — Backend: Rate-Limit Middleware [CONCLUÍDA]

- [x] `express-rate-limit` já presente em `package.json`
- [x] Adicionados `guestReservaLimiter` (5/min) e `pagamentoPublicLimiter` (10/min, skip GET) em `rateLimiter.ts`

---

## Fase 4 — Backend: Reserva Guest [CONCLUÍDA]

- [x] `Reserva.validateGuest` com CPF dígito verificador + email + telefone + nome completo
- [x] `createReservaGuest` no service (disponibilidade em transação, INSERT `APP_GUEST`, routing público, NOVA_RESERVA sem historico global)
- [x] `createReservaGuestController` no controller
- [x] Rota `POST /api/reservas/guest` com `guestReservaLimiter` + `requireFields` (montada em `publicReservaRouter`, já registrada em `app.ts`)

---

## Fase 5 — Backend: Modificar Reserva Usuário (reserva-pra-terceiro) [CONCLUÍDA]

- [x] `validateUsuario` aceita os 4 campos de hóspede (regra: todos ou nenhum)
- [x] INSERT em `_createReservaUsuario` grava os 4 campos quando presentes

---

## Fase 6 — Backend: Endpoint /usuarios/me [CONCLUÍDA]

- [x] Endpoint `GET /api/usuarios/me` já existe e já retorna nome_completo, email, cpf, numero_celular — nada a fazer

---

## Fase 7 — Backend: Refatoração _aplicarAprovacao [CONCLUÍDA]

- [x] Extraído `_aplicarAprovacao(hotelId, nomeHotel, reserva, formaPagamento, opts)` de `_handleWebhook`
- [x] Inclui todos os efeitos colaterais: histórico global, FCM hotel+user, notificação inbox, WhatsApp confirmation, email `reservaConfirmadaTemplate`
- [x] `_handleWebhook` agora faz só as UPDATEs dentro da transação e chama `_aplicarAprovacao` após commit
- [x] Typecheck limpo

---

## Fase 8 — Backend: Pagamento Fake Endpoints [CONCLUÍDA]

- [ ] `pagamentoReserva.service.ts` — adicionar 4 funções:
  - `createPagamentoFake({codigoPublico, canal})`:
    - Resolve `hotel_id` + `reserva_id` via `reserva_routing` (igual webhook faz em `:293-305`)
    - Dentro de `withTenant`: verifica `status IN ('SOLICITADA','AGUARDANDO_PAGAMENTO')`
    - Verifica ausência de pagamento `PENDENTE` (409 se houver)
    - INSERT em `pagamento_reserva` com `status='PENDENTE'`, `expires_at = canal==='WHATSAPP' ? NOW()+30min : NULL`
    - UPDATE reserva para `AGUARDANDO_PAGAMENTO`
    - Retorna `{pagamento_id, status, modalidades: ['PIX','CARTAO_CREDITO','CARTAO_DEBITO'], valor_total, expires_at}`
  - `getPagamentoPublic({codigoPublico, pagamentoId})`:
    - Retorna `{status, expires_at, valor_total}` (usado pelo polling do timer WPP)
  - `confirmarPagamentoFake({codigoPublico, pagamentoId, formaPagamento})`:
    - Dentro de `withTenant`: valida existência + `status='PENDENTE'` + `expires_at > NOW() OR NULL`
    - Chama `_aplicarAprovacao(client, hotelId, ..., formaPagamento)`
    - Retorna `{pagamento_id, status:'APROVADO'}`
    - Se expirado → 410; se já processado → 409
  - `cancelarPagamentoFake({codigoPublico, pagamentoId})`:
    - UPDATE pagamento `CANCELADO`, reserva `CANCELADA`
    - FCM `RESERVA_CANCELADA` para hotel + email `reservaCancelada` (usar template novo ou reaproveitar `reservaExpiradaTemplate`)
- [ ] `pagamentoReserva.controller.ts` — 4 controllers públicos (sem `hotelGuard`)
- [ ] `pagamentoReserva.routes.ts` — novo `publicPagamentoRouter`:
  ```ts
  publicPagamentoRouter.post('/',         pagamentoPublicLimiter, createPagamentoPublicoController);
  publicPagamentoRouter.get('/:id',       pagamentoPublicLimiter, getPagamentoPublicoController);
  publicPagamentoRouter.post('/:id/confirmar', pagamentoPublicLimiter, requireFields('forma_pagamento'), confirmarPagamentoController);
  publicPagamentoRouter.post('/:id/cancelar',  pagamentoPublicLimiter, cancelarPagamentoController);
  ```
- [ ] `app.ts` — `app.use('/api/reservas/:codigo_publico/pagamentos', publicPagamentoRouter)`. **Router com `{mergeParams: true}`** para acessar `codigo_publico` do parent.
- [ ] ⚠ Postman: criar reserva guest → criar pagamento → confirmar → verificar reserva `APROVADA`, FCM hotel, email enviado

---

## Fase 9 — Backend: Job de Expiração [CONCLUÍDA]

- [ ] Criar `Backend/src/services/paymentExpiration.job.ts`:
  - `startPaymentExpirationJob()` com `setInterval(60_000, tick)`
  - `tick()`:
    - Query master: `SELECT codigo_publico, hotel_id, schema_name FROM reserva_routing r JOIN anfitriao a USING(hotel_id) WHERE EXISTS (...)` — buscar pagamentos PENDENTES expirados por schema
    - Para cada: `withTenant(schema, async (client) => cancelarPagamentoFake + email reservaExpirada)`
    - Log `console.log('[expire] X pagamentos expirados')`
    - Try/catch global, nunca propaga erro
- [ ] `app.ts` — chamar `startPaymentExpirationJob()` no bootstrap (após DB connect)
- [ ] ⚠ Teste: criar pagamento com `expires_at = NOW() - 1min` manualmente; rodar job; confirmar reserva CANCELADA

---

## Fase 10 — Backend: WhatsApp [CONCLUÍDA]

- [ ] `whatsappReservation.service.ts` — após criar reserva via WPP (função que já existe):
  - Chamar `createPagamentoFake({codigoPublico, canal:'WHATSAPP'})`
  - Enviar WPP: `"Seu link de pagamento: {FRONTEND_URL}/pagamento/{codigoPublico}/{pagamentoId} — expira em 30 minutos."`
  - Enviar email `reservaPendentePagamentoTemplate` (se `email_hospede` disponível)
- [ ] `sendApprovedReservationConfirmation` (já existe, chamada em `_aplicarAprovacao`) — garantir que envia WPP **e** email `reservaConfirmadaTemplate` com link `/reservas/:codigoPublico`
- [ ] ⚠ Teste: simular mensagem WPP de reserva → verificar envio do link de pagamento

---

## Fase 11 — Frontend: Dependências e Validators [CONCLUÍDA]

- [ ] Confirmar `mask_text_input_formatter` em `Frontend/pubspec.yaml`; se ausente, `flutter pub add mask_text_input_formatter`
- [ ] Criar `Frontend/lib/features/auth/utils/validators.dart` extraindo de `user_signup_page.dart`:
  - `String? validateEmail(String? v)`
  - `String? validateCpf(String? v)` — valida os 11 dígitos + dígito verificador (aceita máscara ou limpo)
  - `String? validateTelefoneBr(String? v)`
  - `String? validateNomeCompleto(String? v)` — mínimo 2 palavras com 2+ chars
- [ ] Atualizar `user_signup_page.dart` para importar os validators do novo arquivo
- [ ] ⚠ Rodar `flutter test` para confirmar que nenhum test do signup quebrou

---

## Fase 12 — Frontend: HospedeInfoForm Widget [CONCLUÍDA]

- [ ] Criar `Frontend/lib/features/booking/presentation/widgets/hospede_info_form.dart`
- [ ] `HospedeInfoForm extends StatefulWidget` recebe:
  - `HospedeInfoFormData? initialData` (para pré-preenchimento user autenticado)
  - `VoidCallback? onChanged` (avisa parent sobre mudanças)
- [ ] Expõe via `GlobalKey<HospedeInfoFormState>`:
  - `bool validate()` — chama `_formKey.currentState!.validate()`
  - `HospedeInfoFormData getData()` — retorna dados despmascarados
  - `bool hasDiverged(HospedeInfoFormData original)` — true se algum campo mudou
- [ ] UI: 4 `TextFormField` em Column com padding padrão do app
  - Nome: capitalize words
  - Email: `keyboardType: emailAddress`
  - CPF: máscara `###.###.###-##`
  - Telefone: máscara `(##) #####-####`
- [ ] Se `initialData != null` e user autenticado mas editou algo → mostrar chip sutil "Reservando para outra pessoa" acima do form

---

## Fase 13 — Frontend: BookingService métodos novos [CONCLUÍDA]

- [ ] `Frontend/lib/features/booking/data/services/booking_service.dart` — adicionar:
  - `Future<void> createReservaGuest({...todos os campos...})` — POST `/reservas/guest`
  - `Future<PagamentoFakeModel> createPagamento(String codigoPublico, String canal)` — POST `/reservas/:cp/pagamentos`
  - `Future<PagamentoFakeModel> fetchPagamento(String codigoPublico, int pagamentoId)` — GET
  - `Future<void> confirmarPagamento(String codigoPublico, int pagamentoId, PaymentMethod metodo)` — POST `/confirmar`
  - `Future<void> cancelarPagamento(String codigoPublico, int pagamentoId)` — POST `/cancelar`
- [ ] Modificar `createReserva` existente para aceitar campos opcionais de hóspede
- [ ] Criar `Frontend/lib/features/booking/domain/models/pagamento_fake_model.dart` com `{id, status, modalidades, valorTotal, expiresAt?}`

---

## Fase 14 — Frontend: UsuarioService.getMe [CONCLUÍDA]

- [x] `Usuario.dart:getAutenticado` já consome `/usuarios/me` — será usado direto pelo CheckoutNotifier

---

## Fase 15 — Frontend: PaymentBottomSheet [CONCLUÍDA]

- [ ] Criar `Frontend/lib/features/booking/presentation/widgets/payment_bottom_sheet.dart`
- [ ] `Future<PaymentSheetResult> showPaymentBottomSheet(BuildContext, {required resumo, required onPay, required onCancel})`
  - `showModalBottomSheet(context, isScrollControlled: true, isDismissible: false, enableDrag: false, builder: ...)`
  - Layout:
    - Handle (decorativo)
    - Resumo (hotel, datas, total)
    - 3 `RadioListTile<PaymentMethod>` (PIX, Cartão crédito, Cartão débito)
    - Botão "Pagar" primary cheio (disabled até escolher modalidade)
    - Botão "Cancelar" outlined
  - `WillPopScope`/`PopScope` bloqueando botão back — apenas os 2 botões fecham
- [ ] Enum `PaymentSheetResult { paid, cancelled }` (sem `dismissed`)

---

## Fase 16 — Frontend: CheckoutNotifier + CheckoutPage refactor [CONCLUÍDA]

- [ ] `checkout_notifier.dart`:
  - `CheckoutState`: adicionar `initialCheckin`, `initialCheckout`, `initialHospedeData`, `isAuthenticated`, `codigoPublicoReserva`, `pagamentoId`, `disponivel`, `isCheckingDisponibilidade`
  - `loadData(...)`: carregar categoria + quarto + config + **disponibilidade** (se datas presentes) + **dados do user autenticado** via `Future.wait`. Se auth, montar `HospedeInfoFormData` a partir de `getMe()`.
  - Nova função `verificarDisponibilidade(hotelId, categoriaId, checkin, checkout)`: chama GET disponibilidade e atualiza `state.disponivel`
  - `confirm(...)` nova assinatura aceitando `hospedeData: HospedeInfoFormData, isAuthenticated: bool`:
    - Valida disponibilidade na última hora (re-fetch)
    - Chama `createReserva` ou `createReservaGuest` dependendo de `isAuthenticated`
    - Chama `createPagamento(codigoPublico, 'APP')` → grava `pagamentoId`
    - **Retorna** `Future<ReservaCreatedResult>` com `codigoPublico` e `pagamentoId` (em vez de setar `reservaCreated=true` e deixar page redirecionar)
  - Novas funções `confirmarPagamento(metodo)` e `cancelarPagamento()` chamando o service
- [ ] `checkout_page.dart`:
  - Construtor aceita `initialCheckin` e `initialCheckout`
  - `initState`: chama `loadData(hotelId, categoriaId, quartoId, initialCheckin, initialCheckout)`
  - Se `state.initialCheckin != null`, campos de data ficam disabled com hint "Alterar na tela anterior"
  - **Sempre** renderiza `HospedeInfoForm(initialData: state.initialHospedeData)`
  - **Botão "Finalizar Reserva" é disabled** se:
    - datas não escolhidas OU
    - form não validado OU
    - `state.disponivel == false` OU
    - `state.isCheckingDisponibilidade == true`
  - Quando `disponivel == false`: mostrar banner vermelho "Quarto indisponível nessas datas" acima do botão
  - `_onConfirm` novo fluxo:
    1. `formKey.currentState!.validate()`
    2. `final result = await notifier.confirm(...)` (retorna `ReservaCreatedResult`)
    3. `final paymentResult = await showPaymentBottomSheet(context, onPay: (metodo) => notifier.confirmarPagamento(metodo), onCancel: () => notifier.cancelarPagamento())`
    4. Se `paid` e `isAuthenticated`: `ticketsNotifier.reload(); context.go('/tickets')`
    5. Se `paid` e `!isAuthenticated`: `context.go('/booking/success?codigo=${result.codigoPublico}&mode=guest')`
    6. Se `cancelled`: `context.pop()` + SnackBar
  - **Remover** o `ref.listen` atual em `checkout_page.dart:45-50` que redireciona a `/tickets`
- [ ] ⚠ Smoke-test manual: user autenticado, guest, e ambos com reserva pra terceiro

---

## Fase 17 — Frontend: Rota com queryParams e propagação de datas [CONCLUÍDA]

- [ ] `Frontend/lib/core/router/app_router.dart:209` — modificar rota de checkout para ler `checkin`/`checkout` de `state.uri.queryParameters` e passar ao `CheckoutPage`
- [ ] `Frontend/lib/features/rooms/presentation/widgets/availability_checker.dart` — ao clicar "Reservar" (botão que hoje não navega), adicionar navegação:
  ```dart
  context.push(
    '/booking/checkout/$hotelId/$categoriaId/$quartoId'
    '?checkin=${_fmt(_checkInDate!)}&checkout=${_fmt(_checkOutDate!)}',
  );
  ```
- [ ] `Frontend/lib/features/rooms/presentation/pages/room_details_page.dart:495` — se o state do `room_details_notifier` tiver datas (verificar; caso não, manter comportamento atual sem queryParams)
- [ ] ⚠ Testar: (a) fluxo `availability_checker → reservar` abre checkout com datas travadas; (b) fluxo legado sem queryParam ainda funciona com picker

---

## Fase 18 — Frontend: Rotas Novas (públicas) [CONCLUÍDA]

- [ ] `app_router.dart` — adicionar **fora do `ShellRoute`** e **fora** de `protectedRoutes`:
  - `GoRoute(path: '/reservas/:codigoPublico', builder: (_, s) => PublicTicketPage(codigoPublico: ...))`
  - `GoRoute(path: '/pagamento/:codigoPublico/:pagamentoId', builder: (_, s) => WhatsappPaymentPage(...))`
  - `GoRoute(path: '/booking/success', builder: (_, s) => ReservationSuccessPage(codigoPublico: queryParam, mode: queryParam))`
- [ ] Criar `Frontend/lib/features/booking/presentation/pages/public_ticket_page.dart`
  - `ConsumerStatefulWidget`, consome `GET /api/reservas/:codigo_publico`
  - Layout somente-leitura: resumo + status + codigoPublico em destaque + botão "Compartilhar"
  - Scaffold próprio (sem MainLayout/bottom nav)
- [ ] Criar `Frontend/lib/features/booking/presentation/pages/reservation_success_page.dart`
  - Recebe `codigoPublico`, `mode: 'user'|'guest'`
  - User: "Reserva confirmada! Veja seus tickets" + botão `/tickets`
  - Guest: "Reserva confirmada! Enviamos o ticket para seu email" + botão "Copiar link" (usa `url_launcher` clipboard ou `Clipboard.setData`) + botão "Ver ticket" para `/reservas/:codigoPublico`
- [ ] Criar `Frontend/lib/features/booking/presentation/pages/whatsapp_payment_page.dart`
  - `ConsumerStatefulWidget` com polling de 5s em `fetchPagamento`
  - Timer regressivo baseado em `expires_at - DateTime.now()` (recalculado a cada tick do polling)
  - Layout: resumo + radios de modalidade + botão "Pagar" (sem Cancelar)
  - Estados: `PENDENTE` (mostra radios + botão), `APROVADO` (overlay "Pagamento confirmado"), `CANCELADO/expirado` (overlay "Link expirado")

---

## Fase 19 — Frontend: Correção notificações hotel [CONCLUÍDA]

- [ ] `notifications_page.dart:228` — `case 'NOVA_RESERVA'` → `context.push('/tickets/details/$codigoPublico')` (requer `codigoPublico` no payload, já existe)
- [ ] `notification_service.dart:129` — mesmo ajuste no handler de tap de push FCM
- [ ] ⚠ Smoke-test: reservar via user/guest → confirmar que hotel recebe push → tap abre detalhes (não a lista)

---

## Fase 20 — Smoke Tests Manuais [PENDENTE]

Executar os 4 fluxos ponta-a-ponta com backend e app rodando localmente:

- [ ] **Fluxo A (user autenticado, pra si mesmo):**
  - Login → verificar disponibilidade → reservar → form pré-preenchido → não editar → finalizar → sheet → pagar PIX → `/tickets` com reserva `APROVADA` → push chegou no hotel
- [ ] **Fluxo A' (user autenticado, pra terceiro):**
  - Login → reservar → editar os 4 campos → finalizar → confirmar que aparece chip "Reservando para outra pessoa" → sheet → pagar → reserva no `/tickets` vinculada ao user, mas com `nome_hospede` diferente
- [ ] **Fluxo B (guest):**
  - Sem login → reservar → form vazio → preencher 4 campos → finalizar → sheet → pagar → `/booking/success` → email chegou → link do email abre `PublicTicketPage`
- [ ] **Fluxo B cancelado:**
  - Guest → finalizar → sheet → Cancelar → SnackBar → volta pra detalhes do quarto → reserva `CANCELADA` no banco
- [ ] **Fluxo B indisponibilidade:**
  - Guest → reserva 1 criada e APROVADA → outro guest tenta mesmas datas → banner "indisponível" aparece; botão finalizar disabled
- [ ] **Fluxo C (hotel):**
  - Hotel recebe push → tap → `/tickets/details/:codigoPublico`
- [ ] **Fluxo D (WhatsApp):**
  - Simular mensagem WPP que cria reserva → guest recebe link via WPP + email → abrir `/pagamento/:cp/:pid` no navegador → timer contando → pagar → recebe ticket via WPP + email
- [ ] **Fluxo D expiração:**
  - Criar pagamento WPP → aguardar 30 min (ou manipular `expires_at` no banco) → confirmar CANCELADA + email `reservaExpirada`

---

## Fase 21 — Limpeza (sem PR) [PARCIAL]

- [x] `npx tsc --noEmit` no backend — typecheck limpo
- [x] `flutter analyze` nos arquivos modificados — sem novos warnings (só deprecations pré-existentes de `Radio` e infos em `my_rooms_notifier.dart` / `manual_reservation_dialog.dart`, tudo fora do escopo desta task)
- [x] `.env.example` atualizado na Fase 0
- [ ] `Backend/swagger.yaml` com os 5 novos endpoints (deixado para instruções do usuário)
- [ ] Smoke-test manual — aguardando ambiente (usuário direciona)
- [ ] Abertura de PR — **não solicitar; instruções específicas do usuário**

---

## Matriz de dependências entre fases

```
0 → 1 → 2 → 3 → 4 ─┬→ 7 → 8 → 9 → 10
          └→ 5 ────┤
               6 ──┘
                   (todas as fases backend concluídas)
                    │
                    ▼
                   11 → 12 → 13 → 14 → 15 → 16 → 17 → 18 → 19 → 20 → 21
```

**Paralelização possível:**
- Fases 4, 5, 6 (backend) são independentes — podem ser 3 PRs separados ou 3 branches feature que mergeiam em `res-68`
- Fases 12, 15, 18 (frontend widgets/pages) são independentes entre si; só precisam das fases 11 (validators) e 13 (service)

---

## Critérios de "pronto pra mergear"

- [ ] Todos os 8 smoke-tests da Fase 20 passam
- [ ] Nenhum teste automatizado quebrado
- [ ] Nenhum `TODO` ou `FIXME` novo não resolvido
- [ ] Swagger atualizado
- [ ] Sem credenciais no código (tudo em `.env`)
- [ ] Logs de `console.log` de debug removidos; apenas `console.warn` em erros operacionais
