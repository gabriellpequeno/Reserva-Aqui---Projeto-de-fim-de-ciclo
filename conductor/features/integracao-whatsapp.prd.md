# Feature PRD - Integracao WhatsApp

## Origem
- Canal principal do MVP para atendimento de hospedes
- Dependencia direta para futura camada de IA e RAG

## Problema
O hospede inicia a conversa pelo WhatsApp em um unico numero da plataforma, mas o backend precisa validar que a mensagem entrou no canal correto, registrar o historico com seguranca, evitar duplicidade de eventos e manter o fluxo pronto para automacoes futuras.

## Objetivo
Receber e responder mensagens do WhatsApp com seguranca operacional, vincular o hospede quando possivel, manter o historico completo da conversa no backend e cobrir os fluxos basicos de texto, midia simples e comprovante PDF de reserva aprovada.

## Personas
- **Hospede:** quer enviar uma mensagem simples, receber retorno imediato e obter comprovantes quando a reserva for confirmada.
- **Hotel:** quer que a conversa fique registrada corretamente e que o bot nao responda em duplicidade.
- **Equipe de IA:** precisa de um historico estruturado, idempotente e pronto para evoluir para RAG.

## User Stories
1. Como hospede, quero mandar mensagem para o numero oficial da plataforma e ter meu atendimento registrado sem erro.
2. Como time tecnico, quero validar que o webhook recebeu uma mensagem do canal oficial da plataforma.
3. Como time tecnico, quero impedir reprocessamento da mesma mensagem quando a Meta reenviar o evento.
4. Como hospede com conta ja criada, quero que meu historico do WhatsApp seja vinculado ao meu cadastro.
5. Como time tecnico, quero persistir tambem a resposta do bot e o ultimo status do envio para ter rastreabilidade operacional.
6. Como hospede, quero receber uma resposta profissional mesmo fora da janela de 24 horas.
7. Como hospede, quero receber uma resposta simples quando eu enviar audio, imagem ou documento, mesmo que a plataforma ainda nao processe o conteudo.
8. Como hospede com reserva aprovada, quero receber um PDF simples de confirmacao via WhatsApp.

## Criterios de Aceite
- [ ] Webhook GET valida corretamente o cadastro na Meta.
- [ ] Webhook POST responde `200` rapidamente para eventos validos.
- [ ] O webhook valida o `metadata.phone_number_id` apenas como canal global da plataforma quando `WHATSAPP_PHONE_ID` estiver configurado.
- [ ] O sistema deduplica mensagens inbound por `wamid` / `messages[0].id`.
- [ ] A sessao de chat do WhatsApp pode iniciar sem `hotel_id` definido.
- [ ] O sistema procura `user_id` pelo telefone normalizado e mantem guest quando nao encontrar conta.
- [ ] A mensagem recebida e persistida no historico com os metadados relevantes do canal.
- [ ] A resposta do bot e enviada e persistida no historico.
- [ ] O sistema salva o `message_id` retornado pela Meta e o ultimo status outbound conhecido.
- [ ] Fora da janela de 24 horas, o envio usa um template generico configurado.
- [ ] Audio, imagem e documento recebem resposta amigavel simples e tem seus metadados persistidos.
- [ ] Uma reserva aprovada pode gerar e enviar um PDF simples de confirmacao via WhatsApp.
- [ ] A sessao pode ser encerrada por fim de fluxo ou por inatividade configuravel.
- [ ] Eventos de status nao quebram o fluxo.

## Fora de Escopo desta rodada
- Resposta final com IA/RAG
- Resolucao do hotel por contexto conversacional
- Download e processamento real de midia
- Validacao criptografica do POST via assinatura da Meta
- Retry automatico de envio outbound
