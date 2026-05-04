import { Response } from 'express';
import { HotelRequest } from '../middlewares/hotelGuard';
import { AuthRequest }  from '../middlewares/authGuard';
import { isPeriod } from '../modules/dashboard/period.utils';
import { getHostMetrics, getAdminMetrics } from '../modules/dashboard/dashboard.service';

/**
 * GET /host/dashboard?period=today|last7|current_month|last30
 * Protegido por hotelGuard. Retorna métricas operacionais do hotel autenticado.
 */
export async function getHostDashboardController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const periodRaw = (req.query.period as string | undefined) ?? 'today';
    if (!isPeriod(periodRaw)) {
      res.status(400).json({ error: 'Período inválido. Use today, last7, current_month ou last30.' });
      return;
    }
    const payload = await getHostMetrics(req.hotelId!, periodRaw);
    res.status(200).json({ data: payload });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    if (message.includes('não encontrad')) {
      res.status(404).json({ error: message });
      return;
    }
    console.error('[getHostDashboard] erro:', message);
    res.status(500).json({ error: 'Erro ao carregar dashboard do hotel' });
  }
}

/**
 * GET /admin/dashboard?period=today|last7|current_month|last30
 * Protegido por adminGuard. Retorna métricas agregadas da plataforma.
 */
export async function getAdminDashboardController(
  req: AuthRequest,
  res: Response,
): Promise<void> {
  try {
    const periodRaw = (req.query.period as string | undefined) ?? 'today';
    if (!isPeriod(periodRaw)) {
      res.status(400).json({ error: 'Período inválido. Use today, last7, current_month ou last30.' });
      return;
    }
    const payload = await getAdminMetrics(periodRaw);
    res.status(200).json({ data: payload });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    console.error('[getAdminDashboard] erro:', message);
    res.status(500).json({ error: 'Erro ao carregar dashboard da plataforma' });
  }
}
