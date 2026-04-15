---
name: performance-profiling
description: Orienta medicao antes de otimizar e uso de Lighthouse/auditorias. Use ao investigar LCP, INP, CLS ou regressoes de bundle.
---

# Performance Profiling

## Regras

- Medir com evidencia (Lighthouse, DevTools, traces) antes de micro-otimizar.
- Priorizar gargalos que impactam Core Web Vitals e JS bloqueante.

## Script do projeto

```bash
python .agent/skills/performance-profiling/scripts/lighthouse_audit.py <url>
```

## Referencia completa

Ver `.agent/skills/performance-profiling/SKILL.md`.
