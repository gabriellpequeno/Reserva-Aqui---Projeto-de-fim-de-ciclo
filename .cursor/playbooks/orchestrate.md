# Playbook: orquestrar (ex-`/orchestrate`)

## Objetivo

Coordenar **tres ou mais** perspectivas (papéis) em tarefa multi-dominio, com plano aprovado antes de implementacao paralela.

## Pre-requisitos

- Pedido que toque mais de um dominio (ex.: API + UI + testes + seguranca).

## Fase 1 — Planejamento (sequencial)

1. Garantir entendimento do pedido; se vago, usar `brainstorming`.
2. Produzir ou atualizar `docs/PLAN.md` (ou `docs/PLAN-<slug>.md`) com divisao de trabalho e agentes/papeis sugeridos.
3. **Parar** e obter confirmacao explicita do usuario para seguir para implementacao.

## Fase 2 — Implementacao (apos aprovacao)

1. Para cada area (frontend, backend, dados, testes, ops, seguranca), executar o trabalho no escopo acordado.
2. Repassar contexto entre etapas: pedido original, decisoes, estado do plano, artefatos ja produzidos.
3. Rodar verificacoes relevantes do projeto (ex.: lint; scripts em `.agent/skills/*/scripts/` quando aplicavel).

## Regras

- Orquestracao valida exige **no minimo tres** papeis distintos (ex.: planejamento + dominio A + dominio B + verificacao conta como multiplos).
- Nao avancar da Fase 1 para a 2 sem aprovacao.

## Saida esperada

- Relatorio curto: tarefa, modos/papeis usados, verificacoes, entregaveis, riscos remanescentes.
