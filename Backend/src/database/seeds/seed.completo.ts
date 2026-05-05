/**
 * Seed: Completo — Hotéis, Usuários, Quartos, Avaliações e Imagens Mockadas
 *
 * Cria:
 *   - 1 admin da plataforma
 *   - 6 usuários reais (hóspedes)
 *   - 5 hotéis em 5 estados diferentes (SP, RJ, BA, RS, AM)
 *   - Cada hotel com 5 categorias e 2-3 quartos por categoria
 *   - Fotos mockadas (storage_path) para capa do hotel e quartos
 *   - Avaliações completas (todas as notas + comentário) por usuários reais
 *   - Reservas CONCLUÍDAS vinculando usuário → quarto → avaliação
 *
 * Padrão de storage_path (relativo a UPLOAD_DIR):
 *   Capa hotel:  hotels/{hotel_id}/cover/portrait/seed-{1..3}.jpg
 *                hotels/{hotel_id}/cover/landscape/seed-{1..3}.jpg
 *   Foto quarto: hotels/{hotel_id}/rooms/{quarto_id}/seed-{1..3}.jpg
 *
 * CORREÇÕES vs versão anterior:
 *   - Usuários criados via registerUsuario() (valida + hash correto + converte data)
 *   - data_nascimento no formato dd/mm/aaaa (exigido pelo validator de Usuario)
 *   - Fotos de quarto: DELETE + INSERT (tabela quarto_foto não tem UNIQUE em storage_path)
 *   - Fotos de hotel: DELETE + INSERT (idem foto_hotel)
 *   - cpf com pontuação — o service já faz replace(/\D/g,'') internamente
 *
 * Idempotente: ON CONFLICT (email) para usuários/hotéis; delete+insert para fotos.
 * Guard: ignorado em produção.
 */

import 'dotenv/config';
import argon2 from 'argon2';
import { masterPool }                                 from '../masterDb';
import { withTenant }                                 from '../schemaWrapper';
import { registerAnfitriao }                          from '../../services/anfitriao.service';
import { registerUsuario }                            from '../../services/usuario.service';
import { createConfiguracaoHotel }                    from '../../services/configuracao.service';
import { createCatalogo }                             from '../../services/catalogo.service';
import { createCategoriaQuarto, addItemToCategoria }  from '../../services/categoriaQuarto.service';
import { createQuarto }                               from '../../services/quarto.service';
import { DynamicIngestionService }                    from '../../services/ai/dynamicIngestion.service';
import { CategoriaItem }                              from '../../entities/Catalogo';

if (process.env.NODE_ENV === 'production') {
  console.log('[seed/completo] Seed ignorado em produção');
  process.exit(0);
}

// ─────────────────────────────────────────────────────────────────────────────
// ARGON2 OPTIONS (mesmo padrão do serviço de admin)
// ─────────────────────────────────────────────────────────────────────────────
const ARGON2_OPTIONS: argon2.Options = {
  type:        argon2.argon2id,
  memoryCost:  process.env.ARGON2_MEMORY_COST ? parseInt(process.env.ARGON2_MEMORY_COST, 10) : 65536,
  timeCost:    process.env.ARGON2_TIME_COST   ? parseInt(process.env.ARGON2_TIME_COST, 10)   : 3,
  parallelism: process.env.ARGON2_PARALLELISM ? parseInt(process.env.ARGON2_PARALLELISM, 10) : 1,
};

// ─────────────────────────────────────────────────────────────────────────────
// 1. ADMIN
// Admin bypassa registerUsuario — insere via SQL direto (igual ao seed.admin.ts)
// data_nascimento em yyyy-mm-dd pois vai direto ao banco sem parseDataBrToEn
// ─────────────────────────────────────────────────────────────────────────────
const ADMIN = {
  nome_completo:   'Admin ReservaAqui',
  email:           'admin@reservaqui.dev',
  senha:           'Admin@2026',
  cpf:             '00000000000',
  data_nascimento: '1985-06-15',
  numero_celular:  '(11) 99999-0000',
};

// ─────────────────────────────────────────────────────────────────────────────
// 2. USUÁRIOS HÓSPEDES
// data_nascimento em dd/mm/aaaa — validator de Usuario exige esse formato
// cpf com pontuação — registerUsuario() faz replace(/\D/g,'') antes do INSERT
// ─────────────────────────────────────────────────────────────────────────────
const USUARIOS = [
  {
    nome_completo:   'Carlos Eduardo Mendes',
    email:           'carlos.mendes@gmail.com',
    senha:           'Carlos@2026',
    cpf:             '123.456.789-01',
    data_nascimento: '22/03/1990',
    numero_celular:  '(11) 98765-4321',
  },
  {
    nome_completo:   'Ana Paula Ferreira',
    email:           'ana.ferreira@hotmail.com',
    senha:           'AnaP@2026',
    cpf:             '234.567.890-12',
    data_nascimento: '10/07/1993',
    numero_celular:  '(21) 97654-3210',
  },
  {
    nome_completo:   'Roberto Souza Lima',
    email:           'roberto.lima@outlook.com',
    senha:           'Roberto@2026',
    cpf:             '345.678.901-23',
    data_nascimento: '05/11/1987',
    numero_celular:  '(71) 96543-2109',
  },
  {
    nome_completo:   'Fernanda Costa Oliveira',
    email:           'fernanda.oliveira@gmail.com',
    senha:           'Fer@2026',
    cpf:             '456.789.012-34',
    data_nascimento: '28/01/1995',
    numero_celular:  '(51) 95432-1098',
  },
  {
    nome_completo:   'Marcos Antônio Pereira',
    email:           'marcos.pereira@yahoo.com.br',
    senha:           'Marcos@2026',
    cpf:             '567.890.123-45',
    data_nascimento: '14/09/1982',
    numero_celular:  '(92) 94321-0987',
  },
  {
    nome_completo:   'Juliana Ramos Barbosa',
    email:           'juliana.barbosa@gmail.com',
    senha:           'Juli@2026',
    cpf:             '678.901.234-56',
    data_nascimento: '30/04/1998',
    numero_celular:  '(11) 93210-9876',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// 3. HOTÉIS (5 estados: SP, RJ, BA, RS, AM)
// cnpj: 14 dígitos sem pontuação (validator aceita com ou sem, faz replace)
// cep: 8 dígitos sem traço (idem)
// senha: mínimo 8 chars, maiúscula, minúscula, especial e número (validado)
// ─────────────────────────────────────────────────────────────────────────────
interface HotelData {
  nome_hotel:   string;
  cnpj:         string;
  telefone:     string;
  email:        string;
  senha:        string;
  cep:          string;
  uf:           string;
  cidade:       string;
  bairro:       string;
  rua:          string;
  numero:       string;
  complemento?: string;
  descricao:    string;
}

const HOTEIS: HotelData[] = [
  {
    nome_hotel:  'Grand Paulista Hotel',
    cnpj:        '11222333000181',
    telefone:    '(11) 3456-7890',
    email:       'grandpaulista@reservaqui.com',
    senha:       'Hotel@2026',
    cep:         '01310100',
    uf:          'SP',
    cidade:      'São Paulo',
    bairro:      'Bela Vista',
    rua:         'Avenida Paulista',
    numero:      '1000',
    complemento: 'Torre A',
    descricao:   'Hotel 5 estrelas no coração da Avenida Paulista. Sofisticado e moderno, conta com piscina aquecida, spa, restaurante gourmet e academia completa. Ideal para viagens de negócios e turismo cultural em São Paulo.',
  },
  {
    nome_hotel:  'Copacabana Vista Mar',
    cnpj:        '22333444000172',
    telefone:    '(21) 2567-8901',
    email:       'copacabanavistamar@reservaqui.com',
    senha:       'Hotel@2026',
    cep:         '22070011',
    uf:          'RJ',
    cidade:      'Rio de Janeiro',
    bairro:      'Copacabana',
    rua:         'Avenida Atlântica',
    numero:      '3500',
    descricao:   'Hotel boutique frente ao mar em Copacabana. Quartos com vista privilegiada para o oceano Atlântico. A 200m da Praia de Copacabana, próximo ao Cristo Redentor e ao Pão de Açúcar.',
  },
  {
    nome_hotel:  'Pelourinho Palace Hotel',
    cnpj:        '33444555000163',
    telefone:    '(71) 3312-4567',
    email:       'pelourinhoppalace@reservaqui.com',
    senha:       'Hotel@2026',
    cep:         '40020010',
    uf:          'BA',
    cidade:      'Salvador',
    bairro:      'Pelourinho',
    rua:         'Largo do Pelourinho',
    numero:      '12',
    complemento: 'Sobrado histórico',
    descricao:   'Hotel charmoso instalado em sobrado histórico tombado no Centro Histórico de Salvador. Decoração colonial baiana, café da manhã com acarajé, tapioca e frutas tropicais. A 5 minutos das principais igrejas barrocas.',
  },
  {
    nome_hotel:  'Serra Gaúcha Boutique Hotel',
    cnpj:        '44555666000154',
    telefone:    '(54) 3295-6789',
    email:       'serragaucha@reservaqui.com',
    senha:       'Hotel@2026',
    cep:         '95700000',
    uf:          'RS',
    cidade:      'Bento Gonçalves',
    bairro:      'Otávio Rocha',
    rua:         'Rua Carlos Cattani',
    numero:      '240',
    descricao:   'Boutique hotel no Vale dos Vinhedos, região vinícola mais famosa do Brasil. Suítes com lareira e banheira de hidromassagem, degustação de vinhos locais, café colonial com queijos e embutidos artesanais.',
  },
  {
    nome_hotel:  'Amazon Jungle Lodge',
    cnpj:        '55666777000145',
    telefone:    '(92) 3234-5678',
    email:       'amazonjunglelodge@reservaqui.com',
    senha:       'Hotel@2026',
    cep:         '69010010',
    uf:          'AM',
    cidade:      'Manaus',
    bairro:      'Centro',
    rua:         'Rua Marquês de Santa Cruz',
    numero:      '85',
    descricao:   'Eco-resort às margens do Rio Negro em Manaus. Chalés sustentáveis em harmonia com a floresta amazônica. Passeios de canoa, observação de botos, trilhas guiadas e gastronomia regional com pirarucu e açaí.',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// 4. CATÁLOGO DE COMODIDADES (mesmo conjunto para todos os hotéis)
// ─────────────────────────────────────────────────────────────────────────────
const CATALOGO_ITENS: { nome: string; categoria: CategoriaItem }[] = [
  { nome: 'Wi-Fi',              categoria: 'COMODIDADE' },
  { nome: 'Ar-condicionado',    categoria: 'COMODIDADE' },
  { nome: 'TV a cabo',          categoria: 'COMODIDADE' },
  { nome: 'Frigobar',           categoria: 'COMODIDADE' },
  { nome: 'Cofre digital',      categoria: 'COMODIDADE' },
  { nome: 'Secador de cabelo',  categoria: 'COMODIDADE' },
  { nome: 'Cama king-size',     categoria: 'COMODO'     },
  { nome: 'Cama queen-size',    categoria: 'COMODO'     },
  { nome: 'Cama de solteiro',   categoria: 'COMODO'     },
  { nome: 'Banheiro privativo', categoria: 'COMODO'     },
  { nome: 'Varanda',            categoria: 'COMODO'     },
  { nome: 'Banheira',           categoria: 'COMODO'     },
  { nome: 'Piscina',            categoria: 'LAZER'      },
  { nome: 'Academia',           categoria: 'LAZER'      },
  { nome: 'Spa',                categoria: 'LAZER'      },
  { nome: 'Restaurante',        categoria: 'LAZER'      },
  { nome: 'Bar',                categoria: 'LAZER'      },
  { nome: 'Salão de eventos',   categoria: 'LAZER'      },
];

// ─────────────────────────────────────────────────────────────────────────────
// 5. CATEGORIAS E QUARTOS POR HOTEL
// valor_diaria → mapeado para CreateCategoriaQuartoInput.valor_diaria (salvo em preco_base)
//                e CreateQuartoInput.valor_diaria (salvo em valor_override)
// ─────────────────────────────────────────────────────────────────────────────
interface QuartoConfig {
  numero:    string;
  valor:     number;
  descricao: string;
}

interface CategoriaConfig {
  nome:               string;
  preco_base:         number;
  capacidade_pessoas: number;
  itens:              string[];
  quartos:            QuartoConfig[];
}

const CATEGORIAS_POR_HOTEL: CategoriaConfig[][] = [
  // ── [0] Grand Paulista Hotel (SP) ─────────────────────────────────────────
  [
    {
      nome: 'Suíte Presidencial', preco_base: 1200, capacidade_pessoas: 4,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cofre digital','Secador de cabelo','Cama king-size','Banheiro privativo','Varanda','Banheira'],
      quartos: [
        { numero: 'P01', valor: 1200, descricao: 'Suíte presidencial com sala de estar, banheira de hidromassagem e vista panorâmica para a Avenida Paulista.' },
        { numero: 'P02', valor: 1350, descricao: 'Suíte presidencial duplex com terraço privativo e serviço de mordomo 24h.' },
      ],
    },
    {
      nome: 'Suíte Executiva', preco_base: 680, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cofre digital','Secador de cabelo','Cama king-size','Banheiro privativo','Varanda'],
      quartos: [
        { numero: 'E01', valor: 680, descricao: 'Suíte executiva com escrivaninha ampla, cadeira ergonômica e amenities premium.' },
        { numero: 'E02', valor: 720, descricao: 'Suíte executiva com sala de reuniões integrada para até 4 pessoas.' },
        { numero: 'E03', valor: 700, descricao: 'Suíte executiva com vista para o Parque Trianon e cama king-size.' },
      ],
    },
    {
      nome: 'Quarto Casal Superior', preco_base: 420, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cama queen-size','Banheiro privativo'],
      quartos: [
        { numero: 'C01', valor: 420, descricao: 'Quarto casal com cama queen-size, decoração contemporânea e banheiro com box de vidro.' },
        { numero: 'C02', valor: 450, descricao: 'Quarto casal superior com varanda e vista para o jardim interno.' },
        { numero: 'C03', valor: 440, descricao: 'Quarto casal no 8º andar com vista parcial para a cidade.' },
      ],
    },
    {
      nome: 'Quarto Individual Business', preco_base: 280, capacidade_pessoas: 1,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Cofre digital','Cama de solteiro','Banheiro privativo'],
      quartos: [
        { numero: 'I01', valor: 280, descricao: 'Quarto individual compacto e funcional, ideal para executivos em trânsito.' },
        { numero: 'I02', valor: 300, descricao: 'Quarto individual com escrivaninha e poltrona de leitura.' },
      ],
    },
    {
      nome: 'Quarto Família', preco_base: 580, capacidade_pessoas: 4,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cama queen-size','Cama de solteiro','Banheiro privativo'],
      quartos: [
        { numero: 'F01', valor: 580, descricao: 'Quarto família com cama queen-size + 2 camas de solteiro, ideal para família com crianças.' },
        { numero: 'F02', valor: 620, descricao: 'Quarto família amplo com duas camas queen-size e dois banheiros.' },
      ],
    },
  ],

  // ── [1] Copacabana Vista Mar (RJ) ─────────────────────────────────────────
  [
    {
      nome: 'Suíte Vista Mar Premium', preco_base: 1500, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cofre digital','Secador de cabelo','Cama king-size','Banheiro privativo','Varanda','Banheira'],
      quartos: [
        { numero: 'VM1', valor: 1500, descricao: 'Suíte frente ao mar com varanda privatizada, banheira com vista para o oceano e cama king-size.' },
        { numero: 'VM2', valor: 1600, descricao: 'Suíte de canto com duas janelas panorâmicas para o mar e banheira dupla.' },
      ],
    },
    {
      nome: 'Quarto Vista Mar', preco_base: 890, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cofre digital','Cama queen-size','Banheiro privativo','Varanda'],
      quartos: [
        { numero: 'QM1', valor: 890, descricao: 'Quarto com vista direta para a Praia de Copacabana, cama queen-size e varanda.' },
        { numero: 'QM2', valor: 920, descricao: 'Quarto frente ao mar no 12º andar com vista privilegiada para o nascer do sol.' },
        { numero: 'QM3', valor: 870, descricao: 'Quarto vista mar com decoração praiana e varanda com espreguiçadeiras.' },
      ],
    },
    {
      nome: 'Quarto Vista Cidade', preco_base: 650, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cama queen-size','Banheiro privativo'],
      quartos: [
        { numero: 'QC1', valor: 650, descricao: 'Quarto com vista para o bairro de Copacabana, decoração moderna e cama queen-size.' },
        { numero: 'QC2', valor: 680, descricao: 'Quarto vista cidade com vista parcial para o Morro do Leme.' },
      ],
    },
    {
      nome: 'Quarto Romântico', preco_base: 950, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cofre digital','Secador de cabelo','Cama king-size','Banheiro privativo','Banheira','Varanda'],
      quartos: [
        { numero: 'R01', valor: 950, descricao: 'Quarto temático romântico com champanhe de boas-vindas, banheira e vista mar.' },
        { numero: 'R02', valor: 980, descricao: 'Quarto romântico com jacuzzi privativo e iluminação cênica, ideal para lua de mel.' },
      ],
    },
    {
      nome: 'Quarto Individual Econômico', preco_base: 380, capacidade_pessoas: 1,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Cama de solteiro','Banheiro privativo'],
      quartos: [
        { numero: 'IE1', valor: 380, descricao: 'Quarto individual compacto, ótimo custo-benefício em Copacabana.' },
        { numero: 'IE2', valor: 400, descricao: 'Quarto individual recém-reformado com chuveiro de pressão e frigobar.' },
      ],
    },
  ],

  // ── [2] Pelourinho Palace Hotel (BA) ──────────────────────────────────────
  [
    {
      nome: 'Suíte Colonial Master', preco_base: 750, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cofre digital','Secador de cabelo','Cama king-size','Banheiro privativo','Varanda','Banheira'],
      quartos: [
        { numero: 'CM1', valor: 750, descricao: 'Suíte com decoração barroca restaurada, móveis coloniais originais do século XVIII e vista para o Pelourinho.' },
        { numero: 'CM2', valor: 800, descricao: 'Suíte com arcos de pedra, teto abobadado e banheira de bronze antigo recuperada.' },
      ],
    },
    {
      nome: 'Quarto Superior Histórico', preco_base: 450, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cama queen-size','Banheiro privativo','Varanda'],
      quartos: [
        { numero: 'H01', valor: 450, descricao: 'Quarto no sobrado histórico com vista para a praça do Pelourinho, azulejos portugueses e piso de tabuão.' },
        { numero: 'H02', valor: 480, descricao: 'Quarto com janelas em arco e vista para a Igreja do Rosário dos Pretos.' },
        { numero: 'H03', valor: 460, descricao: 'Quarto com sacada sobre a rua histórica, hammock e arte afro-brasileira original.' },
      ],
    },
    {
      nome: 'Quarto Cultural', preco_base: 320, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Cama queen-size','Banheiro privativo'],
      quartos: [
        { numero: 'CU1', valor: 320, descricao: 'Quarto temático com obras de artistas baianos locais, cada peça à venda no check-out.' },
        { numero: 'CU2', valor: 340, descricao: 'Quarto decorado com tapetes de fibras naturais e artesanato do Mercado Modelo.' },
        { numero: 'CU3', valor: 330, descricao: 'Quarto com cores vibrantes do axé, instrumentos decorativos e vista interna.' },
      ],
    },
    {
      nome: 'Chalé do Terraço', preco_base: 560, capacidade_pessoas: 3,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cama queen-size','Cama de solteiro','Banheiro privativo','Varanda'],
      quartos: [
        { numero: 'CT1', valor: 560, descricao: 'Chalé no terraço superior com vista de 360° para a Baía de Todos os Santos.' },
        { numero: 'CT2', valor: 590, descricao: 'Chalé duplex no terraço com mezanino e área de solário privativo.' },
      ],
    },
    {
      nome: 'Quarto Individual Econômico', preco_base: 220, capacidade_pessoas: 1,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Cama de solteiro','Banheiro privativo'],
      quartos: [
        { numero: 'EC1', valor: 220, descricao: 'Quarto individual no pátio interno, silencioso e fresco, ideal para viajantes solo.' },
        { numero: 'EC2', valor: 240, descricao: 'Quarto individual com escrivaninha e iluminação natural pelo claraboia.' },
      ],
    },
  ],

  // ── [3] Serra Gaúcha Boutique Hotel (RS) ──────────────────────────────────
  [
    {
      nome: 'Suíte Vinhedo Premium', preco_base: 980, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cofre digital','Secador de cabelo','Cama king-size','Banheiro privativo','Varanda','Banheira'],
      quartos: [
        { numero: 'VP1', valor: 980,  descricao: 'Suíte com lareira a lenha, banheira de hidromassagem e varanda com vista direta para os vinhedos.' },
        { numero: 'VP2', valor: 1050, descricao: 'Suíte com adega privativa, deque de madeira e vista panorâmica do Vale dos Vinhedos.' },
      ],
    },
    {
      nome: 'Chalé Rústico', preco_base: 680, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cama queen-size','Banheiro privativo','Varanda'],
      quartos: [
        { numero: 'CR1', valor: 680, descricao: 'Chalé de madeira com teto de telha colonial, lareira e deck com vista para o pinheiro nativo.' },
        { numero: 'CR2', valor: 710, descricao: 'Chalé em pedra e madeira com banheiro de pedras naturais.' },
        { numero: 'CR3', valor: 695, descricao: 'Chalé com mezanino, sala de estar e área de churrasqueira privativa.' },
      ],
    },
    {
      nome: 'Quarto Cantina', preco_base: 450, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cama queen-size','Banheiro privativo'],
      quartos: [
        { numero: 'CA1', valor: 450, descricao: 'Quarto decorado com barris de vinho, paredes de tijolos expostos e adega decorativa.' },
        { numero: 'CA2', valor: 470, descricao: 'Quarto Cantina com vista para o pátio de pipa e degustação diária inclusa.' },
        { numero: 'CA3', valor: 460, descricao: 'Quarto com coleção de rótulos históricos e janela para o jardim italiano.' },
      ],
    },
    {
      nome: 'Quarto Família Gaudério', preco_base: 620, capacidade_pessoas: 5,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cama queen-size','Cama de solteiro','Banheiro privativo','Varanda'],
      quartos: [
        { numero: 'GF1', valor: 620, descricao: 'Suíte família com decoração gauchesca, cama casal + beliches e brinquedoteca integrada.' },
        { numero: 'GF2', valor: 660, descricao: 'Suíte família de 65m² com cozinha compacta e jardim privativo para churrasco.' },
      ],
    },
    {
      nome: 'Quarto Individual Colono', preco_base: 280, capacidade_pessoas: 1,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Cama de solteiro','Banheiro privativo'],
      quartos: [
        { numero: 'IC1', valor: 280, descricao: 'Quarto individual inspirado na imigração italiana, com bordados e enxoval artesanal local.' },
        { numero: 'IC2', valor: 300, descricao: 'Quarto individual com varanda e vista para o jardim de ervas aromáticas do hotel.' },
      ],
    },
  ],

  // ── [4] Amazon Jungle Lodge (AM) ──────────────────────────────────────────
  [
    {
      nome: 'Suíte Rio Negro', preco_base: 1100, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cofre digital','Secador de cabelo','Cama king-size','Banheiro privativo','Varanda','Banheira'],
      quartos: [
        { numero: 'RN1', valor: 1100, descricao: 'Suíte suspensa sobre o rio com deck privativo, vista para o encontro das águas e banheira de imersão.' },
        { numero: 'RN2', valor: 1200, descricao: 'Suíte master com janelas do chão ao teto, binoculares para fauna e abertura de cama inclusa.' },
      ],
    },
    {
      nome: 'Chalé Florestal', preco_base: 680, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cama queen-size','Banheiro privativo','Varanda'],
      quartos: [
        { numero: 'CF1', valor: 680, descricao: 'Chalé elevado na copa das árvores com passarela suspensa, mosquiteiro de dossel e hamaca.' },
        { numero: 'CF2', valor: 720, descricao: 'Chalé florestal com teto de palha nativa e chuveiro ao ar livre.' },
        { numero: 'CF3', valor: 700, descricao: 'Chalé no solo com jardim botânico privativo e acesso direto ao igapó.' },
      ],
    },
    {
      nome: 'Quarto Jiboia', preco_base: 480, capacidade_pessoas: 2,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cama queen-size','Banheiro privativo'],
      quartos: [
        { numero: 'JI1', valor: 480, descricao: 'Quarto com estampa jiboia, madeiras certificadas do Amazonas e artesanato indígena.' },
        { numero: 'JI2', valor: 500, descricao: 'Quarto Jiboia com rede de dormir extra e kit de banho à base de andiroba.' },
        { numero: 'JI3', valor: 490, descricao: 'Quarto com decoração etnobotânica e janela para o igarapé.' },
      ],
    },
    {
      nome: 'Bungalô Família Amazônica', preco_base: 860, capacidade_pessoas: 5,
      itens: ['Wi-Fi','Ar-condicionado','TV a cabo','Frigobar','Cama queen-size','Cama de solteiro','Banheiro privativo','Varanda'],
      quartos: [
        { numero: 'BA1', valor: 860, descricao: 'Bungalô para famílias com dois dormitórios, cozinha amazônica e observação de fauna noturna.' },
        { numero: 'BA2', valor: 920, descricao: 'Bungalô premium sobre palafita, com canoa privativa e guia de ecoturismo incluso.' },
      ],
    },
    {
      nome: 'Quarto Explorador', preco_base: 320, capacidade_pessoas: 1,
      itens: ['Wi-Fi','Ar-condicionado','Cama de solteiro','Banheiro privativo'],
      quartos: [
        { numero: 'EX1', valor: 320, descricao: 'Quarto individual equipado com mochila de trilha, mapa da floresta e lanterna frontal.' },
        { numero: 'EX2', valor: 350, descricao: 'Quarto explorador com kit repelente premium e botas de borracha inclusas.' },
      ],
    },
  ],
];

// ─────────────────────────────────────────────────────────────────────────────
// 6. AVALIAÇÕES POR HOTEL
// ─────────────────────────────────────────────────────────────────────────────
interface AvaliacaoData {
  usuarioIdx:       number;
  nota_limpeza:     number;
  nota_atendimento: number;
  nota_conforto:    number;
  nota_organizacao: number;
  nota_localizacao: number;
  comentario:       string;
}

const AVALIACOES_POR_HOTEL: AvaliacaoData[][] = [
  // [0] Grand Paulista Hotel (SP)
  [
    { usuarioIdx: 0, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Simplesmente impecável! Fui com minha esposa para o aniversário e o hotel superou todas as expectativas. O staff nos surpreendeu com pétalas de rosa e champanhe. A vista da Paulista à noite é de tirar o fôlego. Voltaremos com certeza!' },
    { usuarioIdx: 1, nota_limpeza: 5, nota_atendimento: 4, nota_conforto: 5, nota_organizacao: 4, nota_localizacao: 5,
      comentario: 'Excelente hotel para negócios. Check-in rápido, quarto espaçoso e bem equipado. Wi-Fi estável mesmo no horário de pico — essencial para videoconferências. Localização perfeita a pé dos principais centros empresariais.' },
    { usuarioIdx: 2, nota_limpeza: 4, nota_atendimento: 5, nota_conforto: 4, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Hotel muito bem localizado na Paulista. Atendimento exemplar — o concierge nos indicou restaurantes incríveis. O quarto era confortável, mas o ar-condicionado fazia barulho à noite.' },
    { usuarioIdx: 3, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 4,
      comentario: 'Minha terceira estadia aqui e sempre saio satisfeita. Café da manhã farto com opções veganas. A piscina aquecida é um diferencial para os dias frios de SP. Só poderia ter mais vagas de estacionamento.' },
    { usuarioIdx: 4, nota_limpeza: 4, nota_atendimento: 4, nota_conforto: 4, nota_organizacao: 4, nota_localizacao: 5,
      comentario: 'Boa relação custo-benefício para o padrão da Paulista. O quarto era limpo e funcional. Esperei 40 minutos por toalhas extras, poderia melhorar. No mais, recomendo.' },
    { usuarioIdx: 5, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 4, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Fiz reserva de última hora e o hotel me acomodou perfeitamente. Equipe extremamente atenciosa. O spa é maravilhoso — fiz uma massagem e saí renovada. Recomendo para quem quer hotel completo no coração de SP.' },
  ],

  // [1] Copacabana Vista Mar (RJ)
  [
    { usuarioIdx: 1, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Que experiência incrível! Acordar todo dia com aquela vista para o mar não tem preço. Quarto limpo impecavelmente. Tomamos caipirinha na varanda vendo o pôr do sol — perfeito para lua de mel!' },
    { usuarioIdx: 0, nota_limpeza: 4, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 4, nota_localizacao: 5,
      comentario: 'Hotel de nível internacional em Copacabana. A 2 minutos a pé da praia. Café da manhã com vista para o mar é um luxo. Preços do frigobar um pouco salgados, mas entende-se pela localização.' },
    { usuarioIdx: 3, nota_limpeza: 5, nota_atendimento: 4, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Viagem inesquecível ao Rio! Hotel na posição perfeita da orla. Café da manhã com pão de queijo quentinho. A cama é extremamente confortável. Estacionamento complicado, mas há convênio com valet.' },
    { usuarioIdx: 2, nota_limpeza: 3, nota_atendimento: 4, nota_conforto: 4, nota_organizacao: 3, nota_localizacao: 5,
      comentario: 'A localização salva o hotel. O quarto estava desatualizado na decoração e havia umidade no banheiro. A recepção resolveu rapidamente quando reclamei. Para o preço, esperava mais capricho.' },
    { usuarioIdx: 5, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Perfeito em todos os sentidos! Piscina, restaurante com frutos do mar frescos, Wi-Fi excelente. Serviço de quarto funcionou à meia-noite. Me senti em casa em Copacabana.' },
    { usuarioIdx: 4, nota_limpeza: 5, nota_atendimento: 4, nota_conforto: 4, nota_organizacao: 4, nota_localizacao: 4,
      comentario: 'Boa experiência. Quarto com vista mar vale cada centavo. Staff falou inglês fluente, ótimo para turistas internacionais. Voltaria na suíte premium sem pensar duas vezes.' },
  ],

  // [2] Pelourinho Palace Hotel (BA)
  [
    { usuarioIdx: 2, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Que jóia escondida! Dormir em sobrado colonial do século XVIII foi surreal. Os azulejos portugueses, as madeiras envelhecidas — cada detalhe conta uma história. O café baiano com acarajé foi o melhor da minha vida.' },
    { usuarioIdx: 3, nota_limpeza: 4, nota_atendimento: 5, nota_conforto: 4, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Hotel com alma! Localização no Pelourinho imbatível. O guia cultural indicado foi fantástico. O quarto é charmoso mas pequeno — encarei como parte da experiência histórica.' },
    { usuarioIdx: 0, nota_limpeza: 5, nota_atendimento: 4, nota_conforto: 5, nota_organizacao: 4, nota_localizacao: 5,
      comentario: 'Incrível! Fui para o Carnaval e é a escolha perfeita. A vista do terraço para os trios elétricos passando é inesquecível. Quarto colonial charmoso e equipe muito receptiva.' },
    { usuarioIdx: 5, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Experiência cultural completa. Aula de capoeira, visita às igrejas e samba na varanda. O Chalé do Terraço com vista para a Baía de Todos os Santos ao entardecer é espetacular. Voltarei!' },
    { usuarioIdx: 1, nota_limpeza: 4, nota_atendimento: 5, nota_conforto: 3, nota_organizacao: 4, nota_localizacao: 5,
      comentario: 'O charme histórico é inegável, mas quem busca comodidades modernas pode se frustrar. Wi-Fi fraco nas alas antigas. O staff compensa com muito carinho e orgulho da cultura local.' },
    { usuarioIdx: 4, nota_limpeza: 5, nota_atendimento: 4, nota_conforto: 4, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Única na proposta. Não é um hotel comum — é uma imersão cultural na Bahia. A vista da sacada para as fachadas coloniais ao amanhecer é uma pintura viva.' },
  ],

  // [3] Serra Gaúcha Boutique Hotel (RS)
  [
    { usuarioIdx: 3, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'O hotel mais romântico que já frequentei. A lareira no quarto no inverno é algo que não esqueço. O café colonial com queijos artesanais foi monumental. A degustação de vinhos foi a cereja do bolo. Lua de mel perfeita!' },
    { usuarioIdx: 0, nota_limpeza: 5, nota_atendimento: 4, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 4,
      comentario: 'Fui em outubro na época da vindima e foi mágico. Pisei uvas no lagar e levei uma garrafa personalizada. O chalé rústico era aconchegante. Fica um pouco longe do centro de Bento, mas vale cada km.' },
    { usuarioIdx: 5, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Perfeito para quem ama vinho e natureza. O tour dos vinhedos ao amanhecer com neblina — parecia um quadro impressionista. O jantar é refinado e maridado perfeitamente com os rótulos locais.' },
    { usuarioIdx: 1, nota_limpeza: 4, nota_atendimento: 5, nota_conforto: 4, nota_organizacao: 4, nota_localizacao: 4,
      comentario: 'Muito bom! Fui com família e as crianças adoraram o espaço dos chalés. O churrasco no espaço gourmet foi um sucesso. A experiência gaúcha foi autêntica e memorável.' },
    { usuarioIdx: 2, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'A suíte Vinhedo é de outro nível. Acordar e ver os vinhedos cobertos de neblina da banheira de hidromassagem é transcendental. Staff silencioso e discreto — perfeito para paz e privacidade total.' },
    { usuarioIdx: 4, nota_limpeza: 4, nota_atendimento: 4, nota_conforto: 4, nota_organizacao: 4, nota_localizacao: 4,
      comentario: 'Boa opção na Serra Gaúcha. O quarto Cantina tem muito charme com os barris decorativos. A degustação inclusa é generosa — 5 rótulos com o sommelier. Faltou manutenção no banheiro, mas o conjunto vale a pena.' },
  ],

  // [4] Amazon Jungle Lodge (AM)
  [
    { usuarioIdx: 4, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'A experiência mais surreal da minha vida. Adormecer ouvindo a floresta do chalé elevado nas árvores foi transformador. A excursão para ver botos e a pesca de piranha foram aventuras inesquecíveis. Guias altamente qualificados.' },
    { usuarioIdx: 5, nota_limpeza: 4, nota_atendimento: 5, nota_conforto: 4, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Para quem ama natureza e sustentabilidade, esse é o lugar. Certificação ambiental séria. Gastronomia amazônica é revelação — pirarucu ao tucupi, tacacá, brigadeiro de cupuaçu. Guias nativos enriquecem a experiência.' },
    { usuarioIdx: 0, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 4, nota_localizacao: 5,
      comentario: 'Incrível do início ao fim. A suíte Rio Negro com vista para o encontro das águas é espetacular. Ver o fenômeno do deque privativo é algo que não tem preço. Levo esse lugar para sempre na memória.' },
    { usuarioIdx: 1, nota_limpeza: 3, nota_atendimento: 4, nota_conforto: 3, nota_organizacao: 3, nota_localizacao: 5,
      comentario: 'A experiência da floresta é única, mas prepare-se: insetos mesmo com mosquiteiro, calor úmido e internet instável. Se você aceita essas condições, vai adorar. Se quer luxo convencional, não é o lugar.' },
    { usuarioIdx: 2, nota_limpeza: 5, nota_atendimento: 5, nota_conforto: 5, nota_organizacao: 5, nota_localizacao: 5,
      comentario: 'Fui com a família e foi a melhor viagem das nossas vidas. As crianças viram macacos e araras de perto sem grades! O bungalô família é espaçoso. A canoa privativa foi a atração principal dos meus filhos.' },
    { usuarioIdx: 3, nota_limpeza: 5, nota_atendimento: 4, nota_conforto: 4, nota_organizacao: 4, nota_localizacao: 5,
      comentario: 'Fotógrafo de natureza — esse lugar é um paraíso. Consegui imagens de onças-pintadas e macacos uivadores que nenhum zoológico proporciona. A equipe me levou a locais especiais de observação antes do amanhecer.' },
  ],
];

// ─────────────────────────────────────────────────────────────────────────────
// UTILITÁRIOS
// ─────────────────────────────────────────────────────────────────────────────

/** Retorna data em yyyy-mm-dd somando n dias à base */
function addDays(base: Date, days: number): string {
  const d = new Date(base);
  d.setDate(d.getDate() + days);
  return d.toISOString().split('T')[0];
}

/** storage_path mockado para foto de quarto (relativo a UPLOAD_DIR) */
function mockRoomPhotoPath(hotelId: string, quartoId: number, n: number): string {
  return `hotels/${hotelId}/rooms/${quartoId}/seed-${n}.jpg`;
}

/** storage_path mockado para capa do hotel (relativo a UPLOAD_DIR) */
function mockHotelCoverPath(hotelId: string, orientacao: 'portrait' | 'landscape', n: number): string {
  return `hotels/${hotelId}/cover/${orientacao}/seed-${n}.jpg`;
}

// ─────────────────────────────────────────────────────────────────────────────
// SEED PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
export async function seedCompleto(): Promise<void> {
  console.log('=== Iniciando Seed Completo ===\n');

  // ── 1. ADMIN ──────────────────────────────────────────────────────────────
  console.log('--- [1/4] Admin ---');
  {
    // Admin usa INSERT direto (mesma abordagem do seed.admin.ts)
    // data_nascimento em yyyy-mm-dd pois vai direto ao banco sem parseDataBrToEn
    const senhaHash = await argon2.hash(ADMIN.senha, ARGON2_OPTIONS);
    await masterPool.query(
      `INSERT INTO usuario (nome_completo, email, senha, cpf, data_nascimento, numero_celular, papel, ativo)
       VALUES ($1, $2, $3, $4, $5, $6, 'admin', TRUE)
       ON CONFLICT (email) DO UPDATE SET papel = 'admin', nome_completo = EXCLUDED.nome_completo`,
      [ADMIN.nome_completo, ADMIN.email, senhaHash, ADMIN.cpf, ADMIN.data_nascimento, ADMIN.numero_celular],
    );
    console.log(`  ✅ Admin: ${ADMIN.email} / ${ADMIN.senha}`);
  }

  // ── 2. USUÁRIOS HÓSPEDES ──────────────────────────────────────────────────
  // Usa registerUsuario() que internamente chama:
  //   Usuario.validate()       → valida email, senha, cpf, data (dd/mm/aaaa), celular
  //   argon2.hash()            → hash da senha
  //   parseDataBrToEn()        → converte dd/mm/aaaa para yyyy-mm-dd antes do INSERT
  //   input.cpf.replace(...)   → remove pontuação do cpf antes do INSERT
  console.log('\n--- [2/4] Usuários Hóspedes ---');
  const userIds: string[] = [];

  for (const u of USUARIOS) {
    try {
      const { rows: existing } = await masterPool.query<{ user_id: string }>(
        `SELECT user_id FROM usuario WHERE email = $1`,
        [u.email.toLowerCase()],
      );

      if (existing[0]) {
        userIds.push(existing[0].user_id);
        console.log(`  ⚠️  ${u.email} já existe (reutilizado)`);
      } else {
        const created = await registerUsuario({
          nome_completo:   u.nome_completo,
          email:           u.email,
          senha:           u.senha,
          cpf:             u.cpf,               // com pontuação — service faz replace(/\D/g,'')
          data_nascimento: u.data_nascimento,    // dd/mm/aaaa — validator e parseDataBrToEn
          numero_celular:  u.numero_celular,
        });
        userIds.push(created.user_id);
        console.log(`  ✅ ${u.nome_completo} | ${u.email} / ${u.senha}`);
      }
    } catch (err: any) {
      console.error(`  ❌ Erro ao criar usuário ${u.email}: ${err.message}`);
    }
  }

  // ── 3. HOTÉIS + QUARTOS + FOTOS MOCKADAS ─────────────────────────────────
  console.log('\n--- [3/4] Hotéis, Quartos e Fotos ---');

  const hotelResults: { hotel_id: string; schema_name: string; nome_hotel: string }[] = [];

  for (let hi = 0; hi < HOTEIS.length; hi++) {
    const hotelData = HOTEIS[hi];
    console.log(`\n⏳ [${hi + 1}/${HOTEIS.length}] ${hotelData.nome_hotel} (${hotelData.uf})...`);

    let hotel: { hotel_id: string; schema_name: string; nome_hotel: string };

    try {
      // registerAnfitriao faz: Anfitriao.validate() + argon2.hash() + INSERT + provisionTenant
      const created = await registerAnfitriao(hotelData);
      hotel = { hotel_id: created.hotel_id, schema_name: created.schema_name, nome_hotel: created.nome_hotel };
      console.log(`  ✅ Hotel criado | hotel_id: ${hotel.hotel_id} | schema: ${hotel.schema_name}`);
    } catch (err: any) {
      if (
        err.message?.includes('duplicate key') ||
        err.message?.includes('unique constraint') ||
        err.message?.includes('ja existe') ||
        err.message?.includes('already exists')
      ) {
        const { rows } = await masterPool.query<{ hotel_id: string; schema_name: string; nome_hotel: string }>(
          `SELECT hotel_id, schema_name, nome_hotel FROM anfitriao WHERE email = $1`,
          [hotelData.email.toLowerCase()],
        );
        if (!rows[0]) { console.error(`  ❌ ${hotelData.nome_hotel} não encontrado após conflict`); continue; }
        hotel = rows[0];
        console.log(`  ⚠️  ${hotelData.nome_hotel} já existe (schema: ${hotel.schema_name})`);
      } else {
        console.error(`  ❌ Erro em ${hotelData.nome_hotel}: ${err.message}`);
        continue;
      }
    }

    hotelResults.push(hotel);

    try {
      // 3b. Configuração operacional
      await createConfiguracaoHotel(hotel.hotel_id, {
        horario_checkin:       '14:00',
        horario_checkout:      '12:00',
        max_dias_reserva:      30,
        politica_cancelamento: 'Cancelamento gratuito até 48h antes do check-in. Após esse prazo, será cobrada 1 diária como taxa.',
        aceita_animais:        hi === 4,
        idiomas_atendimento:   hi === 1 ? 'Português, Inglês, Espanhol' : 'Português, Inglês',
      });

      // 3c. Fotos de capa mockadas
      // foto_hotel não tem UNIQUE em storage_path → DELETE das seeds + INSERT fresco
      await masterPool.query(
        `DELETE FROM foto_hotel WHERE hotel_id = $1 AND storage_path LIKE 'hotels/%/cover/%/seed-%.jpg'`,
        [hotel.hotel_id],
      );
      for (const orientacao of ['portrait', 'landscape'] as const) {
        for (let n = 1; n <= 3; n++) {
          await masterPool.query(
            `INSERT INTO foto_hotel (hotel_id, storage_path, orientacao, ordem) VALUES ($1, $2, $3, $4)`,
            [hotel.hotel_id, mockHotelCoverPath(hotel.hotel_id, orientacao, n), orientacao, n - 1],
          );
        }
      }
      console.log('  ✅ 6 fotos de capa mockadas (3 portrait + 3 landscape)');

      // 3d. Catálogo de comodidades
      const catalogoIds: Record<string, number> = {};
      for (const item of CATALOGO_ITENS) {
        try {
          const criado = await createCatalogo(hotel.hotel_id, { nome: item.nome, categoria: item.categoria });
          catalogoIds[item.nome] = criado.id;
        } catch {
          // Já existe — busca id
          const { rows } = await withTenant(hotel.schema_name, (client) =>
            client.query<{ id: number }>(
              `SELECT id FROM catalogo WHERE nome = $1 AND categoria = $2 AND deleted_at IS NULL`,
              [item.nome, item.categoria],
            ),
          );
          if (rows[0]) catalogoIds[item.nome] = rows[0].id;
        }
      }
      console.log(`  ✅ Catálogo: ${Object.keys(catalogoIds).length} itens`);

      // 3e. Categorias + Quartos + Fotos de quarto mockadas
      const categorias = CATEGORIAS_POR_HOTEL[hi];

      for (const cat of categorias) {
        let categoriaId: number;

        try {
          // CreateCategoriaQuartoInput: { nome, valor_diaria, capacidade_pessoas }
          const categoria = await createCategoriaQuarto(hotel.hotel_id, {
            nome:               cat.nome,
            capacidade_pessoas: cat.capacidade_pessoas,
            valor_diaria:       cat.preco_base,
          });
          categoriaId = categoria.id;

          for (const nomeItem of cat.itens) {
            const itemId = catalogoIds[nomeItem];
            if (!itemId) continue;
            try {
              // AddCategoriaItemInput: { catalogo_id, quantidade }
              await addItemToCategoria(hotel.hotel_id, categoriaId, { catalogo_id: itemId, quantidade: 1 });
            } catch { /* item já vinculado */ }
          }
        } catch {
          const { rows } = await withTenant(hotel.schema_name, (client) =>
            client.query<{ id: number }>(
              `SELECT id FROM categoria_quarto WHERE nome = $1 AND deleted_at IS NULL`,
              [cat.nome],
            ),
          );
          if (!rows[0]) { console.log(`  ⚠️  Categoria "${cat.nome}" não encontrada`); continue; }
          categoriaId = rows[0].id;
        }

        for (const q of cat.quartos) {
          let quartoId: number;

          try {
            // CreateQuartoInput: { categoria_quarto_id, numero, descricao, valor_diaria }
            // valor_diaria → salvo em valor_override no banco (sobrescreve preco_base da categoria)
            const quarto = await createQuarto(hotel.hotel_id, {
              categoria_quarto_id: categoriaId,
              numero:              q.numero,
              descricao:           q.descricao,
              valor_diaria:        q.valor,
            });
            quartoId = quarto.id;
          } catch {
            const { rows } = await withTenant(hotel.schema_name, (client) =>
              client.query<{ id: number }>(
                `SELECT id FROM quarto WHERE numero = $1 AND deleted_at IS NULL`,
                [q.numero],
              ),
            );
            if (!rows[0]) { console.log(`  ⚠️  Quarto ${q.numero} não encontrado`); continue; }
            quartoId = rows[0].id;
          }

          // Fotos de quarto mockadas
          // quarto_foto não tem UNIQUE em storage_path → DELETE das seeds + INSERT fresco
          await withTenant(hotel.schema_name, async (client) => {
            await client.query(
              `DELETE FROM quarto_foto WHERE quarto_id = $1 AND storage_path LIKE 'hotels/%/rooms/%/seed-%.jpg'`,
              [quartoId],
            );
            for (let n = 1; n <= 3; n++) {
              await client.query(
                `INSERT INTO quarto_foto (quarto_id, storage_path, ordem) VALUES ($1, $2, $3)`,
                [quartoId, mockRoomPhotoPath(hotel.hotel_id, quartoId, n), n - 1],
              );
            }
          });
        }

        console.log(`  ✅ Categoria "${cat.nome}" | ${cat.quartos.length} quartos | 3 fotos/quarto`);
      }

      // 3f. RAG/PGVector
      await DynamicIngestionService.ingestHotelData(hotel.hotel_id, hotel.schema_name);
      console.log('  ✅ RAG/PGVector indexado');

    } catch (err: any) {
      console.error(`  ❌ Erro na configuração de ${hotel.nome_hotel}: ${err.message}`);
    }
  }

  // ── 4. AVALIAÇÕES ─────────────────────────────────────────────────────────
  console.log('\n--- [4/4] Avaliações ---');

  const today = new Date();

  for (let hi = 0; hi < hotelResults.length; hi++) {
    const hotel      = hotelResults[hi];
    const avaliacoes = AVALIACOES_POR_HOTEL[hi] ?? [];
    if (!avaliacoes.length) continue;

    console.log(`\n⏳ Avaliações: ${hotel.nome_hotel}...`);

    try {
      await withTenant(hotel.schema_name, async (client) => {
        const { rows: quartos } = await client.query<{ id: number; numero: string }>(
          `SELECT id, numero FROM quarto WHERE deleted_at IS NULL ORDER BY id`,
        );
        if (!quartos.length) { console.log('  ⚠️  Sem quartos'); return; }

        const { rows: catNomes } = await client.query<{ quarto_id: number; nome: string }>(
          `SELECT q.id AS quarto_id, cq.nome
           FROM quarto q
           JOIN categoria_quarto cq ON cq.id = q.categoria_quarto_id
           WHERE q.deleted_at IS NULL`,
        );
        const catPorQuarto: Record<number, string> = {};
        for (const r of catNomes) catPorQuarto[r.quarto_id] = r.nome;

        let avalCount = 0;

        for (let ai = 0; ai < avaliacoes.length; ai++) {
          const av     = avaliacoes[ai];
          const userId = userIds[av.usuarioIdx];
          if (!userId) continue;

          const quarto   = quartos[ai % quartos.length];
          const daysAgo  = 30 + ai * 12;
          const checkin  = addDays(today, -daysAgo - 3);
          const checkout = addDays(today, -daysAgo);
          const valor    = 350 + ai * 60;

          // Registra usuário como hóspede do tenant (FK exigida pela tabela reserva)
          await client.query(
            `INSERT INTO hospede (user_id) VALUES ($1) ON CONFLICT DO NOTHING`,
            [userId],
          );

          // Cria reserva CONCLUÍDA vinculada ao usuário real
          const { rows: reservaRows } = await client.query<{ id: number }>(
            `INSERT INTO reserva
               (quarto_id, user_id, num_hospedes, data_checkin, data_checkout,
                status, canal_origem, valor_total, codigo_publico, observacoes)
             VALUES ($1, $2, 2, $3, $4, 'CONCLUIDA', 'APP', $5, gen_random_uuid(), '[seed-completo]')
             RETURNING id`,
            [quarto.id, userId, checkin, checkout, valor],
          );
          if (!reservaRows.length) continue;
          const reservaId = reservaRows[0].id;

          // nota_total = média arredondada das 5 dimensões
          const notaTotal = Math.round(
            (av.nota_limpeza + av.nota_atendimento + av.nota_conforto +
             av.nota_organizacao + av.nota_localizacao) / 5,
          );

          // avaliacao: UNIQUE(user_id, reserva_id) → ON CONFLICT DO NOTHING é seguro aqui
          await client.query(
            `INSERT INTO avaliacao
               (user_id, reserva_id, nota_limpeza, nota_atendimento, nota_conforto,
                nota_organizacao, nota_localizacao, nota_total, comentario)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
             ON CONFLICT (user_id, reserva_id) DO NOTHING`,
            [userId, reservaId,
             av.nota_limpeza, av.nota_atendimento, av.nota_conforto,
             av.nota_organizacao, av.nota_localizacao, notaTotal, av.comentario],
          );

          // Espelha no historico_reserva_global (master DB)
          // UNIQUE(hotel_id, reserva_tenant_id) → ON CONFLICT DO NOTHING seguro
          await masterPool.query(
            `INSERT INTO historico_reserva_global
               (user_id, hotel_id, reserva_tenant_id, nome_hotel, tipo_quarto,
                data_checkin, data_checkout, num_hospedes, valor_total, status)
             VALUES ($1, $2, $3, $4, $5, $6, $7, 2, $8, 'CONCLUIDA')
             ON CONFLICT (hotel_id, reserva_tenant_id) DO NOTHING`,
            [userId, hotel.hotel_id, reservaId, hotel.nome_hotel,
             catPorQuarto[quarto.id] ?? 'Quarto', checkin, checkout, valor],
          );

          avalCount++;
        }

        console.log(`  ✅ ${avalCount} avaliações criadas com reservas CONCLUÍDAS`);
      });
    } catch (err: any) {
      console.error(`  ❌ Erro nas avaliações de ${hotel.nome_hotel}: ${err.message}`);
    }
  }

  // ── RESUMO FINAL ──────────────────────────────────────────────────────────
  console.log(`
╔══════════════════════════════════════════════════════════════════════════════╗
║               SEED COMPLETO — CREDENCIAIS E ESTRUTURA                      ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  ADMIN                                                                     ║
║    admin@reservaqui.dev                /  Admin@2026                       ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  HOTÉIS  (senha: Hotel@2026 para todos)                                    ║
║    grandpaulista@reservaqui.com        São Paulo      / SP  5 categorias   ║
║    copacabanavistamar@reservaqui.com   Rio de Janeiro / RJ  5 categorias   ║
║    pelourinhoppalace@reservaqui.com    Salvador       / BA  5 categorias   ║
║    serragaucha@reservaqui.com          Bento Gonçalves/ RS  5 categorias   ║
║    amazonjunglelodge@reservaqui.com    Manaus         / AM  5 categorias   ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  USUÁRIOS HÓSPEDES                                                         ║
║    carlos.mendes@gmail.com            /  Carlos@2026                       ║
║    ana.ferreira@hotmail.com           /  AnaP@2026                         ║
║    roberto.lima@outlook.com           /  Roberto@2026                      ║
║    fernanda.oliveira@gmail.com        /  Fer@2026                          ║
║    marcos.pereira@yahoo.com.br        /  Marcos@2026                       ║
║    juliana.barbosa@gmail.com          /  Juli@2026                         ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  FOTOS MOCKADAS — paths relativos ao UPLOAD_DIR (padrão: Backend/storage/) ║
║                                                                            ║
║  Capa do hotel:                                                            ║
║    hotels/{hotel_id}/cover/portrait/seed-1.jpg   (seed-2.jpg, seed-3.jpg) ║
║    hotels/{hotel_id}/cover/landscape/seed-1.jpg  (seed-2.jpg, seed-3.jpg) ║
║                                                                            ║
║  Fotos de quarto:                                                          ║
║    hotels/{hotel_id}/rooms/{quarto_id}/seed-1.jpg (seed-2.jpg, seed-3.jpg)║
║                                                                            ║
║  Para usar imagens reais: copie arquivos .jpg para os paths acima          ║
║  substituindo seed-N.jpg pela imagem desejada.                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
`);
  console.log('=== Seed Completo Finalizado ===');
}

// Auto-execução quando rodado diretamente
if (require.main === module) {
  seedCompleto()
    .catch((err) => {
      console.error('[seed/completo] Erro fatal:', err);
      process.exit(1);
    })
    .finally(async () => {
      await masterPool.end();
      process.exit(0);
    });
}
