/**
 * Testes de integração das rotas /host/dashboard e /admin/dashboard.
 *
 * Mockam o módulo dashboard.service para isolar do banco.
 * Definem JWT_SECRET antes de importar módulos que capturam o segredo em load time.
 */
process.env.JWT_SECRET = 'test-secret-for-dashboard-routes-suite-please-ignore';

jest.mock('../../modules/dashboard/dashboard.service');

import express from 'express';
import request from 'supertest';
import jwt from 'jsonwebtoken';
import {
  getHostMetrics,
  getAdminMetrics,
} from '../../modules/dashboard/dashboard.service';
import {
  HostDashboardResponse,
  AdminDashboardResponse,
} from '../../modules/dashboard/dashboard.types';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const {
  hostDashboardRouter,
  adminDashboardRouter,
} = require('../dashboard.routes') as {
  hostDashboardRouter: import('express').Router;
  adminDashboardRouter: import('express').Router;
};

const JWT_SECRET = process.env.JWT_SECRET!;

const getHostMetricsMock  = getHostMetrics  as jest.Mock;
const getAdminMetricsMock = getAdminMetrics as jest.Mock;

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/host/dashboard',  hostDashboardRouter);
  app.use('/api/admin/dashboard', adminDashboardRouter);
  return app;
}

function signUserToken(papel: 'usuario' | 'admin'): string {
  return jwt.sign({ user_id: 'u1', email: 'u@x.com', papel }, JWT_SECRET, { expiresIn: '1h' });
}

function signHotelToken(): string {
  return jwt.sign({ hotel_id: 'h1', email: 'h@x.com' }, JWT_SECRET, { expiresIn: '1h' });
}

const adminToken  = () => signUserToken('admin');
const userToken   = () => signUserToken('usuario');
const hotelToken  = () => signHotelToken();

const sampleHostPayload: HostDashboardResponse = {
  period: 'today',
  metrics: {
    reservasHoje:       3,
    ocupacaoPercentual: 42.5,
    receitaPeriodo:     1250.75,
    avaliacaoMedia:     4.2,
    totalAvaliacoes:    18,
  },
  proximosCheckins:  [],
  reservasPorStatus: [{ status: 'APROVADA', count: 5 }],
};

const sampleAdminPayload: AdminDashboardResponse = {
  period: 'today',
  metrics: {
    totalUsuarios:  120,
    totalHoteis:    8,
    reservasHoje:   25,
    receitaPeriodo: 9999.0,
  },
  topHoteis:         [{ hotelId: 'h1', nomeHotel: 'Hotel A', reservasAtivas: 7 }],
  reservasPorStatus: [{ status: 'CONCLUIDA', count: 12 }],
  novosCadastros:    { usuarios: 4, hoteis: 1 },
};

describe('GET /api/host/dashboard', () => {
  let app: express.Application;
  beforeEach(() => {
    jest.clearAllMocks();
    app = createApp();
  });

  it('retorna 401 sem token', async () => {
    const res = await request(app).get('/api/host/dashboard');
    expect(res.status).toBe(401);
  });

  it('retorna 403 com token de usuário (sem hotel_id)', async () => {
    const res = await request(app)
      .get('/api/host/dashboard')
      .set('Authorization', `Bearer ${userToken()}`);
    expect(res.status).toBe(403);
    expect(getHostMetricsMock).not.toHaveBeenCalled();
  });

  it('retorna 403 com token de admin (ainda sem hotel_id)', async () => {
    const res = await request(app)
      .get('/api/host/dashboard')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(403);
  });

  it('retorna 200 + { data: payload } com token de hotel válido', async () => {
    getHostMetricsMock.mockResolvedValueOnce(sampleHostPayload);
    const res = await request(app)
      .get('/api/host/dashboard')
      .set('Authorization', `Bearer ${hotelToken()}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ data: sampleHostPayload });
    expect(getHostMetricsMock).toHaveBeenCalledWith('h1', 'today');
  });

  it('default para period=today quando não informado', async () => {
    getHostMetricsMock.mockResolvedValueOnce(sampleHostPayload);
    await request(app)
      .get('/api/host/dashboard')
      .set('Authorization', `Bearer ${hotelToken()}`);
    expect(getHostMetricsMock).toHaveBeenCalledWith('h1', 'today');
  });

  it('retorna 400 para period inválido', async () => {
    const res = await request(app)
      .get('/api/host/dashboard?period=invalid')
      .set('Authorization', `Bearer ${hotelToken()}`);
    expect(res.status).toBe(400);
    expect(getHostMetricsMock).not.toHaveBeenCalled();
  });

  it('aceita period=last30', async () => {
    getHostMetricsMock.mockResolvedValueOnce({ ...sampleHostPayload, period: 'last30' });
    const res = await request(app)
      .get('/api/host/dashboard?period=last30')
      .set('Authorization', `Bearer ${hotelToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data.period).toBe('last30');
    expect(getHostMetricsMock).toHaveBeenCalledWith('h1', 'last30');
  });

  it('retorna 404 quando service lança "hotel não encontrado"', async () => {
    getHostMetricsMock.mockRejectedValueOnce(new Error('Hotel não encontrado'));
    const res = await request(app)
      .get('/api/host/dashboard')
      .set('Authorization', `Bearer ${hotelToken()}`);
    expect(res.status).toBe(404);
  });

  it('retorna 500 em erro desconhecido sem vazar mensagem', async () => {
    getHostMetricsMock.mockRejectedValueOnce(new Error('something broke in SQL'));
    const res = await request(app)
      .get('/api/host/dashboard')
      .set('Authorization', `Bearer ${hotelToken()}`);
    expect(res.status).toBe(500);
    expect(res.body.error).not.toContain('SQL');
  });
});

describe('GET /api/admin/dashboard', () => {
  let app: express.Application;
  beforeEach(() => {
    jest.clearAllMocks();
    app = createApp();
  });

  it('retorna 401 sem token', async () => {
    const res = await request(app).get('/api/admin/dashboard');
    expect(res.status).toBe(401);
  });

  it('retorna 403 com token de usuário comum', async () => {
    const res = await request(app)
      .get('/api/admin/dashboard')
      .set('Authorization', `Bearer ${userToken()}`);
    expect(res.status).toBe(403);
    expect(getAdminMetricsMock).not.toHaveBeenCalled();
  });

  it('retorna 403 com token de hotel (não é admin)', async () => {
    const res = await request(app)
      .get('/api/admin/dashboard')
      .set('Authorization', `Bearer ${hotelToken()}`);
    // adminGuard chama authGuard, que exige user_id; hotel token não tem user_id
    // → 401/403 depende da implementação do authGuard. Aceitamos qualquer 4xx aqui.
    expect([401, 403]).toContain(res.status);
    expect(getAdminMetricsMock).not.toHaveBeenCalled();
  });

  it('retorna 200 + { data: payload } com token admin', async () => {
    getAdminMetricsMock.mockResolvedValueOnce(sampleAdminPayload);
    const res = await request(app)
      .get('/api/admin/dashboard')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ data: sampleAdminPayload });
    expect(getAdminMetricsMock).toHaveBeenCalledWith('today');
  });

  it('aceita period=current_month', async () => {
    getAdminMetricsMock.mockResolvedValueOnce({ ...sampleAdminPayload, period: 'current_month' });
    const res = await request(app)
      .get('/api/admin/dashboard?period=current_month')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data.period).toBe('current_month');
    expect(getAdminMetricsMock).toHaveBeenCalledWith('current_month');
  });

  it('retorna 400 para period inválido', async () => {
    const res = await request(app)
      .get('/api/admin/dashboard?period=ontem')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(400);
    expect(getAdminMetricsMock).not.toHaveBeenCalled();
  });

  it('retorna 500 em erro desconhecido', async () => {
    getAdminMetricsMock.mockRejectedValueOnce(new Error('pg explodiu'));
    const res = await request(app)
      .get('/api/admin/dashboard')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(500);
  });
});
