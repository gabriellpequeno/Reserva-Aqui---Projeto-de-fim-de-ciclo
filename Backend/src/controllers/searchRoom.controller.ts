import { Request, Response } from 'express';
import { searchRooms, BLOCKING_RESERVATION_STATUSES } from '../services/searchRoom.service';

interface SearchRoomsQuery {
  q?: string;
  checkin?: string;
  checkout?: string;
  hospedes?: string;
  amenidades?: string;
}

function isValidISODate(dateStr: string): boolean {
  return /^\d{4}-\d{2}-\d{2}$/.test(dateStr);
}

function parseAmenidadeIds(amenidadesStr: string): number[] | null {
  if (!amenidadesStr) return null;
  const ids = amenidadesStr.split(',').map(id => parseInt(id.trim(), 10));
  if (ids.some(isNaN)) return null;
  return ids;
}

export async function handleSearchRooms(req: Request, res: Response): Promise<void> {
  try {
    const { q, checkin, checkout, hospedes, amenidades } = req.query as SearchRoomsQuery;

    // Valida q obrigatório
    if (!q || typeof q !== 'string') {
      res.status(400).json({ error: 'Parâmetro q é obrigatório' });
      return;
    }

    // Valida comprimento de q após trim
    const trimmedQ = q.trim();
    if (trimmedQ.length < 2) {
      res.status(400).json({ error: 'Parâmetro q deve ter no mínimo 2 caracteres' });
      return;
    }
    if (trimmedQ.length > 255) {
      res.status(400).json({ error: 'Parâmetro q não pode exceder 255 caracteres' });
      return;
    }

    // Valida checkin/checkout
    if ((checkin && !checkout) || (!checkin && checkout)) {
      res.status(400).json({ error: 'checkin e checkout devem ser enviados juntos' });
      return;
    }

    if (checkin && checkout) {
      if (!isValidISODate(checkin) || !isValidISODate(checkout)) {
        res.status(400).json({
          error: 'Formato de data inválido em checkin/checkout (use YYYY-MM-DD)'
        });
        return;
      }

      if (checkout <= checkin) {
        res.status(400).json({ error: 'checkout deve ser posterior a checkin' });
        return;
      }

      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const checkinDate = new Date(checkin);
      if (checkinDate < today) {
        res.status(400).json({ error: 'checkin não pode ser anterior à data atual' });
        return;
      }
    }

    // Valida hospedes
    if (hospedes) {
      const hospedesNum = parseInt(hospedes, 10);
      if (isNaN(hospedesNum)) {
        res.status(400).json({ error: 'Parâmetro hospedes deve ser um inteiro' });
        return;
      }
      if (hospedesNum < 1 || hospedesNum > 20) {
        res.status(400).json({ error: 'Parâmetro hospedes deve estar entre 1 e 20' });
        return;
      }
    }

    // Valida amenidades
    if (amenidades) {
      const amenidadeIds = parseAmenidadeIds(amenidades as string);
      if (amenidadeIds === null) {
        res.status(400).json({ error: 'Parâmetro amenidades deve ser CSV de inteiros' });
        return;
      }
      if (amenidadeIds.length > 20) {
        res.status(400).json({ error: 'Parâmetro amenidades não pode exceder 20 IDs' });
        return;
      }
    }

    // Prepara refinos com filtros reais
    const refinos = {
      checkin: checkin || undefined,
      checkout: checkout || undefined,
      hospedes: hospedes ? parseInt(hospedes, 10) : undefined,
      amenidadeIds: amenidades ? parseAmenidadeIds(amenidades as string) || undefined : undefined,
    };

    const results = await searchRooms(trimmedQ, refinos);
    res.status(200).json(results);
  } catch (error) {
    console.error('[searchRoom] Erro ao processar searchRooms:', error);
    res.status(500).json({ error: 'Erro interno' });
  }
}
