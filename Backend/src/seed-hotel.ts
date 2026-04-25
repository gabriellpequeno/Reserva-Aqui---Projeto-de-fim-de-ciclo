import 'dotenv/config'; // carrega .env ANTES de qualquer import que use process.env

import { registerAnfitriao } from './services/anfitriao.service';
import { createCategoriaQuarto } from './services/categoriaQuarto.service';
import { createQuarto } from './services/quarto.service';
import { DynamicIngestionService } from './services/ai/dynamicIngestion.service';
import { masterPool } from './database/masterDb';

// Senha que atende: maiúscula + minúscula + @ + número
const SEED_PASSWORD = 'Seed@2026';

const hoteisParaCriar = [
  // ── SÃO PAULO ───────────────────────────────────────────────
  {
    nome_hotel: 'Hotel Paradiso', cnpj: '12345678000199', telefone: '11999999991',
    email: 'paradiso@teste.com', cep: '01000000', uf: 'SP', cidade: 'São Paulo',
    bairro: 'Centro', rua: 'Rua das Flores', numero: '100',
    descricao: 'O melhor hotel de São Paulo, perto de tudo e com muito conforto.',
  },
  {
    nome_hotel: 'Paulista Premium', cnpj: '12345678000299', telefone: '11999999992',
    email: 'paulista@teste.com', cep: '01310100', uf: 'SP', cidade: 'São Paulo',
    bairro: 'Bela Vista', rua: 'Av. Paulista', numero: '1500',
    descricao: 'Executivo e moderno, ideal para viagens de negócios.',
  },
  {
    nome_hotel: 'Vila Madalena Hostel', cnpj: '12345678000399', telefone: '11999999993',
    email: 'vilamada@teste.com', cep: '05414000', uf: 'SP', cidade: 'São Paulo',
    bairro: 'Vila Madalena', rua: 'Rua Purpurina', numero: '45',
    descricao: 'Descolado e jovem, no coração boêmio da cidade.',
  },
  {
    nome_hotel: 'Ibirapuera Park Hotel', cnpj: '12345678000499', telefone: '11999999994',
    email: 'ibira@teste.com', cep: '04094050', uf: 'SP', cidade: 'São Paulo',
    bairro: 'Ibirapuera', rua: 'Av. Pedro Alvares Cabral', numero: '200',
    descricao: 'Tranquilidade e natureza ao lado do maior parque da cidade.',
  },
  {
    nome_hotel: 'Guarulhos Airport Inn', cnpj: '12345678000599', telefone: '11999999995',
    email: 'gru@teste.com', cep: '07190000', uf: 'SP', cidade: 'Guarulhos',
    bairro: 'Aeroporto', rua: 'Rod Helio Smidt', numero: '1',
    descricao: 'Praticidade para quem esta em transito no aeroporto de Guarulhos.',
  },
  // ── CEARÁ ───────────────────────────────────────────────────
  {
    nome_hotel: 'Jeri Beach Resort', cnpj: '12345678000699', telefone: '85999999991',
    email: 'jeri@teste.com', cep: '62598000', uf: 'CE', cidade: 'Jijoca de Jericoacoara',
    bairro: 'Vila', rua: 'Rua do Forro', numero: '10',
    descricao: 'Pe na areia, luxo e a melhor vista do por do sol nas dunas.',
  },
  {
    nome_hotel: 'Fortaleza Beira Mar', cnpj: '12345678000799', telefone: '85999999992',
    email: 'fortaleza@teste.com', cep: '60165120', uf: 'CE', cidade: 'Fortaleza',
    bairro: 'Meireles', rua: 'Av. Beira Mar', numero: '3000',
    descricao: 'Conforto padrao internacional na orla mais famosa do Ceara.',
  },
  {
    nome_hotel: 'Canoa Quebrada Lodge', cnpj: '12345678000899', telefone: '85999999993',
    email: 'canoa@teste.com', cep: '62800000', uf: 'CE', cidade: 'Aracati',
    bairro: 'Canoa Quebrada', rua: 'Broadway', numero: '150',
    descricao: 'Charme rustico perto das falesias de Canoa Quebrada.',
  },
  {
    nome_hotel: 'Cumbuco Kite House', cnpj: '12345678000999', telefone: '85999999994',
    email: 'cumbuco@teste.com', cep: '61619000', uf: 'CE', cidade: 'Caucaia',
    bairro: 'Cumbuco', rua: 'Av. dos Ventos', numero: '55',
    descricao: 'O refugio perfeito para amantes de Kitesurf.',
  },
];

async function seed() {
  console.log('--- Iniciando Seed Multiplo de Hoteis ---');

  try {
    for (const dados of hoteisParaCriar) {
      console.log(`\n⏳ Processando: ${dados.nome_hotel} (${dados.uf})...`);

      try {
        // 1. Cadastra o Hotel
        const hotel = await registerAnfitriao({
          ...dados,
          senha: SEED_PASSWORD,
        } as any);
        console.log(`  ✅ Hotel criado | schema: ${hotel.schema_name}`);

        // 2. Cadastra uma Categoria de Quarto
        const valorDiaria = parseFloat((Math.random() * 200 + 150).toFixed(2));
        const categoria = await createCategoriaQuarto(hotel.hotel_id, {
          nome: 'Quarto Padrao',
          capacidade_pessoas: 2,
          valor_diaria: valorDiaria,
        });
        console.log(`  ✅ Categoria criada | R$ ${valorDiaria}/diaria`);

        // 3. Cadastra 3 Quartos
        for (const num of ['101', '102', '103']) {
          await createQuarto(hotel.hotel_id, {
            categoria_quarto_id: categoria.id,
            numero: num,
          });
        }
        console.log(`  ✅ Quartos 101, 102, 103 criados`);

        // 4. Ingestao de Dados no PGVector (RAG)
        await DynamicIngestionService.ingestHotelData(hotel.hotel_id, hotel.schema_name);
        console.log(`  ✅ RAG/PGVector indexado`);
      } catch (err: any) {
        if (
          err.message?.includes('duplicate key') ||
          err.message?.includes('unique constraint') ||
          err.message?.includes('ja existe')
        ) {
          console.log(`  ⚠️ ${dados.nome_hotel} ja existe no banco (ignorado).`);
        } else {
          console.error(`  ❌ Erro: ${err.message}`);
        }
      }
    }
  } catch (error: any) {
    console.error('❌ Erro fatal no seed:', error.message);
  } finally {
    console.log('\n--- Seed Finalizado! ---');
    await masterPool.end();
    process.exit(0);
  }
}

seed();
