# Context: Push Notifications & Inbox — ReservAqui Backend

> Last updated: 2026-04-15T07:00:00Z
> Version: 1

## Purpose

Sistema de notificações em tempo real (<2s) para o ReservAqui.
Cobre dois canais distintos:
- **Push via FCM** (Firebase Cloud Messaging) — entrega imediata ao dispositivo (app Flutter do hóspede + dashboard web do hotel)
- **Inbox persistente** (`notificacao_hotel`) — histórico de alertas legível pelo hotel no dashboard

Os quatro eventos de negócio notificados são:
1. Hóspede cria reserva → hotel recebe push + entrada na inbox
2. Hotel aprova reserva → hóspede recebe push
3. Pagamento confirmado (webhook InfinitePay) → ambos recebem push + hotel recebe inbox *(ponto de chamada documentado, não conectado até InfinitePay ser integrado)*
4. Hóspede cancela reserva → hotel e hóspede recebem push + hotel recebe inbox

## Architecture / How It Works

### Camada FCM (`fcm.service.ts`)

Wrapper do Firebase Admin SDK com inicialização lazy e graceful no-op:
- Na primeira chamada, tenta parsear `FIREBASE_SERVICE_ACCOUNT` do `.env` (JSON minificado da service account)
- Se a variável não estiver definida ou for inválida: loga `console.warn` e retorna sem erro — o fluxo de negócio não é interrompido
- Se definida: inicializa `firebase-admin` uma única vez (flag `initialized`)
- Usa `sendEachForMulticast` para enviar para múltiplos tokens em um único request FCM
- Tokens inválidos/expirados retornados pelo FCM são deletados de `dispositivo_fcm` em fire-and-forget (`_removeInvalidTokens`)

### Registro de tokens (`dispositivo_fcm`)

Tabela no master DB. Cada dispositivo que faz login armazena seu token FCM.
- `POST /api/dispositivos-fcm/usuario` + `authGuard` → registra token do hóspede
- `POST /api/dispositivos-fcm/hotel`   + `hotelGuard` → registra token do hotel
- `DELETE /api/dispositivos-fcm/usuario` + `authGuard` → remove token no logout
- `DELETE /api/dispositivos-fcm/hotel`   + `hotelGuard` → remove token no logout
- UPSERT via `ON CONFLICT (fcm_token)`: token que migra de conta atualiza `user_id`/`hotel_id`

### Inbox do hotel (`notificacao_hotel`)

Tabela no tenant DB. Persiste notificações do hotel para leitura no dashboard.
- `GET  /api/hotel/notificacoes?nao_lidas=true` + `hotelGuard` → lista (todas ou só não lidas, máx 100)
- `PATCH /api/hotel/notificacoes/:id/lida`     + `hotelGuard` → marca uma como lida (idempotente)
- `PATCH /api/hotel/notificacoes/lida-todas`   + `hotelGuard` → marca todas como lidas

A rota `/lida-todas` é registrada **antes** de `/:id/lida` no router para evitar que a string `"lida-todas"` seja capturada como um `:id` numérico.

### Hooks em `reserva.service.ts`

Os 4 eventos são disparados em **fire-and-forget** via `Promise.all([...]).catch(() => {})`:
- Falhas de push/inbox **nunca** interrompem o fluxo de negócio (reserva salva normalmente)
- `insertNotificacao` em `notificacaoHotel.service.ts` já tem try/catch interno adicional

| Ponto de disparo | Arquivo | Função privada | O que dispara |
|-----------------|---------|----------------|---------------|
| Nova reserva (APP) | `reserva.service.ts` | `_createReservaUsuario` | FCM → tokens do hotel + INSERT inbox `NOVA_RESERVA` |
| Aprovação | `reserva.service.ts` | `_updateStatus` (status=`APROVADA`) | FCM → tokens do usuário + INSERT inbox `APROVACAO_RESERVA` |
| Cancelamento pelo hóspede | `reserva.service.ts` | `_cancelarReservaUsuario` | FCM → tokens do hotel + FCM → tokens do usuário + INSERT inbox `RESERVA_CANCELADA` |
| Pagamento confirmado | *(futuro webhook InfinitePay)* | — | Ponto ainda não conectado — será adicionado ao handler do webhook |

### Configuração do Firebase (quando o projeto for criado)

1. Firebase Console → Project Settings → Service accounts → **Generate new private key**
2. Abrir o `.json` baixado e minificar (remover quebras de linha)
3. Adicionar no `.env`:
   ```
   FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"...","private_key":"..."}
   ```
4. Reiniciar o servidor — FCM passa a funcionar automaticamente sem nenhuma alteração de código

## Affected Project Files

| File | Uses this system? | Relationship |
|------|:-----------------:|--------------|
| `Backend/src/services/fcm.service.ts` | Yes | Wrapper Firebase Admin SDK — `sendPush`, `getHotelTokens`, `getUserTokens` |
| `Backend/src/entities/DispositivoFcm.ts` | Yes | Valida `fcm_token` e `origem` (DASHBOARD_WEB / APP_IOS / APP_ANDROID) |
| `Backend/src/services/dispositivoFcm.service.ts` | Yes | Registra/remove tokens FCM no master DB com UPSERT |
| `Backend/src/controllers/dispositivoFcm.controller.ts` | Yes | Handlers para registro e remoção de token |
| `Backend/src/routes/dispositivoFcm.routes.ts` | Yes | 4 endpoints: POST/DELETE × usuario/hotel |
| `Backend/src/services/notificacaoHotel.service.ts` | Yes | Listar, marcarLida, marcarTodasLidas, insertNotificacao (interno) |
| `Backend/src/controllers/notificacaoHotel.controller.ts` | Yes | Handlers HTTP → service calls |
| `Backend/src/routes/notificacaoHotel.routes.ts` | Yes | 3 endpoints com hotelGuard; `/lida-todas` antes de `/:id/lida` |
| `Backend/src/services/reserva.service.ts` | Modified | Importa `sendPush`, `getHotelTokens`, `getUserTokens`, `insertNotificacao`; hooks nos 3 eventos ativos |
| `Backend/src/app.ts` | Modified | Monta `/api/dispositivos-fcm` e `/api/hotel/notificacoes` |
| `Backend/database/scripts/init_master.sql` | Read-only | Tabela `dispositivo_fcm` com constraint `chk_fcm_proprietario` (user_id XOR hotel_id) |
| `Backend/database/scripts/init_tenant.sql` | Read-only | Tabela `notificacao_hotel` com `lida_em`, `acao_requerida`, `payload JSONB` |

## Code Reference

### `Backend/src/services/fcm.service.ts` — `sendPush(tokens, payload)`

```typescript
export async function sendPush(tokens: string[], payload: FcmPayload): Promise<void> {
  if (!tokens.length) return;
  if (!_init()) {
    console.warn('[FCM] FIREBASE_SERVICE_ACCOUNT não configurado — push não enviado:', payload.title);
    return;
  }
  // sendEachForMulticast → detecta tokens inválidos → _removeInvalidTokens fire-and-forget
}
```

**How it works:** Inicializa Firebase Admin uma vez (lazy). Sem credenciais: no-op com warn. Com credenciais: `sendEachForMulticast` + limpeza automática de tokens mortos.
**Coupling / side-effects:** Deleta tokens inválidos de `dispositivo_fcm` em background após falha de entrega.

### `Backend/src/services/notificacaoHotel.service.ts` — `insertNotificacao(hotelId, input)`

```typescript
export async function insertNotificacao(hotelId: string, input: CreateNotificacaoInput): Promise<void> {
  try {
    const schemaName = await _getSchemaName(hotelId);
    await withTenant(schemaName, async (client) => {
      await client.query(`INSERT INTO notificacao_hotel ...`, [...]);
    });
  } catch (err) {
    console.error('[NotificacaoHotel] Erro ao inserir notificação:', err);
    // falha silenciosa — não propaga
  }
}
```

**How it works:** Try/catch interno garante que falha na inbox nunca quebra o fluxo de negócio. Chamado dentro do `Promise.all([...]).catch(() => {})` em `reserva.service.ts` — dupla proteção.
**Coupling / side-effects:** Usa `withTenant` + `_getSchemaName` → depende do hotel estar ativo no master DB.

### Hook em `reserva.service.ts` — padrão fire-and-forget

```typescript
// Padrão usado nos 3 pontos de evento
Promise.all([
  getHotelTokens(hotelId).then(tokens => sendPush(tokens, { ... })),
  insertNotificacao(hotelId, { ... }),
  getUserTokens(userId).then(tokens => sendPush(tokens, { ... })), // quando aplicável
]).catch(() => {});
```

**How it works:** `Promise.all` paraleliza FCM e inbox. `.catch(() => {})` no final garante que qualquer falha é descartada silenciosamente — a reserva já foi salva antes deste bloco.

## Key Design Decisions

- **Fire-and-forget para todos os hooks:** Notificações são side effects opcionais. Uma falha de FCM ou de INSERT na inbox não deve reverter uma reserva já confirmada no banco.
- **Graceful no-op sem Firebase:** O projeto Firebase ainda não existe. O backend funciona normalmente sem `FIREBASE_SERVICE_ACCOUNT` — apenas loga um warn por chamada. Quando o projeto for criado, basta adicionar a variável.
- **`_removeInvalidTokens` em background:** Tokens expirados são comuns em apps móveis (desinstalação, logout sem chamar DELETE). A limpeza automática evita acúmulo de tokens mortos sem bloquear o envio.
- **Inbox apenas para hotel:** O hóspede usa `historico_reserva_global` (master DB) como fonte de verdade do estado das suas reservas — não há `notificacao_usuario` no schema.
- **Dois endpoints DELETE separados (usuario/hotel):** Evita lógica de "qual guard deu pass?" — cada cliente sabe qual rota usar no logout.
- **`/lida-todas` antes de `/:id/lida` no router:** Ordem importa no Express — se `/:id` viesse primeiro, a string literal `"lida-todas"` seria capturada como id e falharia silenciosamente na conversão `Number()`.

## Changelog

### v1 — 2026-04-15
- `fcm.service.ts` criado com inicialização lazy, graceful no-op, `sendEachForMulticast`, limpeza automática de tokens inválidos
- `firebase-admin` instalado como dependência (`npm install firebase-admin`)
- CRUD de `dispositivo_fcm`: entity + service + controller + 4 endpoints (POST/DELETE × usuario/hotel)
- CRUD de `notificacao_hotel`: service + controller + 3 endpoints (listagem, marcar lida, marcar todas lidas)
- Hooks adicionados em `reserva.service.ts`: nova reserva (→ hotel), aprovação (→ usuário), cancelamento (→ hotel + usuário)
- Ponto de hook para pagamento confirmado documentado mas não conectado (aguarda webhook InfinitePay)
- TypeScript compilando sem erros
