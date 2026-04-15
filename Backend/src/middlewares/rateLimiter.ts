import rateLimit from 'express-rate-limit';

/**
 * Limita as tentativas de login por IP.
 * Previne ataques de força bruta.
 */
export const loginRateLimiter = rateLimit({
  windowMs: process.env.RATE_LIMIT_LOGIN_WINDOW_MS ? parseInt(process.env.RATE_LIMIT_LOGIN_WINDOW_MS, 10) : 60 * 1000,
  max: process.env.RATE_LIMIT_LOGIN_MAX ? parseInt(process.env.RATE_LIMIT_LOGIN_MAX, 10) : 5,
  message: { error: 'Muitas tentativas de login. Tente novamente mais tarde.' },
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false,  // Disable the `X-RateLimit-*` headers
});
