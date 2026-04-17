# Playbook: evoluir app (ex-`/enhance`)

## Objetivo

Adicionar ou alterar funcionalidades em um projeto **ja existente**, com impacto conhecido e acordo em mudancas grandes.

## Entrada

- Descricao do que mudar (feature, tela, integracao).

## Passos

1. **Entender o estado atual**
   - Stack, pastas relevantes, convencoes do repo.
   - Opcional: `python .agent/scripts/session_manager.py info` (se o script existir e for aplicavel).

2. **Planejar**
   - Listar arquivos provaveis e dependencias.
   - Para mudanca estrutural ou muitos arquivos: resumo ao usuario (escopo, risco, ordem) e aguardar confirmacao.

3. **Executar**
   - Aplicar mudancas minimas coerentes; atualizar testes quando existirem.
   - Validar com lint/tipos conforme projeto.

4. **Verificar**
   - Critério de aceite do pedido; regressoes obvias.

## Regras

- Conflito com stack existente (ex.: pedir Firebase em app Postgres): alertar e alinhar antes de codar.
- Nao expandir escopo sem combinacao.

## Saida esperada

- Codigo e/ou docs atualizados; resumo do que foi tocado e como validar.
