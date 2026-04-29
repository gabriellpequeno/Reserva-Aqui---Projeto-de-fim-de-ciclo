import { Request, Response } from 'express';
import { getRoomPublicDetails } from '../services/quartoPublico.service';

// ── Helpers ───────────────────────────────────────────────────────────────────

function mapError(message: string): number {
  if (message.includes('inválid') || message.includes('ID inválido')) return 400;
  if (message.includes('não encontrado')) return 404;
  return 500;
}

function sendError(res: Response, err: unknown): void {
  const message = err instanceof Error ? err.message : 'Erro interno';
  const statusCode = mapError(message);
  const isInternal = statusCode === 500;

  // Log estruturado de erros
  if (isInternal) {
    console.error('[quartoPublico]', err);
  }

  res.status(statusCode).json({
    error: isInternal ? 'Erro ao buscar detalhes do quarto' : message,
  });
}

function parseId(raw: string): number | null {
  const id = parseInt(raw, 10);
  return isNaN(id) ? null : id;
}

// ── Handler HTTP: recebe GET /:hotel_id/quartos/:quarto_id e delega ao service
export async function handleGetRoomPublicDetails(req: Request, res: Response): Promise<void> {
  try {
    const quartoId = parseId(req.params.quarto_id);
    if (!quartoId) {
      res.status(400).json({ error: 'ID do quarto inválido' });
      return;
    }

    const details = await getRoomPublicDetails(req.params.hotel_id, quartoId);
    res.json({ data: details });
  } catch (err) {
    sendError(res, err);
  }
}
