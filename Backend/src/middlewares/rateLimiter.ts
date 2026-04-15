import rateLimit from 'express-rate-limit';

/**
 * Limita tentativas de login a 5 por minuto por IP.
 * Previne ataques de força bruta.
 */
export const loginRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minuto
  max: 5,              // limite de 5 requisições por windowMs
  message: { error: 'Muitas tentativas de login. Tente novamente em 1 minuto.' },
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false,  // Disable the `X-RateLimit-*` headers
});
