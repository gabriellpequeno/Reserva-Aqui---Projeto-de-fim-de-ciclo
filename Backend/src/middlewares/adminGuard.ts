import { Response, NextFunction } from 'express';
import { AuthRequest, authGuard } from './authGuard';

/**
 * Middleware de autorização admin.
 *
 * Encadeia `authGuard` (token válido obrigatório) + verificação `req.userPapel === 'admin'`.
 * Retorna:
 *   - 401 se token ausente/inválido/expirado (propagado do authGuard)
 *   - 403 se token válido porém papel ≠ 'admin'
 *
 * O encadeamento é explícito — nunca assuma que o chamador aplicou authGuard antes.
 */
export function adminGuard(req: AuthRequest, res: Response, next: NextFunction): void {
  authGuard(req, res, (err?: unknown) => {
    if (err) {
      next(err);
      return;
    }

    // Se authGuard já respondeu (ex: 401), headersSent estará true — não continuar.
    if (res.headersSent) return;

    if (req.userPapel !== 'admin') {
      res.status(403).json({ error: 'Acesso negado: requer papel de administrador' });
      return;
    }

    next();
  });
}
