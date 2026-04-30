/**
 * Seed: my-rooms-page — Cenários de Teste
 *
 * Cria um hotel dedicado a testar a my_rooms_page com os seguintes cenários:
 *
 *  Cenário 1 — Dia totalmente lotado (Suíte Master — 3 unidades)
 *    • Quartos 501, 502: APROVADA de HOJE+3 a HOJE+8
 *    • Quarto 503:       APROVADA de HOJE+5 a HOJE+10
 *    • Resultado: HOJE+5, HOJE+6, HOJE+7 têm 3/3 unidades → INDISPONÍVEL no calendário
 *
 *  Cenário 2 — Reserva manual até lotação (Quarto Duplo Premium — 2 unidades)
 *    • Quarto 601: APROVADA de HOJE+1 a HOJE+4  (1/2 ocupado)
 *    • Quarto 602: sem reserva
 *    • Fazer reserva manual para 602 de HOJE+1 a HOJE+4 → dia vai para 2/2 → indisponível
 *
 *  Cenário 3 — Delete total (Quarto Single Business — 1 unidade)
 *    • Quarto 701: sem reserva
 *    • Deletar quantidade = 1 → categoria desaparece da listagem
 *
 *  Cenário 4 — Delete parcial (Suíte Família — 4 unidades)
 *    • Quartos 801, 802, 803, 804: sem reserva
 *    • Deletar quantidade = 2 → card permanece com 2 unidades
 *
 *  Cenário 5 — Busca por nome e filtro por categoria
 *    • 4 categorias com nomes distintos: buscar "master", "duplo", "single", "família"
 *
 * Login do hotel:
 *   email: myrooms@teste.com
 *   senha: Seed@2026
 */
import 'dotenv/config';
import { registerAnfitriao }                         from '../../services/anfitriao.service';
import { updateConfiguracaoHotel }                   from '../../services/configuracao.service';
import { createCatalogo }                            from '../../services/catalogo.service';
import { createCategoriaQuarto, addItemToCategoria } from '../../services/categoriaQuarto.service';
import { createQuarto }                              from '../../services/quarto.service';
import { masterPool }                                from '../masterDb';
import { withTenant }                                from '../schemaWrapper';
import { CategoriaItem }                             from '../../entities/Catalogo';

if (process.env.NODE_ENV === 'production') {
  console.log('[seed/my-rooms-page] Seed ignorado em produção');
  process.exit(0);
}

const HOTEL = {
  nome_hotel:  'Hotel Teste MyRooms',
  cnpj:        '99999999000199',
  telefone:    '11911111199',
  email:       'myrooms@teste.com',
  senha:       'Seed@2026',
  cep:         '01000000',
  uf:          'SP',
  cidade:      'São Paulo',
  bairro:      'Centro',
  rua:         'Rua dos Testes',
  numero:      '1',
  descricao:   'Hotel de testes criado exclusivamente para validação da my_rooms_page.',
};

const CATALOGO_ITENS: { nome: string; categoria: CategoriaItem }[] = [
  { nome: 'Wi-Fi',              categoria: 'COMODIDADE' },
  { nome: 'Ar-condicionado',    categoria: 'COMODIDADE' },
  { nome: 'TV a cabo',          categoria: 'COMODIDADE' },
  { nome: 'Frigobar',           categoria: 'COMODIDADE' },
  { nome: 'Cama king-size',     categoria: 'COMODO'     },
  { nome: 'Cama queen-size',    categoria: 'COMODO'     },
  { nome: 'Cama de solteiro',   categoria: 'COMODO'     },
  { nome: 'Banheiro privativo', categoria: 'COMODO'     },
];

function fmtDate(d: Date): string {
  return d.toISOString().split('T')[0];
}
function addDays(d: Date, n: number): Date {
  const r = new Date(d);
  r.setDate(r.getDate() + n);
  return r;
}

const TODAY = new Date();

// Cenário 1 — Suíte Master (3 unidades) — dias lotados em HOJE+5, +6, +7
const C1_A_IN  = fmtDate(addDays(TODAY,  3));  // 501+502 checkin
const C1_A_OUT = fmtDate(addDays(TODAY,  8));  // 501+502 checkout (exclusivo)
const C1_B_IN  = fmtDate(addDays(TODAY,  5));  // 503 checkin
const C1_B_OUT = fmtDate(addDays(TODAY, 10));  // 503 checkout

// Cenário 2 — Quarto Duplo Premium (2 unidades) — 601 ocupado, 602 livre para reserva manual
const C2_IN  = fmtDate(addDays(TODAY, 1));
const C2_OUT = fmtDate(addDays(TODAY, 4));

export async function seedMyRoomsPage(): Promise<void> {
  console.log('--- Seed: my-rooms-page ---\n');

  try {
    // ── 1. Criar hotel ──────────────────────────────────────────────────────
    const hotel = await registerAnfitriao(HOTEL as any);
    console.log(`  ✅ Hotel criado: ${hotel.nome_hotel} | schema: ${hotel.schema_name}`);

    // ── 2. Configuração operacional ─────────────────────────────────────────
    await updateConfiguracaoHotel(hotel.hotel_id, {
      horario_checkin:       '14:00',
      horario_checkout:      '12:00',
      max_dias_reserva:      30,
      politica_cancelamento: 'Cancelamento gratuito até 24h antes do check-in.',
      aceita_animais:        false,
      idiomas_atendimento:   'Português',
    });

    // ── 3. Catálogo de comodidades ──────────────────────────────────────────
    const catalogoIds: Record<string, number> = {};
    for (const item of CATALOGO_ITENS) {
      const criado = await createCatalogo(hotel.hotel_id, { nome: item.nome, categoria: item.categoria });
      catalogoIds[item.nome] = criado.id;
    }
    console.log(`  ✅ Catálogo: ${CATALOGO_ITENS.length} itens`);

    // ── 4. Categorias + Quartos ─────────────────────────────────────────────

    // [C1] Suíte Master — 3 unidades
    const catSuite = await createCategoriaQuarto(hotel.hotel_id, {
      nome: 'Suíte Master',
      capacidade_pessoas: 2,
      valor_diaria: 580,
    });
    for (const nome of ['Wi-Fi', 'Ar-condicionado', 'TV a cabo', 'Frigobar', 'Cama king-size', 'Banheiro privativo']) {
      await addItemToCategoria(hotel.hotel_id, catSuite.id, { catalogo_id: catalogoIds[nome], quantidade: 1 });
    }
    await createQuarto(hotel.hotel_id, { categoria_quarto_id: catSuite.id, numero: '501', valor_diaria: 580, descricao: 'Suíte master com cama king-size e vista panorâmica.' });
    await createQuarto(hotel.hotel_id, { categoria_quarto_id: catSuite.id, numero: '502', valor_diaria: 600, descricao: 'Suíte master premium no último andar.' });
    await createQuarto(hotel.hotel_id, { categoria_quarto_id: catSuite.id, numero: '503', valor_diaria: 560, descricao: 'Suíte master com varanda e banheira.' });
    console.log(`  ✅ Categoria "Suíte Master" | 3 quartos (501, 502, 503)`);

    // [C2] Quarto Duplo Premium — 2 unidades
    const catDuplo = await createCategoriaQuarto(hotel.hotel_id, {
      nome: 'Quarto Duplo Premium',
      capacidade_pessoas: 2,
      valor_diaria: 320,
    });
    for (const nome of ['Wi-Fi', 'Ar-condicionado', 'TV a cabo', 'Cama queen-size', 'Banheiro privativo']) {
      await addItemToCategoria(hotel.hotel_id, catDuplo.id, { catalogo_id: catalogoIds[nome], quantidade: 1 });
    }
    await createQuarto(hotel.hotel_id, { categoria_quarto_id: catDuplo.id, numero: '601', valor_diaria: 320, descricao: 'Quarto duplo renovado com cama queen-size.' });
    await createQuarto(hotel.hotel_id, { categoria_quarto_id: catDuplo.id, numero: '602', valor_diaria: 340, descricao: 'Quarto duplo com varanda privativa.' });
    console.log(`  ✅ Categoria "Quarto Duplo Premium" | 2 quartos (601, 602)`);

    // [C3] Quarto Single Business — 1 unidade (para delete total)
    const catSingle = await createCategoriaQuarto(hotel.hotel_id, {
      nome: 'Quarto Single Business',
      capacidade_pessoas: 1,
      valor_diaria: 180,
    });
    for (const nome of ['Wi-Fi', 'Ar-condicionado', 'Cama de solteiro', 'Banheiro privativo']) {
      await addItemToCategoria(hotel.hotel_id, catSingle.id, { catalogo_id: catalogoIds[nome], quantidade: 1 });
    }
    await createQuarto(hotel.hotel_id, { categoria_quarto_id: catSingle.id, numero: '701', valor_diaria: 180, descricao: 'Quarto individual compacto para viagens a trabalho.' });
    console.log(`  ✅ Categoria "Quarto Single Business" | 1 quarto (701)`);

    // [C4] Suíte Família — 4 unidades (para delete parcial)
    const catFamilia = await createCategoriaQuarto(hotel.hotel_id, {
      nome: 'Suíte Família',
      capacidade_pessoas: 4,
      valor_diaria: 420,
    });
    for (const nome of ['Wi-Fi', 'Ar-condicionado', 'TV a cabo', 'Frigobar', 'Cama queen-size', 'Banheiro privativo']) {
      await addItemToCategoria(hotel.hotel_id, catFamilia.id, { catalogo_id: catalogoIds[nome], quantidade: 1 });
    }
    await createQuarto(hotel.hotel_id, { categoria_quarto_id: catFamilia.id, numero: '801', valor_diaria: 420, descricao: 'Suíte família com duas camas queen-size.' });
    await createQuarto(hotel.hotel_id, { categoria_quarto_id: catFamilia.id, numero: '802', valor_diaria: 430, descricao: 'Suíte família com berço disponível sob pedido.' });
    await createQuarto(hotel.hotel_id, { categoria_quarto_id: catFamilia.id, numero: '803', valor_diaria: 440, descricao: 'Suíte família com vista para o jardim.' });
    await createQuarto(hotel.hotel_id, { categoria_quarto_id: catFamilia.id, numero: '804', valor_diaria: 450, descricao: 'Suíte família premium com banheira.' });
    console.log(`  ✅ Categoria "Suíte Família" | 4 quartos (801–804)`);

    // ── 5. Reservas para cenários 1 e 2 ────────────────────────────────────
    await withTenant(hotel.schema_name, async (client) => {

      // Obtém ou cria usuário de seed para vincular às reservas
      let seedUserId: string;
      const { rows: userRows } = await masterPool.query<{ user_id: string }>(
        `INSERT INTO usuario (nome_completo, email, senha, cpf, numero_celular, data_nascimento)
         VALUES ('Usuário Seed', 'seed@reservaqui.dev', '$2b$10$seedpasswordhashxxxxxseedpasswordhashxxxxxx',
                 '000.000.000-00', '(00) 00000-0000', '1990-01-01')
         ON CONFLICT (email) DO UPDATE SET nome_completo = EXCLUDED.nome_completo
         RETURNING user_id`,
      );
      seedUserId = userRows[0].user_id;

      // Registra como hóspede no tenant antes de criar reservas (FK obrigatória)
      await client.query(
        `INSERT INTO hospede (user_id) VALUES ($1) ON CONFLICT DO NOTHING`,
        [seedUserId],
      );

      const { rows: quartoRows } = await client.query<{ id: number; numero: string }>(
        `SELECT id, numero FROM quarto WHERE numero IN ('501','502','503','601') AND deleted_at IS NULL`,
      );
      const byNumero = Object.fromEntries(quartoRows.map((r) => [r.numero, r.id]));

      const insertReserva = async (
        quartoId: number,
        checkin: string,
        checkout: string,
        valor: number,
      ) => {
        await client.query(
          `INSERT INTO reserva
             (quarto_id, user_id, num_hospedes, data_checkin, data_checkout,
              status, canal_origem, valor_total, codigo_publico)
           VALUES ($1, $2, 1, $3, $4, 'APROVADA', 'APP', $5, gen_random_uuid())`,
          [quartoId, seedUserId, checkin, checkout, valor],
        );
      };

      // Cenário 1 — Suíte Master: 501+502 de C1_A, 503 de C1_B → lotação em HOJE+5..+7
      if (byNumero['501']) await insertReserva(byNumero['501'], C1_A_IN, C1_A_OUT, 580 * 5);
      if (byNumero['502']) await insertReserva(byNumero['502'], C1_A_IN, C1_A_OUT, 600 * 5);
      if (byNumero['503']) await insertReserva(byNumero['503'], C1_B_IN, C1_B_OUT, 560 * 5);
      console.log(`  ✅ Reservas C1 (Suíte Master): 501+502 de ${C1_A_IN}→${C1_A_OUT} | 503 de ${C1_B_IN}→${C1_B_OUT}`);

      // Cenário 2 — Duplo Premium: 601 ocupado; 602 livre para reserva manual
      if (byNumero['601']) await insertReserva(byNumero['601'], C2_IN, C2_OUT, 320 * 3);
      console.log(`  ✅ Reserva C2 (Duplo Premium): 601 de ${C2_IN}→${C2_OUT} (602 livre para reserva manual)`);
    });

    console.log(`
╔══════════════════════════════════════════════════════════════════╗
║          SEED my-rooms-page concluído com sucesso                ║
╠══════════════════════════════════════════════════════════════════╣
║  Login: myrooms@teste.com                                        ║
║  Senha: Seed@2026                                                ║
╠══════════════════════════════════════════════════════════════════╣
║  CENÁRIOS DE TESTE                                               ║
║                                                                  ║
║  [C1] Suíte Master — 3 unidades                                  ║
║    • Abrir reserva manual → HOJE+5, +6, +7 = BLOQUEADOS          ║
║    • HOJE+3, +4 = parcial (2/3); a partir de HOJE+8 = 1/3       ║
║                                                                  ║
║  [C2] Quarto Duplo Premium — 2 unidades                          ║
║    • 601 APROVADA ${C2_IN} → ${C2_OUT}              ║
║    • Fazer reserva manual 602 no mesmo período                   ║
║      → dias HOJE+1, +2, +3 ficam BLOQUEADOS (2/2)               ║
║                                                                  ║
║  [C3] Quarto Single Business — 1 unidade                         ║
║    • Deletar quantidade = 1 → categoria some da listagem         ║
║                                                                  ║
║  [C4] Suíte Família — 4 unidades                                 ║
║    • Deletar quantidade = 2 → card fica com 2 unidades           ║
║                                                                  ║
║  [C5] Busca por nome:                                            ║
║    • "master"  → Suíte Master                                    ║
║    • "duplo"   → Quarto Duplo Premium                            ║
║    • "single"  → Quarto Single Business                          ║
║    • "família" → Suíte Família                                   ║
║                                                                  ║
║  [C5] Filtro por categoria: clicar cada chip                     ║
║    → apenas aquela categoria é exibida                           ║
╚══════════════════════════════════════════════════════════════════╝
`);

  } catch (err: any) {
    if (
      err.message?.includes('duplicate key') ||
      err.message?.includes('unique constraint') ||
      err.message?.includes('ja existe')
    ) {
      console.log(`  ⚠️  Hotel "Hotel Teste MyRooms" já existe (rode db:reset para recriar)`);
    } else {
      throw err;
    }
  }
}

// Auto-execução quando rodado diretamente
if (require.main === module) {
  seedMyRoomsPage()
    .catch((err) => {
      console.error('[seed/my-rooms-page] Erro fatal:', err);
      process.exit(1);
    })
    .finally(async () => {
      await masterPool.end();
      process.exit(0);
    });
}
