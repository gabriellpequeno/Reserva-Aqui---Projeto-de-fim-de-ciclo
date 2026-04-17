---
name: testing-patterns
description: Define piramide de testes, AAA, mocks e organizacao. Use ao escrever ou revisar testes.
---

# Testing Patterns

## Piramide

- Muitos testes unitarios rapidos; alguns de integracao; E2E para fluxos criticos.

## AAA

- Arrange: preparar dados e dependencias.
- Act: executar o comportamento.
- Assert: verificar resultado observavel.

## Mocks

- Mockar fronteiras (rede, tempo, DB em unit); nao mascarar bugs reais com mocks excessivos.

## Script do projeto

- Testes: `python .agent/skills/testing-patterns/scripts/test_runner.py .` (se existir no repo)

## Referencia completa

Ver `.agent/skills/testing-patterns/SKILL.md`.
