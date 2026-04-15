import { Request, Response, NextFunction } from 'express';

/**
 * Enforces HTTPS connections in production.
 * Checks the 'x-forwarded-proto' header typically set by reverse proxies (Heroku, AWS ALBs, Nginx).
 */
export function httpsEnforcer(req: Request, res: Response, next: NextFunction) {
  if (process.env.NODE_ENV === 'production') {
    if (req.headers['x-forwarded-proto'] !== 'https') {
      return res.status(403).json({ error: 'Acesso negado: Requer conexão HTTPS segura' });
    }
  }
  next();
}
