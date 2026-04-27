import { Request, Response } from 'express';
import { searchRooms } from '../services/searchRoom.service';

export async function handleSearchRooms(req: Request, res: Response): Promise<void> {
  try {
    const { q, checkin, checkout, hospedes } = req.query;

    // Valida q obrigatório
    if (!q || typeof q !== 'string') {
      res.status(400).json({ error: 'Parâmetro q é obrigatório' });
      return;
    }

    // Valida comprimento mínimo de q após trim
    const trimmedQ = q.trim();
    if (trimmedQ.length < 2) {
      res.status(400).json({ error: 'Parâmetro q deve ter no mínimo 2 caracteres' });
      return;
    }

    // Prepara refinos (aceitos mas ignorados nesta versão)
    const refinos = {
      checkin: typeof checkin === 'string' ? checkin : undefined,
      checkout: typeof checkout === 'string' ? checkout : undefined,
      hospedes: typeof hospedes === 'string' ? parseInt(hospedes, 10) : undefined,
    };

    const results = await searchRooms(trimmedQ, refinos);
    res.status(200).json(results);
  } catch (error) {
    console.error('[searchRoom] Erro ao processar searchRooms:', error);
    res.status(500).json({ error: 'Erro interno' });
  }
}
