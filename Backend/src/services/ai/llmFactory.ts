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

function getPrimaryProvider(): LLMProvider {
  const fromEnv = normalizeProvider(process.env.AI_PRIMARY_PROVIDER);
  if (fromEnv) return fromEnv;
  if (!process.env.GEMINI_API_KEY && process.env.GROQ_API_KEY) return 'groq';
  return 'gemini';
}

function hasKeyFor(provider: LLMProvider): boolean {
  return provider === 'gemini' ? !!process.env.GEMINI_API_KEY : !!process.env.GROQ_API_KEY;
}

function buildLLM(provider: LLMProvider, opts: InvokeOptions) {
  if (provider === 'gemini') {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) throw new Error('GEMINI_API_KEY ausente');
    const llm = new ChatGoogleGenerativeAI({
      apiKey,
      model: 'gemini-2.5-flash-lite',
      temperature: opts.temperature ?? 0.1,
      maxRetries: 0,
    });
    return opts.tools && opts.tools.length ? llm.bindTools(opts.tools) : llm;
  }

  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) throw new Error('GROQ_API_KEY ausente');
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

async function tryInvoke(provider: LLMProvider, input: string | BaseMessage[], opts: InvokeOptions): Promise<AIMessage> {
  const llm = buildLLM(provider, opts);
  return (await llm.invoke(input as any)) as AIMessage;
}

export async function invokeWithFallback(
  input: string | BaseMessage[],
  opts: InvokeOptions = {},
): Promise<AIMessage> {
  const primary = getPrimaryProvider();
  const fallback: LLMProvider = primary === 'gemini' ? 'groq' : 'gemini';

  // Tenta primário
  if (hasKeyFor(primary)) {
    try {
      return await tryInvoke(primary, input, opts);
    } catch (err) {
      if (!isRecoverableError(err)) throw err;

      // Retry rápido no MESMO provider se ele sugeriu delay (típico TPM burst do Groq).
      const delay = extractRetryDelayMs(err);
      if (delay !== null) {
        console.warn(`[llmFactory] ${primary} 429 transitório, aguardando ${delay}ms e retry.`);
        await sleep(delay);
        try {
          return await tryInvoke(primary, input, opts);
        } catch (retryErr) {
          if (!hasKeyFor(fallback) || !isRecoverableError(retryErr)) throw retryErr;
          console.warn(`[llmFactory] ${primary} falhou após retry; fallback -> ${fallback}.`);
        }
      } else {
        if (!hasKeyFor(fallback)) throw err;
        console.warn(`[llmFactory] ${primary} falhou (quota/rate); fallback -> ${fallback}.`);
      }
    }
  }

  if (!hasKeyFor(fallback)) {
    throw new Error('Nenhum provider de IA configurado (GEMINI_API_KEY ou GROQ_API_KEY).');
  }

  return await tryInvoke(fallback, input, opts);
}
