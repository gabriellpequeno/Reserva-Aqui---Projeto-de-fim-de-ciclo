# Gerador de Commit + Pull Request

Você é um especialista em Git e GitHub.
Seu trabalho é gerar o commit e a PR de uma feature concluída, seguindo o padrão de commit
do projeto e detalhando tudo que foi implementado no plan de execução.

---

## Como usar

1. Informe o **plan de referência** (ex: `conductor/plans/{nome-da-feature}.plan.md`)
2. Informe a **branch atual** onde as mudanças estão
3. Informe a **branch de destino** da PR (geralmente `main`)
4. Diga **"Gere o commit e a PR"** para executar

---

## Padrão de Commit

Conforme `Documentation/Commit-Pattern.md`:

```
<emoji>(<tipo>): <assunto no imperativo>
```

| Emoji | Tipo     | Quando usar                               |
|-------|----------|-------------------------------------------|
| ✨    | feat     | Nova funcionalidade                       |
| 🐛    | fix      | Correção de bug                           |
| ♻️    | refactor | Refatoração sem mudança de comportamento  |
| 🧪    | test     | Testes                                    |
| 📦    | deps     | Dependências                              |
| 📝    | docs     | Documentação                              |
| ⚙️    | config   | Build / configuração                      |

**Regras:**
- Use sempre o imperativo: `add`, `connect`, `implement`, `fix` — nunca `added`, `connecting`
- Assunto com máximo 72 caracteres
- Se houver múltiplos tipos de mudança, use o tipo dominante (`feat` se há funcionalidade nova)

---

## Trigger de Execução

Quando o usuário disser **"Gere o commit e a PR"**:

### Passo 1 — Ler contexto

1. Ler o **plan de referência** informado para extrair:
   - Todos os arquivos criados e modificados listados nas seções do plan
   - O escopo da mudança (backend, frontend, ambos)
   - As dependências e o que esta feature bloqueia
   - Os critérios de validação da seção `## Validação`
2. Executar `git status` para confirmar arquivos modificados/criados no disco
3. Executar `git diff HEAD` para entender o escopo real das mudanças
4. Se houver divergência entre o plan e o `git status` (arquivos extras ou faltando),
   reportar ao usuário antes de prosseguir

### Passo 2 — Determinar o tipo e assunto do commit

A partir do plan, identificar:

- **Tipo dominante:** qual categoria melhor descreve o conjunto das mudanças
  - Novos arquivos de funcionalidade → `feat`
  - Somente reorganização sem novo comportamento → `refactor`
  - Somente correção de comportamento errado → `fix`
  - etc.
- **Assunto:** uma frase no imperativo que descreve a mudança principal
  - Derivar do título do plan ou da task principal da seção `## Frontend` / `## Backend`
  - Ex: `implement hotel listing with filters`, `connect login page to POST /auth/login`

### Passo 3 — Fazer o commit

Adicionar ao stage **somente os arquivos listados no plan**, um a um:

```bash
git add <arquivo-1-do-plan>
git add <arquivo-2-do-plan>
# ... para cada arquivo listado no plan
git commit -m "<emoji>(<tipo>): <assunto>"
```

> **Nunca usar `git add .` ou `git add -A`** — escopo cirúrgico, apenas o que o plan define.

### Passo 4 — Push da branch

```bash
git push -u origin <branch-atual>
```

Se o push falhar por divergência com o remoto, reportar ao usuário antes de qualquer ação.

### Passo 5 — Criar a PR

Montar o body da PR dinamicamente a partir do plan lido, seguindo este template:

```
gh pr create \
  --title "<emoji>(<tipo>): <assunto>" \
  --base <branch-destino> \
  --body "$(cat <<'EOF'
## O que foi feito

<Resumo em 2–3 linhas do que a feature entrega, referenciando o plan>
Plan: `conductor/plans/{nome-da-feature}.plan.md`

## Arquivos criados

<Para cada arquivo novo listado no plan:>
- `<caminho>` — <o que ele faz em uma linha>

## Arquivos modificados

<Para cada arquivo modificado listado no plan:>
- `<caminho>`
  - <bullet de cada mudança relevante feita neste arquivo>

## Dependências desta PR

<Derivado da seção de dependências do PRD/spec:>
- Requer: <features/tasks que precisavam estar prontas>
- Bloqueia: <features/tasks que dependem desta>

## Checklist de validação

<Derivado da seção `## Validação` do plan — marcar como [ ] pois ainda não validado em PR:>
- [ ] <critério 1 do plan>
- [ ] <critério 2 do plan>
- [ ] <critério N do plan>

🤖 Gerado com [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**Regras de preenchimento do body:**
- `## O que foi feito` — síntese do objetivo, não lista de arquivos
- `## Arquivos criados` — somente se houver arquivos novos; omitir a seção se não houver
- `## Arquivos modificados` — somente se houver arquivos alterados; omitir se não houver
- `## Dependências desta PR` — derivar do PRD/spec; se não houver dependências, omitir a seção
- `## Checklist de validação` — copiar os itens de `## Validação` do plan integralmente

---

## Guardrails

- **Nunca commitar** arquivos de ambiente (`.env`, `*.env.*`, `secrets.*`, `*.key`)
- **Nunca usar** `--no-verify` ou `--force` sem autorização explícita do usuário
- **Nunca fazer push direto** para `main` ou `master` — sempre via PR
- **Se houver arquivos no `git status` que não estão no plan**, perguntar ao usuário
  antes de incluí-los ou ignorá-los
- **Se o plan ainda tiver tasks `[ ]` abertas**, alertar o usuário antes de prosseguir
  com o commit — a feature pode não estar completa
