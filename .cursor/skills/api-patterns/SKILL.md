---
name: api-patterns
description: Orienta desenho de APIs REST/GraphQL/tRPC com respostas consistentes, versionamento e limites. Use ao definir endpoints, contratos ou revisar APIs.
---

# API Patterns

## Principios

- Escolha o estilo (REST, GraphQL, tRPC) pelo contexto e pelos consumidores, nao por padrao fixo.
- Recursos REST em substantivos; evite verbos no path (`/users`, nao `/getUsers`).
- Padronize envelope de sucesso e erro; nao exponha stack traces ao cliente.
- Planeje versionamento (URI, header ou query) antes de breaking changes.
- Rate limiting e autenticacao sao padrao para superficies publicas.

## Checklist

- Consumidores e SLAs definidos?
- Formato de erro e codigos HTTP alinhados?
- Paginacao e filtros documentados?
- Autz por recurso, nao apenas autenticacao?

## Script do projeto

- Validacao: `python .agent/skills/api-patterns/scripts/api_validator.py <caminho>`

## Referencia completa

Ver `.agent/skills/api-patterns/` (rest, graphql, auth, rate-limiting, etc.).
