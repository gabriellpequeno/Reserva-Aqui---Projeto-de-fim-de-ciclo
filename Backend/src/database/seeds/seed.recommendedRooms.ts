/**
 * Seed: Quartos Recomendados
 *
 * Cenários de recomendação cobertos:
 * - Bloco A (3 quartos): nota_media 5.0 — garantidos no topo
 * - Bloco B (5 quartos): nota_media 4.0 — 2 slots sorteados aleatoriamente
 * - Bloco C (3 quartos): nota_media 2.0 — não deve aparecer nas recomendações
 * - Sem avaliação (2 quartos): usados apenas no fallback aleatório
 *
 * Estrutura: para cada quarto avaliado, cria-se uma reserva CONCLUIDA
 * e avaliações vinculadas a ela — seguindo o modelo de dados real.
 *
 * Guard: executar apenas em ambiente de desenvolvimento.
 */
import 'dotenv/config';
import { masterPool } from '../masterDb';
import { withTenant } from '../schemaWrapper';

if (process.env.NODE_ENV === 'production') {
  console.log('[seed/recommendedRooms] Seed ignorado em produção');
  process.exit(0);
}

// Itens de catálogo a criar (comodidades e cômodos padrão)
const CATALOGO_ITENS = [
  { nome: 'Wi-Fi',              categoria: 'COMODIDADE' },
  { nome: 'Ar-condicionado',    categoria: 'COMODIDADE' },
  { nome: 'TV a cabo',          categoria: 'COMODIDADE' },
  { nome: 'Frigobar',           categoria: 'COMODIDADE' },
  { nome: 'Cofre digital',      categoria: 'COMODIDADE' },
  { nome: 'Cama king-size',     categoria: 'COMODO'     },
  { nome: 'Cama queen-size',    categoria: 'COMODO'     },
  { nome: 'Banheiro privativo', categoria: 'COMODO'     },
  { nome: 'Varanda',            categoria: 'COMODO'     },
  { nome: 'Piscina',            categoria: 'LAZER'      },
  { nome: 'Spa',                categoria: 'LAZER'      },
  { nome: 'Academia',           categoria: 'LAZER'      },
];

// Categorias de quarto a criar com seus itens e descrição
interface CategoriaConfig {
  nome: string;
  preco_base: number;
  capacidade_pessoas: number;
  itens: string[]; // nomes dos itens do catálogo
}

const CATEGORIAS: CategoriaConfig[] = [
  {
    nome: 'Suíte Presidencial',
    preco_base: 480,
    capacidade_pessoas: 2,
    itens: ['Wi-Fi', 'Ar-condicionado', 'TV a cabo', 'Frigobar', 'Cofre digital', 'Cama king-size', 'Banheiro privativo', 'Varanda'],
  },
  {
    nome: 'Quarto Deluxe',
    preco_base: 350,
    capacidade_pessoas: 2,
    itens: ['Wi-Fi', 'Ar-condicionado', 'TV a cabo', 'Frigobar', 'Cama queen-size', 'Banheiro privativo'],
  },
  {
    nome: 'Quarto Standard',
    preco_base: 200,
    capacidade_pessoas: 1,
    itens: ['Wi-Fi', 'Ar-condicionado', 'TV a cabo', 'Cama queen-size', 'Banheiro privativo'],
  },
];

// Configuração dos blocos de quartos e suas notas
interface BlocoConfig {
  label: string;
  quartos: { numero: string; valor: number; categoriaIdx: number; descricao: string }[];
  nota: number | null;
  avaliacoesPorQuarto: number;
}

const BLOCOS: BlocoConfig[] = [
  {
    label: 'Bloco A — nota 5.0 (garantidos no topo)',
    quartos: [
      {
        numero: 'SEED-A1', valor: 450, categoriaIdx: 0,
        descricao: 'Suíte presidencial com vista panorâmica, banheira de hidromassagem e serviço de mordomo. Ideal para ocasiões especiais.',
      },
      {
        numero: 'SEED-A2', valor: 520, categoriaIdx: 0,
        descricao: 'Suíte presidencial com terraço privativo e sala de estar separada. Ambientação sofisticada com decoração exclusiva.',
      },
      {
        numero: 'SEED-A3', valor: 480, categoriaIdx: 0,
        descricao: 'Suíte presidencial no último andar com vista 360°. Inclui café da manhã personalizado e acesso ao lounge executivo.',
      },
    ],
    nota: 5,
    avaliacoesPorQuarto: 3,
  },
  {
    label: 'Bloco B — nota 4.0 (sorteio entre 5 quartos para 2 slots)',
    quartos: [
      {
        numero: 'SEED-B1', valor: 350, categoriaIdx: 1,
        descricao: 'Quarto deluxe com cama queen-size, frigobar e TV a cabo. Decoração contemporânea e banheiro espaçoso.',
      },
      {
        numero: 'SEED-B2', valor: 380, categoriaIdx: 1,
        descricao: 'Quarto deluxe renovado com cama queen-size e varanda privativa. Vista para o jardim interno do hotel.',
      },
      {
        numero: 'SEED-B3', valor: 420, categoriaIdx: 1,
        descricao: 'Quarto deluxe superior com cama king-size e banheiro com ducha de chuva. Localizado no andar premium.',
      },
      {
        numero: 'SEED-B4', valor: 360, categoriaIdx: 1,
        descricao: 'Quarto deluxe com cama queen-size e escrivaninha de trabalho. Ideal para viagens corporativas com Wi-Fi de alta velocidade.',
      },
      {
        numero: 'SEED-B5', valor: 400, categoriaIdx: 1,
        descricao: 'Quarto deluxe temático com decoração inspirada na cultura local. Cama queen-size e frigobar abastecido.',
      },
    ],
    nota: 4,
    avaliacoesPorQuarto: 2,
  },
  {
    label: 'Bloco C — nota 2.0 (não deve aparecer nas recomendações)',
    quartos: [
      {
        numero: 'SEED-C1', valor: 200, categoriaIdx: 2,
        descricao: 'Quarto standard com cama queen-size e banheiro privativo. Opção econômica para estadias rápidas.',
      },
      {
        numero: 'SEED-C2', valor: 220, categoriaIdx: 2,
        descricao: 'Quarto standard no andar térreo com acesso facilitado. Cama de casal e TV a cabo.',
      },
      {
        numero: 'SEED-C3', valor: 180, categoriaIdx: 2,
        descricao: 'Quarto standard compacto com tudo o necessário para uma noite confortável.',
      },
    ],
    nota: 2,
    avaliacoesPorQuarto: 1,
  },
  {
    label: 'Sem avaliação (fallback aleatório)',
    quartos: [
      {
        numero: 'SEED-N1', valor: 280, categoriaIdx: 1,
        descricao: 'Quarto deluxe recém-inaugurado, sem avaliações ainda. Cama queen-size e vista para piscina.',
      },
      {
        numero: 'SEED-N2', valor: 310, categoriaIdx: 1,
        descricao: 'Quarto deluxe reformado com novos móveis e decoração moderna. Aguardando primeiros hóspedes.',
      },
    ],
    nota: null,
    avaliacoesPorQuarto: 0,
  },
];

// CPF e email fixos do usuário de seed — evita duplicatas em re-execuções
const SEED_USER = {
  nome_completo: 'Usuário Seed',
  email: 'seed@reservaqui.dev',
  senha: '$2b$10$seedpasswordhashxxxxxseedpasswordhashxxxxxx', // bcrypt placeholder
  cpf: '000.000.000-00',
  numero_celular: '(00) 00000-0000',
  data_nascimento: '1990-01-01',
};

async function seedRecommendedRooms(): Promise<void> {
  // Busca hotel ativo para inserir os quartos de seed
  const { rows: hoteis } = await masterPool.query<{ hotel_id: string; schema_name: string }>(
    `SELECT hotel_id, schema_name FROM anfitriao WHERE ativo = TRUE LIMIT 1`
  );

  if (!hoteis.length) {
    console.warn('[seed/recommendedRooms] Nenhum hotel ativo encontrado — rode seed-hotel.ts primeiro');
    process.exit(1);
  }

  const hotel = hoteis[0];
  console.log(`[seed/recommendedRooms] Hotel alvo: ${hotel.hotel_id} (${hotel.schema_name})`);

  // Cria (ou reutiliza) usuário de seed no master para vincular às avaliações
  console.log('\n[seed] Criando usuário de seed no master...');
  const { rows: userRows } = await masterPool.query<{ user_id: string }>(
    `INSERT INTO usuario (nome_completo, email, senha, cpf, numero_celular, data_nascimento)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (email) DO UPDATE SET nome_completo = EXCLUDED.nome_completo
     RETURNING user_id`,
    [SEED_USER.nome_completo, SEED_USER.email, SEED_USER.senha, SEED_USER.cpf, SEED_USER.numero_celular, SEED_USER.data_nascimento]
  );
  const seedUserId = userRows[0].user_id;
  console.log(`  [seed] Usuário de seed id=${seedUserId}`);

  await withTenant(hotel.schema_name, async (client) => {

    // Registra o usuário de seed como hóspede no tenant (idempotente)
    await client.query(
      `INSERT INTO hospede (user_id) VALUES ($1) ON CONFLICT DO NOTHING`,
      [seedUserId]
    );
    console.log(`  [seed] Hospede seed registrado no tenant`);

    // Insere itens no catálogo local do hotel (idempotente via ON CONFLICT)
    console.log('\n[seed] Inserindo catálogo de comodidades...');
    const catalogoIds: Record<string, number> = {};

    for (const item of CATALOGO_ITENS) {
      const { rows } = await client.query<{ id: number }>(
        `INSERT INTO catalogo (nome, categoria)
         VALUES ($1, $2)
         ON CONFLICT (nome, categoria) DO UPDATE SET nome = EXCLUDED.nome
         RETURNING id`,
        [item.nome, item.categoria]
      );
      catalogoIds[item.nome] = rows[0].id;
      console.log(`  [catalogo] "${item.nome}" (${item.categoria}) id=${rows[0].id}`);
    }

    // Cria as categorias de quarto com seus itens
    console.log('\n[seed] Inserindo categorias de quarto...');
    const categoriaIds: number[] = [];

    for (const cat of CATEGORIAS) {
      const { rows } = await client.query<{ id: number }>(
        `INSERT INTO categoria_quarto (nome, preco_base, capacidade_pessoas)
         VALUES ($1, $2, $3)
         ON CONFLICT DO NOTHING
         RETURNING id`,
        [cat.nome, cat.preco_base, cat.capacidade_pessoas]
      );

      let catId: number;
      if (rows.length) {
        catId = rows[0].id;
      } else {
        const { rows: existing } = await client.query<{ id: number }>(
          `SELECT id FROM categoria_quarto WHERE nome = $1 AND deleted_at IS NULL LIMIT 1`,
          [cat.nome]
        );
        catId = existing[0].id;
      }

      categoriaIds.push(catId);
      console.log(`  [categoria] "${cat.nome}" id=${catId}`);

      // Vincula itens do catálogo à categoria (idempotente)
      for (const nomeItem of cat.itens) {
        const itemId = catalogoIds[nomeItem];
        if (!itemId) continue;
        await client.query(
          `INSERT INTO categoria_item (categoria_quarto_id, catalogo_id, quantidade)
           VALUES ($1, $2, 1)
           ON CONFLICT DO NOTHING`,
          [catId, itemId]
        );
      }
      console.log(`    [categoria_item] ${cat.itens.length} itens vinculados`);
    }

    // Insere os quartos por bloco
    for (const bloco of BLOCOS) {
      console.log(`\n[seed] ${bloco.label}`);

      for (const q of bloco.quartos) {
        const catId = categoriaIds[q.categoriaIdx];

        // Insere ou atualiza o quarto com descricao
        await client.query(
          `INSERT INTO quarto (numero, categoria_quarto_id, valor_override, disponivel, descricao)
           VALUES ($1, $2, $3, TRUE, $4)
           ON CONFLICT (numero) DO UPDATE
             SET valor_override = EXCLUDED.valor_override,
                 descricao      = EXCLUDED.descricao`,
          [q.numero, catId, q.valor, q.descricao]
        );

        const { rows: quartoRows } = await client.query<{ id: number }>(
          `SELECT id FROM quarto WHERE numero = $1 LIMIT 1`,
          [q.numero]
        );

        if (!quartoRows.length) {
          console.warn(`  [seed] Quarto ${q.numero} não encontrado após insert`);
          continue;
        }

        const quartoId = quartoRows[0].id;

        // Quartos sem avaliação: apenas insere o quarto
        if (bloco.nota === null) {
          console.log(`  [seed] Quarto ${q.numero} (id=${quartoId}) inserido sem avaliação`);
          continue;
        }

        // Cria reservas CONCLUIDAS e avaliações vinculadas ao usuário de seed
        for (let i = 0; i < bloco.avaliacoesPorQuarto; i++) {
          const { rows: reservaRows } = await client.query<{ id: number }>(
            `INSERT INTO reserva
               (quarto_id, user_id, num_hospedes, data_checkin, data_checkout, status, canal_origem, valor_total, codigo_publico)
             VALUES
               ($1, $2, 1, '2025-01-01', '2025-01-02', 'CONCLUIDA', 'APP', $3, gen_random_uuid())
             RETURNING id`,
            [quartoId, seedUserId, q.valor]
          );

          if (!reservaRows.length) continue;

          const reservaId = reservaRows[0].id;
          const nota = bloco.nota as number;

          await client.query(
            `INSERT INTO avaliacao
               (user_id, reserva_id, nota_limpeza, nota_atendimento, nota_conforto, nota_organizacao, nota_localizacao, nota_total)
             VALUES ($1, $2, $3, $3, $3, $3, $3, $3)
             ON CONFLICT DO NOTHING`,
            [seedUserId, reservaId, nota]
          );
        }

        console.log(
          `  [seed] Quarto ${q.numero} (id=${quartoId}) — ${bloco.avaliacoesPorQuarto} avaliação(ões) nota ${bloco.nota}`
        );
      }
    }

    console.log('\n[seed/recommendedRooms] Seed concluído com sucesso');
  });
}

seedRecommendedRooms()
  .catch((err) => {
    console.error('[seed/recommendedRooms] Erro fatal:', err);
    process.exit(1);
  })
  .finally(() => masterPool.end());
