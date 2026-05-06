# BUG-13 — bot (chat RAG) - Finalização de Reserva e Coleta de Email

## Arquivo principal (backend)
`Backend/src/agent/` (AgentOrchestratorService, fluxo de reserva)
`Backend/src/chat/` (gerenciamento de sessão e estado da conversa)

## Prioridade
**Alta** — o bot anuncia que a reserva foi feita mas não cria o ticket nem envia notificação

## Branch sugerida
`fix/bot-reservation-flow`

---

## Bugs

### 1. Bot não solicita email antes de finalizar a reserva

**Comportamento atual:**
- O bot consulta quarto e hotel, chega até a etapa de solicitar a reserva, mas **não pede o email** do usuário
- O email é fundamental para enviar o ticket de confirmação

**O que corrigir:**
- [ ] No fluxo de reserva do `AgentOrchestratorService`, adicionar a etapa de coleta de email **antes** de criar a reserva
- [ ] Se o usuário estiver autenticado (JWT presente na sessão), usar o email do `userId` — não perguntar novamente
- [ ] Se o usuário **não** estiver autenticado, o bot deve obrigatoriamente perguntar o email antes de prosseguir
- [ ] Validar o formato do email coletado antes de continuar o fluxo
- [ ] Persistir o email na sessão do chat para não perguntar novamente durante a mesma conversa

### 2. Reserva anunciada como feita mas não criada

**Comportamento atual:**
- O bot retorna mensagem confirmando que a reserva foi realizada
- A reserva **não aparece** no painel do hotel (sem notificação recebida)
- O ticket **não é gerado** para o usuário

**O que verificar e corrigir:**

- [ ] **Verificar se o `AgentOrchestratorService` de fato chama `POST /usuarios/reservas`** ao concluir o fluxo de reserva, ou se apenas simula a confirmação na resposta do bot
- [ ] Se a chamada existe, verificar se está usando o token JWT correto (usuário autenticado) ou se está falhando silenciosamente por falta de autenticação
- [ ] Verificar se erros na criação da reserva estão sendo capturados e tratados — um `try/catch` que engole o erro e retorna "reserva feita" de qualquer forma seria a causa do comportamento
- [ ] Após a reserva ser criada com sucesso no backend:
  - O hotel deve receber a notificação (verificar `NotificationService` ou WebSocket)
  - O ticket deve aparecer na `tickets_page` do usuário
- [ ] Adicionar log/trace no fluxo de reserva do bot para facilitar debugging

### 3. Garantir consistência entre bot e app

- [ ] Uma reserva feita via bot deve aparecer na `tickets_page` do app exatamente igual a uma reserva feita pelo fluxo normal
- [ ] O `codigo_publico` gerado deve ser enviado ao usuário pelo bot como confirmação (ex: "Reserva confirmada! Seu código é RA-XXXXX")
- [ ] Se o email foi coletado pelo bot, enviar o ticket de confirmação para esse email

---

## Fluxo esperado após a correção

```
Usuário no chat
  └─ Consulta quarto disponível
       └─ Bot confirma disponibilidade
            └─ Usuário solicita reserva
                 └─ Bot verifica autenticação
                      ├─ Autenticado: usa email do JWT
                      └─ Não autenticado: pede email → valida formato
                           └─ Bot chama POST /usuarios/reservas
                                ├─ Sucesso: "Reserva RA-XXXXX confirmada! Você receberá um e-mail."
                                │           + notificação para o hotel
                                └─ Erro: "Não foi possível concluir a reserva. [motivo]"
```

---

## Dependências
- BUG-7 (tickets) — a reserva criada pelo bot deve aparecer corretamente na tickets_page
- P6-F (chat RAG integration) — esta task é uma correção de bug sobre a task P6-F; verificar o estado atual da implementação antes de iniciar

## Observações
- Não refatorar o bot inteiro — focar especificamente no fluxo de reserva e coleta de email
- Adicionar testes manuais documentados: chat → reserva → verificar ticket no app + notificação no hotel
