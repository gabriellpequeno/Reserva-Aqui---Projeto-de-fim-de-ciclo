import { Request, Response } from 'express';
import { searchRooms } from '../services/searchRoom.service';

export async function handleSearchRooms(req: Request, res: Response): Promise<void> {
  try {
    const { q, checkin, checkout, hospedes, amenities } = req.query;

    // Aceita q vazio ou não fornecido — retorna todos os quartos disponíveis
    const searchQuery = typeof q === 'string' ? q.trim() : '';

    // Parse amenities: suporta amenities=a&amenities=b ou amenities[]=a&amenities[]=b
    let amenitiesList: string[] | undefined;
    if (Array.isArray(amenities)) {
      amenitiesList = (amenities as string[]).filter(a => typeof a === 'string' && a.length > 0);
    } else if (typeof amenities === 'string' && amenities.length > 0) {
      amenitiesList = [amenities];
    }

    // Prepara refinos
    const refinos = {
      checkin: typeof checkin === 'string' ? checkin : undefined,
      checkout: typeof checkout === 'string' ? checkout : undefined,
      hospedes: typeof hospedes === 'string' ? parseInt(hospedes, 10) : undefined,
      amenities: amenitiesList && amenitiesList.length > 0 ? amenitiesList : undefined,
    };

    const results = await searchRooms(searchQuery, refinos);
    res.status(200).json(results);
  } catch (error) {
    console.error('[searchRoom] Erro ao processar searchRooms:', error);
    res.status(500).json({ error: 'Erro interno' });
  }
}
