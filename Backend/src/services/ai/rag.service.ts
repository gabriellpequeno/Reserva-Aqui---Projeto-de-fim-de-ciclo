import { GoogleGenerativeAIEmbeddings } from '@langchain/google-genai';
import { masterPool } from '../../database/masterDb';

export class RagService {
  /**
   * Busca no banco de dados os trechos de documento (FAQ, políticas, etc.) mais relevantes 
   * para a pergunta do usuário, garantindo que sejam exclusivos do hotel atual.
   * Utiliza busca por similaridade de cosseno (pgvector <=>).
   * 
   * @param query Mensagem/Pergunta do usuário
   * @param hotelId ID do hotel para isolar o contexto (Tenant safety)
   * @param limit Quantidade de fragmentos a recuperar (default: 3)
   * @returns String formatada contendo os trechos injetáveis no prompt
   */
  static async searchRelevantContext(query: string, hotelId: string, limit = 3): Promise<string> {
    const apiKey = process.env.GEMINI_API_KEY;
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

      // 3. Formata os chunks recuperados para passar à LLM
      const contextBlocks = rows.map((r, i) => `[Contexto ${i + 1} (Score: ${Number(r.similarity).toFixed(2)})]\\n${r.content}`);
      return contextBlocks.join('\\n\\n');
    } catch (error) {
      console.error('[RagService] Erro durante a busca vetorial:', error);
      return 'Erro interno ao recuperar contexto de IA.';
    } finally {
      if (client) client.release();
    }
  }
}
