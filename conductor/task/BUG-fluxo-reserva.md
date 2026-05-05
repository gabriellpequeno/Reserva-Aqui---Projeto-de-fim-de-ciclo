# BUG — Fluxo de Reserva (User + Guest + WhatsApp + Hotel)

## Contexto
Fluxo de reserva está quebrado em múltiplos pontos. Correção é **urgente** — bloqueia demo e uso real do app.
Pagamento será **modal fake** (bottom sheet com PIX / Cartão crédito / Cartão débito) para não depender de PSP real durante a apresentação. A integração com InfinitePay fica preservada no código (`pagamentoReserva.service.ts`) mas não é invocada no fluxo fake — fica como caminho alternativo para o futuro.

## Telas/Serviços afetados
- **Frontend**
  - `lib/features/booking/presentation/pages/checkout_page.dart`
  - `lib/features/booking/presentation/notifiers/checkout_notifier.dart`
  - `lib/features/booking/data/services/booking_service.dart`
  - `lib/features/rooms/presentation/widgets/availability_checker.dart` (propagar datas via rota)
  - `lib/features/rooms/presentation/pages/room_details_page.dart` (ler datas antes de navegar)
  - `lib/features/notifications/presentation/pages/notifications_page.dart`
  - `lib/features/notifications/data/services/notification_service.dart`
  - `lib/core/router/app_router.dart` (queryParams no checkout + rota pública `/reservas/:codigoPublico`)
  - **Novos widgets:** `payment_bottom_sheet.dart`, `guest_info_form.dart`
  - **Novas páginas:** `reservation_success_page.dart`, `public_ticket_page.dart`
- **Backend**
  - `src/controllers/reserva.controller.ts` + `src/routes/reserva.routes.ts` (endpoint guest público)
  - `src/services/reserva.service.ts` (função `createReservaGuest`)
  - `src/controllers/pagamentoReserva.controller.ts` + `src/routes/pagamentoReserva.routes.ts` (endpoints fake públicos)
  - `src/services/pagamentoReserva.service.ts` (funções fake: `createPagamentoFake`, `confirmarPagamentoFake`, `cancelarPagamentoFake`)
  - `src/services/whatsappReservation.service.ts` (envio do link fake + email)
  - **Novo:** `src/services/email.service.ts` (Nodemailer SMTP) + `src/services/emailTemplates.ts`
  - **Novo:** `src/services/paymentExpiration.job.ts` (expira links WPP após 30 min)

## Prioridade
**P0 — Bloqueador de demo**

## Branch sugerida
`res-68-bugfix-fluxo-reserva`

---

## Bugs identificados

### 1. User autenticado — tela de pagamento não acontece
**Atual:** `CheckoutPage` (checkout_page.dart:45-50) chama `BookingService.createReserva` e navega direto para `/tickets`, pulando pagamento.

**Esperado:** após criar a reserva, abrir **bottom sheet de pagamento** (PIX / Cartão de crédito / Cartão de débito) com botões **Pagar** e **Cancelar**.
- **Pagar** → `POST /api/reservas/:codigo_publico/pagamentos/confirmar` → status vira `APROVADA` → navega para `/tickets`.
- **Cancelar** → `POST /api/reservas/:codigo_publico/pagamentos/cancelar` → status vira `CANCELADA` → volta pra tela do quarto com SnackBar.

### 2. Guest (não autenticado) — não consegue reservar
**Atual:** checkout exige JWT (`POST /usuarios/reservas` tem `authGuard`). Guest é barrado.

**Esperado:** permitir checkout sem login, coletando dados do hóspede na própria tela (seção `GuestInfoForm`):
- Nome completo (obrigatório)
- Email (obrigatório, validação de formato)
- CPF (obrigatório, máscara `000.000.000-00` + dígito verificador)
- Telefone (obrigatório, máscara BR `(00) 00000-0000`)
- Validadores reutilizados de `user_signup_page.dart`.

Após submit + pagamento fake:
- Email do guest recebe **2 links**:
  1. Link do ticket público (rota `/reservas/:codigoPublico`, fora da interface autenticada do hotel).
  2. Link do recibo/voucher (mesmo destino com variante `?voucher=true` ou template de voucher simples).
- Guest **nunca** é redirecionado para `/tickets` (rota protegida); após pagar, vê `ReservationSuccessPage` com mensagem "Enviamos o ticket para seu email".

### 3. Hotel — notificação de nova reserva não leva aos detalhes
**Atual:** `notifications_page.dart:228` — tap em `NOVA_RESERVA` navega para `/tickets` (lista).

**Esperado:** tap navega para `/tickets/details/:codigoPublico`. Mesmo ajuste em `notification_service.dart:129` (tap de push FCM).

### 4. WhatsApp — falta link de pagamento + ticket por email
**Atual:** `whatsappReservation.service.ts` envia confirmação apenas após aprovação manual.

**Esperado:** quando reserva é criada via WPP (canal `WHATSAPP`):
1. Gerar pagamento fake com `expires_at = NOW() + 30 min`.
2. Enviar ao hóspede via WhatsApp **e** email uma URL do tipo `{FRONTEND_URL}/pagamento/:codigoPublico/:pagamentoId` (página fake de pagamento **sem botão cancelar** — só timer).
3. Ao pagar, enviar via WhatsApp **e** email o link do ticket público (`/reservas/:codigoPublico`).
4. Job de expiração: se `expires_at < NOW()` e status ainda `PENDENTE`, marca pagamento `CANCELADO`, reserva `CANCELADA` e avisa o guest.

### 5. Datas da disponibilidade não fluem para o checkout
**Atual:** `availability_checker.dart` tem `_checkInDate` e `_checkOutDate` locais; ao clicar "Reservar" em `room_details_page.dart:495`, só `hotelId/categoriaId/quartoId` são passados. Checkout abre com date-picker vazio e o usuário escolhe tudo de novo.

**Esperado:** datas fluem via **queryParams** na rota:
```
/booking/checkout/:hotelId/:categoriaId/:quartoId?checkin=YYYY-MM-DD&checkout=YYYY-MM-DD
```
Se presentes, `CheckoutPage` inicializa `_checkInDate`/`_checkOutDate` com esses valores e **trava** os campos de data (somente-leitura, com dica "alterar na tela anterior"). Se ausentes (deep link direto, fluxo legado), mantém comportamento atual de picker.

---

## O que integrar / implementar

### Backend

- [ ] **Nodemailer + SMTP**
  - Criar `src/services/email.service.ts` com transporte configurável via `.env` (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`).
  - Templates em `src/services/emailTemplates.ts`:
    - `reservaPendentePagamento` — contém URL da página de pagamento + resumo
    - `reservaConfirmada` — contém `/reservas/:codigoPublico` + voucher
    - `reservaExpirada` — pagamento WPP expirou sem ser pago
- [ ] **Endpoint público guest** — `POST /api/reservas/guest` (sem `authGuard`, rate-limited):
  - Body: `hotel_id, quarto_id, categoria_id, num_hospedes, data_checkin, data_checkout, valor_total, nome_hospede, email_hospede, cpf_hospede, telefone_contato`
  - Validação: email, CPF (dígito verificador), telefone BR.
  - Insere reserva com `user_id = NULL`, `canal_origem = 'APP_GUEST'`, status `SOLICITADA`.
  - Dispara notificação `NOVA_RESERVA` ao hotel (reusa lógica em `_createReservaUsuario`).
- [ ] **Endpoints fake de pagamento** (`/api/reservas/:codigo_publico/pagamentos/...`):
  - `POST /` — cria pagamento fake `PENDENTE`, retorna `{pagamento_id, modalidades: ['PIX','CARTAO_CREDITO','CARTAO_DEBITO'], expires_at?: ISO}`.
  - `POST /:pagamento_id/confirmar` — body `{forma_pagamento}`. Marca pagamento `APROVADO`, reserva `APROVADA`. Reaproveita efeitos colaterais de `_handleWebhook` (FCM hotel + user, histórico global, WhatsApp confirmation, email `reservaConfirmada`).
  - `POST /:pagamento_id/cancelar` — marca pagamento `CANCELADO`, reserva `CANCELADA`, notifica hotel.
  - Todos públicos, rate-limit por IP (10 req/min).
  - `codigo_publico` como chave opaca (não expor `reserva_id` numérico).
- [ ] **WhatsApp** (`whatsappReservation.service.ts`):
  - Após criar reserva via WPP, chamar `createPagamentoFake` com `expires_at = NOW() + 30min`.
  - Enviar ao número do guest via WPP: URL `{FRONTEND_URL}/pagamento/:codigoPublico/:pagamentoId`.
  - Enviar email com o mesmo link.
  - Quando `confirmarPagamentoFake` roda (user abre o link e paga), enviar WPP + email com ticket.
- [ ] **Job de expiração**: `paymentExpiration.job.ts`
  - Intervalo 1 min (`setInterval` ou cron interno).
  - Busca pagamentos `PENDENTE` com `expires_at < NOW()` → marca `CANCELADO`, reserva `CANCELADA`, envia email `reservaExpirada`.
  - Fire-and-forget, erros logados mas não propagam.
- [ ] **Schema:** adicionar coluna `expires_at TIMESTAMP NULL` em `pagamento_reserva` (migration idempotente no padrão de `_ensureSlugConstraint`).
- [ ] **Schema:** adicionar coluna `email_hospede VARCHAR(255) NULL` em `reserva`.
- [ ] **Notificação `NOVA_RESERVA`** — payload já inclui `codigo_publico` (`reserva.service.ts:311`), validar.
- [ ] **Rate-limit middleware** — criar `src/middlewares/rateLimit.ts` usando `express-rate-limit` ou implementação simples por IP.

### Frontend

- [ ] **Rota com queryParams** — `app_router.dart:209`:
  ```dart
  path: '/booking/checkout/:hotelId/:categoriaId/:quartoId',
  builder: (context, state) {
    final checkin = state.uri.queryParameters['checkin'];
    final checkoutDate = state.uri.queryParameters['checkout'];
    return CheckoutPage(
      hotelId: ...,
      categoriaId: ...,
      quartoId: ...,
      initialCheckin: checkin != null ? DateTime.tryParse(checkin) : null,
      initialCheckout: checkoutDate != null ? DateTime.tryParse(checkoutDate) : null,
    );
  }
  ```
- [ ] **`availability_checker.dart`** — ao clicar "Reservar", navegar passando datas:
  ```dart
  context.push(
    '/booking/checkout/$hotelId/$categoriaId/$quartoId'
    '?checkin=${fmt(_checkInDate!)}&checkout=${fmt(_checkOutDate!)}',
  );
  ```
- [ ] **`room_details_page.dart:495`** — idem se houver datas selecionadas.
- [ ] **`CheckoutPage`**:
  - Construtor aceita `initialCheckin`/`initialCheckout`; `initState` inicializa state.
  - Se datas vêm via query, campos de data ficam somente-leitura com hint "Alterar na tela anterior".
  - Ler auth status via `authNotifier`: se não autenticado → renderiza `GuestInfoForm` acima do botão.
  - "Finalizar Reserva":
    1. User autenticado → `POST /api/usuarios/reservas` (existe).
    2. Guest → `POST /api/reservas/guest` (novo).
    3. Ambos → `POST /api/reservas/:codigoPublico/pagamentos` → abre `PaymentBottomSheet`.
    4. Bottom sheet: user escolhe modalidade → "Pagar" chama `/confirmar` ou "Cancelar" chama `/cancelar`.
    5. Após sucesso: user → `/tickets`; guest → `/booking/success?codigo=...&mode=guest`.
  - **Remover** `ref.listen` atual que redireciona a `/tickets` (`checkout_page.dart:45-50`). Navegação passa a ser decidida pelo retorno do sheet.
- [ ] **Novo widget:** `lib/features/booking/presentation/widgets/guest_info_form.dart`
  - `Form` + `GlobalKey<FormState>` + 4 `TextFormField` com validators + máscaras.
  - Expõe `validate()` e `getData()` → `GuestInfoFormData`.
- [ ] **Novo widget:** `lib/features/booking/presentation/widgets/payment_bottom_sheet.dart`
  - `showModalBottomSheet(isScrollControlled: true, isDismissible: false, ...)`.
  - Exibe: resumo (hotel, datas, total), 3 radio options (PIX, Cartão crédito, Cartão débito), 2 botões.
  - Retorna `PaymentSheetResult.paid | cancelled | dismissed`.
- [ ] **Nova página:** `lib/features/booking/presentation/pages/reservation_success_page.dart`
  - Variante user: "Reserva confirmada! Veja seus tickets" + botão para `/tickets`.
  - Variante guest: "Reserva confirmada! Enviamos o ticket para seu email" + botão "Copiar link do ticket".
- [ ] **Nova página:** `lib/features/booking/presentation/pages/public_ticket_page.dart`
  - Consome `GET /api/reservas/:codigo_publico` (já existe, público).
  - Layout somente-leitura com resumo + status + botão "Baixar voucher (PDF)" (opcional; se fora do escopo, apenas texto).
  - Rota `/reservas/:codigoPublico` adicionada **fora do `ShellRoute`** e **fora** da lista de `protectedRoutes`.
- [ ] **Nova página:** `lib/features/booking/presentation/pages/whatsapp_payment_page.dart`
  - Rota `/pagamento/:codigoPublico/:pagamentoId`.
  - Mesma UI do `PaymentBottomSheet` mas em tela cheia, **sem botão Cancelar**, com **timer regressivo** consumindo `expires_at` retornado por um novo `GET /api/reservas/:codigoPublico/pagamentos/:id`.
  - Pública (sem auth).
- [ ] **Notificações (hotel):**
  - `notifications_page.dart:228` — `case 'NOVA_RESERVA'` passa a navegar para `/tickets/details/${codigoPublico}`.
  - `notification_service.dart:129` — mesmo ajuste para push tap.
- [ ] **Validators compartilhados:** extrair de `user_signup_page.dart` para `lib/features/auth/utils/validators.dart` (`validateEmail`, `validateCpf`, `validateTelefoneBr`, `validateNomeCompleto`).
- [ ] **Máscaras:** confirmar `mask_text_input_formatter` em `pubspec.yaml`; se ausente, adicionar.

---

## Endpoints usados / criados

| Método | Rota | Auth | Ação |
|--------|------|------|------|
| POST | `/api/reservas/guest` | ❌ (rate-lim) | Cria reserva de guest (novo) |
| POST | `/api/reservas/:codigo_publico/pagamentos` | ❌ | Cria pagamento fake (novo) |
| GET | `/api/reservas/:codigo_publico/pagamentos/:id` | ❌ | Lê status/expires_at (novo, pro timer WPP) |
| POST | `/api/reservas/:codigo_publico/pagamentos/:id/confirmar` | ❌ | Confirma pagamento fake (novo) |
| POST | `/api/reservas/:codigo_publico/pagamentos/:id/cancelar` | ❌ | Cancela reserva (novo) |
| GET | `/api/reservas/:codigo_publico` | ❌ | Leitura pública do ticket (já existe) |
| POST | `/api/usuarios/reservas` | ✅ | User autenticado (já existe) |
| POST | `/api/hotel/reservas/:reserva_id/pagamentos` | ✅ hotel | Hotel (já existe, mantido como alternativa InfinitePay real) |

---

## Variáveis de ambiente (`Backend/.env`)

A adicionar:
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=...
SMTP_PASS=...
SMTP_FROM="ReservAqui <noreply@reservaqui.app>"
FRONTEND_URL=http://localhost:3000   # ou URL pública pra produção
```

InfinitePay pode permanecer configurado sem afetar (não é invocado no fluxo fake).

---

## Critérios de aceitação

- [ ] **User autenticado**: seleciona datas no `availability_checker` → "Reservar" → checkout já vem com datas preenchidas e **travadas** → confirma → **bottom sheet de pagamento abre** → escolhe modalidade → "Pagar" → navega para `/tickets` com reserva `APROVADA`.
- [ ] **User autenticado** clica "Cancelar" no sheet → reserva `CANCELADA`, volta para detalhes do quarto, SnackBar.
- [ ] **Guest**: mesma UX com 4 campos validados (nome, email, CPF com dígito verificador, telefone) → bottom sheet → "Pagar" → `ReservationSuccessPage` com mensagem "checar email".
- [ ] **Guest**: recebe email com link do ticket público; link abre em `/reservas/:codigoPublico` sem exigir login.
- [ ] **Guest**: em **nenhum momento** é redirecionado para `/tickets` ou área autenticada do hotel.
- [ ] **Hotel**: tap em push/in-app `NOVA_RESERVA` abre `/tickets/details/:codigoPublico`.
- [ ] **WhatsApp**: reserva criada via WPP → hóspede recebe link de pagamento (sem botão cancelar, com timer) via WPP + email → ao pagar, recebe ticket via WPP + email.
- [ ] **WhatsApp**: sem pagamento em 30 min → reserva `CANCELADA` automaticamente, email `reservaExpirada` enviado.
- [ ] **Datas**: propagam do `availability_checker` para `CheckoutPage` via queryParams; checkout inicia com elas travadas.
- [ ] Nenhum teste unitário existente é quebrado.
- [ ] Backend sobe com `.env` contendo SMTP.

---

## Dependências
- **Requer:** P5-C (checkout), P5-D (tickets), P0 (auth), serviço WhatsApp existente — todos prontos
- **Nova dep Flutter:** `mask_text_input_formatter` (se ausente)
- **Nova dep Node:** `nodemailer` + `@types/nodemailer` + `express-rate-limit` (ou equivalente)

## Bloqueia
- Demo completa do app
- Testes E2E do fluxo de reserva

---

## Observações
- Todo pagamento é **fake**: nenhuma chamada a PSP real. `_handleWebhook` existente **não** é invocado; o confirm/cancel fake replica seus efeitos colaterais diretamente (FCM, histórico, email).
- A integração InfinitePay fica preservada no código (`pagamentoReserva.service.ts:94-143`) como caminho alternativo — pode ser ativada futuramente via feature flag sem mudar nada nas telas.
- Links do email/WPP usam `FRONTEND_URL` + path `/reservas/:codigoPublico` (deep link para app ou PWA).
- `public_ticket_page.dart` é **standalone** (fora do `ShellRoute`), sem bottom nav — para não expor UI de hotel autenticado aos guests.
