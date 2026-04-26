import Groq from 'groq-sdk';
import { ChatGroq } from '@langchain/groq';
import { HumanMessage, SystemMessage } from '@langchain/core/messages';

const GRAPH_API_BASE = 'https://graph.facebook.com/v22.0';
const WHISPER_MODEL = 'whisper-large-v3-turbo';
const VISION_MODEL = 'meta-llama/llama-4-scout-17b-16e-instruct';

export interface DownloadedMedia {
  buffer: Buffer;
  mimeType: string;
  filename: string;
}

function getGroqClient(): Groq {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) throw new Error('GROQ_API_KEY ausente — necessária para processamento de áudio/imagem.');
  return new Groq({ apiKey });
}

/**
 * Baixa mídia da Meta Graph API.
 * Fluxo: GET /{mediaId} resolve a URL temporária; GET <url> com Bearer baixa o binário.
 */
export async function downloadWhatsAppMedia(mediaId: string, fallbackMime = 'application/octet-stream'): Promise<DownloadedMedia> {
  const token = process.env.WHATSAPP_TOKEN;
  if (!token) throw new Error('WHATSAPP_TOKEN ausente — não é possível baixar mídia.');

  const metaResponse = await fetch(`${GRAPH_API_BASE}/${mediaId}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!metaResponse.ok) {
    throw new Error(`Falha ao resolver URL da mídia ${mediaId}: ${metaResponse.status} ${metaResponse.statusText}`);
  }
  const meta = (await metaResponse.json()) as { url?: string; mime_type?: string };
  if (!meta.url) {
    throw new Error(`Meta retornou sem URL para mídia ${mediaId}`);
  }

  const binResponse = await fetch(meta.url, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!binResponse.ok) {
    throw new Error(`Falha ao baixar binário da mídia: ${binResponse.status} ${binResponse.statusText}`);
  }
  const arrayBuf = await binResponse.arrayBuffer();
  const mimeType = meta.mime_type ?? binResponse.headers.get('content-type') ?? fallbackMime;

  return {
    buffer: Buffer.from(arrayBuf),
    mimeType,
    filename: `media-${mediaId}`,
  };
}

/** Transcreve áudio via Groq Whisper (whisper-large-v3-turbo). */
export async function transcribeAudio(media: DownloadedMedia): Promise<string> {
  const groq = getGroqClient();
  const ext = guessExtensionFromMime(media.mimeType) ?? 'ogg';
  const file = new File([new Uint8Array(media.buffer)], `${media.filename}.${ext}`, { type: media.mimeType });

  const response = await groq.audio.transcriptions.create({
    file,
    model: WHISPER_MODEL,
    language: 'pt',
    response_format: 'text',
  });

  const text = typeof response === 'string' ? response : ((response as any).text ?? '');
  return text.trim();
}

/** Descreve imagem via Llama 4 Scout (multimodal, via Groq). Se houver texto na imagem, transcreve. */
export async function describeImage(media: DownloadedMedia, caption?: string | null): Promise<string> {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) throw new Error('GROQ_API_KEY ausente.');

  const vision = new ChatGroq({
    apiKey,
    model: VISION_MODEL,
    temperature: 0,
    maxRetries: 0,
  });

  const base64 = media.buffer.toString('base64');
  const dataUrl = `data:${media.mimeType};base64,${base64}`;

  const userContent: any[] = [
    {
      type: 'text',
      text: caption
        ? `Descreva de forma objetiva o que há nesta imagem. Legenda do usuário: "${caption}".`
        : 'Descreva de forma objetiva o que há nesta imagem.',
    },
    { type: 'image_url', image_url: { url: dataUrl } },
  ];

  const response = await vision.invoke([
    new SystemMessage(
      'Você descreve imagens para um bot de hotelaria. Seja conciso (máximo 2 frases). Se houver texto legível (CPF, RG, datas, documento, comprovante), transcreva-o literalmente.',
    ),
    new HumanMessage({ content: userContent as any }),
  ]);

  return response.content.toString().trim();
}

function guessExtensionFromMime(mime: string): string | null {
  const map: Record<string, string> = {
    'audio/ogg': 'ogg',
    'audio/mpeg': 'mp3',
    'audio/mp3': 'mp3',
    'audio/wav': 'wav',
    'audio/x-wav': 'wav',
    'audio/webm': 'webm',
    'audio/m4a': 'm4a',
    'audio/mp4': 'm4a',
    'image/jpeg': 'jpg',
    'image/jpg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };
  const base = mime.split(';')[0].trim().toLowerCase();
  return map[base] ?? null;
}
