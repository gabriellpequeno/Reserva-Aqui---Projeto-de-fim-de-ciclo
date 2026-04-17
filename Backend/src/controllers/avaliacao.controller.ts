import { Request, Response } from 'express';
import { AuthRequest } from '../middlewares/authGuard';
import {
  createAvaliacao,
  updateAvaliacao,
  listAvaliacoes,
} from '../services/avaliacao.service';
import { Avaliacao } from '../entities/Avaliacao';

// ── Mapeamento de Erros ───────────────────────────────────────────────────────

function mapError(message: string): number {
  if (message.includes('já avaliou') || message.includes('já existe'))                   return 409;
  if (message.includes('inválid') || message.includes('Nenhum campo')
   || message.includes('deve ser') || message.includes('Só é possível'))                 return 400;
  if (message.includes('não encontrad'))                                                  return 404;
  if (message.includes('sem permissão') || message.includes('proibido'))                 return 403;
  return 500;
}

// ── Controllers de Usuário (authGuard) ────────────────────────────────────────

export async function createAvaliacaoController(
  req: AuthRequest,
  res: Response,
): Promise<void> {
  try {
    const input  = Avaliacao.validate(req.body);
    const result = await createAvaliacao(req.userId!, input);
    res.status(201).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function updateAvaliacaoController(
  req: AuthRequest,
  res: Response,
): Promise<void> {
  try {
    const { codigo_publico } = req.params;
    const input  = Avaliacao.validatePartial(req.body);
    const result = await updateAvaliacao(req.userId!, codigo_publico, input);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

// ── Controller Público ────────────────────────────────────────────────────────

export async function listAvaliacoesController(
  req: Request,
  res: Response,
): Promise<void> {
  try {
    const { hotel_id } = req.params;
    const result = await listAvaliacoes(hotel_id);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}
