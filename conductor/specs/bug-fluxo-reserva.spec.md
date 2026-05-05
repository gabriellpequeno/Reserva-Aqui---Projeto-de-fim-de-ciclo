# Spec — Bug-Fix do Fluxo de Reserva

## Referência
- **Task:** conductor/task/BUG-fluxo-reserva.md
- **Código existente chave:**
  - Checkout Flutter: `Frontend/lib/features/booking/presentation/pages/checkout_page.dart`
  - CheckoutNotifier: `Frontend/lib/features/booking/presentation/notifiers/checkout_notifier.dart`
  - BookingService: `Frontend/lib/features/booking/data/services/booking_service.dart`
  - Availability checker: `Frontend/lib/features/rooms/presentation/widgets/availability_checker.dart`
  - Notifications tap handler: `Frontend/lib/features/notifications/presentation/pages/notifications_page.dart:206-235`
  - Router: `Frontend/lib/core/router/app_router.dart:66` (protectedRoutes), `:209` (checkout route)
  - Reserva service: `Backend/src/services/reserva.service.ts:234-317` (`_createReservaUsuario`) + `:319-400` (`_createReservaWalkin` — template para guest)
  - Pagamento service InfinitePay: `Backend/src/services/pagamentoReserva.service.ts` (preservado, não invocado no fluxo fake)

## Abordagem Técnica

**Pagamento** é simulado via 3 endpoints públicos (`/pagamentos`, `/pagamentos/:id/confirmar`, `/pagamentos/:id/cancelar`) chaveados por `codigo_publico` da reserva. O `/confirmar` não chama PSP: atualiza pagamento `APROVADO` + reserva `APROVADA` e replica os efeitos colaterais que hoje existem no `_handleWebhook` da InfinitePay (FCM hotel + user, histórico global, WhatsApp confirmação, email). O `/cancelar` simetricamente coloca tudo em `CANCELADA`.

**Bottom sheet** (`payment_bottom_sheet.dart`) é um `showModalBottomSheet` não-dismissível (obriga escolha explícita entre Pagar e Cancelar) com 3 radios (PIX, Cartão crédito, Cartão débito) e resumo da reserva. Retorna um `PaymentSheetResult` enum.

**Form unificado de "dados do hóspede"**: a mesma `CheckoutPage` exibe o formulário de 4 campos (nome, email, CPF, telefone) **para todos** — user autenticado e guest. A diferença:
- **User autenticado:** campos chegam **pré-preenchidos** com dados do próprio usuário (via `/usuarios/me`), mas **editáveis**. Permite reservar para terceiros (família, amigos) sem criar fluxo paralelo. A reserva fica vinculada ao `user_id` do dono da conta (histórico em `/tickets`), mas os campos `nome_hospede`/`email_hospede`/`cpf_hospede`/`telefone_contato` armazenam quem efetivamente vai hospedar.
- **Guest (não autenticado):** mesmos campos, vazios, obrigatórios. Sem `user_id`.

Endpoints distintos por auth, mas contrato de body idêntico para os 4 campos de hóspede: `POST /api/usuarios/reservas` (autenticado) e `POST /api/reservas/guest` (público). Validação idêntica client-side (validators compartilhados) e server-side.

**Datas** fluem via **queryParams**: `/booking/checkout/:h/:c/:q?checkin=YYYY-MM-DD&checkout=YYYY-MM-DD`. Se presentes, `CheckoutPage` inicializa state e bloqueia o date-picker (read-only + hint). Ausentes → fallback para o comportamento atual de picker (preserva deep links sem datas).

**Guarda de disponibilidade (obrigatória)**: a `CheckoutPage` **sempre** valida disponibilidade antes de permitir `POST /api/usuarios/reservas` ou `POST /api/reservas/guest`. Três momentos:
1. **Ao montar com datas via queryParam**: dispara `GET /hotel/:hotelId/disponibilidade?data_checkin=&data_checkout=` em paralelo com `loadData`. Filtra pela `categoriaId` da rota; se `disponivel=false`, renderiza estado de erro bloqueando o botão "Finalizar" (sem modal de pagamento, sem criação de reserva).
2. **Após o user escolher datas manualmente** (fluxo legado sem queryParam): chama `/disponibilidade` logo após o `onChange` do picker. Bloqueia submit até resposta `true`.
3. **Defesa em profundidade no backend**: `_createReservaUsuario` e `createReservaGuest` revalidam com `EXISTS` dentro da transação (código atual em `reserva.service.ts:247-259`). Se 409, frontend exibe SnackBar "Quarto acabou de ser reservado" e força re-fetch de disponibilidade.

**WhatsApp** usa os mesmos endpoints fake, mas a UX é diferente: o bot envia ao guest um link `{FRONTEND_URL}/pagamento/:codigoPublico/:pagamentoId` que abre uma **página cheia** (não sheet) **sem botão cancelar**, com **timer regressivo** consumindo o `expires_at` retornado. Quando o timer zera, um job de backend (`paymentExpiration.job.ts` rodando em `setInterval(1min)`) marca o pagamento `CANCELADO` e avisa por email.

**Email** é novo: `Nodemailer` + SMTP via `.env`, com 3 templates (pendente, confirmada, expirada). É fire-and-forget — erros de SMTP não bloqueiam o fluxo de reserva, apenas logam.

**Notificações hotel**: correção trivial em 2 arquivos para que `NOVA_RESERVA` abra detalhes em vez da lista.

---

## Componentes Afetados

### Backend

| Arquivo | Mudança |
|---------|---------|
| `src/services/email.service.ts` | **NOVO** — transporter Nodemailer + `sendEmail({to, subject, html})` |
| `src/services/emailTemplates.ts` | **NOVO** — 3 templates HTML (pendente, confirmada, expirada) |
| `src/services/reserva.service.ts` | **NOVO** `createReservaGuest(input)` — adapta `_createReservaWalkin` com `canal_origem = 'APP_GUEST'`, dispara `NOVA_RESERVA` |
| `src/entities/Reserva.ts` | **MOD** — `validateGuest(input)` (email, CPF dígito verificador, telefone regex BR) |
| `src/controllers/reserva.controller.ts` | **NOVO** `createReservaGuestController` |
| `src/routes/reserva.routes.ts` | **MOD** — novo `guestReservaRouter` com `POST /` |
| `src/services/pagamentoReserva.service.ts` | **NOVO** `createPagamentoFake`, `confirmarPagamentoFake`, `cancelarPagamentoFake`, `getPagamentoPublic` (extrai efeitos colaterais do `_handleWebhook` em função privada reutilizável `_aplicarAprovacao`) |
| `src/controllers/pagamentoReserva.controller.ts` | **NOVO** 4 controllers públicos |
| `src/routes/pagamentoReserva.routes.ts` | **NOVO** `publicPagamentoRouter` com 4 rotas |
| `src/app.ts` | **MOD** — monta `guestReservaRouter` em `/api/reservas/guest` e `publicPagamentoRouter` em `/api/reservas/:codigo_publico/pagamentos` |
| `src/services/paymentExpiration.job.ts` | **NOVO** — `setInterval(1min)` busca e expira pagamentos `PENDENTE` com `expires_at < NOW()` |
| `src/app.ts` | **MOD** — inicializa `startPaymentExpirationJob()` no bootstrap |
| `src/services/whatsappReservation.service.ts` | **MOD** — após criar reserva via WPP, chama `createPagamentoFake(expires_at = +30min)` + envia link via WPP + email |
| `src/middlewares/rateLimit.ts` | **NOVO** — wrapper sobre `express-rate-limit` |
| `src/database/migrations/...` | **NOVO** — idempotent: `ALTER TABLE reserva ADD COLUMN IF NOT EXISTS email_hospede VARCHAR(255)` + `ALTER TABLE pagamento_reserva ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP` (aplicar por tenant via `withTenant` ou script standalone) |

### Frontend

| Arquivo | Mudança |
|---------|---------|
| `pubspec.yaml` | **MOD** — `mask_text_input_formatter: ^2.x` se ausente |
| `lib/features/auth/utils/validators.dart` | **NOVO** — extraído de `user_signup_page.dart`: `validateEmail`, `validateCpf`, `validateTelefoneBr`, `validateNomeCompleto` |
| `lib/features/booking/data/services/booking_service.dart` | **MOD** — `createReservaGuest`, `createPagamento`, `confirmarPagamento`, `cancelarPagamento`, `fetchPagamento` |
| `lib/features/booking/presentation/notifiers/checkout_notifier.dart` | **MOD** — aceita datas iniciais, pré-carrega dados do user autenticado (`/usuarios/me`), expõe `HospedeInfoFormData`, fluxo sheet |
| `lib/features/booking/presentation/pages/checkout_page.dart` | **MOD** — construtor aceita `initialCheckin`/`initialCheckout`, **sempre** renderiza `HospedeInfoForm` (pré-preenchido se autenticado), abre `PaymentBottomSheet` em vez de navegar direto |
| `lib/features/booking/presentation/widgets/hospede_info_form.dart` | **NOVO** — formulário unificado 4 campos com validators + máscaras; aceita `initialData` opcional para pré-preenchimento |
| `lib/features/booking/presentation/widgets/payment_bottom_sheet.dart` | **NOVO** — `showModalBottomSheet` não-dismissível + 3 radios + 2 botões |
| `lib/features/booking/presentation/pages/reservation_success_page.dart` | **NOVO** — variantes user/guest |
| `lib/features/booking/presentation/pages/public_ticket_page.dart` | **NOVO** — standalone, sem `ShellRoute`, consome `GET /api/reservas/:codigo_publico` |
| `lib/features/booking/presentation/pages/whatsapp_payment_page.dart` | **NOVO** — tela cheia com timer, sem botão cancelar |
| `lib/features/rooms/presentation/widgets/availability_checker.dart` | **MOD** — após "Reservar", navega com queryParams de data |
| `lib/features/rooms/presentation/pages/room_details_page.dart:495` | **MOD** — ler datas e passar via queryParams |
| `lib/core/router/app_router.dart` | **MOD** — parse `checkin`/`checkout` query; novas rotas `/reservas/:codigoPublico`, `/pagamento/:codigoPublico/:pagamentoId`, `/booking/success`; garantir que **nenhuma** delas está em `protectedRoutes` |
| `lib/features/notifications/presentation/pages/notifications_page.dart:228` | **MOD** — `NOVA_RESERVA` → `/tickets/details/$codigoPublico` |
| `lib/features/notifications/data/services/notification_service.dart:129` | **MOD** — mesmo para push tap |
| `lib/features/auth/presentation/pages/user_signup_page.dart` | **MOD** — passa a importar validators do arquivo novo |

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| Extrair `_aplicarAprovacao` de `_handleWebhook` para reuso no fluxo fake | Evita duplicar FCM/histórico/email. Quando InfinitePay voltar, webhook continua chamando a mesma função |
| Endpoints fake públicos chaveados por `codigo_publico` (não `reserva_id`) | `codigo_publico` é opaco/aleatório; expor IDs sequenciais vazaria volume |
| Rate-limit por IP nos endpoints públicos | Mitiga enumeração/abuso sem exigir auth |
| Bottom sheet **não-dismissível** (`isDismissible: false`) | Força escolha consciente — evita usuário fechar por engano e ficar com reserva pendente |
| Modalidades PIX/CC/CD são apenas cosméticas (não afetam status) | Fluxo é fake; status final é `APROVADA` independente da escolha |
| Datas via queryParams em vez de provider global | Stateless; funciona em deep link; não quebra se usuário entrar direto no checkout |
| `CheckoutPage` mantém date-picker se queryParams ausentes | Compatibilidade retroativa com fluxos que ainda não propagam |
| Verificação de disponibilidade obrigatória no checkout (3 camadas) | Evita reservas inválidas por deep link direto, usuários que pulam o `availability_checker`, ou concorrência entre dois guests tentando o mesmo quarto |
| Validators extraídos para arquivo compartilhado | Um único lugar para regras; evita divergência entre signup e checkout |
| Form unificado `HospedeInfoForm` para user e guest | Uma única tela e widget; user pode reservar pra terceiros (família/amigos) editando os campos pré-preenchidos. Reduz manutenção e unifica UX |
| Reserva do user autenticado é vinculada ao `user_id` (histórico em `/tickets`) mas armazena `nome_hospede`/`email_hospede`/`cpf_hospede`/`telefone_contato` | Dono da conta vê todas as reservas que fez; emails e documentos vão para a pessoa que vai efetivamente hospedar |
| `POST /api/usuarios/reservas` passa a aceitar campos de hóspede (opcionalmente) | Retrocompat: se `nome_hospede` vem vazio, backend usa nome do user. Se vem preenchido, armazena como dado do hóspede |
| Rotas `/reservas/:codigoPublico` e `/pagamento/...` fora do `ShellRoute` | Não expõem bottom-nav/layout do hotel aos guests |
| Timer de expiração WPP como job no backend, não no frontend | Frontend do guest pode fechar/travar; backend é a fonte da verdade |
| Job roda a cada 1 min (`setInterval`) em vez de cron externo | Sem dependência nova; aceitável para granularidade de 30 min |
| `expires_at` em coluna dedicada (não computado) | Permite query `WHERE expires_at < NOW()` indexada |
| `email_hospede` em coluna dedicada (não `observacoes` JSON) | Query e template de email mais limpos; validação constraint no banco possível |
| Nodemailer em vez de SaaS | Sem dependência externa paga; SMTP aceita gmail/mailtrap/mailgun indiferente |
| Email é fire-and-forget | SMTP pode falhar sem bloquear fluxo crítico de reserva |
| InfinitePay preservada (não removida) | Quando houver documentação/sandbox, basta adicionar feature flag; zero retrabalho |

---

## Contratos de API

### `POST /api/reservas/guest` (novo, público)

**Rate-limit:** 5 req/min por IP

**Request:**
```json
{
  "hotel_id": "uuid",
  "quarto_id": 12,
  "categoria_id": 3,
  "num_hospedes": 2,
  "data_checkin": "2026-06-10",
  "data_checkout": "2026-06-15",
  "valor_total": 1250.00,
  "nome_hospede": "Maria Silva",
  "email_hospede": "maria@example.com",
  "cpf_hospede": "12345678909",
  "telefone_contato": "+5511999998888"
}
```

**Validações backend:**
- `email_hospede`: regex RFC-lite
- `cpf_hospede`: 11 dígitos + dígito verificador válido (strip mask antes)
- `telefone_contato`: regex `^\+?\d{10,13}$` (strip mask)
- Datas ISO, `data_checkout > data_checkin`
- Campos não-vazios

**Response 201:**
```json
{ "data": { "id": 4521, "codigo_publico": "r-ab12cd34" } }
```

**Erros:** `400` validação, `404` hotel/quarto, `409` quarto indisponível, `429` rate-limit.

---

### `POST /api/reservas/:codigo_publico/pagamentos` (novo, público)

**Rate-limit:** 10 req/min por IP

**Request body (opcional):**
```json
{ "canal": "APP" | "WHATSAPP" }
```
Se `canal = WHATSAPP`, backend seta `expires_at = NOW() + 30min`. Caso contrário, `expires_at` fica NULL.

**Response 201:**
```json
{
  "data": {
    "pagamento_id": 88,
    "reserva_id": 4521,
    "codigo_publico": "r-ab12cd34",
    "status": "PENDENTE",
    "modalidades": ["PIX", "CARTAO_CREDITO", "CARTAO_DEBITO"],
    "valor_total": 1250.00,
    "expires_at": "2026-06-10T14:30:00Z"
  }
}
```

**Erros:** `404` reserva, `409` já há pagamento pendente, `422` reserva cancelada/concluída.

---

### `GET /api/reservas/:codigo_publico/pagamentos/:id` (novo, público)

**Response:**
```json
{
  "data": {
    "pagamento_id": 88,
    "status": "PENDENTE" | "APROVADO" | "CANCELADO",
    "expires_at": "...",
    "valor_total": 1250.00
  }
}
```

Usado pela `whatsapp_payment_page.dart` para atualizar o timer e detectar mudança de status.

---

### `POST /api/reservas/:codigo_publico/pagamentos/:id/confirmar` (novo, público)

**Request:**
```json
{ "forma_pagamento": "PIX" | "CARTAO_CREDITO" | "CARTAO_DEBITO" }
```

**Efeitos:**
1. `UPDATE pagamento_reserva SET status='APROVADO', forma_pagamento=..., data_pagamento=NOW() WHERE id=$1 AND status='PENDENTE'`
2. `UPDATE reserva SET status='APROVADA' WHERE id=$1`
3. Chama `_aplicarAprovacao(hotelId, reserva)` — extraída de `_handleWebhook`, replica: FCM hotel + FCM user + historico global + WhatsApp confirmation + email `reservaConfirmada`.

**Response 200:** `{ "data": { "pagamento_id": 88, "status": "APROVADO" } }`

**Erros:** `404`, `409` (já processado), `410` (expirado).

---

### `POST /api/reservas/:codigo_publico/pagamentos/:id/cancelar` (novo, público)

**Efeitos:**
1. `UPDATE pagamento_reserva SET status='CANCELADO' WHERE id=$1`
2. `UPDATE reserva SET status='CANCELADA' WHERE id=$1`
3. FCM hotel `RESERVA_CANCELADA` + email `reservaExpirada` (reuso) ou template dedicado `reservaCancelada`.

**Response 200:** `{ "data": { "pagamento_id": 88, "status": "CANCELADO" } }`

---

### `GET /api/reservas/:codigo_publico` (já existe)

Usado por `PublicTicketPage`. Sem mudança.

---

### `POST /api/usuarios/reservas` (já existe, **MOD**)

Aceita novos campos **opcionais** — se omitidos, backend puxa do `usuario` pelo JWT.

**Request (mudança):**
```json
{
  "hotel_id": "...",
  "quarto_id": 12,
  "num_hospedes": 2,
  "data_checkin": "2026-06-10",
  "data_checkout": "2026-06-15",
  "valor_total": 1250.00,
  "nome_hospede": "Maria Silva",        // NOVO, opcional
  "email_hospede": "maria@example.com", // NOVO, opcional
  "cpf_hospede": "12345678909",         // NOVO, opcional
  "telefone_contato": "+5511999998888"  // NOVO, opcional (entidade já tem coluna)
}
```

Lógica server-side:
- Se `nome_hospede` ausente ou igual ao do user → `nome_hospede = NULL` (comportamento atual).
- Se diferente → grava os 4 campos (reserva pra terceiro). Validação dos 4 como um bloco: ou todos presentes, ou todos ausentes.

### `GET /api/usuarios/me` (confirmar existência; senão, adicionar)

Usado pelo frontend para pré-preencher o form no checkout. Retorna `{nome_completo, email, cpf, numero_celular}`.

---

## Modelos de Dados

### Frontend

```dart
class HospedeInfoFormData {
  final String nome;
  final String email;
  final String cpf;         // despmascarado (11 dígitos)
  final String telefone;    // despmascarado

  /// Indica se os dados foram editados (pelo user autenticado) em relação ao pré-preenchimento.
  /// Usado pelo backend pra decidir se persiste campos nome_hospede/email_hospede etc.
  bool hasDivergedFromUserData(HospedeInfoFormData userData) => this != userData;
}

enum PaymentMethod { pix, cartaoCredito, cartaoDebito }

enum PaymentSheetResult { paid, cancelled, dismissed }

class CheckoutState {
  // campos existentes...
  final DateTime? initialCheckin;
  final DateTime? initialCheckout;
  final HospedeInfoFormData? initialHospedeData; // pré-preenchimento quando autenticado
  final bool isAuthenticated;
  final String? codigoPublicoReserva;
  final int? pagamentoId;
}
```

### Backend

```ts
interface CreateReservaGuestInput {
  hotel_id: string;
  quarto_id: number;
  categoria_id: number;
  num_hospedes: number;
  data_checkin: string;
  data_checkout: string;
  valor_total: number;
  nome_hospede: string;
  email_hospede: string;
  cpf_hospede: string;
  telefone_contato: string;
}

type FormaPagamento = 'PIX' | 'CARTAO_CREDITO' | 'CARTAO_DEBITO';

interface PagamentoFakeInput {
  codigo_publico: string;
  canal: 'APP' | 'WHATSAPP';
}
```

### Migrations

```sql
-- Aplicar em cada schema de tenant (via withTenant) na primeira chamada:
ALTER TABLE reserva
  ADD COLUMN IF NOT EXISTS email_hospede VARCHAR(255);

ALTER TABLE pagamento_reserva
  ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP NULL;

CREATE INDEX IF NOT EXISTS idx_pagamento_expires
  ON pagamento_reserva(expires_at)
  WHERE status = 'PENDENTE' AND expires_at IS NOT NULL;
```

Padrão de aplicação idempotente espelha `_ensureSlugConstraint` (`pagamentoReserva.service.ts:73-88`).

---

## Fluxo Detalhado

### Fluxo A — User autenticado

1. User verifica disponibilidade em `availability_checker.dart` com datas X/Y.
2. Clica "Reservar" → `context.push('/booking/checkout/:h/:c/:q?checkin=X&checkout=Y')`.
3. `CheckoutPage` monta com datas travadas; detecta auth → chama `GET /api/usuarios/me` para pré-preencher form.
4. `loadData` carrega categoria/preço/políticas + dados do user em paralelo via `Future.wait`.
5. Form de hóspede aparece **pré-preenchido e editável**; user pode manter (reservar pra si) ou editar (reservar pra terceiro). Se editar, aparece um hint sutil "Reservando para outra pessoa".
6. User clica "Finalizar Reserva":
   - Valida form (mesmos validators do guest).
   - `POST /api/usuarios/reservas` com os 4 campos de hóspede → retorna `{id, codigo_publico}`.
   - `POST /api/reservas/:codigo_publico/pagamentos` body `{canal:'APP'}` → `{pagamento_id}`.
6. `showModalBottomSheet(PaymentBottomSheet(...))`.
7. User escolhe PIX/CC/CD + clica "Pagar":
   - `POST /.../pagamentos/:id/confirmar` body `{forma_pagamento}` → 200.
   - Sheet fecha com `PaymentSheetResult.paid`.
8. `ref.read(ticketsNotifierProvider.notifier).reload(); context.go('/tickets')`.
9. Reserva aparece com status `APROVADA`.
10. Push FCM `APROVACAO_RESERVA` chega (disparada por `_aplicarAprovacao`).

Alternativa 7b — User clica "Cancelar":
- `POST /.../pagamentos/:id/cancelar` → 200.
- Sheet fecha com `cancelled`.
- `context.pop()` + SnackBar "Reserva cancelada".

### Fluxo B — Guest

1-4. Igual ao Fluxo A, mas `authMode = guest` → renderiza `GuestInfoForm`.
5. User preenche 4 campos + clica "Finalizar":
   - Valida form local (se inválido, aborta com erros inline).
   - `POST /api/reservas/guest` → `{id, codigo_publico}`.
   - `POST /api/reservas/:codigo_publico/pagamentos` body `{canal:'APP'}` → `{pagamento_id}`.
   - Backend (novo) envia email `reservaPendentePagamento` com link pra `/pagamento/:codigoPublico/:pagamentoId`.
6. Bottom sheet abre (mesma UI).
7. "Pagar" → `/confirmar` → 200.
   - Backend envia email `reservaConfirmada` com link `/reservas/:codigoPublico`.
8. `context.go('/booking/success?codigo=:codigoPublico&mode=guest')` — nunca `/tickets`.
9. Guest clica no link do email → abre `PublicTicketPage` (sem login).

### Fluxo C — Hotel (notificação)

1. Reserva criada por A ou B dispara `NOVA_RESERVA` (já acontece em `reserva.service.ts:299-313`).
2. Hotel recebe push FCM + entrada em `notificacoes_hotel`.
3. Tap:
   - **Antes:** `context.push('/tickets')`.
   - **Agora:** `context.push('/tickets/details/$codigoPublico')`.
4. Hotel vê detalhes, aprova ou rejeita.

### Fluxo D — WhatsApp

1. Guest inicia reserva via bot WPP.
2. Bot coleta dados + cria reserva (canal `WHATSAPP`) — fluxo existente.
3. **Novo:** imediatamente chama `createPagamentoFake({canal:'WHATSAPP'})`:
   - Backend seta `expires_at = NOW() + 30min`.
   - Retorna `pagamento_id`.
4. `whatsappReservation.service.ts` envia:
   - WPP: "Seu link de pagamento: {FRONTEND_URL}/pagamento/:codigoPublico/:pagamentoId — expira em 30 minutos."
   - Email `reservaPendentePagamento`.
5. Guest abre link → `WhatsappPaymentPage`:
   - Consulta `GET /pagamentos/:id` a cada 5s para atualizar timer e detectar cancelamento/expiração.
   - Mostra radios + botão único "Pagar" (sem Cancelar).
6. Guest paga → `POST /.../confirmar` → 200.
7. Handler (`_aplicarAprovacao`) envia WPP + email `reservaConfirmada` com link `/reservas/:codigoPublico`.

Alternativa 5b — Timer zera:
- Job (`paymentExpiration.job.ts`) detecta `expires_at < NOW()` + status `PENDENTE`:
  - Marca pagamento `CANCELADO`, reserva `CANCELADA`.
  - Envia WPP + email `reservaExpirada`.
- Se guest ainda estiver na `WhatsappPaymentPage`, o polling detecta `status = CANCELADO` e exibe overlay "Link expirado".

---

## Dependências

**Bibliotecas Flutter:**
- [x] `dio`, `flutter_riverpod`, `go_router`, `url_launcher`, `flutter_svg` — presentes
- [ ] `mask_text_input_formatter: ^2.9.0` — **verificar/adicionar**

**Bibliotecas Backend:**
- [ ] `nodemailer: ^6.9.x` + `@types/nodemailer` — **adicionar**
- [ ] `express-rate-limit: ^7.x` — **adicionar**

**Outras features:**
- [x] P5-C, P5-D, P0 prontas
- [x] WhatsApp service operacional
- [x] FCM hotel/user operacional

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Migration de `email_hospede`/`expires_at` em múltiplos tenants | Padrão `_ensureXxx` idempotente executado na primeira chamada relevante de cada tenant; logar aplicação |
| Job de expiração não roda (processo caído) | Se backend sobe de novo, job processa backlog de uma vez; aceitável |
| SMTP mal configurado → emails não saem | `email.service.ts` loga warn e persiste em tabela `email_log` opcional; fluxo principal não bloqueia |
| Rate-limit muito agressivo trava apresentação | Config via `.env` (`RATE_LIMIT_*`); em dev subir threshold |
| Usuário fecha sheet pelo back do Android | `isDismissible: false` + override `WillPopScope`/`PopScope`; fecha apenas via botões |
| Datas com timezone errado (UTC vs local) | Sempre serializar `YYYY-MM-DD` (sem hora); backend e frontend tratam como "data civil" sem TZ |
| Guest com CPF válido mas fictício | Aceitável pra MVP; validação fiscal real fora do escopo |
| `mask_text_input_formatter` e validators divergirem | Validators recebem valor **despmascarado**; máscara é só UX |
| Timer do WhatsappPaymentPage dessincroniza vs servidor | Usar `expires_at` absoluto do servidor + `DateTime.now()` local; não contar down localmente |
| Concorrência: user clica "Pagar" duas vezes rápido | Backend valida `status='PENDENTE'` na UPDATE com guarda; segunda retorna 409 |
| `PublicTicketPage` precisa respeitar layout isolado | Usar `GoRoute` fora do `ShellRoute`, `Scaffold` próprio sem bottom-nav |
| Link do email deve abrir no app (deep link) | Configurar `app_links`/scheme em pubspec + `AndroidManifest`/`Info.plist`; se fora do escopo, abrir em web (PWA) |

---

## Plano de Implementação (ordem sugerida)

1. **Backend schema**: função `_ensureGuestReservaColumns` aplicando as 2 migrations idempotentes; chamada no boot.
2. **Backend email**: `email.service.ts` + 3 templates + teste de envio manual via script.
3. **Backend guest**: `createReservaGuest` + validação + controller + rota + app.ts.
4. **Backend pagamento fake**: extrair `_aplicarAprovacao` de `_handleWebhook`; criar 4 funções fake (create/get/confirmar/cancelar); controllers + rotas.
5. **Backend job**: `paymentExpiration.job.ts` + start no bootstrap.
6. **Backend WhatsApp**: modificar `whatsappReservation.service.ts` para gerar pagamento fake + enviar WPP/email.
7. **Frontend deps**: `mask_text_input_formatter` no pubspec; extrair validators.
8. **Frontend widgets**: `GuestInfoForm`, `PaymentBottomSheet`.
9. **Frontend páginas**: `ReservationSuccessPage`, `PublicTicketPage`, `WhatsappPaymentPage`.
10. **Frontend rotas + router**: queryParams de data, rotas novas não-protegidas.
11. **Frontend checkout**: refactor `CheckoutPage` + `CheckoutNotifier` + `BookingService`.
12. **Frontend disponibilidade**: `availability_checker.dart` + `room_details_page.dart` passam datas via queryParam.
13. **Frontend notificações**: 2 ajustes em notifications_page.dart e notification_service.dart.
14. **Smoke test manual**: 4 fluxos (user, guest, hotel approval, WPP) + verificar emails + verificar expiração.

---

## Testes Automatizados Mínimos (novos)

**Backend:**
- `createReservaGuest` payload válido → reserva criada com `user_id = null`.
- `createReservaGuest` CPF inválido → 400.
- `createReservaGuest` email inválido → 400.
- `createPagamentoFake` reserva inexistente → 404.
- `createPagamentoFake` idempotente: 2ª chamada com pendente → 409.
- `confirmarPagamentoFake` com status já `APROVADO` → 409.
- `confirmarPagamentoFake` dispara `_aplicarAprovacao` (mock: FCM + email chamados).
- `paymentExpiration.job` marca pagamento `CANCELADO` quando `expires_at < NOW()`.

**Frontend (widget tests):**
- `GuestInfoForm` rejeita CPF inválido.
- `PaymentBottomSheet` não fecha em tap fora (`isDismissible: false`).
- `CheckoutPage` com `initialCheckin`/`initialCheckout` renderiza campos travados.
- Router: `/reservas/:codigoPublico` acessível sem auth (não redirect para login).

---

## Critérios de Aceitação

Ver `conductor/task/BUG-fluxo-reserva.md` — mesma lista.
