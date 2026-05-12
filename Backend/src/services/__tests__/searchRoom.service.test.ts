jest.mock('../../database/masterDb', () => ({
  masterPool: {
    query: jest.fn(),
  },
}));

jest.mock('../../database/schemaWrapper', () => ({
  withTenant: jest.fn(),
}));

import { masterPool } from '../../database/masterDb';
import { withTenant } from '../../database/schemaWrapper';
import { searchRooms } from '../searchRoom.service';

const queryMock = masterPool.query as jest.Mock;
const withTenantMock = withTenant as jest.Mock;

describe('searchRoom.service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('deve escapar wildcards em q=50%', async () => {
    queryMock.mockResolvedValue({ rows: [] });

    await searchRooms('50%');

    // Verifica que o padrão foi montado com % escapado
    const [query, params] = queryMock.mock.calls[0];
    expect(params[0]).toEqual('%50\\%%');
    expect(params).toEqual(['%50\\%%', '%50\\%%', '%50\\%%']);
  });

  it('deve fazer busca acento-insensitive com unaccent()', async () => {
    queryMock.mockResolvedValue({ rows: [] });

    await searchRooms('São Paulo');

    // Verifica que a query usa unaccent()
    const [query] = queryMock.mock.calls[0];
    expect(query).toContain('unaccent(');
    expect(query).toContain('ILIKE');
  });

  it('deve filtrar hotéis com ativo = FALSE na master', async () => {
    queryMock.mockResolvedValue({ rows: [] });

    await searchRooms('salvador');

    const [query] = queryMock.mock.calls[0];
    expect(query).toContain('ativo = TRUE');
  });

  it('deve limitar a 20 hotéis', async () => {
    queryMock.mockResolvedValue({ rows: [] });

    await searchRooms('test');

    const [query] = queryMock.mock.calls[0];
    expect(query).toContain('LIMIT 20');
  });

  it('deve fazer fan-out com Promise.all em mulitplos tenants', async () => {
    const hotel1 = {
      hotel_id: 'h1',
      nome_hotel: 'Hotel A',
      cidade: 'Salvador',
      uf: 'BA',
      schema_name: 'schema_h1',
    };
    const hotel2 = {
      hotel_id: 'h2',
      nome_hotel: 'Hotel B',
      cidade: 'Salvador',
      uf: 'BA',
      schema_name: 'schema_h2',
    };

    queryMock.mockResolvedValue({ rows: [hotel1, hotel2] });

    const quartos1 = [
      { id: 1, numero: '101', descricao: 'Q1', valor_diaria: '100', itens: [] },
    ];
    const quartos2 = [
      { id: 2, numero: '201', descricao: 'Q2', valor_diaria: '150', itens: [] },
    ];

    withTenantMock.mockImplementation((schema: string, callback: any) => {
      if (schema === 'schema_h1') return Promise.resolve(quartos1);
      if (schema === 'schema_h2') return Promise.resolve(quartos2);
      return Promise.resolve([]);
    });

    const results = await searchRooms('salvador');

    // Verifica fan-out paralelo (withTenantMock chamado 2 vezes)
    expect(withTenantMock).toHaveBeenCalledTimes(2);
    expect(results).toHaveLength(2);
  });

  it('deve omitir hotel se tenant lançar erro (try/catch individual)', async () => {
    const hotel1 = {
      hotel_id: 'h1',
      nome_hotel: 'Hotel A',
      cidade: 'Salvador',
      uf: 'BA',
      schema_name: 'schema_h1',
    };
    const hotel2 = {
      hotel_id: 'h2',
      nome_hotel: 'Hotel B',
      cidade: 'Salvador',
      uf: 'BA',
      schema_name: 'schema_h2',
    };

    queryMock.mockResolvedValue({ rows: [hotel1, hotel2] });

    withTenantMock.mockImplementation((schema: string) => {
      if (schema === 'schema_h1') return Promise.reject(new Error('Schema not found'));
      if (schema === 'schema_h2') {
        return Promise.resolve([
          { id: 2, numero: '201', descricao: 'Q2', valor_diaria: '150', itens: [] },
        ]);
      }
      return Promise.resolve([]);
    });

    const results = await searchRooms('salvador');

    // Verifica que h1 foi omitido e apenas h2 foi retornado
    expect(results).toHaveLength(1);
    expect(results[0].hotel_id).toBe('h2');
  });

  it('deve retornar lista vazia quando nenhum hotel casa', async () => {
    queryMock.mockResolvedValue({ rows: [] });

    const results = await searchRooms('inexistente');

    expect(results).toEqual([]);
  });

  it('deve enrich quartos com dados do hotel (nome_hotel, cidade, uf)', async () => {
    const hotel = {
      hotel_id: 'h1',
      nome_hotel: 'Pousada do Sol',
      cidade: 'Salvador',
      uf: 'BA',
      schema_name: 'schema_h1',
    };

    queryMock.mockResolvedValue({ rows: [hotel] });

    withTenantMock.mockResolvedValue([
      { id: 1, numero: '101', descricao: 'Quarto', valor_diaria: '100', itens: [] },
    ]);

    const results = await searchRooms('salvador');

    expect(results[0].nome_hotel).toBe('Pousada do Sol');
    expect(results[0].cidade).toBe('Salvador');
    expect(results[0].uf).toBe('BA');
  });

  describe('escapeLikePattern (via params do mock)', () => {
    it('escapa underscore (_) que é wildcard de "qualquer caractere" em LIKE', async () => {
      queryMock.mockResolvedValue({ rows: [] });
      await searchRooms('foo_bar');
      const [, params] = queryMock.mock.calls[0];
      expect(params[0]).toBe('%foo\\_bar%');
    });

    it('escapa backslash antes dos demais wildcards (ordem importa)', async () => {
      queryMock.mockResolvedValue({ rows: [] });
      await searchRooms('a\\b');
      const [, params] = queryMock.mock.calls[0];
      // \ vira \\, então o pattern fica %a\\b%
      expect(params[0]).toBe('%a\\\\b%');
    });

    it('escapa combinação de %, _ e \\ no mesmo input', async () => {
      queryMock.mockResolvedValue({ rows: [] });
      await searchRooms('50%_off\\promo');
      const [, params] = queryMock.mock.calls[0];
      expect(params[0]).toBe('%50\\%\\_off\\\\promo%');
    });

    it('preserva caracteres unicode e acentos sem alterar', async () => {
      queryMock.mockResolvedValue({ rows: [] });
      await searchRooms('São Paulo — Pousada 🏨');
      const [, params] = queryMock.mock.calls[0];
      expect(params[0]).toBe('%São Paulo — Pousada 🏨%');
    });

    it('faz trim da query antes de montar o pattern', async () => {
      queryMock.mockResolvedValue({ rows: [] });
      await searchRooms('   salvador   ');
      const [, params] = queryMock.mock.calls[0];
      expect(params[0]).toBe('%salvador%');
    });
  });

  describe('query curta / vazia', () => {
    it('quando q tem menos de 2 chars após trim, usa query sem filtros', async () => {
      queryMock.mockResolvedValue({ rows: [] });
      await searchRooms(' a ');
      const [query, params] = queryMock.mock.calls[0];
      expect(params).toBeUndefined();
      expect(query).not.toContain('ILIKE');
      expect(query).toContain('ativo = TRUE');
      expect(query).toContain('LIMIT 20');
    });

    it('quando q é string vazia, também usa o caminho sem filtros', async () => {
      queryMock.mockResolvedValue({ rows: [] });
      await searchRooms('');
      const [query, params] = queryMock.mock.calls[0];
      expect(params).toBeUndefined();
      expect(query).not.toContain('ILIKE');
    });
  });
});
