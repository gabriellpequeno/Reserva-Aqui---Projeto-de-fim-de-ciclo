---
name: deployment-procedures
description: Orienta releases seguros: preparacao, backup, deploy, verificacao e rollback. Use antes de subir para staging ou producao.
---

# Deployment Procedures

## Ciclo minimo (5 fases)

1. **Preparar** — checklist, versao, migracoes planejadas.
2. **Backup** — o que reverter se falhar (release anterior, dump, artefato).
3. **Deploy** — comando ou pipeline do projeto.
4. **Verificar** — saude, smoke test, metricas criticas.
5. **Confirmar ou rollback** — decisao explicita; nao deixar estado indefinido.

## Regras

- Plano de rollback documentado antes de producao.
- Observar janela pos-deploy (logs, erros, latencia).
- Adaptar ao provedor (Vercel, Docker, K8s, VPS): mesma logica, comandos diferentes.

## Referencia completa

Ver `.agent/skills/deployment-procedures/SKILL.md`.
