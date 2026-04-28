/**
 * Controller: Recomendações de Quartos
 *
 * Rota pública — GET /quartos/recomendados
 * Retorna 5 quartos recomendados baseados em notas.
 */
import { Request, Response } from 'express';
import { getRecommendedRooms } from '../services/recommendedRooms.service';

export async function handleGetRecommendedRooms(
  req: Request,
  res: Response
): Promise<void> {
  const startTime = Date.now();

  try {
    const rooms = await getRecommendedRooms();

    const elapsedMs = Date.now() - startTime;
    console.log(
      `[recommendedRooms] GET /quartos/recomendados — status=200, tempo_ms=${elapsedMs}, quantidade=${rooms.length}`
    );

    res.status(200).json(rooms);
  } catch (error) {
    const elapsedMs = Date.now() - startTime;
    console.error(
      `[recommendedRooms] Erro ao processar getRecommendedRooms (tempo_ms=${elapsedMs}):`,
      error
    );
    res.status(500).json({ error: 'Erro interno' });
  }
}