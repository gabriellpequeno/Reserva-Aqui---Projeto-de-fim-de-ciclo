jest.mock('../../services/searchRoom.service');
jest.mock('../../database/masterDb');
jest.mock('../../database/schemaWrapper');

import express from 'express';
import request from 'supertest';
import searchRoomRoutes from '../searchRoom.routes';
import { searchRooms } from '../../services/searchRoom.service';

const searchRoomsMock = searchRooms as jest.Mock;

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/quartos', searchRoomRoutes);
  return app;
}

describe('GET /api/quartos/busca', () => {
  let app: express.Application;

  beforeEach(() => {
    jest.clearAllMocks();
    app = createApp();
  });

  it('deve retornar 400 quando q está ausente', async () => {
    const response = await request(app).get('/api/quartos/busca');

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ error: 'Parâmetro q é obrigatório' });
  });

  it('deve retornar 400 quando q tem menos de 2 caracteres', async () => {
    const response = await request(app).get('/api/quartos/busca?q=a');

    expect(response.status).toBe(400);
    expect(response.body).toEqual({
      error: 'Parâmetro q deve ter no mínimo 2 caracteres',
    });
  });

  it('deve retornar 400 quando q tem apenas 1 caractere válido após trim', async () => {
    const response = await request(app).get('/api/quartos/busca?q=a');

    expect(response.status).toBe(400);
    expect(response.body).toEqual({
      error: 'Parâmetro q deve ter no mínimo 2 caracteres',
    });
  });

  it('deve retornar 200 com lista vazia quando nenhum hotel casa', async () => {
    searchRoomsMock.mockResolvedValueOnce([]);

    const response = await request(app).get('/api/quartos/busca?q=inexistente');

    expect(response.status).toBe(200);
    expect(response.body).toEqual([]);
  });

  it('deve retornar 200 com quartos quando houver match', async () => {
    const mockResults = [
      {
        quarto_id: 1,
        hotel_id: 'h1',
        numero: '101',
        descricao: 'Quarto confortável',
        valor_diaria: '150.00',
        itens: [
          { catalogo_id: 1, nome: 'TV', categoria: 'Eletrônicos', quantidade: 1 },
        ],
        nome_hotel: 'Hotel A',
        cidade: 'Salvador',
        uf: 'BA',
      },
    ];

    searchRoomsMock.mockResolvedValueOnce(mockResults);

    const response = await request(app).get('/api/quartos/busca?q=salvador');

    expect(response.status).toBe(200);
    expect(response.body).toEqual(mockResults);
    expect(response.body[0]).toHaveProperty('quarto_id');
    expect(response.body[0]).toHaveProperty('hotel_id');
    expect(response.body[0]).toHaveProperty('nome_hotel');
    expect(response.body[0]).toHaveProperty('cidade');
    expect(response.body[0]).toHaveProperty('uf');
    expect(response.body[0]).toHaveProperty('valor_diaria');
    expect(response.body[0]).toHaveProperty('descricao');
    expect(response.body[0]).toHaveProperty('itens');
  });

  it('deve aceitar refinos opcionais (checkin, checkout, hospedes)', async () => {
    searchRoomsMock.mockResolvedValueOnce([]);

    const response = await request(app)
      .get('/api/quartos/busca')
      .query({
        q: 'salvador',
        checkin: '2026-05-01',
        checkout: '2026-05-05',
        hospedes: 2,
      });

    expect(response.status).toBe(200);
    expect(searchRoomsMock).toHaveBeenCalled();
  });

  it('deve retornar 500 em erros inesperados do service', async () => {
    searchRoomsMock.mockRejectedValueOnce(new Error('Database error'));

    const response = await request(app).get('/api/quartos/busca?q=salvador');

    expect(response.status).toBe(500);
    expect(response.body).toEqual({ error: 'Erro interno' });
  });
});
