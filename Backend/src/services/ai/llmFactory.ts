import { ChatGoogleGenerativeAI } from '@langchain/google-genai';
import { ChatGroq } from '@langchain/groq';
import { ChatOpenAI } from '@langchain/openai';
import { BaseMessage, AIMessage } from '@langchain/core/messages';

export type LLMProvider = 'gemini' | 'groq' | 'openrouter';

export interface InvokeOptions {
  temperature?: number;
  tools?: any[];
  maxOutputTokens?: number;
}

function normalizeProvider(raw: string | undefined): LLMProvider | null {
  const v = (raw || '').trim().toLowerCase();
  if (v === 'gemini' || v === 'google') return 'gemini';
  if (v === 'groq' || v === 'llama') return 'groq';
  if (v === 'openrouter' || v === 'router') return 'openrouter';
  return null;
}

let geminiKeyIndex = 0;
let groqKeyIndex = 0;
let openrouterKeyIndex = 0;

function getKeys(provider: LLMProvider): string[] {
  const envVar =
    provider === 'gemini'     ? process.env.GEMINI_API_KEY :
    provider === 'groq'       ? process.env.GROQ_API_KEY :
    /* openrouter */            process.env.OPENROUTER_API_KEY;
  if (!envVar) return [];
  return envVar.split(',').map(k => k.trim()).filter(k => k.length > 0);
}

function getPrimaryProvider(): LLMProvider {
  const fromEnv = normalizeProvider(process.env.AI_PRIMARY_PROVIDER);
  if (fromEnv) return fromEnv;
  // Heurística: prefere o provider com chave configurada, na ordem mais resiliente.
  if (getKeys('openrouter').length > 0) return 'openrouter';
  if (getKeys('groq').length > 0) return 'groq';
  return 'gemini';
}

function hasKeyFor(provider: LLMProvider): boolean {
  return getKeys(provider).length > 0;
}

export function getNextKey(provider: LLMProvider): string {
  const keys = getKeys(provider);
  if (keys.length === 0) throw new Error(`${provider.toUpperCase()}_API_KEY ausente`);

  let idx: number;
  if (provider === 'gemini') {
    idx = geminiKeyIndex;
    geminiKeyIndex = (geminiKeyIndex + 1) % keys.length;
  } else if (provider === 'groq') {
    idx = groqKeyIndex;
    groqKeyIndex = (groqKeyIndex + 1) % keys.length;
  } else {
    idx = openrouterKeyIndex;
    openrouterKeyIndex = (openrouterKeyIndex + 1) % keys.length;
  }
  return keys[idx % keys.length];
}

function buildLLM(provider: LLMProvider, opts: InvokeOptions) {
  const apiKey = getNextKey(provider);

  if (provider === 'gemini') {
    // 2.5-flash-lite tem cota separada e demanda menor — fallback mais resiliente
    // a picos de carga ("503: experiencing high demand") do 2.5-flash.
    const llm = new ChatGoogleGenerativeAI({
      apiKey,
      model: 'gemini-2.5-flash-lite',
      temperature: opts.temperature ?? 0.1,
      maxRetries: 0,
    });
    return opts.tools && opts.tools.length ? llm.bindTools(opts.tools) : llm;
  }

  if (provider === 'openrouter') {
    // OpenRouter expõe API compatível com OpenAI. Padrão: mesmo Llama 3.3 70B
    // que o Groq usa — mantém qualidade de tool calling já validada.
    // Override via OPENROUTER_MODEL no .env se quiser outro modelo.
    const llm = new ChatOpenAI({
      apiKey,
      model: process.env.OPENROUTER_MODEL ?? 'meta-llama/llama-3.3-70b-instruct:free',
      temperature: opts.temperature ?? 0.1,
      maxRetries: 0,
      configuration: {
        baseURL: 'https://openrouter.ai/api/v1',
        defaultHeaders: {
          'HTTP-Referer': process.env.OPENROUTER_REFERER ?? 'https://reservaqui.app',
          'X-Title': 'ReservAqui Bene',
        },
      },
    });
    return opts.tools && opts.tools.length ? llm.bindTools(opts.tools) : llm;
  }

  const llm = new ChatGroq({
    apiKey,
    model: 'llama-3.3-70b-versatile',
    temperature: opts.temperature ?? 0.1,
    maxRetries: 0,
  });
  return opts.tools && opts.tools.length ? llm.bindTools(opts.tools) : llm;
}

function isRecoverableError(err: any): boolean {
  const status = err?.status ?? err?.statusCode;
  if (status === 429 || status === 503 || status === 500) return true;
  const msg = String(err?.message ?? err ?? '').toLowerCase();
  return (
    msg.includes('quota') ||
    msg.includes('too many requests') ||
    msg.includes('rate limit') ||
    msg.includes('resource_exhausted') ||
    msg.includes('fetch failed')
  );
}

// Extrai tempo de espera sugerido pelo provider (em ms). Cap em 5s para não estourar SLA do WhatsApp.
function extractRetryDelayMs(err: any): number | null {
  const headerRetryAfter = err?.headers?.get?.('retry-after') ?? err?.headers?.['retry-after'];
  if (headerRetryAfter) {
    const s = parseFloat(String(headerRetryAfter));
    if (!isNaN(s)) return Math.min(Math.ceil(s * 1000), 5000);
  }

  const msg = String(err?.message ?? '');
  const matchSec = msg.match(/try again in\s+([\d.]+)\s*s/i) ??
                   msg.match(/retry in\s+([\d.]+)\s*s/i) ??
                   msg.match(/please retry in\s+([\d.]+)s/i);
  if (matchSec) {
    const s = parseFloat(matchSec[1]);
    if (!isNaN(s)) return Math.min(Math.ceil(s * 1000), 5000);
  }

  return null;
}

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

async function tryInvokeWithKeys(provider: LLMProvider, input: string | BaseMessage[], opts: InvokeOptions): Promise<AIMessage> {
  const keysCount = getKeys(provider).length;
  if (keysCount === 0) throw new Error(`Sem chaves para ${provider}`);

  let lastErr: any;
  
  // Tenta até passar por todas as chaves do provider (round-robin tenta todas 1x)
  for (let i = 0; i < keysCount; i++) {
    try {
      const llm = buildLLM(provider, opts); // constrói com a próxima chave do round-robin
      return (await llm.invoke(input as any)) as AIMessage;
    } catch (err: any) {
      lastErr = err;
      const status = err?.status ?? err?.statusCode ?? err?.response?.status ?? '?';
      const msg = String(err?.message ?? err ?? '').slice(0, 240);
      if (!isRecoverableError(err)) {
        console.error(`[llmFactory] ${provider} FATAL (chave ${i+1}/${keysCount}) [HTTP ${status}]: ${msg}`);
        throw err;
      }
      console.warn(`[llmFactory] ${provider} falhou (chave ${i+1}/${keysCount}) [HTTP ${status}]: ${msg} — tentando próxima.`);
    }
  }

  // Se esgotou todas as chaves e a última retornou 429 com delay
  const delay = extractRetryDelayMs(lastErr);
  if (delay !== null) {
    console.warn(`[llmFactory] ${provider} 429 transitório (esgotou chaves), aguardando ${delay}ms e retry.`);
    await sleep(delay);
    const llm = buildLLM(provider, opts);
    return (await llm.invoke(input as any)) as AIMessage;
  }

  throw lastErr;
}

// Cadeia padrão de fallback quando o primário falha. Ordem reflete a hierarquia
// de resiliência observada: OpenRouter (muitos modelos free) → Groq (rate-limit
// generoso mas com janela curta) → Gemini (503 frequente em horários de pico).
const PROVIDER_ORDER: LLMProvider[] = ['openrouter', 'groq', 'gemini'];

export async function invokeWithFallback(
  input: string | BaseMessage[],
  opts: InvokeOptions = {},
): Promise<AIMessage> {
  const primary = getPrimaryProvider();
  // Tenta o primário primeiro, depois os demais na ordem definida (sem duplicar).
  const chain: LLMProvider[] = [primary, ...PROVIDER_ORDER.filter(p => p !== primary)];

  let lastErr: any = null;
  let triedAny = false;

  for (const provider of chain) {
    if (!hasKeyFor(provider)) continue;
    triedAny = true;
    try {
      return await tryInvokeWithKeys(provider, input, opts);
    } catch (err) {
      lastErr = err;
      if (!isRecoverableError(err)) throw err;
      console.warn(`[llmFactory] ${provider} esgotado; tentando próximo provider da cadeia.`);
    }
  }

  if (!triedAny) {
    throw new Error('Nenhum provider de IA configurado (GEMINI_API_KEY, GROQ_API_KEY ou OPENROUTER_API_KEY).');
  }
  throw lastErr;
}
