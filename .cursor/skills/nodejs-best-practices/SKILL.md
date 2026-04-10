---
name: nodejs-best-practices
description: Orienta Node.js moderno: camadas, async, escolha de framework e seguranca basica. Use em servidores, workers e APIs Node.
---

# Node.js Best Practices

## Arquitetura

- Rotas/controllers finos; logica de negocio em servicos; dados em repositorios/adaptadores.
- Validar entrada na borda (Zod, Joi, schema OpenAPI, etc.).
- Evitar `fs`/CPU sincrono no request path; usar async ou filas para trabalho pesado.

## Runtime e framework

- Edge/serverless: considerar Hono ou similar; APIs perfomantes: Fastify; legado/ecossistema: Express.
- Preferir ESM em projetos novos; alinhar com o que o repo ja usa.

## Seguranca

- Sem segredos no codigo; headers e CORS conscientes do ambiente.
- Limitar payload e tempo de request quando aplicavel.

## Referencia completa

Ver `.agent/skills/nodejs-best-practices/SKILL.md` para arvores de decisao detalhadas.
