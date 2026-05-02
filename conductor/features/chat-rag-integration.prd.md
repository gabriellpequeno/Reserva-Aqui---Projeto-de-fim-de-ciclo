# PRD — Chat RAG Integration (In-App)

## Contexto
A aba de chat (`lib/features/chat/presentation/pages/chat_page.dart`) existe na navegação do app mas opera com mensagens hardcoded e input desconectado. O backend já possui o `AgentOrchestratorService` — motor de IA com RAG, classificação de intenção e tools de reserva — totalmente funcional e exposto apenas via webhook do WhatsApp. Conectar o chat do app a este motor permite que o usuário converse com o assistente diretamente pelo app, sem necessidade do WhatsApp.

## Problema
O usuário vê a aba de chat na navegação do app, mas ela não faz nada. Qualquer mensagem digitada é ignorada. O assistente inteligente (mesmo motor que atende via WhatsApp) só é acessível por WhatsApp — um canal externo que nem todos os usuários utilizam.

## Público-alvo
Qualquer pessoa usando o app — não exige login. O bot pede CPF/nome quando necessário (ex: na hora de reservar), seguindo o mesmo padrão do fluxo WhatsApp.

## Requisitos Funcionais
1. Enviar mensagem de texto ao assistente IA via endpoint REST e receber resposta
2. Manter sessão persistente por dispositivo (UUID local salvo em SharedPreferences)
3. Exibir histórico da conversa na ListView (em memória durante a sessão do app)
4. Exibir indicador de "digitando" enquanto aguarda resposta do bot
5. Auto-scroll para a última mensagem após nova mensagem
6. Suportar `hotelId` opcional como parâmetro de rota para contextualizar a conversa
7. Se o usuário estiver logado (Bearer token presente), enriquecer a sessão com `userId`
8. Persistir mensagens no banco (tabela `mensagem_chat`) para que o `getChatHistory()` do orquestrador funcione

## Requisitos Não-Funcionais
- [ ] Performance: resposta do bot deve chegar em menos de 10s (tempo do LLM + RAG)
- [ ] Responsividade: funcionar em dispositivos móveis e web
- [ ] UX: feedback visual claro (loading, erro de rede, resposta do bot)
- [ ] Resiliência: erro de rede exibe SnackBar, não trava a tela

## Critérios de Aceitação
- Dado que o usuário abre a aba de chat, quando digita "Oi" e clica enviar, então recebe a mensagem de boas-vindas do bot
- Dado que o usuário pergunta "hotéis em Recife", quando o bot processa, então retorna hotéis cadastrados na cidade (se houver)
- Dado que a rede está offline, quando o usuário tenta enviar, então exibe SnackBar de erro
- Dado que o usuário navega para `/chat?hotelId=xxx` a partir da tela do hotel, quando conversa, então o bot já tem o contexto do hotel
- Dado que o usuário está logado, quando envia mensagem, então a sessão é associada ao `userId` para histórico

## Fora de Escopo
- Recriar ou alterar o motor de IA (AgentOrchestratorService, RAG, tools) — apenas expor via REST
- Persistência local de mensagens (SharedPreferences/SQLite) — histórico apenas em memória no app
- Chat com atendente humano (staff)
- Envio de áudio, imagem ou documento pelo chat in-app
- Notificações push de novas mensagens do bot
