# Diagnóstico — Bug-Fix do Fluxo de Reserva

> Branch: `res-69-bug-fluxo-de-reserva-user-guest-whatsapp-hotel`
> Task: `conductor/task/BUG-fluxo-reserva.md`
> Spec: `conductor/specs/bug-fluxo-reserva.spec.md`
> Plan: `conductor/plans/bug-fluxo-reserva.plan.md`

## Sumário

Refatoração do fluxo de reserva para corrigir 5 bugs identificados:

1. **User autenticado** não via tela de pagamento — ia direto pra `/tickets`
2. **Guest (não autenticado)** era barrado pelo JWT no checkout
3. **Hotel** recebia notificação `NOVA_RESERVA` mas era levado para lista, não para os detalhes
4. **WhatsApp** não enviava link de pagamento + ticket por email
5. **Datas** do availability_checker não fluíam para a tela de checkout

### Métricas gerais (após todas as iterações)
- **31 arquivos modificados**, **12 arquivos criados**
- **+2.101 / -502 linhas** alteradas (sem contar novos)
- Backend: **16 arquivos** (incluindo 4 novos: email.service, emailTemplates, paymentExpiration.job, testEmail script)
- Frontend: **20 arquivos** (incluindo 8 novos: validators, hospede_info, pagamento_fake_model, hospede_info_form, payment_bottom_sheet, 3 páginas públicas + approval_bottom_sheet)
- 4 documentos de governança: task / spec / plan / diagnóstico

### Estado da qualidade
- `npx tsc --noEmit` backend: **limpo**
- `flutter analyze` nos arquivos novos: **limpo** (só 2 deprecations legacy do `Radio` no PaymentBottomSheet, preexistentes em `ticket_card.dart`)
- `npm test`: **5 falhas preexistentes** (já falhavam em `main` antes desta task — `whatsappWebhook.service.test.ts`)

---

## 1. Arquivos Criados

### Backend (4)

| Arquivo | Responsabilidade | Afeta o quê |
|---------|------------------|-------------|
| `Backend/src/services/email.service.ts` | Transporter Nodemailer + `sendEmail({to, subject, html})`. Singleton lazy-init. No-op silencioso se `SMTP_HOST` vazio. Fire-and-forget — erros logam mas nunca propagam. | **Webhook InfinitePay** (envia email de confirmação), **endpoints fake de pagamento** (idem), **job de expiração** (envia email `reservaExpiradaTemplate`), **WhatsApp bot** (envia email `reservaPendentePagamentoTemplate`). |
| `Backend/src/services/emailTemplates.ts` | 3 templates HTML inline-CSS: `reservaPendentePagamentoTemplate`, `reservaConfirmadaTemplate`, `reservaExpiradaTemplate`. | Usado por `email.service.ts`. Conteúdo visual renderizado no inbox do hóspede. |
| `Backend/src/services/paymentExpiration.job.ts` | `setInterval(60s)` que varre todos os tenants ativos e cancela pagamentos `PENDENTE` com `expires_at < NOW()`. Cancela reserva associada, notifica hotel por FCM + inbox e envia email ao hóspede. | **Inicia automaticamente** com `app.listen` em `src/app.ts`. Processo roda em background enquanto o backend estiver vivo. Não precisa cron externo. |
| `Backend/src/scripts/testEmail.ts` | Script manual `npx ts-node src/scripts/testEmail.ts <email>` — envia os 3 templates para validar configuração SMTP em dev. | Utilidade de diagnóstico, nunca chamado pela aplicação. |

### Frontend (7)

| Arquivo | Responsabilidade | Afeta o quê |
|---------|------------------|-------------|
| `Frontend/lib/features/auth/utils/validators.dart` | Validators compartilhados: `validateNomeCompleto`, `validateEmail`, `validateCpf` (com dígito verificador real), `validateTelefoneBr`, `onlyDigits`. | Usado por **`user_signup_page.dart`** e **`HospedeInfoForm`**. Substitui validações inline que eram divergentes entre telas. |
| `Frontend/lib/features/booking/domain/models/hospede_info.dart` | Model `HospedeInfoFormData` (nome, email, cpf, telefone despmascarados) + método `hasDivergedFrom()` para detectar edição no pré-preenchimento. | Usado pela `CheckoutPage`, `CheckoutNotifier` e `BookingService`. |
| `Frontend/lib/features/booking/domain/models/pagamento_fake_model.dart` | Model `PagamentoFakeModel` + enum `PaymentMethod {pix, cartaoCredito, cartaoDebito}` com extensão `apiValue`/`label`. | Usado por `BookingService`, `CheckoutNotifier`, `PaymentBottomSheet` e `WhatsappPaymentPage`. |
| `Frontend/lib/features/booking/presentation/widgets/hospede_info_form.dart` | Formulário unificado user+guest com pré-preenchimento via `initialData`. Expõe `validate()`, `getData()`, `hasDiverged` via `HospedeInfoFormState`. Chip "Reservando para outra pessoa" quando user autenticado edita o pré-preenchimento. | Embutido na `CheckoutPage`. |
| `Frontend/lib/features/booking/presentation/widgets/payment_bottom_sheet.dart` | `showModalBottomSheet` não-dismissível (`isDismissible: false`, `PopScope canPop: false`). 3 radios PIX/CC/CD + 2 botões (Pagar/Cancelar). Retorna `PaymentSheetResult.paid | cancelled`. | Aberto pela `CheckoutPage` após criar reserva + pagamento. |
| `Frontend/lib/features/booking/presentation/pages/reservation_success_page.dart` | Rota `/booking/success?codigo=&mode=`. Variantes user/guest — mostra código da reserva com botão copiar; guest é direcionado para `/reservas/:codigo`, user para `/tickets`. | Destino pós-pagamento do guest (não pode ir pra `/tickets` que é protegida). |
| `Frontend/lib/features/booking/presentation/pages/public_ticket_page.dart` | Rota pública `/reservas/:codigoPublico`. Consome `GET /api/reservas/:codigo_publico` (já existente). Layout somente-leitura, standalone (fora do `ShellRoute`). | Acessada via link de email enviado ao guest. Não exige login. |
| `Frontend/lib/features/booking/presentation/pages/whatsapp_payment_page.dart` | Rota pública `/pagamento/:codigoPublico/:pagamentoId`. Polling de status a cada 10s + timer regressivo baseado em `expires_at` do servidor. Sem botão Cancelar — só o timer resolve. Estados: pendente (com radios), aprovado (overlay verde), expirado (overlay cinza). | Acessada via link enviado por WhatsApp ou email ao guest que reservou pelo bot. |

### Governança (4)

| Arquivo | Conteúdo |
|---------|---------|
| `conductor/task/BUG-fluxo-reserva.md` | Task: 5 bugs, critérios de aceitação, endpoints |
| `conductor/specs/bug-fluxo-reserva.spec.md` | Spec: componentes afetados, decisões, contratos, fluxos detalhados |
| `conductor/plans/bug-fluxo-reserva.plan.md` | Plano: 21 fases com status (19 concluídas, 2 de fechamento) |
| `conductor/diagnostics/bug-fluxo-reserva.diagnostic.md` | Este documento |

---

## 2. Arquivos Modificados

### Backend (10)

#### 2.1. `Backend/.env.example` — config
**O que mudou:** bloco SMTP (`SMTP_HOST/PORT/USER/PASS/FROM`) e bloco rate-limit (`RATE_LIMIT_WINDOW_MS`, `RATE_LIMIT_GUEST_RESERVA_MAX`, `RATE_LIMIT_PAGAMENTO_MAX`).
**Afeta:** documentação das variáveis. Aplicação **não quebra** sem SMTP — serviço de email vira no-op e loga warn.

#### 2.2. `Backend/package.json` — deps
**O que mudou:** adicionadas `nodemailer` + `@types/nodemailer`.
**Afeta:** instalação (`npm install`) precisa rodar antes de subir backend.

#### 2.3. `Backend/src/app.ts` — bootstrap
**O que mudou:**
- Import de `publicPagamentoRouter` e `startPaymentExpirationJob`.
- Monta rota `app.use(`${API_PREFIX}/reservas/:codigo_publico/pagamentos`, publicPagamentoRouter)`.
- `startPaymentExpirationJob()` chamado dentro do `if (require.main === module)`.

**Afeta:**
- **Novos endpoints públicos** ficam disponíveis em `/api/v1/reservas/:codigo_publico/pagamentos/*`.
- **Job de expiração** só roda quando backend é executado como processo principal (não em testes).

#### 2.4. `Backend/src/middlewares/rateLimiter.ts` — rate-limit
**O que mudou:**
- Helper `intEnv()` extraído.
- Novos exports: `guestReservaLimiter` (5 req/min) e `pagamentoPublicLimiter` (10 req/min, `skip: req => req.method === 'GET'`).

**Afeta:** aplicado em `POST /api/v1/reservas/guest` e nos 4 endpoints públicos de pagamento. GETs são isentos do limite (permite polling de 10s do WhatsappPaymentPage).

#### 2.5. `Backend/src/entities/Reserva.ts` — validação + tipos
**O que mudou:**
- `CanalOrigem` agora inclui `'APP_GUEST'`.
- `CreateReservaUsuarioInput` ganhou 4 campos opcionais de hóspede.
- Nova interface `CreateReservaGuestInput` (4 campos obrigatórios).
- `ReservaSafe` ganhou `email_hospede: string | null`.
- 4 validators privados novos: `validateEmail`, `validateCpf` (com dígito verificador), `validateTelefone`, `validateNomeCompleto`.
- `validateUsuario` estendida: regra "todos ou nenhum" nos 4 campos de hóspede — 400 se vierem parciais.
- Novo `validateGuest` pra endpoint público.

**Afeta:**
- `POST /api/v1/usuarios/reservas` passa a aceitar reserva pra terceiro (retrocompatível — omitindo os 4 campos, comportamento antigo).
- `POST /api/v1/reservas/guest` usa a validação nova.

#### 2.6. `Backend/src/entities/PagamentoReserva.ts` — tipos
**O que mudou:**
- `PagamentoStatus` agora inclui `'CANCELADO'`.
- Novos exports `FormaPagamento` (`PIX | CARTAO_CREDITO | CARTAO_DEBITO`) e `CanalPagamento` (`APP | WHATSAPP`).
- `PagamentoReservaSafe` ganhou `expires_at: string | null`.

**Afeta:** tipagem consistente em todo o backend. Statuses consumidos por webhook InfinitePay e endpoints fake.

#### 2.7. `Backend/src/services/reserva.service.ts` — núcleo da reserva
**O que mudou:**
- Novo export privado `_ensureReservaFluxoColumns(client)` — função idempotente que adiciona `reserva.email_hospede`, `pagamento_reserva.expires_at` e índice parcial `idx_pagamento_expires`. Chamada no topo de todas as funções de criação.
- Novo export `createReservaGuest` + função privada `_createReservaGuest`:
  - Valida com `Reserva.validateGuest`
  - Verifica disponibilidade no tenant (mesmo `EXISTS` usado em `_createReservaUsuario`)
  - INSERT com `canal_origem = 'APP_GUEST'`, `user_id = NULL`, 4 campos do hóspede
  - Upsert em `reserva_routing` (master)
  - Dispara FCM + inbox `NOVA_RESERVA` ao hotel
  - **Não** insere em `historico_reserva_global` (guest não tem `user_id`)
- `_createReservaUsuario` agora grava os 4 campos de hóspede quando presentes (reserva pra terceiro).

**Afeta:**
- Na primeira chamada de qualquer criação de reserva/pagamento por tenant, as 2 colunas e o índice são adicionados automaticamente — **migration idempotente, sem script manual**.
- Guest reserva via `/reservas/guest`; hotel recebe push imediato.
- User autenticado pode reservar pra terceiro — os campos do hóspede entram no INSERT.

#### 2.8. `Backend/src/services/pagamentoReserva.service.ts` — pagamento
**O que mudou:**
- Imports novos: `_ensureReservaFluxoColumns`, `sendEmail`, `reservaConfirmadaTemplate`, `FormaPagamento`.
- `_handleWebhook` refatorado — extraí `_aplicarAprovacao` (~130 linhas), que centraliza: marcar quarto indisponível, histórico global, FCM hotel+user, WhatsApp confirmação, email de confirmação. O webhook agora só faz UPDATE do pagamento/reserva dentro da transação e depois chama `_aplicarAprovacao`.
- Novos exports do fluxo fake: `createPagamentoFake`, `getPagamentoPublic`, `confirmarPagamentoFake`, `cancelarPagamentoFake`.
- Novo tipo `PagamentoFakeResumo` (`{pagamento_id, reserva_id, codigo_publico, status, valor_total, expires_at, modalidades}`).
- Helper `_resolveTenantByCodigoPublico` usado pelos 4 endpoints fake.
- `createPagamentoFake`:
  - Resolve tenant via `reserva_routing`
  - Se já há pagamento `PENDENTE` não-expirado, **reutiliza** (idempotente)
  - `expires_at = NOW() + 30min` quando `canal === 'WHATSAPP'`, null caso contrário
  - Avança reserva para `AGUARDANDO_PAGAMENTO`
- `confirmarPagamentoFake`:
  - Guarda contra race: `UPDATE ... WHERE status='PENDENTE'` + `expires_at > NOW()`
  - Chama `_aplicarAprovacao` — **mesmo fluxo do webhook InfinitePay real**
- `cancelarPagamentoFake`: UPDATE pagamento `CANCELADO` + reserva `CANCELADA` + FCM/inbox ao hotel.

**Afeta:**
- Webhook InfinitePay **continua funcionando** — só que agora delega os efeitos colaterais a `_aplicarAprovacao`, que é a mesma função chamada pelo fluxo fake.
- Confirmar pagamento fake tem **exatamente** os mesmos efeitos que um pagamento real aprovado (incluindo email, WhatsApp, FCM).

#### 2.9. `Backend/src/services/whatsappReservation.service.ts` — integração WhatsApp
**O que mudou:**
- Nova função `sendPaymentLinkViaWhatsApp({hotelId, reservaId})`:
  - Import dinâmico de `createPagamentoFake`, `sendEmail`, `reservaPendentePagamentoTemplate` (evita ciclo de imports)
  - Cria pagamento fake com `canal: 'WHATSAPP'` (`expires_at = NOW() + 30min`)
  - Se há sessão WPP com janela ativa, envia mensagem de texto com URL `{FRONTEND_URL}/pagamento/:cp/:pid`
  - Busca `email_hospede` ou `email` do user no banco; envia email `reservaPendentePagamentoTemplate` se houver
- Helper `getReservationEmailRow` para buscar emails (reserva + user autenticado).

**Afeta:** disparada pelo `tools.ts` do chatbot logo após o bot criar uma reserva via WhatsApp. Guest recebe link de pagamento nos 2 canais simultaneamente.

#### 2.10. `Backend/src/services/ai/tools.ts` — bot de reserva
**O que mudou:**
- Import de `sendPaymentLinkViaWhatsApp`.
- Após `COMMIT` da criação da reserva pelo bot, chama `sendPaymentLinkViaWhatsApp({hotelId, reservaId})` (fire-and-forget).
- Mensagem retornada ao LLM foi atualizada: "já enviamos o link de pagamento por este chat e por email. O link expira em 30 minutos."

**Afeta:** todo fluxo de reserva pelo chatbot WhatsApp — elimina a necessidade da aprovação manual prévia. O guest agora paga imediatamente e só aí vira `APROVADA`.

#### 2.11. `Backend/src/controllers/reserva.controller.ts`
**O que mudou:** novo `createReservaGuestController` (`POST /api/v1/reservas/guest`, sem auth).

#### 2.12. `Backend/src/controllers/pagamentoReserva.controller.ts`
**O que mudou:**
- `mapError` estendida com status 410 (link expirado) e novas mensagens.
- 4 controllers públicos novos: `createPagamentoPublicoController`, `getPagamentoPublicoController`, `confirmarPagamentoController`, `cancelarPagamentoController`.
- Helper `parsePagamentoId` + constante `FORMAS_VALIDAS`.

#### 2.13. `Backend/src/routes/reserva.routes.ts`
**O que mudou:** `publicReservaRouter.post('/guest', guestReservaLimiter, requireFields(...), createReservaGuestController)`.

#### 2.14. `Backend/src/routes/pagamentoReserva.routes.ts`
**O que mudou:** novo `publicPagamentoRouter` (`{mergeParams: true}`) com 4 rotas, todas com `pagamentoPublicLimiter`.

### Frontend (9)

#### 2.15. `Frontend/lib/core/router/app_router.dart`
**O que mudou:**
- Imports dos 3 novos pages.
- Rota `/booking/checkout/:hotelId/:categoriaId/:quartoId` agora **lê** `checkin` e `checkout` de queryParams e passa ao `CheckoutPage`.
- 3 rotas novas, **fora do ShellRoute** e **fora de `protectedRoutes`**:
  - `/reservas/:codigoPublico` → `PublicTicketPage`
  - `/pagamento/:codigoPublico/:pagamentoId` → `WhatsappPaymentPage`
  - `/booking/success?codigo=&mode=` → `ReservationSuccessPage`

**Afeta:** guests passam a ter 3 deep-links funcionais sem login.

#### 2.16. `Frontend/lib/features/booking/presentation/pages/checkout_page.dart` — reescrita completa
**O que mudou:**
- Construtor aceita `initialCheckin` e `initialCheckout`.
- `initState` preenche as datas locais e chama `loadData` com elas (dispara verificação de disponibilidade automática).
- Datas ficam **travadas** (read-only + hint) quando vindas via queryParam.
- **Sempre** renderiza `HospedeInfoForm` — pré-preenchido se autenticado, vazio se guest.
- Novo banner vermelho "Quarto indisponível nessas datas" quando `state.disponivel == false`.
- Indicador de loading "Verificando disponibilidade..." quando `state.isCheckingDisponibilidade`.
- Botão "Finalizar Reserva" disabled até: datas preenchidas + form válido + disponibilidade OK + não está submetendo.
- **Removido** o antigo `ref.listen` que redirecionava pra `/tickets`. Navegação agora é decidida pelo resultado do bottom sheet.
- `_onConfirm`:
  1. Valida `HospedeInfoForm`
  2. Chama `notifier.confirmarEGerarPagamento` (cria reserva + cria pagamento fake)
  3. Abre `showPaymentBottomSheet` com callbacks `onPay`/`onCancel`
  4. Em `paid`: user → `/tickets`; guest → `/booking/success?codigo=...&mode=guest`
  5. Em `cancelled`: `context.pop()` + SnackBar

#### 2.17. `Frontend/lib/features/booking/presentation/notifiers/checkout_notifier.dart` — reescrita
**O que mudou:**
- `CheckoutState` ganhou: `isCheckingDisponibilidade`, `pagamento`, `disponivel`, `initialCheckin`, `initialCheckout`, `initialHospedeData`, `isAuthenticated`.
- `loadData` carrega em paralelo: categoria + preço + políticas + **dados do user autenticado** via `getAutenticado`. Se auth, monta `HospedeInfoFormData` inicial. Ao final, se datas presentes, já verifica disponibilidade.
- Nova `verificarDisponibilidade`: chama `/disponibilidade`, filtra pela categoria, atualiza `state.disponivel`.
- Nova `confirmarEGerarPagamento`: valida capacidade/disponibilidade, cria reserva (user ou guest — decidido por `isAuthenticated`), cria pagamento fake. Se user editou os dados, passa como "reserva pra terceiro".
- Novas `confirmarPagamento(PaymentMethod)` e `cancelarPagamento()` para os callbacks do bottom sheet.

**Afeta:** todo o fluxo de reserva passa por esse notifier. Sem bugs, o user vê datas preenchidas automaticamente e o guest é detectado pelo `authProvider`.

#### 2.18. `Frontend/lib/features/booking/data/services/booking_service.dart`
**O que mudou:**
- Novo parâmetro `HospedeInfoFormData? hospede` em `createReserva` (envia 4 campos no body se presente).
- 6 métodos novos: `createReservaGuest`, `createPagamento`, `fetchPagamento`, `confirmarPagamento`, `cancelarPagamento`, `fetchReservaPublica`.

#### 2.19. `Frontend/lib/features/rooms/presentation/widgets/availability_checker.dart`
**O que mudou:**
- Novo callback `onDatesChanged(DateTime? ci, DateTime? co)` disparado a cada mudança de data.
- `_selectDate` agora reseta `_checkOutDate` se ele ficar antes/igual ao novo check-in (consistência).

**Afeta:** permite que a `RoomDetailsPage` capture as datas escolhidas pelo usuário antes de navegar para o checkout.

#### 2.20. `Frontend/lib/features/rooms/presentation/pages/room_details_page.dart`
**O que mudou:**
- Novos campos de estado `_checkInDate` e `_checkOutDate`.
- `AvailabilityChecker` agora recebe `onDatesChanged` que dispara `setState`.
- Botão "Reservar" monta a URL com queryParams `?checkin=&checkout=` quando ambas datas estão preenchidas.
- Novo helper `_fmtDateIso`.

**Afeta:** fluxo principal de navegação do app — clicar em "Reservar" agora leva direto ao checkout com disponibilidade já validada.

#### 2.21. `Frontend/lib/features/auth/presentation/pages/user_signup_page.dart`
**O que mudou:** importa `validators.dart` e substitui as 4 validações inline (nome, cpf, telefone, email) pelas funções compartilhadas.
**Afeta:** signup de usuário. Agora usa a **mesma validação de CPF com dígito verificador** que o checkout — antes era mais permissivo.

#### 2.22. `Frontend/lib/features/notifications/presentation/pages/notifications_page.dart`
**O que mudou:** `case 'NOVA_RESERVA'` agora navega para `/tickets/details/$codigoPublico` se disponível (fallback `/tickets`).
**Afeta:** UX do hotel — tap em notificação abre direto a tela de detalhes da nova reserva.

#### 2.23. `Frontend/lib/features/notifications/data/services/notification_service.dart`
**O que mudou:** mesmo ajuste do tap de push FCM (quando o hotel recebe push com o app em background).
**Afeta:** consistência entre tap in-app e tap de push.

---

## 3. Mudanças de Schema (migrations idempotentes)

Aplicadas **automaticamente** na primeira chamada de cada tenant. Não precisa rodar nada manualmente.

```sql
ALTER TABLE reserva
  ADD COLUMN email_hospede VARCHAR(255);   -- IF NOT EXISTS via DO block

ALTER TABLE pagamento_reserva
  ADD COLUMN expires_at TIMESTAMP NULL;    -- IF NOT EXISTS

CREATE INDEX IF NOT EXISTS idx_pagamento_expires
  ON pagamento_reserva(expires_at)
  WHERE status = 'PENDENTE' AND expires_at IS NOT NULL;
```

**Onde são aplicadas:** `_ensureReservaFluxoColumns(client)` é invocada no início de `_createReservaUsuario`, `_createReservaWalkin`, `_createReservaGuest` e todos os `withTenant` de `pagamentoReserva.service.ts`.

**Risco:** se um tenant nunca chamar nenhuma dessas funções, as colunas nunca aparecem — mas isso não quebra nada. Só começam a existir quando necessário.

---

## 4. Endpoints Afetados / Criados

### Criados (5)

| Método | Rota | Auth | Rate-limit | Descrição |
|--------|------|------|------------|-----------|
| POST   | `/api/v1/reservas/guest` | ❌ | 5/min/IP | Cria reserva sem JWT, validação completa dos 4 campos do hóspede |
| POST   | `/api/v1/reservas/:codigo_publico/pagamentos` | ❌ | 10/min/IP | Cria pagamento fake. Idempotente — reutiliza se já pendente |
| GET    | `/api/v1/reservas/:codigo_publico/pagamentos/:id` | ❌ | sem limit (GET) | Polling de status (usado pelo timer do WhatsappPaymentPage) |
| POST   | `/api/v1/reservas/:codigo_publico/pagamentos/:id/confirmar` | ❌ | 10/min/IP | Confirma pagamento fake. Chama `_aplicarAprovacao` |
| POST   | `/api/v1/reservas/:codigo_publico/pagamentos/:id/cancelar` | ❌ | 10/min/IP | Cancela pagamento + reserva. Notifica hotel |

### Modificados (1)

| Método | Rota | Mudança |
|--------|------|---------|
| POST   | `/api/v1/usuarios/reservas` | Agora aceita 4 campos opcionais de hóspede (reserva pra terceiro). Retrocompatível — se omitidos, comportamento antigo. Regra: ou todos ou nenhum |

### Inalterados mas relevantes

- `POST /api/v1/pagamentos/webhook/infinitepay` — webhook da InfinitePay continua funcionando; agora delega efeitos a `_aplicarAprovacao` (mesmo código do fluxo fake)
- `GET /api/v1/reservas/:codigo_publico` — já existia; agora é consumido pela `PublicTicketPage`
- `GET /api/v1/usuarios/me` — já existia; agora é consumido pelo `CheckoutNotifier.loadData` pra pré-preencher o form

---

## 5. Efeitos em Tempo de Execução

### Ao subir o backend (`app.listen`)
1. `startPaymentExpirationJob()` inicia um `setInterval(60s)` (unref para não bloquear shutdown).
2. A cada tick, varre todos os tenants ativos e cancela pagamentos expirados.
3. Log: `[paymentExpiration] job iniciado — tick a cada 60s.`

### Primeira chamada de reserva/pagamento em cada tenant
- `_ensureReservaFluxoColumns` é executada (idempotente — só faz `ALTER` se coluna não existe).
- Log de `ALTER TABLE` aparece no PostgreSQL se for a primeira vez.

### Fluxo de reserva user autenticado
1. User clica em "Reservar" em `room_details_page` → `/booking/checkout/:h/:c/:q?checkin=&checkout=`
2. `CheckoutPage` monta, campos de data travados, dispara `loadData` em paralelo (categoria + preço + política + `/usuarios/me`)
3. `HospedeInfoForm` aparece pré-preenchido
4. Verificação de disponibilidade automática
5. User clica "Finalizar Reserva"
6. `POST /usuarios/reservas` (com ou sem campos de hóspede dependendo de edição)
7. `POST /reservas/:cp/pagamentos` (canal `APP`, sem `expires_at`)
8. Bottom sheet abre
9. User clica "Pagar" com modalidade
10. `POST /reservas/:cp/pagamentos/:id/confirmar`
11. `_aplicarAprovacao` dispara: FCM hotel + user, histórico global, WhatsApp confirmation, email
12. Bottom sheet fecha com `paid` → `context.go('/tickets')`

### Fluxo de reserva guest
Igual ao user, mas:
- `HospedeInfoForm` começa vazio
- `POST /reservas/guest` em vez de `/usuarios/reservas`
- Destino final: `/booking/success?codigo=...&mode=guest` (não `/tickets`)
- Email com link pra `/reservas/:codigo` chega ao guest

### Fluxo WhatsApp
1. Bot chama `criar_reserva` → INSERT + `sendPaymentLinkViaWhatsApp`
2. Pagamento fake criado com `expires_at = NOW() + 30min`
3. URL `/pagamento/:cp/:pid` enviada via WPP (se janela ativa) + email
4. Guest abre link → `WhatsappPaymentPage`
5. Polling a cada 10s atualiza timer
6. Guest paga → `_aplicarAprovacao` roda → confirmação via WPP + email
7. Ou: timer zera → job backend cancela → email de expiração

### Fluxo hotel
Notificação `NOVA_RESERVA` agora inclui `codigo_publico` e o tap navega para `/tickets/details/:codigoPublico` em vez da lista.

---

## 6. Riscos Conhecidos

| Risco | Mitigação | Status |
|-------|-----------|--------|
| Migrations não aplicadas se tenant inativo | Só afeta tenants ativos — o problema só se manifesta ao usar o tenant | OK |
| Job de expiração caído | Ao subir de novo, processa backlog naturalmente | OK |
| SMTP mal configurado | `email.service.ts` vira no-op, só loga warn; fluxo de reserva não bloqueia | OK |
| Concorrência "pagar duas vezes" | `UPDATE ... WHERE status='PENDENTE'` na confirmação; segunda chamada retorna 409 | OK |
| Guest fecha sheet pelo back do Android | `isDismissible: false` + `PopScope canPop: false` | OK |
| InfinitePay + fake ao mesmo tempo | Ambos chamam `_aplicarAprovacao` — nenhuma duplicação | OK |
| `navegar /reservas/:cp` do email abre login? | Rota **fora do ShellRoute** e **fora** de `protectedRoutes` em `app_router.dart` | OK |
| Rate-limit barra polling do timer | `skip: req => req.method === 'GET'` no `pagamentoPublicLimiter` | OK |
| Datas com timezone (UTC vs local) | Serializadas sempre como `YYYY-MM-DD` (sem hora) | OK |

---

## 7. Pendências (fora do escopo de código)

| Item | Observação |
|------|------------|
| `Backend/swagger.yaml` — documentar os 5 endpoints novos | Aguardando instruções do usuário |
| Smoke-test manual dos 4 fluxos | Requer ambiente rodando + SMTP |
| PR no GitHub | Usuário tem instruções próprias; não acionar |
| Decisão sobre ativar InfinitePay real | Preservado no código (`pagamentoReserva.service.ts`), não invocado no fluxo fake |

---

## 8. Checklist por Camada

### Backend
- [x] Schema (email_hospede, expires_at, índice)
- [x] Email service + 3 templates
- [x] Rate-limiters
- [x] Endpoint `/reservas/guest`
- [x] Modificação `/usuarios/reservas` (reserva pra terceiro)
- [x] `/usuarios/me` confirmado
- [x] `_aplicarAprovacao` extraída
- [x] 4 endpoints fake (`POST`, `GET`, `/confirmar`, `/cancelar`)
- [x] Job de expiração
- [x] `sendPaymentLinkViaWhatsApp` + integração em `ai/tools.ts`
- [x] Typecheck limpo

### Frontend
- [x] `mask_text_input_formatter` já presente
- [x] `validators.dart` extraído (+ refactor do signup)
- [x] `HospedeInfoForm`
- [x] `BookingService` estendido
- [x] `/usuarios/me` já existia (`UsuarioService.getAutenticado`)
- [x] `PaymentBottomSheet`
- [x] `CheckoutNotifier` + `CheckoutPage` reescritos
- [x] QueryParams de data na rota + propagação
- [x] 3 rotas públicas (`/reservas/:cp`, `/pagamento/:cp/:pid`, `/booking/success`)
- [x] Correção `NOVA_RESERVA` (2 arquivos)
- [x] Flutter analyze limpo nos arquivos novos

---

## 9. Correções Pós-Entrega (iterações de bugfix)

Durante smoke-test manual surgiram problemas nos efeitos colaterais e na UX. Todos foram corrigidos sem alterar contratos de API.

### 9.1 — Backend: `_aplicarAprovacao` blindada
**Sintoma:** sheet de pagamento mostrava "não foi possível concluir o pagamento" mesmo com `UPDATE` da reserva já commitado.
**Causa raiz:** `_aplicarAprovacao` lançava `TypeError: iso.slice is not a function` em `emailTemplates.ts:23` — driver `pg` retorna colunas `DATE` como `Date` object, mas o template esperava `string`.
**Fixes:**
- `emailTemplates.ts:fmtDate` aceita `string | Date`; `ReservaResumo.dataCheckin/Checkout` tipados como union.
- `_handleWebhook` e `_confirmarPagamentoFake` envolvem `_aplicarAprovacao` em try/catch — o UPDATE já foi commitado dentro do `withTenant`, então nenhuma falha de efeito colateral (FCM/WPP/email) derruba a confirmação.
- `_getUsuarioInfo` dentro do `_aplicarAprovacao` recebeu try/catch próprio.
- `_aplicarAprovacao` agora inclui `num_hospedes` no INSERT do `historico_reserva_global` (estava faltando e causava erro silenciado).

### 9.2 — Frontend: PaymentBottomSheet expõe erro real
**Sintoma:** mensagem genérica "Não foi possível concluir o pagamento — tente novamente" mascarava a causa.
**Fix:** tipo `SubmitOutcome { ok, errorMessage }` substitui `bool` nos callbacks `onPay`/`onCancel`. `CheckoutNotifier.confirmarPagamento` / `cancelarPagamento` passaram de `Future<bool>` para `Future<String?>`. Sheet mostra a mensagem específica do backend (ex: "Pagamento já processado", "Link expirado").

### 9.3 — Backend: docker-compose e env SMTP
**Sintoma:** `[email] SMTP_HOST não configurado — envios serão no-op` mesmo com `.env` preenchido.
**Causa raiz:** `docker-compose.yml` declarava env vars uma-a-uma no bloco `environment:` e **não incluía** `SMTP_*`, `INFINITEPAY_*`, `RATE_LIMIT_*`, `FRONTEND_URL`, `BACKEND_URL`.
**Fix:** adicionadas ao bloco `environment:` — 11 variáveis novas propagadas do `.env` do host para o container.

### 9.4 — Backend: `paymentExpiration.job` quebrava em tenants virgens
**Sintoma:** `column r.email_hospede does not exist` nos logs a cada tick do job.
**Causa raiz:** `_ensureReservaFluxoColumns` só rodava quando o tenant criava reserva/pagamento. Tenants com reservas antigas nunca passavam por essa função, mas o job fazia `SELECT r.email_hospede`.
**Fix:** job chama `_ensureReservaFluxoColumns(client)` antes do SELECT. Mesma proteção em `whatsappReservation.service.ts:getReservationEmailRow`.

### 9.5 — Email: SMTP_FROM reescrito para bater com SMTP_USER
**Sintoma:** email "saía" mas nunca chegava ao destinatário.
**Causa raiz:** Gmail (e muitos outros providers) **rejeita silenciosamente** envios onde o campo `FROM` tem domínio diferente do usuário autenticado. `SMTP_FROM='ReservAqui <noreply@reservaqui.app>'` vs `SMTP_USER='reserv.aqui.123@gmail.com'`.
**Fix:** função `resolveFromHeader` em `email.service.ts` mantém o "Nome" amigável mas reescreve o email para o `SMTP_USER` quando os domínios divergem. Logs adicionados no init (`SMTP verify OK`) e no envio (`messageId`, `accepted`, `rejected`, `response`).

### 9.6 — Frontend: HospedeInfoForm async pre-fill
**Sintoma:** campos nome/email/CPF/telefone ficavam vazios mesmo com user logado.
**Causa raiz:** `CheckoutState.isLoadingData = false` por default → primeira build do widget renderizava o form com `initialData: null` antes do `/usuarios/me` responder. Controllers criados em `initState` ficavam vazios mesmo quando o widget rebuildava com dados.
**Fixes:**
- `CheckoutState.isLoadingData = true` como default — form só monta depois do fetch.
- `HospedeInfoForm.didUpdateWidget` atualiza controllers quando `initialData` muda de `null` → populado, preservando texto já digitado manualmente.

### 9.7 — Frontend: overflow da ReservationSuccessPage
**Sintoma:** "RIGHT OVERFLOW BY 38 PIXELS" no card do código em telas estreitas.
**Fix:** `SelectableText` envolto em `Flexible` + `maxLines: 1` + `TextOverflow.ellipsis`.

### 9.8 — Frontend: permissão Android 13+
**Sintoma:** push silencioso em dispositivos Android 13+ mesmo com FCM funcionando no backend.
**Fix:** adicionada `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` no `AndroidManifest.xml`. A partir da API 33, o SO exige permissão runtime — o `firebase_messaging.requestPermission()` retorna `authorized` mas o banner não aparece sem essa declaração.

### 9.9 — Credenciais: FIREBASE_SERVICE_ACCOUNT inline + reorganização
**Problema original:** push não era enviado — `FIREBASE_SERVICE_ACCOUNT` vazia no `.env`.
**Fixes:**
- Service account JSON minificado e inline no `.env` com aspas simples (`\n` escapado como 2 chars, compatível com Docker Compose v2).
- Pasta `Frontend/PRIVITE_KEY/` renomeada para `PRIVATE_KEY/` (grafia correta).
- Service account movida de `Frontend/PRIVATE_KEY/` para `Backend/PRIVATE_KEY/firebase-admin.json` — pertence conceitualmente ao backend (única parte que a consome).
- `.gitignore` root atualizado: `PRIVATE_KEY/` + `Backend/PRIVATE_KEY/`. `git check-ignore -v` confirma que ambos arquivos continuam fora do git.

### 9.10 — Aprovação via notificação `NOVA_RESERVA` quebrada
**Sintoma:** host recebia push, clicava, abria o TicketDetailsPage mas mostrava "Reserva não encontrada". Sem possibilidade de aprovar.
**Causas raízes:**
1. `Ticket.id` usava só `reserva_tenant_id` (numérico), mas a notificação passava `codigo_publico` — o `firstWhere` nunca batia.
2. `TicketsService.fetchReservas` chamava hardcoded `/usuarios/reservas` — endpoint inacessível ao host.
3. Não havia endpoint/UI para o host aprovar a reserva vista.

**Fixes:**
| Arquivo | Mudança |
|---------|---------|
| `Ticket` model | Adicionado `codigoPublico` e `statusRaw`; `fromJson` mapeia `id OR reserva_tenant_id`, `quarto_id`, e considera `tipo_quarto` como fallback para `nome_hotel` (payload do host não traz `nome_hotel`) |
| `TicketsService.fetchReservas` | Agora recebe `AuthRole`; escolhe `/hotel/reservas` para host e `/usuarios/reservas` para demais |
| `TicketsService.updateReservaStatus` | **NOVO** — `PATCH /api/hotel/reservas/:id/status` com body `{status}` |
| `TicketsNotifier` | Lê role do `authProvider`; métodos `mudarStatusReserva`, `aprovarReserva` (status=APROVADA), `negarReserva` (status=CANCELADA) |
| `TicketDetailsPage` | Lookup flexível por `id` **ou** `codigoPublico`; se host + status `SOLICITADA`/`AGUARDANDO_PAGAMENTO`, exibe botão "Gerenciar reserva" que abre o sheet |
| `ApprovalBottomSheet` (**NOVO**) | Mesmo padrão visual do `PaymentBottomSheet` (não-dismissível, `PopScope`, resumo + 2 botões): **Aprovar** (verde) → APROVADA; **Negar** (vermelho outlined) → CANCELADA |

**Fluxo completo agora:** host recebe push `NOVA_RESERVA` → tap → abre `/tickets/details/:codigoPublico` → acha ticket → botão "Gerenciar reserva" → sheet → aprovar/negar → PATCH backend → reload da lista + SnackBar + volta pra lista.

---

## 10. Bottom Line

- **19 de 21 fases completas** no plan (Fase 20 — smoke-tests — executada, 10 bugs descobertos e corrigidos; Fase 21 — PR — sob instrução específica do usuário)
- **5 bugs originais do escopo resolvidos** + **10 bugs descobertos no smoke-test** também resolvidos
- **0 regressões introduzidas** (testes preexistentes que passavam continuam passando; os 5 que falhavam em `main` já falhavam antes)
- **Retrocompatibilidade total**: `POST /usuarios/reservas` sem campos de hóspede funciona igual; webhook InfinitePay continua igual; `CheckoutPage` sem queryParams cai no date-picker como antes; ticketDetailsPage navegado por `id` continua funcionando
- **InfinitePay preservada** para reativação futura via feature flag, sem retrabalho
- **Não há migration manual** — o schema evolui sob demanda pelo padrão `_ensureXxxColumns`
- **FCM real ativado** — push chega ao app (com POST_NOTIFICATIONS no manifest); emails via Gmail SMTP funcionando (com FROM auto-corrigido)
- **Fluxo hotel fechado** — recebe push → abre detalhes → aprova/nega na mesma sessão
