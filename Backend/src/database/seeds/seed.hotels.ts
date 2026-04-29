/**
 * Seed: Hotéis
 *
 * Cria 9 hotéis de teste (5 em SP, 4 no CE) com dados completos para
 * renderização da hotel_details_page:
 *   - Registro do hotel (anfitrião)
 *   - Configuração operacional via createConfiguracaoHotel
 *   - Catálogo de comodidades via createCatalogo
 *   - 3 categorias de quarto com variação de camas
 *   - Quartos físicos por categoria
 *   - Avaliações com nota média realista
 *   - Indexação RAG/PGVector
 *
 * Guard: executar apenas fora de produção.
 */
import 'dotenv/config';
import { registerAnfitriao }                          from '../../services/anfitriao.service';
import { createConfiguracaoHotel }                    from '../../services/configuracao.service';
import { createCatalogo }                             from '../../services/catalogo.service';
import { createCategoriaQuarto, addItemToCategoria }  from '../../services/categoriaQuarto.service';
import { createQuarto }                               from '../../services/quarto.service';
import { DynamicIngestionService }                    from '../../services/ai/dynamicIngestion.service';
import { masterPool }                                 from '../masterDb';
import { withTenant }                                 from '../schemaWrapper';
import { CategoriaItem }                              from '../../entities/Catalogo';

if (process.env.NODE_ENV === 'production') {
  console.log('[seed/hotels] Seed ignorado em produção');
  process.exit(0);
}

const SEED_PASSWORD = 'Seed@2026';

// Usuário fixo para avaliações — idempotente em re-execuções
const SEED_USER = {
  nome_completo:   'Usuário Seed',
  email:           'seed@reservaqui.dev',
  senha:           '$2b$10$seedpasswordhashxxxxxseedpasswordhashxxxxxx',
  cpf:             '000.000.000-00',
  numero_celular:  '(00) 00000-0000',
  data_nascimento: '1990-01-01',
};

// Comodidades comuns a todos os hotéis
const CATALOGO_ITENS: { nome: string; categoria: CategoriaItem }[] = [
  { nome: 'Wi-Fi',              categoria: 'COMODIDADE' },
  { nome: 'Ar-condicionado',    categoria: 'COMODIDADE' },
  { nome: 'TV a cabo',          categoria: 'COMODIDADE' },
  { nome: 'Frigobar',           categoria: 'COMODIDADE' },
  { nome: 'Cofre digital',      categoria: 'COMODIDADE' },
  { nome: 'Cama king-size',     categoria: 'COMODO'     },
  { nome: 'Cama queen-size',    categoria: 'COMODO'     },
  { nome: 'Cama de solteiro',   categoria: 'COMODO'     },
  { nome: 'Banheiro privativo', categoria: 'COMODO'     },
  { nome: 'Varanda',            categoria: 'COMODO'     },
  { nome: 'Piscina',            categoria: 'LAZER'      },
  { nome: 'Academia',           categoria: 'LAZER'      },
  { nome: 'Spa',                categoria: 'LAZER'      },
  { nome: 'Restaurante',        categoria: 'LAZER'      },
];

// Categorias com variação de camas (filtrável no frontend)
interface CategoriaConfig {
  nome: string;
  preco_base: number;
  capacidade_pessoas: number;
  itens: string[];
  quartos: { numero: string; valor: number; descricao: string }[];
}

const CATEGORIAS: CategoriaConfig[] = [
  {
    nome: 'Suíte — 1 cama king',
    preco_base: 480,
    capacidade_pessoas: 2,
    itens: ['Wi-Fi', 'Ar-condicionado', 'TV a cabo', 'Frigobar', 'Cofre digital', 'Cama king-size', 'Banheiro privativo', 'Varanda'],
    quartos: [
      { numero: '201', valor: 480, descricao: 'Suíte com cama king-size, banheiro privativo com banheira e varanda com vista.' },
      { numero: '202', valor: 520, descricao: 'Suíte premium no último andar, cama king-size e vista panorâmica da cidade.' },
    ],
  },
  {
    nome: 'Quarto Duplo — 1 cama queen',
    preco_base: 320,
    capacidade_pessoas: 2,
    itens: ['Wi-Fi', 'Ar-condicionado', 'TV a cabo', 'Frigobar', 'Cama queen-size', 'Banheiro privativo'],
    quartos: [
      { numero: '101', valor: 320, descricao: 'Quarto duplo com cama queen-size, frigobar e banheiro privativo.' },
      { numero: '102', valor: 340, descricao: 'Quarto duplo renovado com cama queen-size e varanda privativa.' },
      { numero: '103', valor: 360, descricao: 'Quarto duplo superior com cama queen-size e vista para o jardim.' },
    ],
  },
  {
    nome: 'Quarto Single — 1 cama solteiro',
    preco_base: 180,
    capacidade_pessoas: 1,
    itens: ['Wi-Fi', 'Ar-condicionado', 'TV a cabo', 'Cama de solteiro', 'Banheiro privativo'],
    quartos: [
      { numero: '301', valor: 180, descricao: 'Quarto individual compacto, ideal para viagens a trabalho.' },
      { numero: '302', valor: 200, descricao: 'Quarto individual com escrivaninha e Wi-Fi de alta velocidade.' },
    ],
  },
];

// Avaliações de seed por hotel (nota média ~4.2 para renderização realista)
const AVALIACOES_SEED = [
  { nota: 5, comentario: 'Excelente atendimento e quarto impecável. Voltarei com certeza!' },
  { nota: 4, comentario: 'Ótimo custo-benefício, localização perfeita. Recomendo.' },
  { nota: 5, comentario: 'Estrutura incrível, café da manhã variado e staff muito atencioso.' },
  { nota: 4, comentario: 'Confortável e limpo. Check-in rápido e sem problemas.' },
  { nota: 3, comentario: 'Boa estadia, mas o ar-condicionado do quarto fazia barulho.' },
];

const hoteisParaCriar = [
  // ── SÃO PAULO ────────────────────────────────────────────────
  {
    nome_hotel: 'Hotel Paradiso',        cnpj: '12345678000199', telefone: '11999999991',
    email: 'paradiso@teste.com',         cep: '01000000', uf: 'SP', cidade: 'São Paulo',
    bairro: 'Centro',     rua: 'Rua das Flores',           numero: '100',
    descricao: 'O melhor hotel de São Paulo, perto de tudo e com muito conforto.',
  },
  {
    nome_hotel: 'Paulista Premium',      cnpj: '12345678000299', telefone: '11999999992',
    email: 'paulista@teste.com',         cep: '01310100', uf: 'SP', cidade: 'São Paulo',
    bairro: 'Bela Vista', rua: 'Av. Paulista',             numero: '1500',
    descricao: 'Executivo e moderno, ideal para viagens de negócios.',
  },
  {
    nome_hotel: 'Vila Madalena Hostel',  cnpj: '12345678000399', telefone: '11999999993',
    email: 'vilamada@teste.com',         cep: '05414000', uf: 'SP', cidade: 'São Paulo',
    bairro: 'Vila Madalena', rua: 'Rua Purpurina',         numero: '45',
    descricao: 'Descolado e jovem, no coração boêmio da cidade.',
  },
  {
    nome_hotel: 'Ibirapuera Park Hotel', cnpj: '12345678000499', telefone: '11999999994',
    email: 'ibira@teste.com',            cep: '04094050', uf: 'SP', cidade: 'São Paulo',
    bairro: 'Ibirapuera', rua: 'Av. Pedro Alvares Cabral', numero: '200',
    descricao: 'Tranquilidade e natureza ao lado do maior parque da cidade.',
  },
  {
    nome_hotel: 'Guarulhos Airport Inn', cnpj: '12345678000599', telefone: '11999999995',
    email: 'gru@teste.com',              cep: '07190000', uf: 'SP', cidade: 'Guarulhos',
    bairro: 'Aeroporto',  rua: 'Rod Helio Smidt',          numero: '1',
    descricao: 'Praticidade para quem esta em transito no aeroporto de Guarulhos.',
  },
  // ── CEARÁ ────────────────────────────────────────────────────
  {
    nome_hotel: 'Jeri Beach Resort',     cnpj: '12345678000699', telefone: '85999999991',
    email: 'jeri@teste.com',             cep: '62598000', uf: 'CE', cidade: 'Jijoca de Jericoacoara',
    bairro: 'Vila',       rua: 'Rua do Forro',              numero: '10',
    descricao: 'Pe na areia, luxo e a melhor vista do por do sol nas dunas.',
  },
  {
    nome_hotel: 'Fortaleza Beira Mar',   cnpj: '12345678000799', telefone: '85999999992',
    email: 'fortaleza@teste.com',        cep: '60165120', uf: 'CE', cidade: 'Fortaleza',
    bairro: 'Meireles',   rua: 'Av. Beira Mar',             numero: '3000',
    descricao: 'Conforto padrao internacional na orla mais famosa do Ceara.',
  },
  {
    nome_hotel: 'Canoa Quebrada Lodge',  cnpj: '12345678000899', telefone: '85999999993',
    email: 'canoa@teste.com',            cep: '62800000', uf: 'CE', cidade: 'Aracati',
    bairro: 'Canoa Quebrada', rua: 'Broadway',              numero: '150',
    descricao: 'Charme rustico perto das falesias de Canoa Quebrada.',
  },
  {
    nome_hotel: 'Cumbuco Kite House',    cnpj: '12345678000999', telefone: '85999999994',
    email: 'cumbuco@teste.com',          cep: '61619000', uf: 'CE', cidade: 'Caucaia',
    bairro: 'Cumbuco',    rua: 'Av. dos Ventos',            numero: '55',
    descricao: 'O refugio perfeito para amantes de Kitesurf.',
  },
];

export async function seedHotels(): Promise<void> {
  console.log('--- Iniciando Seed de Hotéis ---\n');

  // Cria (ou reutiliza) usuário de seed para avaliações
  const { rows: userRows } = await masterPool.query<{ user_id: string }>(
    `INSERT INTO usuario (nome_completo, email, senha, cpf, numero_celular, data_nascimento)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (email) DO UPDATE SET nome_completo = EXCLUDED.nome_completo
     RETURNING user_id`,
    [SEED_USER.nome_completo, SEED_USER.email, SEED_USER.senha,
     SEED_USER.cpf, SEED_USER.numero_celular, SEED_USER.data_nascimento],
  );
  const seedUserId = userRows[0].user_id;
  console.log(`[seed] Usuário de seed: ${seedUserId}\n`);

  for (const dados of hoteisParaCriar) {
    console.log(`⏳ ${dados.nome_hotel} (${dados.uf})...`);

    try {
      // 1. Registra o hotel
      const hotel = await registerAnfitriao({ ...dados, senha: SEED_PASSWORD } as any);
      console.log(`  ✅ Hotel criado | schema: ${hotel.schema_name}`);

      // 2. Configuração operacional via service
      await createConfiguracaoHotel(hotel.hotel_id, {
        horario_checkin:        '14:00',
        horario_checkout:       '12:00',
        max_dias_reserva:       30,
        politica_cancelamento:  'Cancelamento gratuito até 24h antes do check-in. Após esse prazo, será cobrada 1 diária.',
        aceita_animais:         false,
        idiomas_atendimento:    'Português',
      });
      console.log('  ✅ Configuração criada');

      // 3. Catálogo de comodidades via service
      const catalogoIds: Record<string, number> = {};
      for (const item of CATALOGO_ITENS) {
        const criado = await createCatalogo(hotel.hotel_id, {
          nome:      item.nome,
          categoria: item.categoria,
        });
        catalogoIds[item.nome] = criado.id;
      }
      console.log(`  ✅ Catálogo: ${CATALOGO_ITENS.length} itens`);

      // 4. Categorias de quarto via service + itens vinculados
      for (const cat of CATEGORIAS) {
        const categoria = await createCategoriaQuarto(hotel.hotel_id, {
          nome:               cat.nome,
          capacidade_pessoas: cat.capacidade_pessoas,
          valor_diaria:       cat.preco_base,
        });

        for (const nomeItem of cat.itens) {
          const itemId = catalogoIds[nomeItem];
          if (!itemId) continue;
          await addItemToCategoria(hotel.hotel_id, categoria.id, {
            catalogo_id: itemId,
            quantidade:  1,
          });
        }

        // 5. Quartos da categoria via service
        for (const q of cat.quartos) {
          await createQuarto(hotel.hotel_id, {
            categoria_quarto_id: categoria.id,
            numero:              q.numero,
            descricao:           q.descricao,
            valor_diaria:        q.valor,
          });
        }
        console.log(`  ✅ Categoria "${cat.nome}" | ${cat.quartos.length} quartos`);
      }

      // 6. Avaliações — via SQL direto pois createAvaliacao exige reserva real
      await withTenant(hotel.schema_name, async (client) => {
        // Registra usuário de seed como hóspede no tenant
        await client.query(
          `INSERT INTO hospede (user_id) VALUES ($1) ON CONFLICT DO NOTHING`,
          [seedUserId],
        );

        const { rows: quartoRows } = await client.query<{ id: number }>(
          `SELECT id FROM quarto WHERE numero = '101' AND deleted_at IS NULL LIMIT 1`,
        );

        if (!quartoRows.length) return;
        const quartoId = quartoRows[0].id;

        for (const av of AVALIACOES_SEED) {
          const { rows: reservaRows } = await client.query<{ id: number }>(
            `INSERT INTO reserva
               (quarto_id, user_id, num_hospedes, data_checkin, data_checkout,
                status, canal_origem, valor_total, codigo_publico)
             VALUES ($1, $2, 1, '2025-03-01', '2025-03-02',
                     'CONCLUIDA', 'APP', 320, gen_random_uuid())
             RETURNING id`,
            [quartoId, seedUserId],
          );
          if (!reservaRows.length) continue;

          await client.query(
            `INSERT INTO avaliacao
               (user_id, reserva_id, nota_limpeza, nota_atendimento, nota_conforto,
                nota_organizacao, nota_localizacao, nota_total, comentario)
             VALUES ($1, $2, $3, $3, $3, $3, $3, $3, $4)
             ON CONFLICT DO NOTHING`,
            [seedUserId, reservaRows[0].id, av.nota, av.comentario],
          );
        }
        console.log(`  ✅ ${AVALIACOES_SEED.length} avaliações criadas`);
      });

      // 7. Indexação RAG/PGVector
      await DynamicIngestionService.ingestHotelData(hotel.hotel_id, hotel.schema_name);
      console.log('  ✅ RAG/PGVector indexado\n');

    } catch (err: any) {
      if (
        err.message?.includes('duplicate key') ||
        err.message?.includes('unique constraint') ||
        err.message?.includes('ja existe')
      ) {
        console.log(`  ⚠️  ${dados.nome_hotel} já existe no banco (ignorado)\n`);
      } else {
        console.error(`  ❌ Erro em ${dados.nome_hotel}: ${err.message}\n`);
      }
    }
  }

  console.log('--- Seed de Hotéis Finalizado ---');
}

// Auto-execução apenas quando rodado diretamente (não via orquestrador)
if (require.main === module) {
  seedHotels()
    .catch((err) => {
      console.error('[seed/hotels] Erro fatal:', err);
      process.exit(1);
    })
    .finally(async () => {
      await masterPool.end();
      process.exit(0);
    });
}
