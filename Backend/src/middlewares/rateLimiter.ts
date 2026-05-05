import rateLimit from 'express-rate-limit';

const intEnv = (key: string, fallback: number): number =>
  process.env[key] ? parseInt(process.env[key]!, 10) : fallback;

/**
 * Limita as tentativas de login por IP.
 * Previne ataques de força bruta.
 */
export const loginRateLimiter = rateLimit({
  windowMs: intEnv('RATE_LIMIT_LOGIN_WINDOW_MS', 60 * 1000),
  max:      intEnv('RATE_LIMIT_LOGIN_MAX', 5),
  message: { error: 'Muitas tentativas de login. Tente novamente mais tarde.' },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Limita a criação de reservas guest (público, sem JWT).
 * Mitiga spam de reservas fake e enumeração de hotéis.
 */
export const guestReservaLimiter = rateLimit({
  windowMs: intEnv('RATE_LIMIT_WINDOW_MS', 60 * 1000),
  max:      intEnv('RATE_LIMIT_GUEST_RESERVA_MAX', 5),
  message: { error: 'Muitas reservas em pouco tempo. Tente novamente em instantes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Limita operações de escrita nos endpoints públicos de pagamento fake
 * (criar/confirmar/cancelar). GETs (polling do timer WPP) são isentos — se
 * precisarem de limite, acrescentar um limiter dedicado mais generoso.
 */
export const pagamentoPublicLimiter = rateLimit({
  windowMs: intEnv('RATE_LIMIT_WINDOW_MS', 60 * 1000),
  max:      intEnv('RATE_LIMIT_PAGAMENTO_MAX', 10),
  message: { error: 'Muitas requisições ao endpoint de pagamento. Aguarde um instante.' },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => req.method === 'GET',
});
