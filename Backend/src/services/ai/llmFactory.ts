import { ChatGoogleGenerativeAI } from '@langchain/google-genai';
import { ChatGroq } from '@langchain/groq';
import { BaseMessage, AIMessage } from '@langchain/core/messages';

type LLMProvider = 'gemini' | 'groq';

export interface InvokeOptions {
  temperature?: number;
  tools?: any[];
  maxOutputTokens?: number;
}

function normalizeProvider(raw: string | undefined): LLMProvider | null {
  const v = (raw || '').trim().toLowerCase();
  if (v === 'gemini' || v === 'google') return 'gemini';
  if (v === 'groq' || v === 'llama') return 'groq';
  return null;
}

let geminiKeyIndex = 0;
let groqKeyIndex = 0;

function getKeys(provider: LLMProvider): string[] {
  const envVar = provider === 'gemini' ? process.env.GEMINI_API_KEY : process.env.GROQ_API_KEY;
  if (!envVar) return [];
  return envVar.split(',').map(k => k.trim()).filter(k => k.length > 0);
}

function getPrimaryProvider(): LLMProvider {
  const fromEnv = normalizeProvider(process.env.AI_PRIMARY_PROVIDER);
  if (fromEnv) return fromEnv;
  if (getKeys('gemini').length === 0 && getKeys('groq').length > 0) return 'groq';
  return 'gemini';
}

function hasKeyFor(provider: LLMProvider): boolean {
  return getKeys(provider).length > 0;
}

function getNextKey(provider: LLMProvider): string {
  const keys = getKeys(provider);
  if (keys.length === 0) throw new Error(`${provider.toUpperCase()}_API_KEY ausente`);
  
  if (provider === 'gemini') {
    const key = keys[geminiKeyIndex % keys.length];
    geminiKeyIndex = (geminiKeyIndex + 1) % keys.length;
    return key;
  } else {
    const key = keys[groqKeyIndex % keys.length];
    groqKeyIndex = (groqKeyIndex + 1) % keys.length;
    return key;
  }
}

function buildLLM(provider: LLMProvider, opts: InvokeOptions) {
  const apiKey = getNextKey(provider);

  if (provider === 'gemini') {
    const llm = new ChatGoogleGenerativeAI({
      apiKey,
      model: 'gemini-2.5-flash-lite',
      temperature: opts.temperature ?? 0.1,
      maxRetries: 0,
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
    } catch (err) {
      lastErr = err;
      if (!isRecoverableError(err)) throw err;
      
      console.warn(`[llmFactory] ${provider} falhou (chave ${i+1}/${keysCount}). Tentando próxima se houver...`);
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

export async function invokeWithFallback(
  input: string | BaseMessage[],
  opts: InvokeOptions = {},
): Promise<AIMessage> {
  const primary = getPrimaryProvider();
  const fallback: LLMProvider = primary === 'gemini' ? 'groq' : 'gemini';

  // Tenta primário (passando por todas as suas chaves)
  if (hasKeyFor(primary)) {
    try {
      return await tryInvokeWithKeys(primary, input, opts);
    } catch (err) {
      if (!hasKeyFor(fallback) || !isRecoverableError(err)) throw err;
      console.warn(`[llmFactory] ${primary} esgotado; fallback -> ${fallback}.`);
    }
  }

  if (!hasKeyFor(fallback)) {
    throw new Error('Nenhum provider de IA configurado (GEMINI_API_KEY ou GROQ_API_KEY).');
  }

  // Tenta fallback (passando por todas as suas chaves)
  return await tryInvokeWithKeys(fallback, input, opts);
}
