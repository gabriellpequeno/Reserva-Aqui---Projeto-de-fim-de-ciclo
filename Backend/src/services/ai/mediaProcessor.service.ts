import Groq from 'groq-sdk';
import { getNextKey } from './llmFactory';

const GRAPH_API_BASE = 'https://graph.facebook.com/v22.0';
const WHISPER_MODEL = 'whisper-large-v3-turbo';

export const IMAGE_UNSUPPORTED_REPLY =
  'Ainda não consigo analisar imagens por aqui. Pode me descrever em texto o que precisa? 🙂';

export interface DownloadedMedia {
  buffer: Buffer;
  mimeType: string;
  filename: string;
}

function getGroqClient(): Groq {
  const apiKey = getNextKey('groq');
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

/** Análise de imagem ainda não suportada — retorna mensagem fixa para o usuário. */
export async function describeImage(_media: DownloadedMedia, _caption?: string | null): Promise<string> {
  return IMAGE_UNSUPPORTED_REPLY;
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
