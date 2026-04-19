# Playbook: criar feature (ex-`/create-feature`)

## Objetivo

Implementar uma feature seguindo um **prompt ou especificacao** centralizada do repositorio.

## Entrada

- Descricao da feature; opcionalmente arquivo de prompt do projeto.

## Prompt padrao (se existir)

1. Ler `documentation/prompts/create-feature-prompt.md` **se o arquivo existir** e seguir a estrutura definida la.
2. Se nao existir, usar o playbook `plan.md` para gerar criterios de aceite e tarefas, depois implementar.

## Passos

1. Carregar requisitos do prompt central ou do usuario.
2. Identificar arquivos e camadas afetados (UI, API, dados, testes).
3. Implementar em ordem que reduza risco (contratos, dados, logica, UI).
4. Validar com testes manuais ou automatizados do projeto.

## Saida esperada

- Mudancas integradas; como validar a feature em 1-3 passos.
