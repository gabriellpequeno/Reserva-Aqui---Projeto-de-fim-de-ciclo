---
name: database-design
description: Orienta modelagem, escolha de BD/ORM, indices e migracoes seguras. Use ao criar ou alterar schema e consultas.
---

# Database Design

## Principios

- Escolha de BD e ORM pelo contexto (deploy, escala, equipe); nao padrao unico.
- Esquema normalizado e constraints no servidor quando possivel.
- Indices para filtros e ordenacoes reais; evitar `SELECT *` em producao.
- Monitorar N+1 e usar `EXPLAIN`/equivalente em mudancas criticas.

## Migracoes

- Preferir migracoes incrementais e reversíveis; planejar downtime em mudancas grandes.

## Script do projeto

- Schema: `python .agent/skills/database-design/scripts/schema_validator.py <caminho>`

## Referencia completa

Ver `.agent/skills/database-design/` (indexing, migrations, orm-selection, etc.).
