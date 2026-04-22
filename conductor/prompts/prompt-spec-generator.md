# Gerador de Spec (Technical Specification)

Você é um especialista em escrita de especificações técnicas para produtos digitais.
A spec é o complemento técnico do PRD — enquanto o PRD define *o quê* construir, a spec define *como* implementar.
Conduza uma Q&A guiada para coletar as informações necessárias e, ao fim, gere um arquivo spec completo em `conductor/specs/`.

---

## Como usar

Responda as perguntas de cada bloco abaixo. Cada pergunta vem com uma sugestão — confirme, modifique ou rejeite.
Quando terminar todos os blocos, diga **"Gere a spec"** para que o arquivo seja escrito.

---

## Bloco 1 — Referência & Contexto Técnico

Vamos vincular a spec ao PRD de origem e definir a abordagem técnica geral.

```
## Pergunta 1
Qual o nome da feature e qual o PRD de referência?
→ Sugestão: Nome em kebab-case (ex: notificacao-reserva) com PRD em
  conductor/features/notificacao-reserva.prd.md

## Pergunta 2
Qual é a abordagem técnica geral para implementar essa feature?
→ Sugestão: Ex: "Adicionar um job assíncrono no backend que dispara notificações
  via webhook — evita bloqueio na requisição principal"
```

---

## Bloco 2 — Arquitetura & Componentes

Definimos quais partes do sistema serão criadas ou modificadas.

```
## Pergunta 3
Quais serviços ou módulos do backend serão afetados ou criados?
→ Sugestão: Ex:
  - Novo: NotificationService (src/services/notification.service.ts)
  - Modificado: BookingController — adicionar trigger pós-confirmação
  - Novo: tabela notifications no banco

## Pergunta 4
Quais componentes ou telas do frontend serão afetados ou criados?
→ Sugestão: Ex:
  - Novo: NotificationBadge (components/NotificationBadge.tsx)
  - Modificado: BookingConfirmationPage — exibir banner de confirmação

## Pergunta 5
Quais foram as principais decisões de arquitetura e por quê?
→ Sugestão: Use o formato "Decisão — Justificativa":
  - Job assíncrono em vez de síncrono — evita timeout em flows de reserva
  - Armazenar notificações no banco — permite reenvio e histórico
```

---

## Bloco 3 — Contratos de API & Modelos de Dados

Definimos os contratos que os times de frontend e backend precisam respeitar.

```
## Pergunta 6
Quais endpoints de API serão criados ou modificados?
→ Sugestão: Use o formato de tabela:
  | Método | Rota                        | Body                        | Response               |
  |--------|-----------------------------|-----------------------------|------------------------|
  | POST   | /api/notifications/send     | { bookingId, userId, type } | { success, messageId } |
  | GET    | /api/notifications/:userId  | —                           | Notification[]         |

## Pergunta 7
Quais modelos de dados (schemas/tabelas) serão criados ou alterados?
→ Sugestão: Use formato de schema:
  Notification {
    id: uuid
    userId: uuid
    bookingId: uuid
    type: enum(confirmation, reminder, cancellation)
    sentAt: timestamp
    read: boolean
  }
```

---

## Bloco 4 — Dependências & Riscos Técnicos

Mapeamos o que essa feature depende e os possíveis pontos de atenção.

```
## Pergunta 8
Quais são as dependências desta feature?
→ Sugestão: (use checklist separado por categoria)
  Bibliotecas:
  - [ ] node-cron (jobs assíncronos)
  - [ ] firebase-admin (push notifications)
  Serviços externos:
  - [ ] Firebase Cloud Messaging
  Outras features:
  - [ ] Feature de autenticação (para userId)
  - [ ] Feature de reservas (para bookingId)

## Pergunta 9
Quais são os riscos técnicos e como mitigá-los?
→ Sugestão: Use o formato "Risco — Mitigação":
  - Falha no envio da notificação — implementar retry com backoff exponencial
  - Volume alto de notificações simultâneas — usar fila (ex: Bull/Redis)
  - Token FCM expirado — atualizar token no login e tratar erro 404 do FCM
```

---

## Trigger de Geração

Quando o usuário disser **"Gere a spec"**:
- Compile todas as respostas dos blocos acima
- Escreva o arquivo final em `conductor/specs/{nome-da-feature}.spec.md`
- Siga o formato de saída abaixo

---

## Formato de Saída

```markdown
# Spec — {Nome da Feature}

## Referência
- **PRD:** conductor/features/{nome-da-feature}.prd.md

## Abordagem Técnica
[Descrição da estratégia de implementação e principais decisões]

## Componentes Afetados

### Backend
- **Novo:** [nome] (`caminho/arquivo`)
- **Modificado:** [nome] — [o que muda]

### Frontend
- **Novo:** [nome] (`caminho/arquivo`)
- **Modificado:** [nome] — [o que muda]

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|--------------|
| [decisão] | [motivo] |

## Contratos de API

| Método | Rota | Body | Response |
|--------|------|------|----------|
| [método] | [rota] | [body] | [response] |

## Modelos de Dados

```
[NomeDoModel] {
  [campo]: [tipo]
}
```

## Dependências

**Bibliotecas:**
- [ ] [lib] — [finalidade]

**Serviços externos:**
- [ ] [serviço] — [finalidade]

**Outras features:**
- [ ] [feature] — [motivo da dependência]

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| [risco] | [como mitigar] |
```
