# Playbook: planejar (ex-`/plan`)

## Objetivo

Produzir um plano escrito **sem implementar codigo**, com escopo e verificacao claros.

## Entrada

- Pedido do usuario (objetivo, restricoes, prazo se houver).

## Passos

1. Classificar: e novo projeto, feature ou correcao? Ha ambiguidade?
2. Se ambiguido: aplicar skill `brainstorming` (perguntas minimas) antes de planejar.
3. Atuar como planejador: quebrar em tarefas pequenas com criterio de verificacao cada uma.
4. Gravar o plano em `docs/PLAN-<slug>.md` (slug curto, kebab-case, max ~30 caracteres).
5. Informar o caminho exato do arquivo criado e os proximos passos (revisao humana, depois implementacao).

## Regras

- Nao criar nem alterar codigo de producao neste playbook.
- Manter o plano em ate uma pagina quando possivel (ver skill `plan-writing`).

## Saida esperada

- Arquivo `docs/PLAN-<slug>.md` existente no repositorio.
- Lista de tarefas com verificacao e dependencias.
