---
name: python-patterns
description: Orienta Python moderno: frameworks, async vs sync, tipagem e estrutura. Use em APIs, scripts e servicos Python.
---

# Python Patterns

## Frameworks

- API/microsservicos: FastAPI costuma ser o padrao; full-stack/admin: Django; minimal: Flask.
- I/O-bound: async e bibliotecas compatíveis; CPU-bound: sync, processos ou workers dedicados.

## Codigo

- Tipar APIs publicas e limites de dominio; usar Pydantic onde couber.
- Evitar misturar sync e async sem fronteira clara.
- Estrutura de pastas alinhada ao projeto existente; nao inventar novos padroes sem necessidade.

## Referencia completa

Ver `.agent/skills/python-patterns/SKILL.md` para arvores de decisao e exemplos.
