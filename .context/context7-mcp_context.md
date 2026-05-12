# Context: Context7 MCP Server — ReservAqui

> Last updated: 2026-05-11T00:00:00-03:00
> Version: 1

## Purpose

Documentar a integração com o servidor MCP do **Context7** (`https://mcp.context7.com/mcp`) usado pelo Claude Code dentro do repositório ReservAqui. O Context7 fornece **documentação oficial e atualizada** de bibliotecas, frameworks, SDKs, CLIs e serviços de cloud diretamente para o agente — substituindo `WebSearch` para consultas de docs com mais precisão e velocidade.

Cada desenvolvedor precisa apenas:
1. Gerar uma API key em [context7.com](https://context7.com) (chave pessoal — formato `ctx7sk-...`).
2. Exportar `CONTEXT7_API_KEY` como variável de ambiente do SO.
3. Reiniciar o Claude Code dentro do projeto.

O `.mcp.json` da raiz já está pronto e referencia `${CONTEXT7_API_KEY}` — **a chave nunca é commitada**.

## Architecture / How It Works

- **Transport:** HTTP (`type: "http"`) apontando para `https://mcp.context7.com/mcp` — não exige binário/runtime local, diferente de servidores `stdio`.
- **Autenticação:** Header `CONTEXT7_API_KEY` enviado pelo Claude Code em cada chamada. O valor é interpolado de `${CONTEXT7_API_KEY}` no momento da inicialização do MCP — Claude lê a env var do processo pai (terminal/SO).
- **Resolução de variável:** A interpolação `${VAR}` é feita pelo Claude Code, não pelo SO. O processo precisa **enxergar** a variável — daí a importância de exportar de forma persistente (`setx` no Windows ou `~/.bashrc`/`~/.zshrc` em Unix) e reabrir o terminal.
- **Tools expostas:** Duas funções principais ficam disponíveis no Claude após a conexão:
  - `mcp__context7__resolve-library-id` — converte um nome (ex.: `"React"`) em um ID Context7 (`/reactjs/react.dev`). Deve ser chamada antes de `query-docs`, exceto se o usuário já passar um ID no formato `/org/project`.
  - `mcp__context7__query-docs` — busca a documentação na biblioteca resolvida com uma query específica. Limite recomendado: **3 chamadas por pergunta** do usuário.
- **Quando usar:** Sintaxe de API, opções de configuração, migração entre versões, debug específico de uma lib, instruções de setup, uso de CLI. **Mesmo** quando o Claude acha que sabe — dados de treino podem estar desatualizados.
- **Quando NÃO usar:** Refatoração, escrita de scripts do zero, debug de lógica de negócio do projeto, code review, conceitos gerais de programação. Para estes casos, o Claude opera com o contexto local.

## Setup Guide (Obrigatório para novos desenvolvedores)

### 1. Obter a API Key

| Passo | Ação |
|------|------|
| 1.1 | Acessar [context7.com](https://context7.com) e fazer login (GitHub recomendado) |
| 1.2 | Abrir o **Dashboard** → menu lateral **"API Keys"** |
| 1.3 | Clicar em **"Create API Key"** — nome sugerido: `reservaqui-dev-<seu_nome>` |
| 1.4 | Copiar a chave gerada (`ctx7sk-XXXXXXXX...`) — **a chave aparece apenas uma vez** |

> A chave é pessoal. **Não commitar** no git, **não compartilhar** em chats. Se vazar, revogar imediatamente em **API Keys → Revoke** e gerar outra.

### 2. Exportar a variável de ambiente

#### 2.1 Windows

**Opção A — Persistente (recomendado):**
```powershell
setx CONTEXT7_API_KEY "ctx7sk-cole-sua-chave-aqui"
```
> `setx` grava em `HKCU:\Environment` e só afeta **processos novos**. Feche todos os terminais e o Claude Code antes de testar.

**Opção B — Sessão atual apenas:**
```powershell
$env:CONTEXT7_API_KEY = "ctx7sk-cole-sua-chave-aqui"
```

**Opção C — GUI:** `Win + R` → `sysdm.cpl` → aba **Avançado** → **Variáveis de Ambiente...** → **Variáveis de usuário** → **Novo...** → Nome: `CONTEXT7_API_KEY`, Valor: a chave.

**Verificar (em terminal novo):**
```powershell
echo $env:CONTEXT7_API_KEY
```

#### 2.2 Linux / macOS

Adicione no arquivo de config do shell em uso:

```bash
# Bash
echo 'export CONTEXT7_API_KEY="ctx7sk-cole-sua-chave-aqui"' >> ~/.bashrc
source ~/.bashrc

# Zsh (padrão no macOS desde Catalina)
echo 'export CONTEXT7_API_KEY="ctx7sk-cole-sua-chave-aqui"' >> ~/.zshrc
source ~/.zshrc

# Fish
echo 'set -gx CONTEXT7_API_KEY "ctx7sk-cole-sua-chave-aqui"' >> ~/.config/fish/config.fish
source ~/.config/fish/config.fish
```

> Descubra o shell em uso com `echo $SHELL`.

**Verificar:**
```bash
echo $CONTEXT7_API_KEY
```

#### 2.3 Reiniciar o Claude Code

Feche **completamente** o Claude Code (não basta abrir nova conversa) e reabra dentro do diretório do projeto. O `.mcp.json` é lido na inicialização.

### 3. Verificação

Peça ao Claude algo que dependa do Context7, ex.:

> "Use o Context7 para buscar a doc atual de Server Components do React 19."

O Claude deve chamar `mcp__context7__resolve-library-id` e depois `mcp__context7__query-docs`. Se aparecer **401/403**, a chave não está sendo enviada corretamente — revise a Parte 2.

## Affected Project Files

| File | Uses this system? | Relationship |
|------|:-----------------:|--------------|
| `.mcp.json` | Sim | Define o servidor `context7` (HTTP + header `CONTEXT7_API_KEY` interpolado da env). Único arquivo do repo que toca o MCP. |
| `~/.bashrc` / `~/.zshrc` (Linux/Mac) | Sim (por dev) | Onde a env var deve ser exportada de forma persistente. **Fora do repo.** |
| Variáveis de Usuário do Windows | Sim (por dev) | Onde o `setx` grava a chave. **Fora do repo.** |

## Code Reference

### `.mcp.json` — bloco `context7`

```json
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
      }
    }
  }
}
```

**How it works:** Claude Code lê o arquivo na inicialização, interpola `${CONTEXT7_API_KEY}` com a env var do processo, e estabelece a conexão HTTP. Cada request a `mcp__context7__*` carrega o header.

**Coupling / side-effects:** Sem a env var exportada, a interpolação resulta em string vazia → o servidor responde `401`. Sem o `.mcp.json`, as tools `mcp__context7__*` nem aparecem para o Claude.

### Fluxo de uso típico

```
1. Usuário pergunta sobre React 19 Server Components
2. Claude → mcp__context7__resolve-library-id("React")
   → retorna ["/reactjs/react.dev", "/facebook/react", ...]
3. Claude → mcp__context7__query-docs("/reactjs/react.dev", "Server Components in React 19")
   → retorna trechos da doc oficial
4. Claude responde ao usuário citando os trechos
```

## Key Design Decisions

- **HTTP em vez de stdio:** O Context7 é um servidor remoto — não há binário local nem dependência Node/Python a instalar. Cada dev só precisa da env var.
- **Interpolação `${CONTEXT7_API_KEY}` em vez de chave literal:** Mantém o `.mcp.json` commitável sem expor segredos. Cada dev cadastra a própria chave no SO. Mesma estratégia usada por `Backend/.env` para `WHATSAPP_TOKEN`, `GEMINI_API_KEY` e similares.
- **Chave por dev (não compartilhada):** Permite revogação individual em caso de vazamento sem afetar o time. O dashboard do Context7 nomeia chaves (`reservaqui-dev-<nome>`) para facilitar auditoria.
- **Persistente via `setx`/`~/.bashrc` em vez de `.env` do projeto:** O Claude Code é um processo global do SO — não roda no contexto do `Backend/` ou `Frontend/`. Por isso a env var precisa estar no nível do usuário/sistema, não em um `.env` local.
- **Limite de 3 chamadas `query-docs` por pergunta:** Diretiva oficial do servidor Context7. Acima disso o Claude deve usar o melhor resultado obtido e seguir.

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---------|---------------|---------|
| `401 Unauthorized` em chamadas Context7 | Chave inválida, revogada ou env var vazia | `echo` da var no terminal atual; gerar nova chave se necessário |
| Tools `mcp__context7__*` não aparecem no Claude | Claude Code não foi reiniciado, ou está fora do diretório do projeto | Fechar Claude Code completamente e reabrir em `C:\Kellvin\desafio-final-ciclo\Reserva-Aqui---Projeto-de-fim-de-ciclo\` |
| Variável aparece em um terminal mas não em outro | `setx`/`~/.bashrc` só afeta terminais novos | Fechar todos os terminais antigos; em macOS pode exigir logout/login |
| `echo $env:CONTEXT7_API_KEY` vazio após `setx` | `setx` não afeta a sessão onde foi executado | Abrir uma janela nova de PowerShell |
| Chave colada por engano no `.mcp.json` literal | Erro humano | Revogar imediatamente em [context7.com/dashboard](https://context7.com/dashboard) → API Keys → Revoke; gerar nova; voltar ao formato `${CONTEXT7_API_KEY}`; se já pushada, reescrever histórico |

## Changelog

### v1 — 2026-05-11
- Servidor `context7` adicionado ao `.mcp.json` da raiz (HTTP em `https://mcp.context7.com/mcp`).
- Header `CONTEXT7_API_KEY` configurado com interpolação `${CONTEXT7_API_KEY}` — chave **nunca** commitada.
- Documentado fluxo completo de obtenção de chave em `context7.com`, exportação de env var em Windows (`setx`/`$env:`/GUI) e Linux/macOS (`~/.bashrc`/`~/.zshrc`/Fish), reinicialização do Claude Code e verificação.
- Documentado limite de 3 chamadas `query-docs` por pergunta e os casos de uso recomendados (docs de libs/frameworks/CLIs) vs. proibidos (refator, lógica de negócio, code review).
