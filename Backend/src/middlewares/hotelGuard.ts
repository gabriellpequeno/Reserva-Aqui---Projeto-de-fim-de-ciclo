import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET!;

export interface HotelRequest extends Request {
  hotelId?:    string;
  hotelEmail?: string;
}

/**
 * Verifica se a requisição possui um JWT válido de anfitrião no header Authorization.
 * Separado do authGuard de usuário para isolar contextos — um token de hóspede
 * não consegue acessar rotas protegidas pelo hotelGuard, e vice-versa.
 *
 * Formato esperado: "Bearer <token>"
 * Payload esperado: { hotel_id: string; email: string }
 */
export function hotelGuard(req: HotelRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Token não fornecido ou formato inválido' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = jwt.verify(token, JWT_SECRET) as { hotel_id?: string; email: string };

    // Rejeita tokens de usuário (que teriam user_id mas não hotel_id)
    if (!payload.hotel_id) {
      res.status(403).json({ error: 'Acesso negado: token não pertence a um anfitrião' });
      return;
    }

    req.hotelId    = payload.hotel_id;
    req.hotelEmail = payload.email;

    next();
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      res.status(401).json({ error: 'Token expirado' });
      return;
    }
    res.status(401).json({ error: 'Token inválido' });
  }
}
