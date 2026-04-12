import { Request, Response, NextFunction } from 'express';

/**
 * Middleware genérico para verificar a presença de campos obrigatórios no corpo da requisição.
 * Evita que requisições vazias cheguem ao controller/service.
 */
export function requireFields(...fields: string[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const missing = fields.filter(f => req.body[f] === undefined || req.body[f] === null || req.body[f] === '');
    
    if (missing.length > 0) {
      res.status(400).json({ error: `Campos obrigatórios ausentes: ${missing.join(', ')}` });
      return;
    }
    
    next();
  };
}
