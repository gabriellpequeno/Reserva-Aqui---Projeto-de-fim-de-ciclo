# MIGRATION_AGENT_TO_CURSOR

## Objetivo da Fase 1

Inventariar os ativos da pasta `.agent/` e definir o destino de cada categoria na estrutura `.cursor/`, sem mover arquivos ainda.

## Inventario Atual (`.agent`)

- `agents`: 20 arquivos (`.agent/agents/*.md`)
- `skills`: 52 skills (`.agent/skills/**/SKILL.md`)
- `workflows`: 12 arquivos (`.agent/workflows/*.md`)
- `rules`: 2 arquivos (`.agent/rules/*.md`)
- `scripts`: 4 arquivos (`.agent/scripts/*`)

## Estrutura Alvo (`.cursor`)

- `.cursor/rules/*.mdc`
- `.cursor/skills/<skill>/SKILL.md`
- `.cursor/playbooks/*.md` (proposto para conversao de workflows slash)
- `.cursor/migration/` (opcional, para checkpoints de migracao)

## Matriz de Mapeamento (Categoria -> Destino)

| Origem `.agent` | Destino `.cursor` | Estrategia |
|---|---|---|
| `agents/*.md` | `rules/*.mdc` + `skills/*` | Converter persona em regra de comportamento + skill operacional quando necessario |
| `skills/**/SKILL.md` | `skills/**/SKILL.md` | Migracao quase direta, com normalizacao de formato e concisao |
| `workflows/*.md` | `playbooks/*.md` e/ou `skills/*` | Converter slash-command em fluxo executavel por checklist |
| `rules/*.md` | `rules/*.mdc` | Converter para frontmatter Cursor (`description`, `alwaysApply`, `globs`) |
| `scripts/*` | manter em `.agent/scripts/*` (fase inicial) | Reapontar referencias em skills/rules; mover so se houver ganho claro |

## Mapeamento Inicial por Arquivo

### 1) Regras (prioridade P0)

| Origem | Destino proposto | Prioridade |
|---|---|---|
| `.agent/rules/architecture.md` | `.cursor/rules/architecture-core.mdc` | P0 |
| `.agent/rules/GEMINI.md` | `.cursor/rules/assistant-policy.mdc` | P0 |

### 2) Agentes (prioridade P1)

Padrao de conversao: cada agente gera 1 regra de comportamento em `.cursor/rules/agent-<nome>.mdc`. Em casos onde houver processo reutilizavel, gerar tambem skill em `.cursor/skills/<nome>/SKILL.md`.

| Origem | Destino proposto | Prioridade |
|---|---|---|
| `.agent/agents/orchestrator.md` | `.cursor/rules/agent-orchestrator.mdc` + skill `orchestration` | P1 |
| `.agent/agents/project-planner.md` | `.cursor/rules/agent-project-planner.mdc` + skill `project-planning` | P1 |
| `.agent/agents/frontend-specialist.md` | `.cursor/rules/agent-frontend-specialist.mdc` | P1 |
| `.agent/agents/backend-specialist.md` | `.cursor/rules/agent-backend-specialist.mdc` | P1 |
| `.agent/agents/database-architect.md` | `.cursor/rules/agent-database-architect.mdc` | P1 |
| `.agent/agents/mobile-developer.md` | `.cursor/rules/agent-mobile-developer.mdc` | P2 |
| `.agent/agents/game-developer.md` | `.cursor/rules/agent-game-developer.mdc` | P2 |
| `.agent/agents/devops-engineer.md` | `.cursor/rules/agent-devops-engineer.mdc` | P1 |
| `.agent/agents/security-auditor.md` | `.cursor/rules/agent-security-auditor.mdc` | P1 |
| `.agent/agents/penetration-tester.md` | `.cursor/rules/agent-penetration-tester.mdc` | P2 |
| `.agent/agents/test-engineer.md` | `.cursor/rules/agent-test-engineer.mdc` | P1 |
| `.agent/agents/debugger.md` | `.cursor/rules/agent-debugger.mdc` | P1 |
| `.agent/agents/performance-optimizer.md` | `.cursor/rules/agent-performance-optimizer.mdc` | P2 |
| `.agent/agents/seo-specialist.md` | `.cursor/rules/agent-seo-specialist.mdc` | P2 |
| `.agent/agents/documentation-writer.md` | `.cursor/rules/agent-documentation-writer.mdc` | P2 |
| `.agent/agents/product-manager.md` | `.cursor/rules/agent-product-manager.mdc` | P2 |
| `.agent/agents/product-owner.md` | `.cursor/rules/agent-product-owner.mdc` | P2 |
| `.agent/agents/qa-automation-engineer.md` | `.cursor/rules/agent-qa-automation-engineer.mdc` | P1 |
| `.agent/agents/code-archaeologist.md` | `.cursor/rules/agent-code-archaeologist.mdc` | P2 |
| `.agent/agents/explorer-agent.md` | `.cursor/rules/agent-explorer.mdc` | P1 |

### 3) Skills (prioridade P0/P1)

Diretriz: manter nomes e mover por lotes.

- **P0 (nucleo):**
  - `clean-code`, `plan-writing`, `brainstorming`, `architecture`, `lint-and-validate`
- **P1 (engenharia base):**
  - `api-patterns`, `nodejs-best-practices`, `python-patterns`, `database-design`, `testing-patterns`, `tdd-workflow`, `vulnerability-scanner`
- **P2 (especializadas):**
  - `game-development/*`, `flutter-expert`, `firebase`, `geo-fundamentals`, `seo-fundamentals`, `web-design-guidelines`, etc.

Observacao: skills com muitos anexos (`skill-creator`, `manual-updater`, `app-builder/templates`) devem ser migradas com validacao de links internos.

### 4) Workflows (prioridade P1)

Padrao de conversao: de slash command para playbook procedural.

| Origem | Destino proposto | Prioridade |
|---|---|---|
| `.agent/workflows/plan.md` | `.cursor/playbooks/plan.md` | P1 |
| `.agent/workflows/orchestrate.md` | `.cursor/playbooks/orchestrate.md` | P1 |
| `.agent/workflows/debug.md` | `.cursor/playbooks/debug.md` | P1 |
| `.agent/workflows/deploy.md` | `.cursor/playbooks/deploy.md` | P1 |
| `.agent/workflows/test.md` | `.cursor/playbooks/test.md` | P1 |
| `.agent/workflows/enhance.md` | `.cursor/playbooks/enhance.md` | P2 |
| `.agent/workflows/create.md` | `.cursor/playbooks/create.md` | P2 |
| `.agent/workflows/create-feature.md` | `.cursor/playbooks/create-feature.md` | P2 |
| `.agent/workflows/preview.md` | `.cursor/playbooks/preview.md` | P2 |
| `.agent/workflows/status.md` | `.cursor/playbooks/status.md` | P2 |
| `.agent/workflows/brainstorm.md` | `.cursor/playbooks/brainstorm.md` | P2 |
| `.agent/workflows/ui-ux-pro-max.md` | `.cursor/playbooks/ui-ux-pro-max.md` | P3 |

### 5) Scripts (prioridade P1)

| Origem | Decisao Fase 1 | Prioridade |
|---|---|---|
| `.agent/scripts/checklist.py` | Manter no local e referenciar de `.cursor/skills` | P1 |
| `.agent/scripts/verify_all.py` | Manter no local e referenciar de `.cursor/skills` | P1 |
| `.agent/scripts/session_manager.py` | Manter no local e avaliar acoplamento com playbooks | P2 |
| `.agent/scripts/auto_preview.py` | Manter no local e usar via playbook `preview` | P2 |

## Riscos e Decisoes Arquiteturais da Fase 1

- Nao existe paridade nativa de "agentes de pasta" no Cursor; o equivalente pratico e combinar `rules` (comportamento persistente) e `skills` (contexto executavel).
- Workflows com sintaxe slash nao devem ser copiados literalmente; devem virar playbooks com gatilho semantico.
- Regras `.mdc` precisam permanecer curtas e focadas (preferencia: uma preocupacao por arquivo).

## Definition of Done da Fase 1

- Inventario completo registrado.
- Matriz de mapeamento definida por categoria.
- Prioridades de migracao (P0..P3) aprovadas.
- Sem alteracoes funcionais no projeto nesta fase.

## Proxima Fase (Fase 2)

Criar a estrutura inicial da `.cursor/` e migrar o primeiro lote P0:

1. `.cursor/rules/architecture-core.mdc`
2. `.cursor/rules/assistant-policy.mdc`
3. `.cursor/skills/clean-code/SKILL.md`
4. `.cursor/skills/plan-writing/SKILL.md`
5. `.cursor/skills/brainstorming/SKILL.md`
6. `.cursor/skills/architecture/SKILL.md`
7. `.cursor/skills/lint-and-validate/SKILL.md`

## Status de Execucao

- **Etapa 1**: concluida e aprovada.
- **Etapa 2**: concluida (fundacao `.cursor` + migracao P0 aditiva, sem remover `.agent`).
- **Etapa 3**: concluida (regras P1, skills P1, playbooks P1; `.agent` intacta).
- **Etapa 4**: concluida (playbooks P2 + catalogo `.cursor/AGENTS.md`).
- **Etapa 5**: concluida (playbook P3 `ui-ux-pro-max`).
- **Etapa 6**: concluida — todas as skills com `SKILL.md` na `.agent` possuem homonimo resumido em `.cursor/skills/` (inclui `app-builder-templates`); 20 regras `agent-*.mdc`; secao Cursor em `DOT_AGENTS_MANUAL.md` e `AGENTS.md` atualizados.

### Entregas da Etapa 3 (referencia rapida)

**Rules (`.cursor/rules/`):**

- `engineering-frontend.mdc`
- `engineering-backend.mdc`
- `engineering-testing.mdc`
- `engineering-security.mdc`

**Skills (`.cursor/skills/`):**

- `api-patterns/`, `nodejs-best-practices/`, `python-patterns/`, `database-design/`, `testing-patterns/`, `tdd-workflow/`, `vulnerability-scanner/`

**Playbooks (`.cursor/playbooks/`):**

- `plan.md`, `orchestrate.md`, `debug.md`, `deploy.md`, `test.md`

### Entregas da Etapa 4

**Playbooks P2 (`.cursor/playbooks/`):**

- `enhance.md`, `create.md`, `create-feature.md`, `preview.md`, `status.md`, `brainstorm.md`

**Catalogo:**

- `.cursor/AGENTS.md` — mapa Cursor vs `.agent` e ordem de uso.

### Entregas da Etapa 5

**Playbook P3:**

- `ui-ux-pro-max.md` — fluxo resumido usando `.agent/.shared/ui-ux-pro-max/scripts/search.py`

### Entregas da Etapa 6

**Skills:** cobertura alinhada a cada `.agent/skills/**/SKILL.md` — pastas com o mesmo nome quando possivel; sub-rotas de `game-development/` espelhadas como `game-2d-games`, `game-3d-games`, etc.; `app-builder/templates` como `app-builder-templates`.

**Regras de agente:** `.cursor/rules/agent-*.mdc` (20 arquivos), `alwaysApply: false`, apontando para `.agent/agents/<nome>.md`.

**Documentacao:** `DOT_AGENTS_MANUAL.md` secao **2.1 Uso no Cursor**; `.cursor/AGENTS.md` atualizado.

## Proxima Fase (Etapa 7) — manutencao opcional

1. Afinar `globs` das regras `agent-*.mdc` por dominio (ex.: `agent-frontend-specialist` so com `**/*.tsx`) se quiser ativacao automatica ao abrir arquivos.
2. Deprecar gradualmente referencias exclusivas a `.agent` na documentacao externa, mantendo `.agent` como arquivo morto de detalhe ou consolidar scripts em `tools/`.
3. Rodar `python .agent/skills/manual-updater/scripts/sync_manual.py` quando o inventario de skills mudar.

## Planejamento da Etapa 3

### Objetivo

Migrar o lote P1 para tornar a `.cursor` operacional para demandas de implementacao, revisao e deploy, com playbooks iniciais.

### Escopo da Etapa 3

1. **Rules adicionais (P1)**
   - Consolidar regras de engenharia por dominio em arquivos `.mdc` curtos:
     - `engineering-frontend.mdc`
     - `engineering-backend.mdc`
     - `engineering-testing.mdc`
     - `engineering-security.mdc`

2. **Skills P1**
   - Migrar para `.cursor/skills/`:
     - `api-patterns`
     - `nodejs-best-practices`
     - `python-patterns`
     - `database-design`
     - `testing-patterns`
     - `tdd-workflow`
     - `vulnerability-scanner`

3. **Playbooks iniciais (workflows P1)**
   - Converter para `.cursor/playbooks/`:
     - `plan.md`
     - `orchestrate.md`
     - `debug.md`
     - `deploy.md`
     - `test.md`

4. **Compatibilidade de scripts**
   - Preservar uso de scripts existentes em `.agent/scripts/` e `.agent/skills/*/scripts/`.
   - Ajustar referencias internas nas skills/playbooks migradas.

### Fora de Escopo da Etapa 3

- Migrar o lote P2/P3 (skills especializadas e workflows de baixa prioridade).
- Desativar ou remover a pasta `.agent`.
- Refatorar scripts Python legados.

### Criterios de Aceite (Etapa 3)

- 4 regras `.mdc` P1 criadas e coerentes.
- 7 skills P1 migradas com `name`/`description` validos.
- 5 playbooks P1 criados em formato operacional.
- Referencias a scripts testadas ao menos em nivel de caminho/comando.
- Sem regressao documental: `.agent` permanece intacta.

### Riscos e Mitigacoes

- **Risco:** duplicacao de regras entre `.agent` e `.cursor`.
  - **Mitigacao:** manter `.cursor` como fonte principal para novas iteracoes e marcar duplicidades no proprio arquivo de migracao.
- **Risco:** playbooks longos e pouco acionaveis.
  - **Mitigacao:** limitar cada playbook a checklist objetivo com entradas, passos e saida esperada.
