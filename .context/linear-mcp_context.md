# Context: Linear MCP Server — ReservAqui

> Last updated: 2026-05-11T00:00:00-03:00
> Version: 1

## Purpose

Documentar a integração com o servidor MCP oficial do **Linear** (`https://mcp.linear.app/mcp`) usado pelo Claude Code dentro do repositório ReservAqui. O Linear é o **issue tracker oficial** do projeto (prefixo de equipe `RES`), e o MCP permite ao Claude:

- Criar, atualizar e fechar issues no Linear
- Buscar issues por filtros (status, assignee, label, projeto)
- Listar projetos, equipes e ciclos
- Comentar em issues e mover entre estados (Backlog → In Progress → Done)
- Auxiliar no fluxo de PR: ler descrição da issue, gerar nome de branch padrão (`res-<num>-<slug>`) e enriquecer commit/PR com referência à issue

Cada desenvolvedor precisa apenas:
1. Gerar uma Personal API key em **Linear → Settings → Account → Security & access** (formato `lin_api_...`).
2. Exportar `LINEAR_API_KEY` como variável de ambiente do SO.
3. Reiniciar o Claude Code dentro do projeto.

O `.mcp.json` da raiz já está pronto e referencia `${LINEAR_API_KEY}` no header `Authorization: Bearer` — **a chave nunca é commitada**.

## Architecture / How It Works

- **Transport:** HTTP (`type: "http"`) apontando para `https://mcp.linear.app/mcp` — não exige binário/runtime local, igual ao Context7.
- **Autenticação:** O servidor oficial suporta dois modos:
  - **OAuth 2.1 com dynamic client registration** (modo padrão da CLI `claude mcp add`) — abre fluxo interativo no navegador.
  - **Bearer token direto** — `Authorization: Bearer <token>` no header. Aceita Personal API keys (`lin_api_...`) ou OAuth tokens.
  - Adotamos o **modo Bearer com Personal API key** porque é determinístico, não exige fluxo interativo a cada máquina e usa o mesmo padrão `${VAR}` do Context7. Cada dev gera a própria chave no Linear.
- **Resolução de variável:** `${LINEAR_API_KEY}` é interpolado pelo Claude Code no momento da inicialização — o processo precisa **enxergar** a variável (daí a importância de exportar persistente via `setx` no Windows ou `~/.bashrc`/`~/.zshrc` em Unix e reabrir o terminal).
- **Tools expostas:** Várias funções `mcp__linear__*` ficam disponíveis no Claude após a conexão (criar issue, atualizar, listar, comentar, etc.). A lista exata depende da versão do servidor — execute `/mcp` no Claude Code para ver as tools ativas.
- **Padrão de branch:** As branches do projeto seguem `res-<numero>-<slug-em-kebab-case>` (lowercase), derivadas do ID da issue Linear. Exemplos do histórico do repo: `res-91-fix-chatbot-intent-routing-and-date-context`, `res-87-infra-deploy-automatico-via-github-actions-cicd`.

## Setup Guide (Obrigatório para novos desenvolvedores)

### 1. Obter a Personal API Key

| Passo | Ação |
|------|------|
| 1.1 | Acessar [linear.app](https://linear.app) e fazer login na workspace do ReservAqui |
| 1.2 | Abrir **Settings** (⚙️ canto inferior esquerdo) → **Account** → **Security & access** |
| 1.3 | Rolar até **"Personal API keys"** → clicar em **"New API key"** |
| 1.4 | Label sugerida: `reservaqui-claude-code-<seu_nome>` |
| 1.5 | Copiar a chave gerada (`lin_api_XXXX...`) — **a chave aparece apenas uma vez** |

> A chave é pessoal, vinculada ao seu usuário e herda **todas as suas permissões** na workspace. **Não commitar**, **não compartilhar**. Se vazar, revogar imediatamente em **Settings → Account → Security & access → Revoke** e gerar outra.

### 2. Exportar a variável de ambiente

#### 2.1 Windows

**Opção A — Persistente (recomendado):**
```powershell
setx LINEAR_API_KEY "lin_api_cole-sua-chave-aqui"
```
> `setx` grava em `HKCU:\Environment` e só afeta **processos novos**. Feche todos os terminais e o Claude Code antes de testar.

**Opção B — Sessão atual apenas:**
```powershell
$env:LINEAR_API_KEY = "lin_api_cole-sua-chave-aqui"
```

**Opção C — GUI:** `Win + R` → `sysdm.cpl` → aba **Avançado** → **Variáveis de Ambiente...** → **Variáveis de usuário** → **Novo...** → Nome: `LINEAR_API_KEY`, Valor: a chave.

**Verificar (em terminal novo):**
```powershell
echo $env:LINEAR_API_KEY
```

#### 2.2 Linux / macOS

Adicione no arquivo de config do shell em uso:

```bash
# Bash
echo 'export LINEAR_API_KEY="lin_api_cole-sua-chave-aqui"' >> ~/.bashrc
source ~/.bashrc

# Zsh (padrão no macOS desde Catalina)
echo 'export LINEAR_API_KEY="lin_api_cole-sua-chave-aqui"' >> ~/.zshrc
source ~/.zshrc

# Fish
echo 'set -gx LINEAR_API_KEY "lin_api_cole-sua-chave-aqui"' >> ~/.config/fish/config.fish
source ~/.config/fish/config.fish
```

> Descubra o shell em uso com `echo $SHELL`.

**Verificar:**
```bash
echo $LINEAR_API_KEY
```

#### 2.3 Reiniciar o Claude Code

Feche **completamente** o Claude Code e reabra dentro do diretório do projeto. O `.mcp.json` é lido na inicialização. Após reabrir, rode `/mcp` no chat para ver o servidor `linear` listado como `connected`.

### 3. Verificação

Peça ao Claude algo que dependa do Linear, ex.:

> "Use o Linear MCP para listar minhas issues abertas no projeto ReservAqui."

O Claude deve chamar `mcp__linear__*` (ou similar). Se aparecer **401/403**, a chave não está sendo enviada corretamente — revise a Parte 2.

## Affected Project Files

| File | Uses this system? | Relationship |
|------|:-----------------:|--------------|
| `.mcp.json` | Sim | Define o servidor `linear` (HTTP + header `Authorization: Bearer ${LINEAR_API_KEY}`). Único arquivo do repo que toca o MCP. |
| `.claude/settings.local.json` | Sim | Lista `linear` em `enabledMcpjsonServers` para autorizar o servidor a rodar (sem isso o Claude pede permissão a cada sessão). |
| `~/.bashrc` / `~/.zshrc` (Linux/Mac) | Sim (por dev) | Onde a env var deve ser exportada de forma persistente. **Fora do repo.** |
| Variáveis de Usuário do Windows | Sim (por dev) | Onde o `setx` grava a chave. **Fora do repo.** |

## Code Reference

### `.mcp.json` — bloco `linear`

```json
{
  "mcpServers": {
    "linear": {
      "type": "http",
      "url": "https://mcp.linear.app/mcp",
      "headers": {
        "Authorization": "Bearer ${LINEAR_API_KEY}"
      }
    }
  }
}
```

**How it works:** Claude Code lê o arquivo na inicialização, interpola `${LINEAR_API_KEY}` com a env var do processo, e estabelece a conexão HTTP. Cada request a `mcp__linear__*` carrega o header `Authorization: Bearer lin_api_...`.

**Coupling / side-effects:** Sem a env var exportada, a interpolação resulta em `Bearer ` (vazio) → o servidor responde `401`. Sem o `.mcp.json`, as tools `mcp__linear__*` nem aparecem para o Claude.

### Convenção de branch

Toda branch nova vinculada a uma issue do Linear segue:

```
res-<numero-da-issue>-<slug-em-kebab-case>
```

Exemplos reais do repo:
- `res-91-fix-chatbot-intent-routing-and-date-context` → issue RES-91
- `res-87-infra-deploy-automatico-via-github-actions-cicd` → issue RES-87

Quando o Claude criar uma branch a partir de uma issue Linear, ele deve:
1. Buscar a issue via MCP (título + descrição)
2. Derivar o slug do título (lowercase, espaços → `-`, remover acentos/pontuação)
3. Truncar para algo legível (~60 chars)

### Fluxo de uso típico

```
1. Usuário pede: "Crie um card no Linear para X e abra a branch"
2. Claude → mcp__linear__create_issue(team="RES", title="X", ...)
   → retorna { identifier: "RES-118", title: "X", url: "..." }
3. Claude → git checkout -b res-118-<slug-do-X>
4. (após implementar) Claude → git commit / git push / gh pr create
5. Claude → mcp__linear__update_issue(id="RES-118", state="In Review")
```

## Key Design Decisions

- **HTTP em vez de stdio:** O Linear MCP é um servidor remoto oficial — não há binário local nem dependência Node/Python a instalar. Cada dev só precisa da env var. Mesmo princípio do Context7.
- **Bearer com Personal API key, não OAuth interativo:** A doc do Linear sugere `claude mcp add --transport http linear-server https://mcp.linear.app/mcp` que faz OAuth, mas isso só é viável quando o `.mcp.json` é por-dev. Como o nosso `.mcp.json` é commitado e compartilhado, usamos Personal API key via `${LINEAR_API_KEY}` — cada dev gera a própria chave, segue o mesmo padrão do Context7, e a credencial nunca toca o repo.
- **Chave por dev (não compartilhada):** A Personal API key herda as permissões do usuário no Linear — auditoria nativa (toda ação criada pelo MCP fica em nome do dev correto). Permite revogação individual em caso de vazamento.
- **Persistente via `setx`/`~/.bashrc` em vez de `.env` do projeto:** O Claude Code é um processo global do SO — não roda no contexto do `Backend/` ou `Frontend/`. A env var precisa estar no nível do usuário/sistema, não em um `.env` local carregado por dotenv.
- **Padrão `res-<num>-<slug>` para branches:** Já é convenção do time observada no histórico do repo. Garante rastreabilidade direta entre git e Linear sem campos extras.

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---------|---------------|---------|
| `401 Unauthorized` em chamadas Linear | Chave inválida, revogada, ou env var vazia | `echo` da var no terminal atual; gerar nova chave em **Settings → Account → Security & access** |
| `403 Forbidden` em ações específicas (criar issue, mover state) | Personal API key herda permissões do usuário — ação fora do escopo da workspace dele | Confirmar que o usuário tem permissão manual na UI; promover papel se necessário |
| Tools `mcp__linear__*` não aparecem no Claude | Claude Code não foi reiniciado, fora do diretório do projeto, ou `linear` não está em `enabledMcpjsonServers` | Reiniciar Claude Code; rodar `/mcp` para ver status; conferir `.claude/settings.local.json` |
| Variável aparece em um terminal mas não em outro | `setx`/`~/.bashrc` só afeta terminais novos | Fechar todos os terminais antigos; em macOS pode exigir logout/login |
| `echo $env:LINEAR_API_KEY` vazio após `setx` | `setx` não afeta a sessão onde foi executado | Abrir uma janela nova de PowerShell |
| Chave colada por engano no `.mcp.json` literal | Erro humano | Revogar em **Linear → Settings → Account → Security & access → Revoke**; gerar nova; voltar ao formato `${LINEAR_API_KEY}`; se já pushada, reescrever histórico |
| `/mcp` mostra `linear` mas todas as tools falham com timeout | Workspace pode não ter o app MCP habilitado | Workspace admin precisa autorizar o Linear MCP em **Settings → Workspace → Integrations** |

## Changelog

### v1 — 2026-05-11
- Servidor `linear` adicionado ao `.mcp.json` da raiz (HTTP em `https://mcp.linear.app/mcp`).
- Header `Authorization` configurado com interpolação `Bearer ${LINEAR_API_KEY}` — chave **nunca** commitada.
- `linear` adicionado a `.claude/settings.local.json → enabledMcpjsonServers` para auto-permissão na sessão.
- Documentado fluxo completo de obtenção de Personal API key em `linear.app → Settings → Account → Security & access`, exportação de env var em Windows (`setx`/`$env:`/GUI) e Linux/macOS (`~/.bashrc`/`~/.zshrc`/Fish), reinicialização do Claude Code e verificação via `/mcp`.
- Documentada a convenção `res-<num>-<slug>` de branches já em uso no repo (observada em `git log`).
- Decisão: Bearer com Personal API key em vez do OAuth interativo da CLI `claude mcp add`, para manter `.mcp.json` commitável e cada dev com auditoria nativa via sua própria chave.
