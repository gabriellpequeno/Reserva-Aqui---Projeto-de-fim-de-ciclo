# BUG-13 — Bot (Chat RAG) — Finalização de Reserva, Notificação e Consulta

## Arquivos principais (backend)
- `Backend/src/services/ai/tools.ts` (tool `criar_reserva` + nova `consultar_reserva`)
- `Backend/src/services/ai/contextResolver.service.ts` (ChatContext)
- `Backend/src/services/ai/agentOrchestrator.service.ts` (system prompt)
- `Backend/src/services/reserva.service.ts` (service layer reutilizado)

## Prioridade
**Alta** — reserva via bot não notifica hotel, não aparece na tickets_page, canal_origem errado

## Branch sugerida
`fix/bug-13-bot-reservation-flow`

---

## Problemas confirmados

1. Tool `criar_reserva` faz INSERT direto no banco, ignorando side-effects do `reserva.service.ts`:
   - ❌ Não chama `insertNotificacao` → hotel não recebe notificação no painel
   - ❌ Não chama `sendPush` → hotel não recebe push FCM
   - ❌ Não chama `_upsertHistoricoGlobal` → reserva não aparece na `tickets_page`
   - ❌ Não chama `_ensureReservaFluxoColumns` → colunas extras podem não existir
2. `canal_origem` hardcoded como `'WHATSAPP'` mesmo quando vem do chat do APP Flutter
3. Email do hóspede nunca é coletado para walk-in (guest sem login)
4. Não existe tool para consultar status de reserva existente
5. `codigo_publico` não é exibido na mensagem de confirmação do bot

---

## O que fazer

### T1 — Refatorar `criar_reserva` → chamar `reserva.service` ✅ crítico

**Arquivo:** `Backend/src/services/ai/tools.ts`

**Antes:** INSERT direto via SQL + `sendPaymentLinkViaWhatsApp`
**Depois:** Chamar service functions existentes

- [ ] Criar novo input type `CreateReservaChatInput` com campos mínimos:
  - `hotel_id` (obrigatório — do context)
  - `quarto_id` (obrigatório — coletado pelo bot)
  - `num_hospedes` (obrigatório)
  - `data_checkin` (obrigatório — YYYY-MM-DD)
  - `data_checkout` (obrigatório — YYYY-MM-DD)
  - `walkInNome` (obrigatório quando não autenticado)
  - `walkInEmail` (obrigatório quando não autenticado)

- [ ] Se `context.userId` existe → chamar `createReservaUsuario()` do `reserva.service.ts`
  - Passa `hotel_id`, `quarto_id`, `num_hospedes`, `data_checkin`, `data_checkout`
  - O service já cuida de: validação, cálculo de valor, notificação, histórico

- [ ] Se `context.userId` é null → chamar uma versão adaptada ou criar `createReservaChat()` no `reserva.service.ts`
  - Campos mínimos: `nome_hospede` + `email_hospede` (sem CPF, sem telefone)
  - O service cuida do resto

- [ ] Atualizar schema Zod da tool:
  - Remover `walkInCpf`
  - Adicionar `walkInEmail` com description clara pro LLM
  - Manter `walkInNome`

- [ ] Retornar `codigo_publico` formatado na mensagem de sucesso:
  ```
  SUCESSO! Reserva criada com código RA-XXXXX. Status: AGUARDANDO_PAGAMENTO.
  Datas: {checkin} a {checkout}. Valor total: R$ {valor}.
  O hóspede receberá confirmação no email informado.
  ```

- [ ] Tratar erros do service e devolver mensagem clara pro modelo (não alucinar sucesso)

### T2 — Adicionar `canal` ao ChatContext

**Arquivo:** `Backend/src/services/ai/contextResolver.service.ts`

- [ ] Adicionar ao SELECT: `s.canal as "canal"`
- [ ] Adicionar à interface `ChatContext`: `canal: 'APP' | 'WHATSAPP'`
- [ ] Na tool `criar_reserva`, usar `context.canal` para definir `canal_origem`

### T3 — Criar tool `consultar_reserva`

**Arquivo:** `Backend/src/services/ai/tools.ts`

- [ ] Nova tool `consultar_reserva` com schema:
  - `codigoPublico` (string, obrigatório) — código público da reserva (ex: "RA-XXXXX")

- [ ] Internamente:
  - Chamar `getReservaByCodigoPublico()` do `reserva.service.ts`
  - Retornar: status, datas, nome do hotel, tipo de quarto, valor total
  - **Não retornar dados sensíveis** (CPF, email, telefone)

- [ ] Segurança: antes de revelar detalhes, pedir confirmação do nome do hóspede
  - Incluir na description da tool: "Após buscar, peça ao usuário confirmar o nome do hóspede antes de revelar detalhes."

- [ ] Registrar a tool no array de tools do `handleReserva` no orchestrator

### T4 — Criar `createReservaChat()` no `reserva.service.ts`

**Arquivo:** `Backend/src/services/reserva.service.ts`

- [ ] Nova função pública `createReservaChat()` que aceita dados mínimos:
  ```typescript
  interface CreateReservaChatInput {
    hotel_id:       string;
    quarto_id:      number;
    num_hospedes:   number;
    data_checkin:   string;
    data_checkout:  string;
    canal_origem:   CanalOrigem;
    sessao_chat_id: string;
    // Hóspede autenticado
    user_id?:       string;
    // Hóspede anônimo (mínimo: nome + email)
    nome_hospede?:  string;
    email_hospede?: string;
  }
  ```

- [ ] Internamente reutiliza a lógica existente:
  - `_ensureReservaFluxoColumns()`
  - Cálculo de `valor_total` via `quarto.valor_override ?? categoria.preco_base`
  - INSERT na tabela `reserva` com `canal_origem` correto
  - `_upsertHistoricoGlobal()` (se `user_id` presente)
  - `_upsertReservaRouting()`
  - `insertNotificacao()` + `sendPush()` (fire-and-forget)
  - `sendPaymentLinkViaWhatsApp()` (fire-and-forget)

### T5 — Atualizar system prompt do agente

**Arquivo:** `Backend/src/services/ai/agentOrchestrator.service.ts`

- [ ] No `handleReserva`, atualizar o `systemPrompt` para incluir:
  - "Se o usuário NÃO estiver autenticado, você DEVE coletar o NOME COMPLETO e EMAIL antes de chamar criar_reserva."
  - "Após criar a reserva, informe o código público ao usuário."
  - "Se o usuário perguntar sobre uma reserva existente, use a ferramenta consultar_reserva."

---

## Endpoints usados

| Método | Rota                   | Auth | Descrição                    |
|--------|------------------------|------|------------------------------|
| POST   | `/chat/message`        | ❌*  | Enviar mensagem ao bot       |

> *JWT opcional: se presente, enriquece a sessão com `userId`.

---

## Dependências
- **Requer:** P6-F (chat RAG integration) — já implementado ✅
- **Backend existente:** `reserva.service.ts`, `notificacaoHotel.service.ts`, `ContextResolverService` — todos prontos ✅
- **Não mexer em:** RAG (`rag.service.ts`, `dynamicIngestion.service.ts`) — fora do escopo

## Bloqueia
- Reservas via bot gerando tickets visíveis no app
- Hotel recebendo notificação de reservas via bot
- Consulta de status de reserva pelo chat

---

## Checklist de verificação

- [x] Reserva via bot (APP) → hotel recebe notificação no painel
- [x] Reserva via bot (APP) → reserva aparece na `tickets_page` (se autenticado)
- [x] Reserva via bot (APP) → `canal_origem = 'APP'`
- [x] Reserva via bot (WPP) → `canal_origem = 'WHATSAPP'`
- [x] Guest sem login → bot pede nome + email (não CPF)
- [x] Guest sem login → recebe email com link de pagamento
- [x] `codigo_publico` exibido na confirmação
- [x] `consultar_reserva` → retorna status da reserva
- [x] `consultar_reserva` → pede confirmação do nome antes de revelar detalhes
- [x] Erro no service → bot NÃO anuncia sucesso falso

---

## Observações

- **Não criar endpoint REST novo** — tudo acontece dentro das tools do `AgentOrchestratorService`
- **Não mexer no fluxo guest do APP** (`CreateReservaGuestInput` continua exigindo 4 campos pra quem reserva pelo formulário)
- **Tempo estimado:** ~25 minutos (T1: 10min, T2: 5min, T3: 5min, T4: 5min, T5: 2min)
- **RAG fora do escopo:** A questão do `DynamicIngestionService` só rodar no seed é um issue separado (não afeta reservas)
