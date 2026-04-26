import { invokeWithFallback } from './llmFactory';

export enum IntentType {
  DUVIDA = 'DUVIDA',     // RAG: Perguntas gerais, FAQ, políticas
  RESERVA = 'RESERVA',   // Agent + Tools: Disponibilidade, agendamento, preços
  OUTROS = 'OUTROS',     // Resposta direta leve: Saudações ou mensagens irrelevantes
}

export class IntentClassifierService {
  // Fast-path: saudações/encerramentos triviais. Evita chamada de rede.
  private static readonly FAST_PATH_OUTROS = /^\s*(oi+|ol[aá]+|oie+|e[ai]+|hey+|hello+|bom\s*dia|boa\s*tarde|boa\s*noite|tchau+|at[eé]\s*(mais|logo|breve)|valeu+|obrigad[oa]+|vlw+|brigad[oa]+|\?+|\.+|!+)\s*[!.?]*\s*$/i;

  static async classify(message: string, history: string[] = []): Promise<IntentType> {
    // Atalho sem IA para mensagens triviais (zero latência, zero quota)
    if (this.FAST_PATH_OUTROS.test(message)) {
      return IntentType.OUTROS;
    }

    if (!process.env.GEMINI_API_KEY && !process.env.GROQ_API_KEY) {
      console.warn('[IntentClassifier] Nenhum provider de IA configurado, fallback para OUTROS.');
      return IntentType.OUTROS;
    }

    const contextSection = history.length > 0
      ? `\nHISTÓRICO RECENTE (use para entender o que a mensagem atual quer dizer em contexto):\n${history.slice(-4).join('\n')}\n`
      : '';

    const prompt = `
Você é um classificador de intenções estrito para um assistente virtual de hotéis no WhatsApp.
Classifique a MENSAGEM ATUAL do usuário em EXATAMENTE UMA das categorias abaixo.
${contextSection}
Categorias permitidas:
1. DUVIDA: O usuário quer informações específicas sobre um hotel JÁ ESCOLHIDO (ex: horário de check-in/out, se aceita pets, café da manhã, regras, comodidades, endereço do hotel).
2. RESERVA: Qualquer fluxo de busca, disponibilidade ou reserva. Inclui:
   - Mencionar uma CIDADE, ESTADO ou REGIÃO (ex: "caruaru", "rio de janeiro", "pernambuco", "nordeste")
   - Nome de um hotel específico para selecionar
   - Perguntas sobre disponibilidade de quartos, preços, datas
   - Respostas curtas a uma pergunta anterior do bot sobre onde/quando (ex: bot perguntou a cidade e usuário respondeu só "caruaru")
   - Pedir para criar/confirmar reserva
3. OUTROS: Saudações ("oi", "bom dia"), encerramentos ("tchau", "obrigado"), ou mensagens aleatórias sem ligação com hotéis.

IMPORTANTE: Se o bot acabou de perguntar algo (cidade, datas, hotel) e o usuário respondeu, o contexto DETERMINA a categoria. Ex: bot pergunta cidade, usuário responde "caruaru" -> RESERVA.

Regra rigorosa: Responda APENAS com a palavra da categoria em MAIÚSCULAS (DUVIDA, RESERVA ou OUTROS). Nada além disso.

MENSAGEM ATUAL: "${message}"
Intenção:
    `.trim();

    try {
      const response = await invokeWithFallback(prompt, { temperature: 0 });
      const output = response.content.toString().trim().toUpperCase();

      if (output.includes('RESERVA')) return IntentType.RESERVA;
      if (output.includes('DUVIDA')) return IntentType.DUVIDA;

      return IntentType.OUTROS;
    } catch (error) {
      console.error('[IntentClassifier] Falha ao classificar a intenção (timeout ou API error). Fallback: OUTROS.', error);
      return IntentType.OUTROS;
    }
  }
}
