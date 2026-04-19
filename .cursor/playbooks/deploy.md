# Playbook: publicar (ex-`/deploy`)

## Objetivo

Publicar com checklist de pre-voo, fluxo de build/deploy e verificacao pos-deploy.

## Variantes

- Apenas checagens: nao publicar; so validar.
- Preview/staging vs producao: seguir politica do projeto.

## Pre-voo (ajustar aos comandos do repo)

- Qualidade: lint e tipos (`npm run lint`, `npx tsc --noEmit` ou equivalente).
- Testes automatizados passando.
- Seguranca: sem segredos no codigo; dependencias auditadas se houver ferramenta.
- Documentacao/versao: changelog ou tag se o time exigir.

## Fluxo

1. Executar checklist.
2. Build do artefato (comando do projeto).
3. Deploy na plataforma alvo (CLI ou CI).
4. Verificar saude (URL, API, migracao aplicada se houver).
5. Plano de rollback documentado mentalmente ou em ticket.

## Falha

- Reportar etapa que falhou, log resumido e proximo passo (corrigir ou reverter).

## Regras

- Nao pular verificacao pos-deploy em producao.
- Alinhar com skill `deployment-procedures` na `.agent` se existir.
