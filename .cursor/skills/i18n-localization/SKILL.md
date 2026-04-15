---
name: i18n-localization
description: Orienta internacionalizacao (textos, RTL, layout). Use ao adicionar idiomas ou revisar strings na UI.
---

# i18n Localization

## Regras

- Evitar strings hardcoded em fluxos criticos; usar sistema de traducao do projeto.
- Preferir propriedades logicas (`margin-inline`) a `left`/`right` quando houver RTL.

## Script do projeto

```bash
python .agent/skills/i18n-localization/scripts/i18n_checker.py <caminho>
```

## Referencia completa

Ver `.agent/skills/i18n-localization/SKILL.md`.
