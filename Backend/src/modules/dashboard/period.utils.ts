import { Period, ALL_PERIODS } from './dashboard.types';

export { ALL_PERIODS };

/**
 * Verifica se uma string é um Period válido (whitelist).
 * Usado pelos controllers para rejeitar valores fora do enum com 400.
 */
export function isPeriod(value: unknown): value is Period {
  return typeof value === 'string' && (ALL_PERIODS as readonly string[]).includes(value);
}

/**
 * Resolve um preset de período para um intervalo [start, end) em timezone do servidor.
 *
 * - `today`         → hoje (00:00:00) até amanhã (00:00:00)
 * - `last7`         → 7 dias atrás (mesmo instante) até agora
 * - `current_month` → início do mês corrente até início do próximo mês
 * - `last30`        → 30 dias atrás até agora
 */
export function resolvePeriod(p: Period): { start: Date; end: Date } {
  const now = new Date();

  switch (p) {
    case 'today': {
      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const end   = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
      return { start, end };
    }
    case 'last7': {
      const start = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      return { start, end: now };
    }
    case 'current_month': {
      const start = new Date(now.getFullYear(), now.getMonth(), 1);
      const end   = new Date(now.getFullYear(), now.getMonth() + 1, 1);
      return { start, end };
    }
    case 'last30': {
      const start = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      return { start, end: now };
    }
  }
}
