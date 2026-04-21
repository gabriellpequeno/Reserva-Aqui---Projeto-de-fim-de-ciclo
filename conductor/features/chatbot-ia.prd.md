# Feature PRD - Chatbot IA com RAG

## Origem
- Continuação direta da integração WhatsApp
- Responsável por responder dúvidas sobre o hotel e iniciar fluxos de reserva/roteiro

## Problema
Hoje o WhatsApp já registra a conversa e devolve uma resposta provisória, mas ainda não identifica o hotel dentro de um canal compartilhado nem responde com base nos dados reais do produto.

## Objetivo
Automatizar o atendimento do WhatsApp resolvendo primeiro o hotel da conversa e depois combinando dados estruturados do banco relacional com regras, FAQ e políticas indexadas em `pgvector`.

## Personas
- **Hóspede:** quer resposta rápida sobre políticas, serviços e estrutura do hotel.
- **Hotel:** quer reduzir dúvidas repetitivas e manter respostas coerentes com suas próprias regras, preços e disponibilidade.
- **Equipe do produto:** quer uma base sólida para expandir para reservas e roteiros via IA.

## User Stories
1. Como hóspede, quero perguntar algo pelo número único da plataforma e receber uma resposta do hotel correto.
2. Como hotel, quero que o bot use apenas o contexto do meu hotel, não de outro.
3. Como sistema, quero consultar preços, disponibilidade e reservas no banco relacional, e usar `pgvector` para FAQ, políticas e documentos.
4. Como equipe técnica, quero persistir a resposta final da IA no mesmo histórico do chat.

## Critérios de Aceite
- [ ] O sistema resolve ou solicita o hotel antes de usar conhecimento hotel-scoped.
- [ ] Cada hotel possui sua própria base de documentos.
- [ ] Preços, disponibilidade e reservas são consultados nas tabelas canônicas do banco.
- [ ] O RAG usa `pgvector` para buscar trechos relevantes.
- [ ] O bot responde dúvidas do hotel com base nos documentos cadastrados.
- [ ] O sistema classifica intenção mínima entre dúvida, reserva e roteiro.
- [ ] A resposta final da IA substitui a resposta provisória no fluxo principal.
- [ ] A resposta final fica salva no histórico da conversa.

## Fora de Escopo desta rodada
- RAG para base turística externa
- Áudio e imagem
- Automação completa de reserva/pagamento pelo agente
