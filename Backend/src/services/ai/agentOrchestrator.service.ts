import { HumanMessage, SystemMessage, AIMessage, ToolMessage } from '@langchain/core/messages';
import { IntentClassifierService, IntentType } from './intentClassifier.service';
import { RagService } from './rag.service';
import { buildAgentTools } from './tools';
import { ChatContext } from './contextResolver.service';
import { masterPool } from '../../database/masterDb';
import { invokeWithFallback } from './llmFactory';

export class AgentOrchestratorService {
  /**
   * Processa a mensagem do usuário executando o roteamento da IA.
   * Divide o fluxo entre DÚVIDA (RAG), RESERVA (Agente com Tools) e OUTROS (Conversa normal).
   */
  static async processMessage(sessionId: string, userMessage: string, context: ChatContext): Promise<string> {
    if (!process.env.GEMINI_API_KEY && !process.env.GROQ_API_KEY) {
      return 'Desculpe, nosso assistente inteligente está temporariamente indisponível.';
    }

    // 1. Buscar histórico primeiro (o classifier precisa dele pra entender contexto)
    const history = await this.getChatHistory(sessionId);

    // 2. Monta texto resumido do histórico para dar contexto ao classifier
    const historyAsText = history.slice(-4).map(m => {
      const role = m instanceof HumanMessage ? 'Usuário' : 'Bot';
      return `${role}: ${m.content}`;
    });

    // 3. Classifica com contexto
    let intent = await IntentClassifierService.classify(userMessage, historyAsText);

    // 4. Defesa em profundidade: se DUVIDA ou OUTROS sem hotel selecionado,
    //    rotear para RESERVA — só o agente de reserva tem a tool para buscar hotéis no banco.
    if (!context.hotelId && intent !== IntentType.RESERVA) {
      // Re-roteia quando a mensagem PARECE buscar hotel (cidade, estado, "hotel em", etc.)
      if (this.looksLikeHotelSearch(userMessage)) {
        console.log(`[AgentOrchestrator] Re-roteando ${intent} -> RESERVA (mensagem parece busca de hotel, sem hotel selecionado)`);
        intent = IntentType.RESERVA;
      }
    }

    console.log(`[AgentOrchestrator] Intenção detectada: ${intent} | Sessão: ${sessionId}`);

    // 5. Roteamento (Semantic Router simples)
    if (intent === IntentType.DUVIDA) {
      return this.handleDuvida(userMessage, context, history);
    } else if (intent === IntentType.RESERVA) {
      return this.handleReserva(userMessage, context, history);
    } else {
      return this.handleOutros(userMessage, history);
    }
  }

  // Heurística: true se a mensagem não for claramente apenas saudação/encerramento
  // E tiver ao menos uma palavra substantiva. Cobre casos como "caruaru", "em SP",
  // "cidade de recife", "procuro hotel", "quero reservar", etc.
  private static looksLikeHotelSearch(message: string): boolean {
    const trimmed = message.trim();
    if (trimmed.length < 2) return false;

    const onlyGreeting = /^\s*(oi+|ol[aá]+|oie+|hey+|hello+|bom\s*dia|boa\s*tarde|boa\s*noite|tchau+|valeu+|obrigad[oa]+|vlw+|brigad[oa]+)\s*[!.?]*\s*$/i;
    if (onlyGreeting.test(trimmed)) return false;

    // Qualquer menção a busca/reserva/cidade/estado conhecido dispara RESERVA
    const searchCues = /(hot[eé]l|hotel|hoteis|hotéis|reserva|quarto|disponibilidade|di[aá]ria|pre[çc]o|buscar|procuro|procurar|quero|vou\s+pra|em\s+[a-zà-ú]+|cidade\s+de|estado\s+de|ver\s+op[çc][õo]es|op[çc][õo]es)/i;
    if (searchCues.test(trimmed)) return true;

    // Palavra isolada ou curta que não é saudação — provavelmente nome de cidade/estado
    const wordCount = trimmed.split(/\s+/).length;
    if (wordCount <= 4) return true;

    return false;
  }

  private static async getChatHistory(sessionId: string) {
    // Histórico enxuto (6 últimas) pra economizar TPM do Groq e latência.
    const { rows } = await masterPool.query(`
      SELECT origem, conteudo
      FROM mensagem_chat
      WHERE sessao_chat_id = $1
      ORDER BY criado_em DESC
      LIMIT 6
    `, [sessionId]);

    // Coloca na ordem cronológica (mais antiga -> mais nova)
    rows.reverse();

    return rows.map(r => r.origem === 'CLIENTE' ? new HumanMessage(r.conteudo) : new AIMessage(r.conteudo));
  }

  private static async handleDuvida(userMessage: string, context: ChatContext, history: any[]): Promise<string> {
    // Sem hotel selecionado: resposta fixa, NÃO chamar LLM (evita alucinação total).
    if (!context.hotelId) {
      return 'Pra eu responder dúvidas específicas (como horário de check-in, regras de pet, café da manhã, etc.) eu preciso saber de qual hotel você está falando. Me diga a cidade ou o nome do hotel que você tem interesse e eu te mostro as opções disponíveis na ReservAqui.';
    }

    const ragContext = await RagService.searchRelevantContext(userMessage, context.hotelId);

    // Se RAG não trouxe nada útil, resposta fixa também — sem risco de alucinação.
    if (!ragContext || ragContext.startsWith('Nenhum documento') || ragContext.startsWith('Erro')) {
      return 'Não tenho essa informação registrada pra esse hotel no momento. Recomendo falar direto com a recepção pra confirmar.';
    }

    const systemPrompt = `
Você é o assistente de dúvidas da plataforma ReservAqui.

FONTE DA VERDADE (única permitida):
===
${ragContext}
===

REGRAS ABSOLUTAS (não pode quebrar em hipótese alguma):
1. SÓ responda usando as informações da FONTE DA VERDADE acima. Se a resposta não estiver literal e claramente lá, diga: "Não tenho essa informação registrada, recomendo falar com a recepção."
2. PROIBIDO usar conhecimento do seu treinamento, conhecimento geral sobre hotéis, ou qualquer informação externa.
3. PROIBIDO inventar preços, horários, nomes, endereços, serviços, políticas, comodidades, avaliações ou qualquer dado que não esteja explícito na FONTE acima.
4. PROIBIDO citar ou mencionar hotéis que não sejam o selecionado.
5. Seja direto e conciso (máximo 3-4 frases). Tom amigável e profissional.
    `.trim();

    const response = await invokeWithFallback(
      [new SystemMessage(systemPrompt), ...history, new HumanMessage(userMessage)],
      { temperature: 0 },
    );

    return response.content.toString();
  }

  private static async getCidadesDisponiveis(): Promise<string> {
    try {
      const { rows } = await masterPool.query(`
        SELECT DISTINCT cidade, uf
        FROM anfitriao
        WHERE ativo = TRUE
        ORDER BY uf, cidade
      `);
      if (rows.length === 0) return 'Nenhuma cidade cadastrada.';
      return rows.map(r => `${r.cidade}/${r.uf}`).join(', ');
    } catch (e) {
      console.error('[AgentOrchestrator] Falha ao buscar cidades:', e);
      return 'Nenhuma cidade cadastrada.';
    }
  }

  private static async handleReserva(userMessage: string, context: ChatContext, history: any[]): Promise<string> {
    const tools = buildAgentTools(context);
    const cidadesDisponiveis = await this.getCidadesDisponiveis();

    const systemPrompt = `
Agente de Reservas ReservAqui. Tools: buscar_hoteis, selecionar_hotel, checar_disponibilidade, criar_reserva.

CIDADES DISPONÍVEIS (única fonte): ${cidadesDisponiveis}

REGRAS:
1. Cidade/estado mencionado → PRIMEIRA ação: chamar buscar_hoteis. Proibido afirmar existência de hotel sem chamar a tool.
2. "Nenhum hotel encontrado" → informe e sugira APENAS cidades da lista acima. Proibido sugerir outras.
3. Usuário confirmou hotel → chamar selecionar_hotel com o ID.
4. Disponibilidade → só com hotel selecionado; peça datas se faltar; chame checar_disponibilidade.
5. Reserva → criar_reserva só após checar_disponibilidade. Se ferramenta disser "ERRO DE VALIDAÇÃO", peça nome+CPF.
6. Após qualquer tool, SEMPRE responda em texto. Nunca deixe em branco.
7. Tom profissional, conciso, amigável. Nada de repetir loops.

Estado: Hotel=${context.hotelId ? 'SIM' : 'NÃO'} | UsuárioAutenticado=${context.userId ? 'SIM' : 'NÃO (pedir nome+CPF na hora de reservar)'}
    `.trim();

    const messages: any[] = [
      new SystemMessage(systemPrompt),
      ...history,
      new HumanMessage(userMessage)
    ];

    const MAX_ITERATIONS = 3;
    let response = await invokeWithFallback(messages, { temperature: 0, tools });
    let lastToolResult = '';

    for (let i = 0; i < MAX_ITERATIONS; i++) {
      if (!response.tool_calls || response.tool_calls.length === 0) break;

      messages.push(response);

      for (const call of response.tool_calls) {
        console.log(`[AgentOrchestrator] Invocando Tool: ${call.name} (iter ${i + 1})`);
        const tool = tools.find(t => t.name === call.name);
        if (!tool) {
          messages.push(new ToolMessage({
            name: call.name,
            tool_call_id: call.id as string,
            content: `Ferramenta desconhecida: ${call.name}`
          }));
          continue;
        }
        try {
          const result = await (tool as any).invoke(call.args);
          lastToolResult = result.toString();
          messages.push(new ToolMessage({
            name: call.name,
            tool_call_id: call.id as string,
            content: lastToolResult
          }));
        } catch (e) {
          messages.push(new ToolMessage({
            name: call.name,
            tool_call_id: call.id as string,
            content: `Erro fatal na ferramenta: ${(e as Error).message}`
          }));
        }
      }

      response = await invokeWithFallback(messages, { temperature: 0, tools });
    }

    const finalText = response.content.toString().trim();

    // Defesa: se o modelo terminou sem produzir texto, construímos resposta a partir do último tool result.
    if (!finalText) {
      console.warn('[AgentOrchestrator] Resposta final vazia após loop de tools. Montando fallback a partir do último tool result.');
      if (lastToolResult.startsWith('Nenhum hotel encontrado') || lastToolResult.startsWith('Nenhum quarto disponível')) {
        return `${lastToolResult} Nas cidades cadastradas temos: ${cidadesDisponiveis}. Quer que eu busque em alguma dessas?`;
      }
      if (lastToolResult.startsWith('ERRO')) {
        return lastToolResult.replace(/^ERRO(\s+DE\s+VALIDAÇÃO)?:\s*/i, '');
      }
      return 'Posso te ajudar com busca de hotéis, disponibilidade, reservas ou dúvidas. Me diga a cidade em que você tem interesse.';
    }

    return finalText;
  }

  // Saudações que disparam o welcome pitch (apresentação) fixo, sem chamar LLM.
  private static readonly GREETING_REGEX = /^\s*(oi+|ol[aá]+|oie+|e[ai]+|hey+|hello+|bom\s*dia|boa\s*tarde|boa\s*noite|salve+|come[çc]ar|in[ií]cio|menu|ajuda|help|iniciar)\s*[!.?]*\s*$/i;

  private static readonly WELCOME_PITCH =
    'Olá! 👋 Seja bem-vindo(a) à ReservAqui — seu assistente de reservas de hotéis. Posso te ajudar a:\n\n' +
    '• 🔎 Buscar hotéis em uma cidade\n' +
    '• 🛏️ Conferir disponibilidade de quartos para suas datas\n' +
    '• ✅ Fazer uma reserva\n' +
    '• 💬 Tirar dúvidas sobre um hotel (horários, regras, serviços)\n\n' +
    'É só me dizer o que você precisa!';

  private static async handleOutros(userMessage: string, history: any[]): Promise<string> {
    // Apresentação fixa em saudações — sempre, independente de ser 1ª interação ou não.
    if (this.GREETING_REGEX.test(userMessage)) {
      return this.WELCOME_PITCH;
    }

    const systemPrompt = `
Você é o assistente virtual do sistema ReservAqui, um sistema de reservas de hotéis.

REGRAS ABSOLUTAS:
1. PROIBIDO responder perguntas sobre hotéis específicos, preços, disponibilidade, cidades ou qualquer conteúdo de negócio. Essas perguntas devem ser redirecionadas para "me diga a cidade que tem interesse que eu busco as opções".
2. PROIBIDO usar conhecimento geral sobre viagens, hospedagem, ou qualquer assunto. Você NÃO é um assistente geral — é exclusivo da ReservAqui.
3. PROIBIDO inventar informações, nomes de hotéis, cidades atendidas, promoções ou qualquer dado.

COMPORTAMENTO PERMITIDO:
- Saudações simples ("oi", "bom dia"): retribuir rapidamente e perguntar como ajudar com hospedagens.
- Despedidas ("tchau", "obrigado"): retribuir brevemente.
- Mensagens sem sentido ou fora de contexto: redirecionar educadamente para reservas ou dúvidas.

Sempre curto (máximo 2 frases). Tom amigável e profissional.
    `.trim();

    const response = await invokeWithFallback(
      [new SystemMessage(systemPrompt), ...history, new HumanMessage(userMessage)],
      { temperature: 0.4 },
    );
    return response.content.toString();
  }
}
