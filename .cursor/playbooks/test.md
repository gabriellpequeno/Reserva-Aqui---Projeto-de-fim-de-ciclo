# Playbook: testar (ex-`/test`)

## Objetivo

Gerar, executar ou inspecionar testes alinhados ao framework do projeto.

## Modos

1. **Executar suite**: usar script do projeto (`npm test`, `pnpm test`, `pytest`, etc.).
2. **Gerar testes**: mapear comportamento, casos limite e dependencias; seguir padroes existentes em `**/*.test.*` ou `**/__tests__/**`.
3. **Cobertura**: comando de cobertura do projeto, se configurado.

## Passos

1. Identificar framework e convencoes (Jest, Vitest, Pytest, etc.).
2. Para geracao: listar casos (feliz, erro, borda); aplicar AAA.
3. Executar testes; corrigir falhas antes de concluir.
4. Resumir: passou/falhou, contagem, proximos riscos.

## Regras

- Testar comportamento observavel; evitar teste fragil a implementacao.
- Usar skills `testing-patterns` e `tdd-workflow` na `.cursor` quando aplicavel.
