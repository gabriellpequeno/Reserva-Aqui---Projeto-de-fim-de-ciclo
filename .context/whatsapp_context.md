# Context: WhatsApp Cloud API & RAG Integration

> Last updated: 2026-04-18T22:40:00-03:00
> Version: 2

## Purpose
Documentar a fundação da integração entre a Meta (WhatsApp Cloud API) e o backend Node.js (Express), além de estabelecer as diretrizes para a futura expansão envolvendo IA Generativa e RAG (Retrieval-Augmented Generation).

## Architecture / How It Works
- **Autenticação Passiva (Webhook Hub)**: A Meta envia um `GET` para a nossa rota `/api/v1/whatsapp/webhook` contendo um `hub.verify_token`. O Node.js retorna o `challenge` apenas se a senha bater com o registrado no arquivo `.env` global, consolidando o túnel transparente.
- **Ecossistema Ativo (Message Receiving)**: Quando o cliente final digita algo no celular do bot ("Oi"), o evento bate como um `POST` no Express. A classe `WhatsAppController` reage parseando o payload da Graph API.
- **Logging Transacional de Memória (Chat History)**: Ao invés do fluxo morrer, toda mensagem recebida do usuário é atrelada estritamente às tabelas do Banco Master `sessao_chat` e `mensagem_chat` sob a `origem = 'CLIENTE'`.
- **Janela de Sessões (24H Service Window)**: A Meta só permite que Templates abram conversas, salvo nos casos de chamadas entrantes (Cliente para o Bot), liberando automaticamente 24h para comunicações em estilo "Texto Livre".
- **WhatsAppService (Output Layer)**: Uma abstração `postToMeta` encabeça a injeção do Bearer System Token (Token Permanente) do hotel. Responsável unicamente por ecoar respostas ou interagir em tempo real no device do cliente.

## Setup Guide (Obrigatório para novos desenvolvedores)

### 1. Variáveis de Ambiente
Copie `Backend/.env.example` para `Backend/.env` e preencha:

| Variável | Onde encontrar |
|----------|---------------|
| `WHATSAPP_TOKEN` | Meta Business Suite → Usuários do sistema → Gerar token permanente |
| `WHATSAPP_PHONE_ID` | Meta Developers → WhatsApp → Configuração da API → ID do número |
| `WHATSAPP_WEBHOOK_VERIFY_TOKEN` | Senha livre definida por você (deve bater no painel da Meta) |
| `GEMINI_API_KEY` | Google AI Studio → Create API Key |

### 2. Webhook (Cloudflare Tunnel + Meta)
```bash
# Terminal 1: Subir o backend
cd Backend && docker-compose up --build

# Terminal 2: Criar túnel público temporário
npx cloudflared tunnel --url http://127.0.0.1:3000
```

No painel **Meta Developers → WhatsApp → Configuração**:
- **URL de Callback**: `https://<url-do-tunel>.trycloudflare.com/api/v1/whatsapp/webhook`
- **Token de verificação**: mesmo valor de `WHATSAPP_WEBHOOK_VERIFY_TOKEN`
- **Campos assinados**: `messages` (obrigatório)

### 3. WABA Subscription (ETAPA CRÍTICA)
> ⚠️ **Sem esta etapa, o webhook recebe testes do painel mas NÃO recebe mensagens reais do celular.**

A Meta exige que a WhatsApp Business Account (WABA) seja explicitamente assinada ao App:
```bash
curl -X POST "https://graph.facebook.com/v25.0/{WABA_ID}/subscribed_apps" \
  -d "access_token={WHATSAPP_TOKEN}"
```

Para encontrar o `WABA_ID`:
1. Meta Business Suite → Configurações → Contas → **Contas do WhatsApp**
2. Clique na conta desejada → o campo **"Identificação"** é o WABA ID

### 4. Verificação
Envie uma mensagem do seu celular para o número do bot. O terminal do Docker deve exibir:
```
Nova mensagem de 5581XXXXXXXXX: <sua mensagem>
🆕 Nova Sessão de Chat Criada: <uuid>
💾 [Database] Mensagem registrada com sucesso na base de dados!
✅ Mensagem enviada com sucesso para 5581XXXXXXXXX
```

## Path for AI (Fase 4: RAG & Langchain)
- A infraestrutura descrita acima de `sessao_chat` foi rigorosamente idealizada para alimentar o *Contexto de Conversa* em requisições de LLM instanciadas por **LangChain**. 
- Antes de evocar a inferência principal do Gemini ou equivalente, o sistema busca a memória atrelada à API rest, injeta-a num Prompt e usa Vectorization (Pgvector) com Tool Callings para devolver respostas coesas de quartos, custos ou roteiros.

## A Implementar

### Validação de Assinatura (X-Hub-Signature-256)
A Meta envia um header `X-Hub-Signature-256` em cada POST do webhook. Validar esse hash garante que o payload realmente veio da Meta e não de um terceiro mal-intencionado. Deve ser feito com `crypto.createHmac('sha256', appSecret)` comparando com o header recebido.

### Política de Retenção de Dados (LGPD)
As mensagens salvas em `mensagem_chat` crescem indefinidamente. Para conformidade com a LGPD e performance do banco:
- Definir um período de retenção (ex: 90 dias)
- Criar um job agendado (cron) para fechar sessões ociosas há mais de 24h (`status = 'FECHADA'`)
- Arquivar ou deletar mensagens fora do período de retenção

### Tempo de Resposta do Webhook (Regra Oficial da Meta)
A Meta exige que o servidor retorne `200 OK` em até **5 segundos**. Caso contrário, ela reenvia o payload (retry) e, após falhas consecutivas, desativa o webhook. Atualmente o controller já responde `200` antes de processar — mas ao integrar a IA (Gemini), garantir que a inferência **nunca bloqueie** o retorno do 200 será crítico.

### Rate Limiting
Adicionar limitador de requisições no endpoint do webhook para proteger contra abuso ou loops de retry da Meta em cenários de instabilidade.

## Affected Project Files
| File | Uses this system? | Relationship |
|------|:-----------------:|--------------|
| `Backend/.env` | Sim | Armazena WHATSAPP_TOKEN permanente, PHONE_ID, VERIFY_TOKEN hub callback e GEMINI_API_KEY. |
| `Backend/docker-compose.yml` | Sim | Injeta as variáveis de WhatsApp/Gemini no container `backend`. |
| `Backend/src/services/whatsapp.service.ts` | Sim | Classe encapsulada portadora das requests HTTPS (POST) a Graph API da Meta via fetch node nativo. |
| `Backend/src/controllers/whatsapp.controller.ts` | Sim | Recebedor, validador de tráfego, responsável pela camada de persistência em MasterDB do chat text. |
| `Backend/src/routes/whatsapp.routes.ts` | Sim | Espelha o controlador à sub-rota '/whatsapp' que habita no `app.ts`. |
| `Backend/src/scripts/reset-db.ts` | Não | Limpa as tabelas de `mensagem_chat` num Database teardown global. |

## Changelog

### v2 — 2026-04-18
- Corrigido: remoção de log bruto de payload (segurança).
- Corrigido: tipagem `any` → `MetaApiResponse` e `Record<string, unknown>` no WhatsAppService.
- Adicionado: Seção completa de **Setup Guide** incluindo a etapa crítica de `subscribed_apps` na WABA.
- Adicionado: `docker-compose.yml` na tabela de arquivos afetados.

### v1 — 2026-04-18
- Estruturação base finalizada (Fase 1 à Fase 3). 
- Injeção das credenciais System User em variável de ambiente.
- Controller respondendo adequadamente as instâncias passivas e ativas de Hooking da Meta.
- Modelagem de gravação no PostgreSQL usando o MasterDB e as tabelas `sessao_chat` e `mensagem_chat` como forma de memória em curto\médio prazo para a vindoura Inteligência da Fase 4.
