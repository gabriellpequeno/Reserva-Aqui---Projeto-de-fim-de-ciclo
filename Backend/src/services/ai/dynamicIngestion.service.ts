import { GoogleGenerativeAIEmbeddings } from '@langchain/google-genai';
import { masterPool } from '../../database/masterDb';

export class DynamicIngestionService {
  /**
   * Lê as configurações de um hotel (Tenant DB) e sincroniza na tabela de embeddings (Master DB).
   * Cria chunks de texto consolidados para que o LangChain possa fazer similaridade (RAG).
   */
  static async ingestHotelData(hotelId: string, schemaName: string): Promise<void> {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY não configurada no .env');
    }

    const embeddings = new GoogleGenerativeAIEmbeddings({
      apiKey,
      model: 'gemini-embedding-001',
    });

    const client = await masterPool.connect();

    try {
      // 1. Busca dados do Mestre
      const { rows: masterRows } = await client.query(`
        SELECT nome_hotel, descricao, cidade, uf, rua, numero, bairro
        FROM anfitriao
        WHERE hotel_id = $1
      `, [hotelId]);

      if (!masterRows[0]) {
        throw new Error(`Hotel ${hotelId} não encontrado no Master DB.`);
      }
      const hotelMaster = masterRows[0];

      // 2. Busca dados do Tenant (Configuração)
      await client.query(`SET search_path TO "${schemaName}", public`);
      
      const { rows: configRows } = await client.query(`
        SELECT horario_checkin, horario_checkout, max_dias_reserva, telefone_recepcao, politica_cancelamento, aceita_animais, idiomas_atendimento
        FROM configuracao_hotel
        WHERE hotel_id = $1
      `, [hotelId]);

      const config = configRows[0] || {};

      // 3. Monta o Documento Principal de FAQ/Políticas
      const fullText = `
Hotel: ${hotelMaster.nome_hotel}
Descrição: ${hotelMaster.descricao || 'Sem descrição'}
Endereço: ${hotelMaster.rua}, ${hotelMaster.numero}, ${hotelMaster.bairro}, ${hotelMaster.cidade} - ${hotelMaster.uf}

[Políticas e Regras do Hotel]
Horário de Check-in: ${config.horario_checkin || '14:00'}
Horário de Check-out: ${config.horario_checkout || '12:00'}
Estadia máxima permitida: ${config.max_dias_reserva || 30} dias
Telefone da Recepção: ${config.telefone_recepcao || 'Não informado'}
Política de Cancelamento: ${config.politica_cancelamento || 'Padrão (Consulte no check-in)'}
Aceita animais de estimação (Pets): ${config.aceita_animais ? 'Sim' : 'Não'}
Idiomas de Atendimento: ${config.idiomas_atendimento || 'Português'}
      `.trim();

      // 4. Gera Embeddings
      const vector = await embeddings.embedQuery(fullText);
      const vectorString = `[${vector.join(',')}]`;

      // 5. Salva na tabela do master 'documento_hotel'
      await client.query('SET search_path TO public');

      // Limpa os antigos embeddings de configuração geral para não duplicar
      await client.query(`
        DELETE FROM documento_hotel
        WHERE hotel_id = $1 AND metadata->>'tipo' = 'CONFIGURACAO_GERAL'
      `, [hotelId]);

      await client.query(`
        INSERT INTO documento_hotel (hotel_id, metadata, content, embedding)
        VALUES ($1, $2, $3, $4::vector)
      `, [
        hotelId,
        JSON.stringify({ tipo: 'CONFIGURACAO_GERAL', atualizado_em: new Date().toISOString() }),
        fullText,
        vectorString
      ]);

      console.log(`[DynamicIngestion] Configurações do hotel ${hotelId} vetorizadas e salvas com sucesso.`);
    } finally {
      await client.query('RESET search_path');
      client.release();
    }
  }
}
