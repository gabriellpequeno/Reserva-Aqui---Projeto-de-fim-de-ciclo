# Playbook: depurar (ex-`/debug`)

## Objetivo

Investigar falha com hipoteses testaveis e correcao com prevencao, sem adivinhar.

## Entrada

- Sintoma, mensagem de erro, passos para reproduzir, comportamento esperado vs observado.

## Passos

1. Coletar evidencias (log, stack, arquivo/linha, ultimas mudancas).
2. Listar hipoteses ordenadas por probabilidade.
3. Testar cada hipotese de forma incremental; registrar resultado.
4. Identificar causa raiz antes de editar codigo amplo.
5. Aplicar correcao minima; sugerir teste ou guarda contra regressao.

## Formato sugerido (resposta)

- Sintoma
- Dados coletados
- Hipoteses e testes
- Causa raiz
- Correcao
- Prevencao (teste, validacao, monitoracao)

## Regras

- Nao mudar codigo sem reproduzir ou reduzir o problema quando possivel.
- Preferir skill `systematic-debugging` na `.agent` para detalhes se necessario.
