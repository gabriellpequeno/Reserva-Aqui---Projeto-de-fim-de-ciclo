import 'dotenv/config';

interface MetaApiResponse {
  error?: {
    message: string;
    code?: number;
  };
  messages?: Array<{ id: string }>;
}

export class WhatsAppService {
  private static readonly token = process.env.WHATSAPP_TOKEN;
  private static readonly phoneId = process.env.WHATSAPP_PHONE_ID;
  private static readonly url = `https://graph.facebook.com/v22.0/${this.phoneId}/messages`;

  private static getHeaders() {
    if (!this.token || !this.phoneId) {
      throw new Error("⚠️ Variáveis de ambiente WHATSAPP_TOKEN ou WHATSAPP_PHONE_ID não configuradas.");
    }
    return {
      "Authorization": `Bearer ${this.token}`,
      "Content-Type": "application/json"
    };
  }

  /**
   * Envia uma mensagem em formato de texto livre.
   * Só funciona dentro da janela de 24 horas após o usuário iniciar a conversa.
   */
  public static async sendText(to: string, text: string): Promise<MetaApiResponse> {
    const body = {
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to: to,
      type: "text",
      text: {
        preview_url: false,
        body: text
      }
    };

    return this.postToMeta(body);
  }

  /**
   * Envia um Template de Mensagem (iniciativa por parte do negócio).
   * Templates precisam estar pré-aprovados na Meta.
   */
  public static async sendTemplate(to: string, templateName: string, languageCode: string = "en_US"): Promise<MetaApiResponse> {
    const body = {
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to: to,
      type: "template",
      template: {
        name: templateName,
        language: {
          code: languageCode
        }
      }
    };

    return this.postToMeta(body);
  }

  private static async postToMeta(body: Record<string, unknown>): Promise<MetaApiResponse> {
    try {
      const response = await fetch(this.url, {
        method: "POST",
        headers: this.getHeaders(),
        body: JSON.stringify(body)
      });

      // Justificativa: response.json() retorna unknown, usamos assertion para o contrato da Meta.
      const data = (await response.json()) as MetaApiResponse;

      if (!response.ok) {
        console.error("❌ Meta API Error:", data.error);
        throw new Error(`Erro na API do WhatsApp: ${data.error?.message || response.statusText}`);
      }

      console.log(`✅ Mensagem enviada com sucesso para ${body.to}`);
      return data;
    } catch (error) {
      console.error("❌ Falha crítica ao conectar com a Meta:", error);
      throw error;
    }
  }
}
