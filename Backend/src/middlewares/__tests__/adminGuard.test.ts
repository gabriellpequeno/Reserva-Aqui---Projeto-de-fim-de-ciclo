/**
 * Testes do middleware adminGuard.
 *
 * IMPORTANTE: authGuard.ts captura `process.env.JWT_SECRET` no momento do import.
 * Definimos o segredo ANTES de qualquer import dinâmico dos módulos sob teste.
 */
process.env.JWT_SECRET = 'test-secret-for-admin-guard-suite-please-ignore';

import express from 'express';
import request from 'supertest';
import jwt from 'jsonwebtoken';

// Imports dinâmicos após setar JWT_SECRET
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { adminGuard }: typeof import('../adminGuard') = require('../adminGuard');
type AuthRequest = import('../authGuard').AuthRequest;

const JWT_SECRET = process.env.JWT_SECRET!;

function createApp() {
  const app = express();
  app.use(express.json());
  app.get('/protected', adminGuard, (req, res) => {
    const r = req as AuthRequest;
    res.json({ ok: true, userId: r.userId, papel: r.userPapel });
  });
  return app;
}

function signToken(payload: Record<string, unknown>): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '1h' });
}

describe('adminGuard', () => {
  let app: express.Application;

  beforeEach(() => {
    app = createApp();
  });

  it('retorna 401 quando não há header Authorization', async () => {
    const res = await request(app).get('/protected');
    expect(res.status).toBe(401);
    expect(res.body.error).toMatch(/Token não fornecido/i);
  });

  it('retorna 401 quando token é inválido', async () => {
    const res = await request(app)
      .get('/protected')
      .set('Authorization', 'Bearer token-invalido');
    expect(res.status).toBe(401);
  });

  it('retorna 403 quando token é válido mas papel é "usuario"', async () => {
    const token = signToken({ user_id: 'u1', email: 'u@x.com', papel: 'usuario' });
    const res = await request(app)
      .get('/protected')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(403);
    expect(res.body.error).toMatch(/administrador/i);
  });

  it('retorna 403 quando token legado não tem papel (fallback "usuario")', async () => {
    const token = signToken({ user_id: 'u1', email: 'u@x.com' });
    const res = await request(app)
      .get('/protected')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(403);
  });

  it('chama next() e expõe req.userPapel="admin" quando papel é admin', async () => {
    const token = signToken({ user_id: 'admin-1', email: 'a@x.com', papel: 'admin' });
    const res = await request(app)
      .get('/protected')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true, userId: 'admin-1', papel: 'admin' });
  });
});
