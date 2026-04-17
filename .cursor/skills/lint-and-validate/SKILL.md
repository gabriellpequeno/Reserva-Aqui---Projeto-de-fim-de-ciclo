---
name: lint-and-validate
description: Rotina de validacao de qualidade apos alteracoes de codigo. Use para lint, tipos e checagens basicas antes de concluir tarefas.
---

# Lint and Validate

## Regra

Nao considere tarefa concluida sem validacao minima adequada ao stack.

## Node / TypeScript

- Lint: `npm run lint`
- Tipagem: `npx tsc --noEmit`

## Python

- Lint: `ruff check .`
- Tipagem (quando aplicavel): `mypy .`

## Loop de qualidade

1. Implementar mudanca.
2. Rodar validacao relevante.
3. Corrigir erros.
4. Revalidar.

Se o projeto nao tiver ferramenta configurada, reportar lacuna e sugerir padrao minimo.
