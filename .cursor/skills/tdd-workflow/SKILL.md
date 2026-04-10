---
name: tdd-workflow
description: Aplica ciclo RED-GREEN-REFACTOR e leis do TDD. Use quando o pedido exigir testes primeiro ou correcao de logica com regressao garantida.
---

# TDD Workflow

## Ciclo

1. RED: escrever teste que falha pelo motivo certo.
2. GREEN: codigo minimo para passar.
3. REFACTOR: melhorar sem mudar comportamento; testes continuam verdes.

## Regras

- Nao escrever codigo de producao sem teste que falhe antes (exceto exploracao descartada).
- Na fase GREEN, evitar recursos extras.

## Quando usar

- Alta em logica nova, bugs sutis e refatoracoes com risco.

## Referencia completa

Ver `.agent/skills/tdd-workflow/SKILL.md`.
