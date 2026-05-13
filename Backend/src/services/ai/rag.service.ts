import { GoogleGenerativeAIEmbeddings } from '@langchain/google-genai';
import { masterPool } from '../../database/masterDb';

// ── Configuração do RAG Pipeline ──────────────────────────────────────────────
const RAG_MIN_RELEVANCE_SCORE = 0.55;   // Score mínimo para considerar documento relevante (chunks de política .md tendem a scores mais baixos)
const RAG_TOP_K_DOCS          = 5;      // Máximo de documentos recuperados por busca
const RAG_MAX_DOC_CONTENT_LEN = 5000;   // Máximo de caracteres por documento (trunca o excedente)

export class RagService {
  /**
   * Busca no banco de dados os trechos de documento (FAQ, políticas, etc.) mais relevantes 
   * para a pergunta do usuário, garantindo que sejam exclusivos do hotel atual.
   * Utiliza busca por similaridade de cosseno (pgvector <=>).
   * 
   * @param query Mensagem/Pergunta do usuário
   * @param hotelId ID do hotel para isolar o contexto (Tenant safety)
   * @param limit Quantidade de fragmentos a recuperar
   * @returns String formatada contendo os trechos injetáveis no prompt
   */
  static async searchRelevantContext(query: string, hotelId: string, limit = RAG_TOP_K_DOCS): Promise<string> {
    const apiKey = process.env.GEMINI_API_KEY?.split(',')[0]?.trim();
    if (!apiKey) {
      console.warn('[RagService] GEMINI_API_KEY não configurada. Ignorando RAG.');
      return '';
    }

    const embeddings = new GoogleGenerativeAIEmbeddings({
      apiKey,
      model: 'gemini-embedding-001',
    });

    let client;
    try {
      client = await masterPool.connect();

      // 1. Gera o vetor (embedding) da pergunta
      const vector = await embeddings.embedQuery(query);
      const vectorString = `[${vector.join(',')}]`;

      // 2. Executa a busca vetorial estrita (filtrando por hotel_id)
      // O operador <=> calcula a distância do cosseno.
      const { rows } = await client.query(`
        SELECT content, 1 - (embedding <=> $2::vector) as similarity
        FROM documento_hotel
        WHERE hotel_id = $1
        ORDER BY embedding <=> $2::vector ASC
        LIMIT $3
      `, [hotelId, vectorString, limit]);

      if (rows.length === 0) {
        return 'Nenhum documento ou contexto de RAG encontrado para este hotel.';
      }

      // 3. Filtra por score mínimo de relevância — descarta resultados de baixa qualidade
      const relevant = rows.filter(r => Number(r.similarity) >= RAG_MIN_RELEVANCE_SCORE);

      if (relevant.length === 0) {
        console.log(`[RagService] ${rows.length} docs encontrados, mas nenhum acima do score mínimo (${RAG_MIN_RELEVANCE_SCORE}). Melhor score: ${Number(rows[0].similarity).toFixed(3)}`);
        return 'Nenhum documento relevante encontrado para esta pergunta.';
      }

      // 4. Formata os chunks recuperados para passar à LLM (truncando se necessário)
      const contextBlocks = relevant.map((r, i) => {
        const content = r.content.length > RAG_MAX_DOC_CONTENT_LEN
          ? r.content.substring(0, RAG_MAX_DOC_CONTENT_LEN) + '... [truncado]'
          : r.content;
        return `[Contexto ${i + 1} (Score: ${Number(r.similarity).toFixed(2)})]\n${content}`;
      });

      return contextBlocks.join('\n\n');
    } catch (error) {
      console.error('[RagService] Erro durante a busca vetorial:', error);
      return 'Erro interno ao recuperar contexto de IA.';
    } finally {
      if (client) client.release();
    }
  }
}
