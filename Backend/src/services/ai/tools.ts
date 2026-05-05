import { tool } from '@langchain/core/tools';
import { z } from 'zod';
import { masterPool } from '../../database/masterDb';
import { ChatContext, ContextResolverService } from './contextResolver.service';
import { sendPaymentLinkViaWhatsApp } from '../whatsappReservation.service';

/**
 * Cria e retorna as Tools (ferramentas) com o contexto de sessão acoplado.
 * Isso garante que a IA não sofra "alucinação" de IDs ou schemas, 
 * pois os dados sensíveis já vêm protegidos pela sessão.
 */
export const buildAgentTools = (context: ChatContext | null) => {
  const buscarHoteisTool = tool(
    async ({ cidade, uf }) => {
      try {
        let query = `SELECT hotel_id, nome_hotel, cidade, uf, descricao FROM anfitriao WHERE ativo = TRUE`;
        const params: any[] = [];
        
        if (cidade) {
          query += ` AND cidade ILIKE $1`;
          params.push(`%${cidade}%`);
        }
        if (uf) {
          query += ` AND uf ILIKE $${params.length + 1}`;
          params.push(uf);
        }
        
        const { rows } = await masterPool.query(query, params);
        if (rows.length === 0) return 'Nenhum hotel encontrado com esses critérios.';
        
        return JSON.stringify(rows);
      } catch (error) {
        return `Erro ao buscar hotéis: ${(error as Error).message}`;
      }
    },
    {
      name: 'buscar_hoteis',
      description: 'Busca hotéis disponíveis na plataforma ReservAqui. Use essa ferramenta para listar opções quando o usuário procurar por hotéis em uma cidade.',
      schema: z.object({
        cidade: z.string().optional().describe('A cidade desejada (ex: São Paulo, Rio de Janeiro).'),
        uf: z.string().optional().describe('A sigla do estado (ex: SP, RJ).'),
      }),
    }
  );

  const checarDisponibilidadeTool = tool(
    async ({ dataCheckin, dataCheckout }) => {
      if (!context?.hotelId || !context?.schemaName) {
        return 'ERRO: A IA precisa selecionar um hotel primeiro antes de checar a disponibilidade.';
      }

      const client = await masterPool.connect();
      try {
        await client.query(`SET search_path TO "${context.schemaName}", public`);
        
        const { rows } = await client.query(`
          SELECT q.id as quarto_id, q.numero, c.nome as categoria, c.preco_base, q.valor_override, c.capacidade_pessoas
          FROM quarto q
          JOIN categoria_quarto c ON q.categoria_quarto_id = c.id
          WHERE q.disponivel = TRUE AND q.deleted_at IS NULL
            AND NOT EXISTS (
              SELECT 1 FROM reserva r
              WHERE r.quarto_id = q.id 
                AND r.status IN ('SOLICITADA', 'AGUARDANDO_PAGAMENTO', 'APROVADA')
                AND r.data_checkin < $2 AND r.data_checkout > $1
            )
        `, [dataCheckin, dataCheckout]);
        
        if (rows.length === 0) return `Nenhum quarto disponível para as datas ${dataCheckin} até ${dataCheckout}.`;
        return JSON.stringify(rows);
      } catch (error) {
        return `Erro ao checar disponibilidade: ${(error as Error).message}`;
      } finally {
        await client.query('RESET search_path');
        client.release();
      }
    },
    {
      name: 'checar_disponibilidade',
      description: 'Verifica a disponibilidade de quartos no hotel ATUAL para datas específicas.',
      schema: z.object({
        dataCheckin: z.string().describe('Data de check-in desejada (formato YYYY-MM-DD).'),
        dataCheckout: z.string().describe('Data de check-out desejada (formato YYYY-MM-DD).'),
      }),
    }
  );

  const criarReservaTool = tool(
    async ({ quartoId, numHospedes, dataCheckin, dataCheckout, walkInNome, walkInCpf }) => {
      if (!context?.hotelId || !context?.schemaName) {
        return 'ERRO: Nenhum hotel selecionado no contexto atual.';
      }

      // Se não houver userId na sessão, exige Nome e CPF (Walk-In)
      if (!context.userId && (!walkInNome || !walkInCpf)) {
        return "ERRO DE VALIDAÇÃO: O usuário não está autenticado. Você DEVE obrigatoriamente perguntar o NOME COMPLETO e CPF do usuário antes de chamar essa ferramenta novamente.";
      }

      const client = await masterPool.connect();
      try {
        await client.query('BEGIN');
        await client.query(`SET search_path TO "${context.schemaName}", public`);

        // 1. Validar quarto e calcular preço
        const { rows: quartoRows } = await client.query(`
          SELECT c.preco_base, q.valor_override 
          FROM quarto q
          JOIN categoria_quarto c ON q.categoria_quarto_id = c.id
          WHERE q.id = $1 AND q.deleted_at IS NULL
        `, [quartoId]);

        if (quartoRows.length === 0) {
          throw new Error('Quarto não encontrado ou indisponível.');
        }

        const diaria = parseFloat(quartoRows[0].valor_override || quartoRows[0].preco_base);
        const dias = Math.ceil((new Date(dataCheckout).getTime() - new Date(dataCheckin).getTime()) / (1000 * 3600 * 24));
        if (dias <= 0) throw new Error('A data de check-out deve ser posterior à de check-in.');
        
        const valorTotal = diaria * dias;

        // 2. Criar a Reserva
        const { rows: reservaRows } = await client.query(`
          INSERT INTO reserva (
            user_id, nome_hospede, cpf_hospede, canal_origem, sessao_chat_id,
            quarto_id, num_hospedes, data_checkin, data_checkout, valor_total
          ) VALUES (
            $1, $2, $3, 'WHATSAPP', $4, $5, $6, $7, $8, $9
          ) RETURNING id, codigo_publico, status
        `, [
          context.userId || null,
          walkInNome || null,
          walkInCpf || null,
          context.sessionId,
          quartoId,
          numHospedes,
          dataCheckin,
          dataCheckout,
          valorTotal
        ]);

        const novaReserva = reservaRows[0];

        // 3. Cadastrar Roteamento Público no Master (para links e pagamentos)
        await client.query('SET search_path TO public');
        await client.query(`
          INSERT INTO reserva_routing (codigo_publico, hotel_id, schema_name)
          VALUES ($1, $2, $3)
        `, [novaReserva.codigo_publico, context.hotelId, context.schemaName]);

        await client.query('COMMIT');

        // Gera pagamento fake + envia link via WhatsApp e email (fire-and-forget).
        // Timer de 30 min é aplicado no backend (expires_at) e varrido pelo job.
        sendPaymentLinkViaWhatsApp({
          hotelId:   context.hotelId,
          reservaId: novaReserva.id,
        }).catch(() => {});

        const resMsg = `SUCESSO! Reserva criada. ID: ${novaReserva.id}. Valor total: R$ ${valorTotal.toFixed(2)}.`
          + ' [Aviso ao bot: informe ao usuário que já enviamos o link de pagamento por este chat e por email. O link expira em 30 minutos.]';

        return resMsg;
      } catch (error) {
        await client.query('ROLLBACK');
        return `Erro crítico ao criar reserva: ${(error as Error).message}`;
      } finally {
        await client.query('RESET search_path');
        client.release();
      }
    },
    {
      name: 'criar_reserva',
      description: 'Cria uma nova reserva para um quarto disponível. Apenas chame essa ferramenta APÓS confirmar a disponibilidade e confirmar com o usuário.',
      schema: z.object({
        quartoId: z.number().describe('O ID numérico do quarto escolhido.'),
        numHospedes: z.number().describe('Quantidade de hóspedes para a estadia.'),
        dataCheckin: z.string().describe('Data de check-in (formato YYYY-MM-DD).'),
        dataCheckout: z.string().describe('Data de check-out (formato YYYY-MM-DD).'),
        walkInNome: z.string().optional().describe('Se o usuário não for cadastrado, passe o nome completo aqui.'),
        walkInCpf: z.string().optional().describe('Se o usuário não for cadastrado, passe o CPF aqui.'),
      }),
    }
  );

  const selecionarHotelTool = tool(
    async ({ hotelIdSelecionado }) => {
      try {
        await ContextResolverService.setHotelContext(context?.sessionId || '', hotelIdSelecionado);
        return 'Hotel selecionado com sucesso! A partir de agora, as próximas perguntas e checagens de disponibilidade serão limitadas a este hotel.';
      } catch (error) {
        return `Erro ao selecionar hotel: ${(error as Error).message}`;
      }
    },
    {
      name: 'selecionar_hotel',
      description: 'Seleciona e "trava" o contexto do chat em um hotel específico. Chame esta ferramenta APÓS o usuário confirmar o hotel que deseja ver ou reservar.',
      schema: z.object({
        hotelIdSelecionado: z.string().describe('O ID do hotel escolhido pelo usuário.'),
      }),
    }
  );

  return [buscarHoteisTool, selecionarHotelTool, checarDisponibilidadeTool, criarReservaTool];
};
