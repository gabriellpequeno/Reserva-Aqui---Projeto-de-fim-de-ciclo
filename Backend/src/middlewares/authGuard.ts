import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET!;

export interface AuthRequest extends Request {
  userId?: string;
  userEmail?: string;
}

/**
 * Verifica se a requisição possui um JWT válido no header Authorization.
 * Formato esperado: "Bearer <token>"
 */
export function authGuard(req: AuthRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Token não fornecido ou formato inválido' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = jwt.verify(token, JWT_SECRET) as { user_id: string; email: string };
    
    // Anexa o ID do usuário à requisição para ser usado no controller
    req.userId = payload.user_id;
    req.userEmail = payload.email;
    
    next();
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
       res.status(401).json({ error: 'Token expirado' });
       return;
    }
    res.status(401).json({ error: 'Token inválido' });
  }
}
