# Playbook: preview local (ex-`/preview`)

## Objetivo

Gerenciar servidor de desenvolvimento local: subir, parar, status ou saude.

## Comandos uteis (script do repo)

O projeto inclui `auto_preview.py`:

```bash
python .agent/scripts/auto_preview.py start [porta]
python .agent/scripts/auto_preview.py stop
python .agent/scripts/auto_preview.py status
```

Ajuste `python`/`python3` conforme o ambiente.

## Passos

1. **Status**: verificar se ja ha processo na porta (ex.: 3000).
2. **Conflito de porta**: oferecer outra porta ou encerrar processo (com consentimento).
3. **Start**: executar o comando acima ou o script definido no `package.json` (`npm run dev`, etc.).
4. Informar URL local e como repetir os passos.

## Regras

- Preferir os comandos oficiais do framework do repo quando existirem (`npm run dev`, `pnpm dev`, etc.).
- Nao assumir porta sem checar.

## Saida esperada

- URL acessivel ou erro claro com proximo passo.
