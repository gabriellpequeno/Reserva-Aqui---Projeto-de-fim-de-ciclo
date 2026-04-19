import { Request, Response } from 'express';
// O RagService será implementado na Fase 4, por enquanto vamos dar um echo ou apenas logar
import { masterPool } from '../database/masterDb';
// import { RagService } from '../services/rag.service';
import { WhatsAppService } from '../services/whatsapp.service';

export class WhatsAppController {
  
  /**
   * Endpoint passivo exigido pela Meta para cadastrar o Webhook.
   * Ele valida o token `hub.verify_token` que você definiu no painel e no .env
   */
  public static verifyWebhook(req: Request, res: Response): void {
    const VERIFY_TOKEN = process.env.WHATSAPP_WEBHOOK_VERIFY_TOKEN;

    const mode = req.query['hub.mode'];
    const token = req.query['hub.verify_token'];
    const challenge = req.query['hub.challenge'];

    if (mode && token) {
      if (mode === 'subscribe' && token === VERIFY_TOKEN) {
        console.log('✅ Webhook verificado com sucesso pela Meta!');
        res.status(200).send(challenge);
      } else {
        console.error('❌ Falha na verificação: Token ou Modo inválido.');
        res.sendStatus(403);
      }
    } else {
      res.sendStatus(400);
    }
  }

  /**
   * Endpoint ativo onde a Meta envia as mensagens novas do cliente (Eventos POST).
   */
  public static async receiveMessage(req: Request, res: Response): Promise<void> {
    const body = req.body;

    // Log seguro: nunca expor payload completo em produção
    if (process.env.NODE_ENV === 'development') {
      console.log('[WEBHOOK] Payload recebido de:', body?.entry?.[0]?.changes?.[0]?.value?.messages?.[0]?.from ?? 'status-event');
    }

    // Verifica se é um evento da API do WhatsApp
    if (body.object) {
      if (
        body.entry &&
        body.entry[0].changes &&
        body.entry[0].changes[0] &&
        body.entry[0].changes[0].value.messages &&
        body.entry[0].changes[0].value.messages[0]
      ) {
        const message = body.entry[0].changes[0].value.messages[0];
        const fromNumber = message.from; // Número do cliente
        const messageType = message.type;

        // Vamos extrair o texto, ignorando por hora áudios ou imagens
        if (messageType === 'text') {
          const incomingText = message.text.body;
          console.log(`Nova mensagem de ${fromNumber}: ${incomingText}`);

          // Responde 200 PRAZO CURTO para a Meta não achar que deu Timeout (Regra crítica)
          res.sendStatus(200);

          try {
            // [SEMANA 1]: Logar mensagens no banco usando sessao_chat e mensagem_chat
            let sessionId: string | null = null;
            
            // 1. Busca uma sessão com status ABERTA para o celular que chamou
            const checkSession = await masterPool.query(
              `SELECT id FROM sessao_chat WHERE canal = 'WHATSAPP' AND identificador_externo = $1 AND status = 'ABERTA' LIMIT 1`,
              [fromNumber]
            );

            if (checkSession.rows.length > 0) {
              sessionId = checkSession.rows[0].id; // Já existe conversa
            } else {
              // 2. Cria nova sessão caso seja a primeira vez ou a anterior já foi fechada
              const newSession = await masterPool.query(
                `INSERT INTO sessao_chat (canal, identificador_externo) VALUES ('WHATSAPP', $1) RETURNING id`,
                [fromNumber]
              );
              sessionId = newSession.rows[0].id;
              console.log(`🆕 Nova Sessão de Chat Criada: ${sessionId}`);
            }

            // 3. Grava a mensagem do hóspede/cliente na tabela de mensagens daquela sessão
            await masterPool.query(
              `INSERT INTO mensagem_chat (sessao_chat_id, origem, conteudo) VALUES ($1, 'CLIENTE', $2)`,
              [sessionId, incomingText]
            );

            console.log(`💾 [Database] Mensagem registrada com sucesso na base de dados!`);

            // 4. Enviar Echo de Recebimento provisório para testar infraestrutura Node -> Meta
            await WhatsAppService.sendText(
              fromNumber,
              `🤖 Olá! Sua mensagem "${incomingText}" foi gravada com sucesso em nosso banco de dados. Nosso assistente inteligente será ligado em breve!`
            );
            
            // (Aqui na Fase 4, o RAG interceptará e o Echo sumirá)
            // const respostaIA = await RagService.processText(fromNumber, incomingText);
            // await WhatsAppService.sendText(fromNumber, respostaIA);

          } catch (error) {
             console.error("❌ Erro no processamento do Banco ou Meta API:", error);
          }
        } else {
          // Mensagem ignorada (não é texto)
          res.sendStatus(200);
        }
      } else {
        // Evento de Status (entregue, lida, falha) e não de Mensagem Nova
        res.sendStatus(200);
      }
    } else {
      res.sendStatus(404);
    }
  }
}
