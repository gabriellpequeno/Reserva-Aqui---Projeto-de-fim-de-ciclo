/**
 * Testes de integração das rotas /admin.
 *
 * Mockam admin.service para isolar do banco.
 * Definem JWT_SECRET antes de importar módulos que capturam o segredo no load time.
 */
process.env.JWT_SECRET = 'test-secret-for-admin-routes-suite-please-ignore';

jest.mock('../../services/admin.service');

import express from 'express';
import request from 'supertest';
import jwt from 'jsonwebtoken';
import {
  listUsers,
  setUserStatus,
  listHotels,
  setHotelStatus,
  AdminUserDTO,
  AdminHotelDTO,
} from '../../services/admin.service';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const adminRoutes: import('express').Router = require('../admin.routes').default;

const JWT_SECRET = process.env.JWT_SECRET!;

const listUsersMock      = listUsers as jest.Mock;
const setUserStatusMock  = setUserStatus as jest.Mock;
const listHotelsMock     = listHotels as jest.Mock;
const setHotelStatusMock = setHotelStatus as jest.Mock;

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/admin', adminRoutes);
  return app;
}

function signToken(papel: 'usuario' | 'admin', user_id = 'u1'): string {
  return jwt.sign({ user_id, email: 'x@x.com', papel }, JWT_SECRET, { expiresIn: '1h' });
}

const adminToken = () => signToken('admin', 'admin-1');
const userToken  = () => signToken('usuario', 'user-1');

const sampleUser: AdminUserDTO = {
  id:       'u-42',
  nome:     'Fulano',
  email:    'fulano@x.com',
  telefone: '(11) 99999-9999',
  fotoUrl:  null,
  status:   'ativo',
  criadoEm: '2026-01-01T00:00:00.000Z',
};

const sampleHotel: AdminHotelDTO = {
  id:               'h-42',
  nome:             'Hotel Exemplo',
  emailResponsavel: 'contato@hotel.com',
  capaUrl:          null,
  status:           'ativo',
  totalQuartos:     null,
  criadoEm:         '2026-01-01T00:00:00.000Z',
};

describe('GET /api/admin/users', () => {
  let app: express.Application;
  beforeEach(() => {
    jest.clearAllMocks();
    app = createApp();
  });

  it('retorna 401 sem token', async () => {
    const res = await request(app).get('/api/admin/users');
    expect(res.status).toBe(401);
  });

  it('retorna 403 com token de usuário comum', async () => {
    const res = await request(app)
      .get('/api/admin/users')
      .set('Authorization', `Bearer ${userToken()}`);
    expect(res.status).toBe(403);
    expect(listUsersMock).not.toHaveBeenCalled();
  });

  it('retorna 200 + { users: [...] } com token admin', async () => {
    listUsersMock.mockResolvedValueOnce([sampleUser]);
    const res = await request(app)
      .get('/api/admin/users')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ users: [sampleUser] });
    expect(listUsersMock).toHaveBeenCalledTimes(1);
  });

  it('encaminha limit/offset quando presentes', async () => {
    listUsersMock.mockResolvedValueOnce([]);
    await request(app)
      .get('/api/admin/users?limit=50&offset=10')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(listUsersMock).toHaveBeenCalledWith({ limit: 50, offset: 10 });
  });
});

describe('PATCH /api/admin/users/:id', () => {
  let app: express.Application;
  beforeEach(() => {
    jest.clearAllMocks();
    app = createApp();
  });

  it('retorna 403 para usuário comum', async () => {
    const res = await request(app)
      .patch('/api/admin/users/u-42')
      .set('Authorization', `Bearer ${userToken()}`)
      .send({ status: 'suspenso' });
    expect(res.status).toBe(403);
    expect(setUserStatusMock).not.toHaveBeenCalled();
  });

  it('retorna 400 quando body não contém status (requireFields)', async () => {
    const res = await request(app)
      .patch('/api/admin/users/u-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({});
    expect(res.status).toBe(400);
  });

  it('retorna 400 quando status é inválido', async () => {
    const res = await request(app)
      .patch('/api/admin/users/u-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ status: 'qualquer-coisa' });
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/Status inválido/i);
    expect(setUserStatusMock).not.toHaveBeenCalled();
  });

  it('retorna 200 + { user } com status válido', async () => {
    const suspended: AdminUserDTO = { ...sampleUser, status: 'suspenso' };
    setUserStatusMock.mockResolvedValueOnce(suspended);
    const res = await request(app)
      .patch('/api/admin/users/u-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ status: 'suspenso' });
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ user: suspended });
    expect(setUserStatusMock).toHaveBeenCalledWith('u-42', 'suspenso');
  });

  it('retorna 404 quando service lança "não encontrado"', async () => {
    setUserStatusMock.mockRejectedValueOnce(new Error('Usuário não encontrado'));
    const res = await request(app)
      .patch('/api/admin/users/u-inexistente')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ status: 'suspenso' });
    expect(res.status).toBe(404);
  });
});

describe('GET /api/admin/hotels', () => {
  let app: express.Application;
  beforeEach(() => {
    jest.clearAllMocks();
    app = createApp();
  });

  it('retorna 401 sem token', async () => {
    const res = await request(app).get('/api/admin/hotels');
    expect(res.status).toBe(401);
  });

  it('retorna 403 para usuário comum', async () => {
    const res = await request(app)
      .get('/api/admin/hotels')
      .set('Authorization', `Bearer ${userToken()}`);
    expect(res.status).toBe(403);
  });

  it('retorna 200 + { hotels } com token admin', async () => {
    listHotelsMock.mockResolvedValueOnce([sampleHotel]);
    const res = await request(app)
      .get('/api/admin/hotels')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ hotels: [sampleHotel] });
  });
});

describe('PATCH /api/admin/hotels/:id', () => {
  let app: express.Application;
  beforeEach(() => {
    jest.clearAllMocks();
    app = createApp();
  });

  it('retorna 400 quando status é inválido para hotel', async () => {
    const res = await request(app)
      .patch('/api/admin/hotels/h-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ status: 'suspenso' }); // suspenso é válido só pra usuário
    expect(res.status).toBe(400);
  });

  it('retorna 200 + { hotel } com status válido', async () => {
    const inactive: AdminHotelDTO = { ...sampleHotel, status: 'inativo' };
    setHotelStatusMock.mockResolvedValueOnce(inactive);
    const res = await request(app)
      .patch('/api/admin/hotels/h-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ status: 'inativo' });
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ hotel: inactive });
    expect(setHotelStatusMock).toHaveBeenCalledWith('h-42', 'inativo');
  });
});
