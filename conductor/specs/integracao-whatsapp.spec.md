# Spec - Integracao WhatsApp

## Visao Geral
O webhook do WhatsApp permanece em `${API_PREFIX}/whatsapp/webhook`. Como a plataforma usa um unico numero de atendimento, o fluxo desta rodada valida o canal global, tenta associar o remetente a um `user_id` existente, deduplica eventos inbound por `wamid`, persiste a mensagem recebida e mantem rastreabilidade do outbound com `message_id` e ultimo status conhecido. O `hotel_id` da sessao continua existindo, mas nao e resolvido no ingresso cru do webhook.

## Endpoints

### GET `${API_PREFIX}/whatsapp/webhook`
- Responsabilidade: validacao passiva da Meta via `hub.verify_token`
- Resposta de sucesso: `200` com `hub.challenge`
- Falha de validacao: `403`

### POST `${API_PREFIX}/whatsapp/webhook`
- Responsabilidade: receber eventos da Meta e despachar mensagens novas
- Regra principal: responder `200` imediatamente para eventos validos
- Eventos de status: atualizar apenas o ultimo status outbound conhecido
- Mensagens duplicadas: ignoradas apos deduplicacao por `wamid`
- Mensagens nao-texto: persistir metadados e responder de forma amigavel por tipo

## Modelo de Dados

### `sessao_chat` (master)
- Campo existente/necessario: `hotel_id UUID REFERENCES anfitriao(hotel_id)`
- Semantica: hotel da conversa quando esse contexto for identificado
- Regra nesta rodada: o campo pode iniciar `NULL`
- Lookup principal: `(canal='WHATSAPP', identificador_externo, status='ABERTA')`
- Encerramento: por fim de fluxo ou por inatividade configuravel via `.env`

### `mensagem_chat` (master)
- Continuar usando `origem='CLIENTE'` para a entrada do hospede
- Continuar usando `origem='BOT_SISTEMA'` para respostas automaticas
- Estender com metadados opcionais do canal WhatsApp, preferencialmente no proprio registro:
  - `meta_message_id`
  - `tipo_mensagem`
  - `meta_status`
  - `metadata_json`
- `meta_message_id` inbound deve suportar deduplicacao por unicidade

### Configuracoes `.env`
- `WHATSAPP_SESSION_IDLE_HOURS`
- `WHATSAPP_DEFAULT_TEMPLATE_NAME`
- `WHATSAPP_DEFAULT_TEMPLATE_LANG`

## Fluxo
1. Extrair `metadata.phone_number_id` e `messages[0]` do payload.
2. Se `WHATSAPP_PHONE_ID` estiver configurado, validar que o evento pertence ao canal oficial da plataforma; payload divergente e ignorado.
3. Se houver `messages[0].id`, verificar deduplicacao por `wamid`. Evento duplicado deve retornar `200` sem reprocesamento.
4. Normalizar o numero do remetente removendo caracteres nao numericos.
5. Procurar usuario em `usuario.numero_celular` com comparacao normalizada.
6. Buscar ou criar `sessao_chat` por canal + numero + status aberto.
7. Para mensagem de texto:
   - persistir a mensagem recebida como `CLIENTE`
   - decidir envio outbound:
     - `sendText` dentro da janela operacional
     - `sendTemplate` com template generico configurado fora da janela de 24 horas
   - persistir a resposta do bot como `BOT_SISTEMA`
   - salvar o `message_id` retornado pela Meta no outbound
8. Para audio, imagem e documento:
   - persistir a mensagem com metadados disponiveis do payload
   - responder com texto simples especifico por tipo
   - nao baixar o arquivo nesta rodada
9. Para eventos de status:
   - localizar a mensagem outbound correspondente
   - atualizar apenas o ultimo status conhecido (`sent`, `delivered`, `read`, `failed`, etc.)
10. Para envio de comprovante:
   - consultar dados da reserva no banco
   - gerar PDF simples no backend
   - enviar via WhatsApp como documento somente para reserva aprovada/confirmada
   - persistir esse outbound no historico
11. Deixar `hotel_id` da sessao para enriquecimento posterior, quando a conversa ou a reserva apontarem o hotel correto.

## Decisoes Tecnicas
- `phone_number_id` e usado apenas para validar o canal oficial da plataforma, nao para identificar o hotel.
- O roteamento por hotel sera feito depois, via contexto da conversa, reserva ou selecao explicita.
- A sessao continua armazenando `hotel_id`, mas esse campo pode ser preenchido em um passo posterior do pipeline.
- Deduplicacao inbound deve ser persistente em banco, nao apenas em memoria.
- Salvar apenas o ultimo status outbound reduz complexidade sem perder o essencial para operacao do canal.
- Fora da janela de 24 horas, usar um unico template generico configurado e mais profissional do que falhar silenciosamente.
- A rodada continua sem download/processamento real de midia; apenas metadados e respostas amigaveis.
- O PDF deve ser simples, gerado no backend com dependencia leve, sem framework pesado.

## Riscos
- Sem uma etapa posterior de resolucao do hotel, o RAG nao podera consultar a base correta.
- Diferencas de formato em numeros de telefone podem impedir a vinculacao do hospede se os dados cadastrais estiverem inconsistentes.
- Sem retry automatico, uma falha outbound continuara exigindo observabilidade e tratamento manual.
- O fallback por template depende de template aprovado e configurado na Meta.

## Implementacao Futura
- Resolucao de hotel por contexto da conversa / reserva / selecao explicita
- Download real de midia
- Transcricao de audio
- OCR / interpretacao de imagem
- Validacao criptografica do POST via assinatura da Meta
- Retry automatico de envio outbound
- Transferencia para atendimento humano
