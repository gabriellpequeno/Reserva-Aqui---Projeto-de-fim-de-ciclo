# Como Funciona o Plano — ReservAqui

## Filosofia

O projeto usa **um único `plan.md`** como checklist vivo de execução.
A separação por feature já existe nas camadas anteriores do pipeline:

```
prd.md              → o que o produto faz (visão de negócio)
features/*.prd.md   → o que ESSA feature faz (user stories)
specs/*.spec.md     → COMO construir tecnicamente (endpoints, tabelas, fluxos)
plan.md             → QUANDO e em que ordem fazer (checklist de tasks)
```

Nunca duplique no `plan.md` informação que já está na spec. O plan é só o tracker.

---

## Estrutura do plan.md

```markdown
# Plan — ReservAqui

## Fase N — Nome da Fase [STATUS]

- [ ] Task 1 da spec
- [ ] Task 2 da spec
- [~] Task em andamento
- [x] Task concluída [sha: abc1234]
```

### Status de cada task

| Símbolo | Significado |
|---------|-------------|
| `[ ]` | Pendente |
| `[~]` | Em progresso (alguém está fazendo agora) |
| `[x]` | Concluída |
| `[sha: abc1234]` | Hash do commit que encerrou a task |

### Status de cada fase

| Tag | Significado |
|-----|-------------|
| `[PENDENTE]` | Ainda não começou |
| `[EM ANDAMENTO]` | Pelo menos uma task em progresso |
| `[CONCLUÍDA]` | Todas as tasks com `[x]` |
| `[checkpoint: abc1234]` | Hash do commit de checkpoint da fase |

---

## De onde vêm as tasks?

**Da spec.** O fluxo é:

```
1. Spec diz: "Criar tabela reservas com campos X, Y, Z"
   → Plan recebe: [ ] Criar tabela reservas

2. Spec diz: "Endpoint POST /reservas com validação de disponibilidade"
   → Plan recebe: [ ] Criar endpoint POST /reservas
                  [ ] Validar disponibilidade de quarto antes de criar

3. Spec diz: "Notificar hóspede via WebSocket ao confirmar reserva"
   → Plan recebe: [ ] Implementar evento WebSocket de confirmação
                  [ ] Consumir evento no app Flutter
```

Uma task deve ser uma unidade de trabalho de **1 a 4 horas**. Se for maior, quebre em duas.

---

## Ciclo de uma task

```
[ ] → abrir spec → codar → testar → commit → [x sha: abc1234]
```

1. Escolha a próxima `[ ]` em ordem sequencial
2. Mude para `[~]` antes de começar
3. Leia a seção correspondente na spec
4. Implemente e teste manualmente
5. Faça o commit
6. Mude para `[x]` e appende o hash: `[x] Criar tabela reservas [sha: d4f91c2]`

---

## Quando adicionar uma nova fase ao plan?

Sempre que uma nova spec for aprovada. O fluxo é:

```
PRD de Feature aprovado
    → Spec escrita e aprovada
        → Nova fase adicionada ao plan.md com as tasks da spec
```

Nunca adicione tasks que não tenham origem em uma spec.

---

## Checkpoint de fase

Ao concluir todas as tasks de uma fase:

1. Verifique manualmente o fluxo completo da feature
2. Faça um commit de checkpoint: `conductor(checkpoint): fim da Fase N — Nome`
3. Registre o hash na linha da fase: `## Fase N — Nome [CONCLUÍDA] [checkpoint: abc1234]`
4. Abra um PR para a `main`

---

## Regras

- `plan.md` é **único** — nunca crie arquivos `.plan.md` por feature
- Tasks vêm **sempre** de uma spec — sem tasks "improvisadas"
- Só marque `[x]` quando a task funcionar **manualmente no fluxo real**
- O plan não tem detalhes técnicos — isso fica na spec
- Atualize o plan no mesmo commit da task sempre que possível
