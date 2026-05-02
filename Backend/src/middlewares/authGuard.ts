import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET!;

export type UserPapel = 'usuario' | 'admin';

export interface AuthRequest extends Request {
  userId?:    string;
  userEmail?: string;
  userPapel?: UserPapel;
}

/**
 * Verifica se a requisição possui um JWT válido no header Authorization.
 * Formato esperado: "Bearer <token>"
 * Payload esperado: { user_id: string; email: string; papel?: 'usuario' | 'admin' }
 *
 * Tokens antigos (sem `papel`) são tratados como `'usuario'` — fallback seguro
 * que nunca dá acesso a rotas admin por engano.
 */
export function authGuard(req: AuthRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Token não fornecido ou formato inválido' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = jwt.verify(token, JWT_SECRET) as {
      user_id: string;
      email: string;
      papel?: string;
    };

    req.userId    = payload.user_id;
    req.userEmail = payload.email;
    req.userPapel = payload.papel === 'admin' ? 'admin' : 'usuario';

    next();
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
       res.status(401).json({ error: 'Token expirado' });
       return;
    }
    res.status(401).json({ error: 'Token inválido' });
  }
}
