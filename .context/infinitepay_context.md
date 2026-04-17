# Context: Pagamentos — InfinitePay

> Last updated: 2026-04-15T08:00:00Z
> Version: 1

## Purpose

Integração de pagamento do ReservAqui com a InfinitePay.
O hotel gera um link de checkout para o hóspede; a InfinitePay notifica o backend via webhook quando o pagamento é confirmado.
Os dados da reserva (hotel, quarto, datas, hóspede) são enviados à InfinitePay para pré-preencher o checkout.

---

## Architecture / How It Works

### Fluxo completo

```
1. Hotel clica "Gerar link de pagamento" no dashboard
   POST /api/hotel/reservas/:reserva_id/pagamentos  (hotelGuard)
   │
   ├── Backend busca reserva + categoria do quarto + dados do usuário (master)
   ├── Monta descrição rica: "Hospedagem em {hotel} | Tipo: {quarto} | Check-in: ... | ..."
   ├── Converte valor_total para centavos (× 100)
   ├── Chama InfinitePay POST /invoices/public/checkout/links
   │     ├── handle         = INFINITEPAY_HANDLE (.env)
   │     ├── itens[0]       = { quantity:1, price: centavos, description: ... }
   │     ├── order_nsu      = reserva.codigo_publico  ← chave de roteamento no webhook
   │     ├── webhook_url    = BACKEND_URL + /api/pagamentos/webhook/infinitepay
   │     ├── redirect_url   = FRONTEND_URL + /reservas/{codigo_publico}/pagamento-concluido
   │     └── customer       = { name, email, phone_number }  (se disponível)
   ├── Recebe checkout_url
   ├── INSERT pagamento_reserva (status=PENDENTE, checkout_url)
   ├── UPDATE reserva SET status = 'AGUARDANDO_PAGAMENTO'
   └── FCM push ao hóspede com checkout_url (tipo: APROVACAO_RESERVA)

2. Hóspede acessa checkout_url e paga

3. InfinitePay chama webhook
   POST /api/pagamentos/webhook/infinitepay  (sem auth)
   │
   ├── Responde 200 IMEDIATAMENTE (InfinitePay exige <1s — retenta em 400)
   ├── Processa em background:
   │     ├── Resolve tenant via reserva_routing (order_nsu = codigo_publico)
   │     ├── UPDATE pagamento_reserva: status=APROVADO + invoice_slug + transaction_nsu + metodo + recibo
   │     │     └── ON CONFLICT (uq_pagamento_invoice_slug) → idempotência: webhook duplicado não faz nada
   │     ├── UPDATE reserva SET status = 'APROVADA'
   │     ├── setQuartoDisponivel(false)  se quarto_id preenchido
   │     ├── UPSERT historico_reserva_global → status APROVADA
   │     └── FCM PAGAMENTO_CONFIRMADO → hotel (push + inbox) + hóspede (push)
   └── Erros logados com console.error — nunca retornam 400 para evitar retentativas infinitas
```

### Idempotência do webhook

A InfinitePay retenta o webhook se receber 400. Para evitar processar o mesmo pagamento duas vezes:

1. Constraint `uq_pagamento_invoice_slug UNIQUE (infinite_invoice_slug)` adicionada dinamicamente via `_ensureSlugConstraint()` (executa `DO $$ IF NOT EXISTS ... ALTER TABLE ... ADD CONSTRAINT $$` dentro do tenant)
2. O UPDATE filtra `WHERE reserva_id = ? AND status = 'PENDENTE'` — se já foi processado, 0 linhas afetadas
3. Verificação de `rowCount === 0` → retorna sem executar os side effects novamente

### Chamada à InfinitePay (`_callInfinitePay`)

Usa `https.request` nativo do Node.js (sem dependências extras).
- Timeout de 10 segundos
- Se `INFINITEPAY_HANDLE` não estiver no `.env`, lança `Error('INFINITEPAY_HANDLE não configurado')` → controller retorna 503
- Tenta parsear `checkout_url`, `url` ou `link` da resposta (múltiplos campos por precaução)

### Dados do cliente enviados à InfinitePay

| Fonte | Campo InfinitePay | Condição |
|-------|------------------|----------|
| `usuario.nome_completo` | `customer.name` | Hóspede registrado |
| `usuario.email` | `customer.email` | Hóspede registrado |
| `usuario.numero_celular` | `customer.phone_number` | Hóspede registrado + campo preenchido |
| `reserva.nome_hospede` | `customer.name` | Walk-in |
| `reserva.telefone_contato` | `customer.phone_number` | Walk-in + campo preenchido |

Walk-ins não têm e-mail → `customer.email` omitido.

---

## Affected Project Files

| File | Uses this system? | Relationship |
|------|:-----------------:|--------------|
| `Backend/src/entities/PagamentoReserva.ts` | Yes | Interface `InfinitePayWebhookPayload` + `validateWebhook()` |
| `Backend/src/services/pagamentoReserva.service.ts` | Yes | `createPagamento`, `listPagamentos`, `handleWebhook` |
| `Backend/src/controllers/pagamentoReserva.controller.ts` | Yes | 3 handlers; webhook responde 200 antes de processar |
| `Backend/src/routes/pagamentoReserva.routes.ts` | Yes | `hotelPagamentoRouter` + `webhookPagamentoRouter` |
| `Backend/src/app.ts` | Modified | 2 mounts: `/hotel/reservas/:reserva_id/pagamentos` + `/pagamentos/webhook` |
| `Backend/.env.example` | Modified | Adicionados `INFINITEPAY_HANDLE`, `BACKEND_URL`, `FRONTEND_URL` |
| `Backend/src/services/fcm.service.ts` | Dependency | Push `PAGAMENTO_CONFIRMADO` e `APROVACAO_RESERVA` |
| `Backend/src/services/notificacaoHotel.service.ts` | Dependency | INSERT inbox `PAGAMENTO_CONFIRMADO` |
| `Backend/src/services/quarto.service.ts` | Dependency | `setQuartoDisponivel(false)` na aprovação |
| `Backend/database/scripts/init_tenant.sql` | Read-only | Schema `pagamento_reserva` (campos webhook: slug, nsu, metodo, recibo) |

---

## Code Reference

### `_callInfinitePay(body)` — chamada HTTP à InfinitePay

```typescript
// POST https://api.infinitepay.io/invoices/public/checkout/links
const infinitePayBody = {
  handle:       process.env.INFINITEPAY_HANDLE,
  itens: [{
    quantity:    1,
    price:       Math.round(valor_total * 100),  // centavos
    description: "Hospedagem em {hotel} | Tipo: {quarto} | Check-in: ... | ...",
  }],
  order_nsu:    reserva.codigo_publico,  // ← chave de roteamento no webhook
  webhook_url:  BACKEND_URL + '/api/pagamentos/webhook/infinitepay',
  redirect_url: FRONTEND_URL + '/reservas/{codigo_publico}/pagamento-concluido',
  customer:     { name, email, phone_number },  // opcional
};
// Retorna: checkout_url (string)
```

**Coupling:** Depende de `INFINITEPAY_HANDLE`, `BACKEND_URL`, `FRONTEND_URL` no `.env`. Sem `INFINITEPAY_HANDLE` → lança erro → controller retorna 503.

### `_ensureSlugConstraint(client)` — constraint dinâmica de idempotência

```typescript
// Executado no início de createPagamento e handleWebhook
// DO $$ IF NOT EXISTS ... ALTER TABLE pagamento_reserva ADD CONSTRAINT uq_pagamento_invoice_slug UNIQUE (infinite_invoice_slug)
```

**How it works:** Idempotente via `IF NOT EXISTS`. Garante que um mesmo `invoice_slug` da InfinitePay não gera dois registros `APROVADO`.

### `infinitePayWebhookController` — resposta imediata

```typescript
// Responde 200 ANTES de processar — InfinitePay exige <1s
res.status(200).json({ received: true });

// Processa em background — erros logados, nunca retornam 400
try {
  const payload = PagamentoReserva.validateWebhook(req.body);
  await handleWebhook(payload);
} catch (err) {
  console.error('[Webhook InfinitePay] Erro ao processar:', err);
}
```

**Por que:** Se o processamento demorar >1s ou falhar, a InfinitePay interpretaria como erro e retentaria. O 200 imediato evita retentativas infinitas. Erros reais são visíveis nos logs do servidor.

---

## Variáveis de Ambiente Necessárias

```env
# Sua InfiniteTag (sem o $ do início) — obrigatório para criar links
INFINITEPAY_HANDLE=sua_infinite_tag

# URL pública do backend — usada como webhook_url na criação do link
# Em dev local com ngrok: https://xxxx.ngrok.io
BACKEND_URL=https://api.reservaqui.com

# URL pública do frontend — redirect após pagamento concluído
FRONTEND_URL=https://app.reservaqui.com
```

### Testando localmente com ngrok

A InfinitePay precisa de uma URL pública para entregar o webhook. Em desenvolvimento:

```bash
# Instale ngrok: https://ngrok.com
ngrok http 3000

# Copie a URL gerada (ex: https://abc123.ngrok.io)
# e coloque no .env:
BACKEND_URL=https://abc123.ngrok.io
```

---

## Campos preenchidos pelo Webhook

Estes campos ficam `NULL` até o webhook chegar:

| Campo `pagamento_reserva` | Origem no webhook InfinitePay |
|--------------------------|-------------------------------|
| `infinite_invoice_slug` | `invoice_slug` |
| `transaction_nsu` | `transaction_nsu` |
| `metodo_captura` | `capture_method` (`credit_card` ou `pix`) |
| `recibo_url` | `receipt_url` |
| `forma_pagamento` | derivado de `capture_method` (`PIX` ou `CARTAO_CREDITO`) |

O `order_nsu` enviado na criação do link é o `codigo_publico` da reserva — permite ao webhook localizar o tenant correto sem precisar de nenhuma tabela auxiliar.

---

## Key Design Decisions

- **`order_nsu` = `codigo_publico` da reserva:** Permite roteamento direto no webhook via `reserva_routing` no master DB, sem nenhuma tabela auxiliar ou estado em memória.
- **Resposta 200 imediata no webhook:** InfinitePay exige resposta <1s e retenta em 400. Processar de forma síncrona bloquearia a resposta além do limite. O processamento em background garante que a InfinitePay sempre recebe 200.
- **`_ensureSlugConstraint` dinâmica:** Evita precisar de uma migration formal para adicionar a constraint. Executa uma vez por tenant, é idempotente, e garante que webhooks duplicados não causam pagamentos duplicados.
- **`https` nativo do Node.js:** Evita dependência adicional (`axios`, `node-fetch`) para uma única chamada HTTP ao InfinitePay.
- **Sem auth no webhook:** InfinitePay não envia token. A segurança é garantida por: (1) idempotência via `invoice_slug`, (2) validação do `order_nsu` contra `reserva_routing`, (3) verificação de `status = 'PENDENTE'` antes de processar.

---

## Changelog

### v1 — 2026-04-15
- Integração InfinitePay implementada (Entity + Service + Controller + Routes)
- `POST /api/hotel/reservas/:reserva_id/pagamentos` — gera link com dados ricos da reserva
- `GET  /api/hotel/reservas/:reserva_id/pagamentos` — lista pagamentos
- `POST /api/pagamentos/webhook/infinitepay` — processa confirmação com resposta imediata
- Idempotência via `uq_pagamento_invoice_slug` + filtro `status = PENDENTE`
- Side effects no webhook: `setQuartoDisponivel`, `historico_reserva_global`, FCM `PAGAMENTO_CONFIRMADO`
- TODO de FCM no `_updateStatus` (aprovação) conectado — agora dispara junto com o link de pagamento
- `INFINITEPAY_HANDLE`, `BACKEND_URL`, `FRONTEND_URL` adicionados ao `.env.example`
- TypeScript compilando sem erros
