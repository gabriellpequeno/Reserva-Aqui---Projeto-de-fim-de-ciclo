# Playbook: UI/UX pro max (ex-`/ui-ux-pro-max`)

## Objetivo

Planejar ou refinar interface usando o **kit** em `.agent/.shared/ui-ux-pro-max/` (busca de design system, estilos e anti-padroes).

## Pre-requisitos

- Python disponivel (`python --version` ou `python3 --version`).

## Fluxo resumido

1. Extrair do pedido: tipo de produto, industria, palavras-chave de estilo, stack (ex.: Next, React, `html-tailwind`).
2. Gerar recomendacoes de design system (comando principal do workflow legado):

```bash
python .agent/.shared/ui-ux-pro-max/scripts/search.py "<tipo> <industria> <keywords>" --design-system [-p "Nome do Projeto"]
```

3. Opcional: persistir artefatos para sessoes seguintes:

```bash
python .agent/.shared/ui-ux-pro-max/scripts/search.py "<query>" --design-system --persist -p "Nome do Projeto"
```

4. Aplicar decisoes no codigo do repo (componentes, tokens, temas) alinhado a `engineering-frontend` e skills de UI do projeto.

## Regras

- Comecar por design system / restricoes antes de codar telas grandes.
- Respeitar anti-padroes indicados pelo script/saida (evitar clichês de template quando o kit alertar).
- Detalhes adicionais: ver `.agent/workflows/ui-ux-pro-max.md` e arquivos em `.agent/.shared/ui-ux-pro-max/`.

## Saida esperada

- Diretrizes de estilo acordadas; implementacao incremental na base de codigo.
