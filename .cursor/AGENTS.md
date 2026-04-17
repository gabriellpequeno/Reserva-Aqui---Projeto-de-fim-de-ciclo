# Agentes e skills neste repositorio

## Cursor (preferencia para novas sessoes)

- **Regras persistentes:** `.cursor/rules/*.mdc` (nucleo, `engineering-*`, e `agent-*` apontando para `.agent/agents/`)
- **Skills do projeto:** `.cursor/skills/<nome>/SKILL.md` (paridade com nomes em `.agent/skills/`)
- **Playbooks operacionais:** `.cursor/playbooks/*.md`

## Legado Antigravity (referencia detalhada)

- **Personas (agentes):** `.agent/agents/*.md`
- **Skills completas e anexos:** `.agent/skills/<nome>/` (inclui scripts e documentacao extra)
- **Workflows originais (slash):** `.agent/workflows/*.md`
- **Scripts globais:** `.agent/scripts/`

## Como usar na pratica

1. Para comportamento sempre ativo, confie nas regras em `.cursor/rules/`.
2. Para tarefas especializadas, carregue a skill em `.cursor/skills/`; se precisar de profundidade, abra o homonimo em `.agent/skills/`.
3. Para fluxos passo a passo, use `.cursor/playbooks/` (equivalente aos comandos `/plan`, `/deploy`, etc.).

## Manual unificado

- `DOT_AGENTS_MANUAL.md` na raiz descreve o ecossistema `.agent/`; caminhos `.cursor/` complementam a operacao no Cursor.
