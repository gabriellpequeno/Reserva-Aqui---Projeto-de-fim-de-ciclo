# Playbook: status do projeto (ex-`/status`)

## Objetivo

Resumir estado do workspace: stack, tarefas em andamento (se conhecido), arquivos relevantes e preview.

## Fontes

- Inspecao do repositorio (package manager, configs, pastas principais).
- Scripts opcionais:
  - `python .agent/scripts/session_manager.py status`
  - `python .agent/scripts/auto_preview.py status`

Use apenas se existirem e forem aplicaveis.

## Passos

1. Identificar tipo de projeto (Node, Python, monorepo, etc.).
2. Listar tecnologias principais a partir de arquivos de config.
3. Resumir ultimas areas tocadas se visivel no contexto da sessao.
4. Se preview estiver rodando, indicar URL e saude quando possivel.

## Formato sugerido (resposta)

- Projeto / raiz
- Stack detectada
- Comandos principais (dev, test, build)
- Preview (se aplicavel)
- Pendencias conhecidas ou perguntas abertas

## Regras

- Nao inventar metricas; indicar o que foi inferido vs confirmado pelo usuario.
