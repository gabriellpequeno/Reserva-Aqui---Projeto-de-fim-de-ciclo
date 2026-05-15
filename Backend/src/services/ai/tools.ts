import { tool } from '@langchain/core/tools';
import { z } from 'zod';
import { masterPool } from '../../database/masterDb';
import { ChatContext, ContextResolverService } from './contextResolver.service';
import { createReservaChat } from '../reserva.service';
import { getReservaByCodigoPublico } from '../reserva.service';

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
        
        // Explicit label so LLM knows to use hotel_id (UUID) — not the name — in selecionar_hotel
        return JSON.stringify(rows.map(r => ({
          hotel_id:  r.hotel_id,   // <- use this UUID in selecionar_hotel
          nome_hotel: r.nome_hotel,
          cidade:    r.cidade,
          uf:        r.uf,
          descricao: r.descricao,
        })));
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
    async ({ quartoId, numHospedes, dataCheckin, dataCheckout, walkInNome, walkInEmail, walkInTelefone }) => {
      if (!context?.hotelId || !context?.schemaName) {
        return 'ERRO: Nenhum hotel selecionado no contexto atual.';
      }

      // Se não houver userId na sessão, exige Nome, Email e Telefone
      if (!context.userId && (!walkInNome || !walkInEmail || !walkInTelefone)) {
        return "ERRO DE VALIDAÇÃO: O usuário não está autenticado. Você DEVE obrigatoriamente perguntar o NOME COMPLETO, EMAIL e TELEFONE (WhatsApp) do usuário antes de chamar essa ferramenta novamente.";
      }

      // Validação de formato do email em runtime — não no schema Zod, porque
      // o JSON Schema gerado por z.string().email() usa uma regex com features
      // que o Groq rejeita (invalid 'regex' format). Mantendo a checagem aqui
      // dentro, garantimos que dado ruim (ex.: "email" literal) não entre no
      // banco sem quebrar o registro da tool no provider.
      if (walkInEmail && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(walkInEmail)) {
        return `ERRO DE VALIDAÇÃO: "${walkInEmail}" não é um email válido. Pergunte o endereço de email completo (formato nome@dominio.com) e chame a tool novamente com o valor correto.`;
      }

      try {
        const reserva = await createReservaChat({
          hotel_id:       context.hotelId,
          quarto_id:      quartoId,
          num_hospedes:   numHospedes,
          data_checkin:   dataCheckin,
          data_checkout:  dataCheckout,
          canal_origem:   context.canal,
          sessao_chat_id: context.sessionId,
          user_id:        context.userId ?? null,
          nome_hospede:   walkInNome ?? null,
          email_hospede:  walkInEmail ?? null,
          telefone_contato: walkInTelefone ?? null,
        });

        return `SUCESSO! Reserva criada com código ${reserva.codigo_publico}. `
          + `Status: ${reserva.status}. Valor total: R$ ${Number(reserva.valor_total).toFixed(2)}. `
          + `Datas: ${dataCheckin} a ${dataCheckout}. `
          + `[Aviso ao bot: informe o código ${reserva.codigo_publico} ao usuário. `
          + `Já enviamos o link de pagamento por este chat e por email. O link expira em 30 minutos.]`;
      } catch (error) {
        return `ERRO CRÍTICO ao criar reserva: ${(error as Error).message}. NÃO informe ao usuário que a reserva foi criada.`;
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
        walkInNome: z.string().optional().describe('Nome completo do hóspede. OBRIGATÓRIO se o usuário não estiver logado.'),
        walkInEmail: z.string().optional().describe('Email do hóspede. OBRIGATÓRIO se o usuário não estiver logado. Será usado para enviar a confirmação e o link de pagamento.'),
        walkInTelefone: z.string().optional().describe('Telefone ou WhatsApp do hóspede (apenas números). OBRIGATÓRIO se o usuário não estiver logado.'),
      }),
    }
  );

  const consultarReservaTool = tool(
    async ({ codigoPublico }) => {
      try {
        const reserva = await getReservaByCodigoPublico(codigoPublico);

        return JSON.stringify({
          codigo_publico:  reserva.codigo_publico,
          status:          reserva.status,
          data_checkin:    reserva.data_checkin,
          data_checkout:   reserva.data_checkout,
          num_hospedes:    reserva.num_hospedes,
          valor_total:     reserva.valor_total,
          tipo_quarto:     reserva.tipo_quarto,
          nome_hospede:    reserva.nome_hospede,
        });
      } catch (error) {
        return `Reserva com código "${codigoPublico}" não encontrada. Verifique se o código está correto.`;
      }
    },
    {
      name: 'consultar_reserva',
      description: 'Consulta o status de uma reserva existente pelo código público (ex: formato UUID). Antes de revelar os detalhes ao usuário, peça a confirmação do NOME do hóspede para garantir segurança.',
      schema: z.object({
        codigoPublico: z.string().describe('O código público da reserva informado pelo usuário.'),
      }),
    }
  );

  const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

  const selecionarHotelTool = tool(
    async ({ hotelIdSelecionado }) => {
      // Guard: LLM sometimes passes the hotel name instead of the UUID.
      // Return a clear error so it corrects itself without crashing Postgres.
      if (!UUID_REGEX.test(hotelIdSelecionado)) {
        return `ERRO: "${hotelIdSelecionado}" não é um hotel_id válido. Use o campo hotel_id (UUID) retornado pela ferramenta buscar_hoteis, não o nome do hotel.`;
      }

      try {
        await ContextResolverService.setHotelContext(context?.sessionId || '', hotelIdSelecionado);
        return 'Hotel selecionado com sucesso! A partir de agora, as próximas perguntas e checagens de disponibilidade serão limitadas a este hotel.';
      } catch (error) {
        return `Erro ao selecionar hotel: ${(error as Error).message}`;
      }
    },
    {
      name: 'selecionar_hotel',
      description: 'Seleciona e "trava" o contexto do chat em um hotel específico. Chame esta ferramenta APÓS o usuário confirmar o hotel que deseja ver ou reservar. IMPORTANTE: use SOMENTE um valor literal do campo hotel_id retornado por buscar_hoteis nesta mesma conversa. NUNCA invente um UUID, NUNCA copie o formato de um exemplo, NUNCA use o nome do hotel.',
      schema: z.object({
        hotelIdSelecionado: z.string().uuid().describe('Cole literalmente o valor do campo hotel_id retornado por buscar_hoteis nesta conversa. Se você não tem um hotel_id real disponível, NÃO chame esta ferramenta — chame buscar_hoteis primeiro.'),
      }),
    }
  );

  return [buscarHoteisTool, selecionarHotelTool, checarDisponibilidadeTool, criarReservaTool, consultarReservaTool];
};
