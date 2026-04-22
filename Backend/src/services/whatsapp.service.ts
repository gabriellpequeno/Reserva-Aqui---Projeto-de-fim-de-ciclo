import 'dotenv/config';

interface MetaApiError {
  message: string;
  code?: number;
}

export interface MetaApiResponse {
  error?: MetaApiError;
  messages?: Array<{ id: string }>;
}

interface MetaMediaUploadResponse {
  error?: MetaApiError;
  id?: string;
}

export class WhatsAppService {
  private static get token(): string | undefined {
    return process.env.WHATSAPP_TOKEN;
  }

  private static get phoneId(): string | undefined {
    return process.env.WHATSAPP_PHONE_ID;
  }

  private static get messagesUrl(): string {
    if (!this.phoneId) {
      throw new Error('Variaveis de ambiente WHATSAPP_TOKEN ou WHATSAPP_PHONE_ID nao configuradas.');
    }

    return `https://graph.facebook.com/v22.0/${this.phoneId}/messages`;
  }

  private static get mediaUrl(): string {
    if (!this.phoneId) {
      throw new Error('Variaveis de ambiente WHATSAPP_TOKEN ou WHATSAPP_PHONE_ID nao configuradas.');
    }

    return `https://graph.facebook.com/v22.0/${this.phoneId}/media`;
  }

  private static getAuthHeaders(): Record<string, string> {
    if (!this.token || !this.phoneId) {
      throw new Error('Variaveis de ambiente WHATSAPP_TOKEN ou WHATSAPP_PHONE_ID nao configuradas.');
    }

    return {
      Authorization: `Bearer ${this.token}`,
    };
  }

  private static getJsonHeaders(): Record<string, string> {
    return {
      ...this.getAuthHeaders(),
      'Content-Type': 'application/json',
    };
  }

  public static async sendText(to: string, text: string): Promise<MetaApiResponse> {
    const body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to,
      type: 'text',
      text: {
        preview_url: false,
        body: text,
      },
    };

    return this.postJsonToMeta(body);
  }

  public static async sendTemplate(
    to: string,
    templateName: string,
    languageCode = 'en_US',
  ): Promise<MetaApiResponse> {
    const body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to,
      type: 'template',
      template: {
        name: templateName,
        language: {
          code: languageCode,
        },
      },
    };

    return this.postJsonToMeta(body);
  }

  public static async sendDocument(
    to: string,
    fileBuffer: Buffer,
    filename: string,
    caption?: string,
  ): Promise<MetaApiResponse> {
    const mediaId = await this.uploadDocument(fileBuffer, filename);

    const body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to,
      type: 'document',
      document: {
        id: mediaId,
        filename,
        caption,
      },
    };

    return this.postJsonToMeta(body);
  }

  private static async uploadDocument(fileBuffer: Buffer, filename: string): Promise<string> {
    const form = new FormData();
    form.append('messaging_product', 'whatsapp');
    form.append('file', new Blob([fileBuffer], { type: 'application/pdf' }), filename);

    const response = await fetch(this.mediaUrl, {
      method: 'POST',
      headers: this.getAuthHeaders(),
      body: form,
    });

    const data = (await response.json()) as MetaMediaUploadResponse;

    if (!response.ok || !data.id) {
      throw new Error(`Erro ao enviar documento para a Meta: ${data.error?.message || response.statusText}`);
    }

    return data.id;
  }

  private static async postJsonToMeta(body: Record<string, unknown>): Promise<MetaApiResponse> {
    const response = await fetch(this.messagesUrl, {
      method: 'POST',
      headers: this.getJsonHeaders(),
      body: JSON.stringify(body),
    });

    const data = (await response.json()) as MetaApiResponse;

    if (!response.ok) {
      throw new Error(`Erro na API do WhatsApp: ${data.error?.message || response.statusText}`);
    }

    return data;
  }
}
