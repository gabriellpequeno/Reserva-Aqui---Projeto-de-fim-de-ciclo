import { Request, Response } from 'express';
import { HotelRequest } from '../middlewares/hotelGuard';
import { AuthRequest }  from '../middlewares/authGuard';
import {
  createReservaUsuario,
  createReservaWalkin,
  createReservaGuest,
  listReservas,
  getReservaById,
  getReservaByCodigoPublico,
  listReservasUsuario,
  updateStatus,
  atribuirQuarto,
  registrarCheckin,
  registrarCheckout,
  cancelarReservaUsuario,
  ListReservasFilters,
  HistoricoReservaSafe,
} from '../services/reserva.service';
import { Reserva, ReservaStatus } from '../entities/Reserva';

// ── Mapeamento de Erros ───────────────────────────────────────────────────────

function mapError(message: string): number {
  if (message.includes('já existe') || message.includes('já cadastrado'))    return 409;
  if (message.includes('inválid') || message.includes('obrigatório')
   || message.includes('Informe') || message.includes('Identifique')
   || message.includes('deve ser') || message.includes('não pode'))          return 400;
  if (message.includes('não encontrad'))                                      return 404;
  if (message.includes('sem permissão') || message.includes('proibido'))     return 403;
  if (message.includes('não autorizado') || message.includes('Credenciais')) return 401;
  return 500;
}

// ── Controllers de Hotel (hotelGuard) ─────────────────────────────────────────

export async function createReservaWalkinController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const input  = Reserva.validateWalkin(req.body);
    const result = await createReservaWalkin(req.hotelId!, input);
    res.status(201).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function listReservasController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const filters: ListReservasFilters = {};

    if (req.query.status)              filters.status             = req.query.status as ReservaStatus;
    if (req.query.data_checkin_from)   filters.data_checkin_from  = req.query.data_checkin_from as string;
    if (req.query.data_checkin_to)     filters.data_checkin_to    = req.query.data_checkin_to as string;
    if (req.query.data_checkout_from)  filters.data_checkout_from = req.query.data_checkout_from as string;
    if (req.query.data_checkout_to)    filters.data_checkout_to   = req.query.data_checkout_to as string;
    if (req.query.nome_hospede)        filters.nome_hospede        = req.query.nome_hospede as string;
    if (req.query.cpf_hospede)         filters.cpf_hospede         = req.query.cpf_hospede as string;

    const result = await listReservas(req.hotelId!, filters);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function getReservaByIdController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const reservaId = Number(req.params.id);
    if (!Number.isInteger(reservaId) || reservaId <= 0) {
      res.status(400).json({ error: 'ID de reserva inválido' });
      return;
    }
    const result = await getReservaById(req.hotelId!, reservaId);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function updateStatusController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const reservaId = Number(req.params.id);
    if (!Number.isInteger(reservaId) || reservaId <= 0) {
      res.status(400).json({ error: 'ID de reserva inválido' });
      return;
    }
    const input  = Reserva.validateStatus(req.body);
    const result = await updateStatus(req.hotelId!, reservaId, input);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function atribuirQuartoController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const reservaId = Number(req.params.id);
    if (!Number.isInteger(reservaId) || reservaId <= 0) {
      res.status(400).json({ error: 'ID de reserva inválido' });
      return;
    }
    const input  = Reserva.validateAtribuirQuarto(req.body);
    const result = await atribuirQuarto(req.hotelId!, reservaId, input);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function registrarCheckinController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const reservaId = Number(req.params.id);
    if (!Number.isInteger(reservaId) || reservaId <= 0) {
      res.status(400).json({ error: 'ID de reserva inválido' });
      return;
    }
    const result = await registrarCheckin(req.hotelId!, reservaId);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function registrarCheckoutController(
  req: HotelRequest,
  res: Response,
): Promise<void> {
  try {
    const reservaId = Number(req.params.id);
    if (!Number.isInteger(reservaId) || reservaId <= 0) {
      res.status(400).json({ error: 'ID de reserva inválido' });
      return;
    }
    const result = await registrarCheckout(req.hotelId!, reservaId);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

// ── Controllers de Usuário (authGuard) ────────────────────────────────────────

export async function createReservaUsuarioController(
  req: AuthRequest,
  res: Response,
): Promise<void> {
  try {
    const input  = Reserva.validateUsuario(req.body);
    const result = await createReservaUsuario(req.userId!, input);
    res.status(201).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function listReservasUsuarioController(
  req: AuthRequest,
  res: Response,
): Promise<void> {
  try {
    const result = await listReservasUsuario(req.userId!);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function cancelarReservaUsuarioController(
  req: AuthRequest,
  res: Response,
): Promise<void> {
  try {
    const { codigo_publico } = req.params;
    await cancelarReservaUsuario(req.userId!, codigo_publico);
    res.status(204).send();
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

// ── Controller Público ────────────────────────────────────────────────────────

export async function createReservaGuestController(
  req: Request,
  res: Response,
): Promise<void> {
  try {
    const input  = Reserva.validateGuest(req.body);
    const result = await createReservaGuest(input);
    res.status(201).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}

export async function getReservaPublicaController(
  req: Request,
  res: Response,
): Promise<void> {
  try {
    const { codigo_publico } = req.params;
    const result = await getReservaByCodigoPublico(codigo_publico);
    res.status(200).json({ data: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno';
    res.status(mapError(message)).json({ error: message });
  }
}
