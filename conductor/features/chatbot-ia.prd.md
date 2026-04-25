# PRD — chatbot-ia

## Contexto
A plataforma ReservAqui possui integração inicial com WhatsApp (Fase 4), mas as respostas ainda não processam o fluxo principal de negócios. Precisamos introduzir a inteligência artificial (Fase 5) para lidar de forma autônoma com o atendimento de dúvidas (RAG), criação de reservas via chat, interpretação de mídia e roteiros turísticos, reduzindo o tempo de resposta e a fricção para o usuário de forma inteligente e segura.

## Problema
- Alta fricção e abandono no processo de reserva tradicional (obrigação de baixar app, criar conta, buscar hotel manualmente).
- Hotéis perdem vendas por demorarem a responder dúvidas repetitivas de hóspedes (políticas, horários, amenidades) fora do horário comercial.
- Custos operacionais altos para os hotéis manterem atendimento humano 24/7.

## Público-alvo
- **Hóspedes** (registrados ou walk-ins) que buscam praticidade para consultar hotéis, esclarecer dúvidas e realizar reservas direto pelo WhatsApp.
- **Fornecedores (Hotéis)** que necessitam automatizar seu atendimento, melhorar o tempo de conversão e captar reservas de forma autônoma.

## Requisitos Funcionais
1. O sistema deve classificar a intenção da mensagem recebida no WhatsApp (dúvida, reserva, roteiro ou conversa) para roteamento inteligente, otimizando o uso de tokens da LLM.
2. O sistema deve manter uma base de conhecimento RAG "hotel-scoped" (usando pgvector) para responder dúvidas operacionais baseadas nas configurações e FAQs extraídos do banco de dados relacional.
3. O sistema deve disponibilizar ferramentas (Tools) para a IA consultar disponibilidade, listar hotéis que atendam a filtros específicos e checar preços consultando diretamente as tabelas canônicas de dados (sem cache no pgvector).
4. A IA deve orquestrar a criação de uma reserva de forma conversacional: caso o hóspede não seja reconhecido no sistema (walk-in), o bot deve solicitar e coletar obrigatoriamente Nome e CPF.
5. O sistema deve processar áudio e imagem, e para evitar timeout, deve disparar de forma antecipada uma mensagem avisando o usuário que a mídia "está sendo analisada" e pedindo para aguardar.
6. A reserva via bot deve prever uma variável de ambiente (`INFINITEPAY_BYPASS=true`) para desativar temporariamente a chamada externa de pagamento em ambiente local/testes.
7. O sistema deve registrar todas as respostas finais geradas pela IA no histórico permanente da sessão de chat.

## Requisitos Não-Funcionais
- [x] Performance: O webhook da Meta precisa obrigatoriamente retornar `200 OK` em menos de 5 segundos. O processamento da IA/Agents (incluindo processamento multimídia) deve ser totalmente assíncrono.
- [x] Performance: O classificador de intenções inicial deve ser leve (sempre que possível, heurístico ou prompt barato) para evitar gargalos antes do RAG/Tools. _(Regex fast-path + `gemini-2.5-flash-lite` — classifica saudações com zero chamada de rede.)_
- [x] Segurança: A IA precisa ser fortemente restringida via *Guardrails* (System Prompts estritos e schema validation via Zod) para evitar que atue fora das políticas do hotel ou altere dados não permitidos no banco. _(Guardrails de alucinação adicionados: cidades reais injetadas, prompts rígidos, respostas fixas quando não há dado confiável.)_
- [ ] Observabilidade: A arquitetura deve permitir instrumentação com LangSmith (quando chaves de API estiverem disponíveis) para auditoria e rastreamento de custos das chamadas LangChain. _(Próximo passo — ver backlog.)_
- [x] **[ADICIONADO] Resiliência multi-provider**: fallback automático Gemini ⇄ Groq em quota/429, retry respeitando `retry-after`, provider primário configurável via `.env`. Protege contra quota zerada de um provider e bursts de TPM.

## Critérios de Aceitação
- Dado um hóspede desconhecido (walk-in), quando tentar finalizar uma reserva via bot, então a IA deve explicitamente pedir o Nome e CPF do usuário antes de acionar a Tool de criação de reserva.
- Dado que o hóspede perguntou sobre política de animais ou horários, quando a intenção for classificada como dúvida de hotel, então o bot deve consultar via similarity search no pgvector (RAG) apenas documentos com o `hotel_id` resolvido e formular a resposta.
- Dado que a variável `INFINITEPAY_BYPASS` é `true`, quando o fluxo de reserva for completado pela IA, então a reserva deve ser salva com sucesso no banco bypassando a necessidade do pagamento real do InfinitePay.
- Dado que o usuário envia uma imagem ou áudio, quando o payload chega no webhook, então o bot deve enviar imediatamente um texto de "aguarde um instante, processando..." e processar de forma assíncrona para não quebrar a SLA da Meta.
- Dado que um usuário pede opções de hotéis em determinada cidade com certas comodidades, quando a mensagem for processada, então o bot deve acionar a tool de listagem filtrada e apresentar os resultados reais puxados do banco.

## Fora de Escopo
- Orquestração cíclica restrita utilizando LangGraph (ficará anotado como débito técnico/melhoria para iterações futuras mais robustas).
- RAG para base de pontos turísticos externos da cidade (será mantido estritamente para os dados do próprio hotel nesta versão).
- Envio de mídias (fotos, áudio) ativamente geradas pelo bot para o usuário.
- Pagamentos com outros métodos além da integração InfinitePay prevista.

## Backlog (diferido para próxima rodada)
Ver: `conductor/backlog/chatbot-ia.backlog.md`
- Processamento real de áudio recebido (transcrição via Whisper).
- Processamento real de imagem recebida (descrição/OCR via modelo multimodal).
- Observabilidade com LangSmith.
- Validação de assinatura da Meta (`X-Hub-Signature-256`).
- Retry automático de envio outbound WhatsApp.
- Transferência para atendimento humano.
- Migração do agent loop para LangGraph (state machine).
