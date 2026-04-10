---
name: webapp-testing
description: Orienta testes web E2E e auditoria de rotas com Playwright quando aplicavel. Use para fluxos criticos e checagens de browser.
---

# Web App Testing

## Abordagem

1. Mapear rotas e fluxos criticos antes de automatizar tudo.
2. Priorizar piramide: muitos testes rapidos, E2E para caminhos essenciais.
3. Preferir seletores estaveis (`data-testid`, roles) a CSS fragil.

## Script do projeto

```bash
python .agent/skills/webapp-testing/scripts/playwright_runner.py <url>
```

Requer Playwright instalado conforme README do skill em `.agent`.

## Referencia completa

Ver `.agent/skills/webapp-testing/SKILL.md`.
