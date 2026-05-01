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
  updateUser,
  updateHotel,
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
const updateUserMock     = updateUser as jest.Mock;
const updateHotelMock    = updateHotel as jest.Mock;

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
  telefone:         '(11) 3333-4444',
  descricao:        'Um hotel',
  cep:              '01310100',
  uf:               'SP',
  cidade:           'São Paulo',
  bairro:           'Bela Vista',
  rua:              'Av. Paulista',
  numero:           '1000',
  complemento:      null,
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
    expect(updateUserMock).not.toHaveBeenCalled();
  });

  it('retorna 400 quando body está vazio', async () => {
    const res = await request(app)
      .patch('/api/admin/users/u-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({});
    expect(res.status).toBe(400);
    expect(setUserStatusMock).not.toHaveBeenCalled();
    expect(updateUserMock).not.toHaveBeenCalled();
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
    expect(updateUserMock).not.toHaveBeenCalled();
  });

  it('retorna 200 + { user } ao editar apenas dados', async () => {
    const updated: AdminUserDTO = { ...sampleUser, nome: 'Novo Nome' };
    updateUserMock.mockResolvedValueOnce(updated);
    const res = await request(app)
      .patch('/api/admin/users/u-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ nome_completo: 'Novo Nome' });
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ user: updated });
    expect(updateUserMock).toHaveBeenCalledWith('u-42', { nome_completo: 'Novo Nome' });
    expect(setUserStatusMock).not.toHaveBeenCalled();
  });

  it('retorna 409 quando email já está em uso (pg 23505)', async () => {
    const pgErr = Object.assign(new Error('duplicate key'), { code: '23505' });
    updateUserMock.mockRejectedValueOnce(pgErr);
    const res = await request(app)
      .patch('/api/admin/users/u-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ email: 'existente@x.com' });
    expect(res.status).toBe(409);
    expect(res.body.error).toMatch(/email/i);
  });

  it('retorna 400 quando email é inválido', async () => {
    updateUserMock.mockRejectedValueOnce(new Error('Email inválido'));
    const res = await request(app)
      .patch('/api/admin/users/u-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ email: 'sem-arroba' });
    expect(res.status).toBe(400);
  });

  it('aplica status e dados juntos, nesta ordem', async () => {
    const afterStatus: AdminUserDTO = { ...sampleUser, status: 'suspenso' };
    const afterData:   AdminUserDTO = { ...afterStatus, nome: 'Outro' };
    setUserStatusMock.mockResolvedValueOnce(afterStatus);
    updateUserMock.mockResolvedValueOnce(afterData);

    const res = await request(app)
      .patch('/api/admin/users/u-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ status: 'suspenso', nome_completo: 'Outro' });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ user: afterData });
    const statusOrder = setUserStatusMock.mock.invocationCallOrder[0];
    const dataOrder   = updateUserMock.mock.invocationCallOrder[0];
    expect(statusOrder).toBeLessThan(dataOrder);
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

  it('retorna 400 quando body está vazio', async () => {
    const res = await request(app)
      .patch('/api/admin/hotels/h-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({});
    expect(res.status).toBe(400);
    expect(setHotelStatusMock).not.toHaveBeenCalled();
    expect(updateHotelMock).not.toHaveBeenCalled();
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

  it('retorna 200 + { hotel } ao editar dados de endereço', async () => {
    const updated: AdminHotelDTO = { ...sampleHotel, descricao: 'Nova descrição' };
    updateHotelMock.mockResolvedValueOnce(updated);
    const res = await request(app)
      .patch('/api/admin/hotels/h-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ descricao: 'Nova descrição' });
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ hotel: updated });
    expect(updateHotelMock).toHaveBeenCalledWith('h-42', { descricao: 'Nova descrição' });
  });

  it('retorna 409 quando email de hotel já está em uso (pg 23505)', async () => {
    const pgErr = Object.assign(new Error('duplicate key'), { code: '23505' });
    updateHotelMock.mockRejectedValueOnce(pgErr);
    const res = await request(app)
      .patch('/api/admin/hotels/h-42')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ email: 'existente@hotel.com' });
    expect(res.status).toBe(409);
  });
});
