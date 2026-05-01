/**
 * Seed: push-fcm — Teste de Push Notification FCM
 *
 * Valida o pipeline completo de push notification:
 *   1. Cria hotel de teste + hóspede de teste (idempotente)
 *   2. Cria um quarto no hotel
 *   3. Verifica se o hotel tem tokens FCM registrados (exige login prévio no app)
 *   4. Cria uma reserva via createReservaUsuario → dispara NOVA_RESERVA para o hotel
 *
 * Pré-requisito:
 *   Fazer login no app como hotel (fcmtest@teste.com / Seed@2026) ANTES de rodar
 *   este seed, para que o FCM token seja registrado no banco.
 *
 * Credenciais:
 *   Hotel:    fcmtest@teste.com  / Seed@2026
 *   Hóspede:  fcmguest@teste.com / Seed@2026
 */
import 'dotenv/config';
import { masterPool } from '../masterDb';
import { registerAnfitriao } from '../../services/anfitriao.service';
import { registerUsuario } from '../../services/usuario.service';
import { updateConfiguracaoHotel } from '../../services/configuracao.service';
import { createCatalogo } from '../../services/catalogo.service';
import { createCategoriaQuarto, addItemToCategoria } from '../../services/categoriaQuarto.service';
import { createQuarto } from '../../services/quarto.service';
import { createReservaUsuario } from '../../services/reserva.service';
import { sendPush }             from '../../services/fcm.service';

if (process.env.NODE_ENV === 'production') {
  console.log('[seed/push-fcm] Seed ignorado em produção');
  process.exit(0);
}

const HOTEL = {
  nome_hotel: 'Hotel FCM Test',
  cnpj: '11111111000111',
  telefone: '11900000001',
  email: 'fcmtest@teste.com',
  senha: 'Seed@2026',
  cep: '01310100',
  uf: 'SP',
  cidade: 'São Paulo',
  bairro: 'Bela Vista',
  rua: 'Avenida Paulista',
  numero: '1000',
  descricao: 'Hotel de teste exclusivo para validação de push notifications FCM.',
};

const GUEST = {
  nome_completo: 'Hóspede FCM Test',
  email: 'fcmguest@teste.com',
  senha: 'Seed@2026',
  cpf: '111.111.111-11',
  numero_celular: '(11) 91111-1111',
  data_nascimento: '15/06/1995',
};

function addDays(d: Date, n: number): string {
  const r = new Date(d);
  r.setDate(r.getDate() + n);
  return r.toISOString().split('T')[0];
}

export async function seedPushFcm(): Promise<void> {
  console.log('--- Seed: push-fcm ---\n');

  // ── 1. Hotel ──────────────────────────────────────────────────────────────
  let hotel: Awaited<ReturnType<typeof registerAnfitriao>>;
  try {
    hotel = await registerAnfitriao(HOTEL as any);
    console.log(`  ✅ Hotel criado: ${hotel.nome_hotel} (${hotel.hotel_id})`);
  } catch (err: any) {
    if (err.message?.includes('duplicate key') || err.message?.includes('unique') || err.message?.includes('ja existe')) {
      const { rows } = await masterPool.query<{ hotel_id: string; schema_name: string; nome_hotel: string }>(
        `SELECT hotel_id, schema_name, nome_hotel FROM anfitriao WHERE email = $1`,
        [HOTEL.email],
      );
      hotel = rows[0] as any;
      console.log(`  ⚠️  Hotel já existe — reutilizando (${hotel.hotel_id})`);
    } else {
      throw err;
    }
  }

  await updateConfiguracaoHotel(hotel.hotel_id, {
    horario_checkin: '14:00',
    horario_checkout: '12:00',
    max_dias_reserva: 30,
    politica_cancelamento: 'Cancelamento gratuito até 24h antes do check-in.',
    aceita_animais: false,
    idiomas_atendimento: 'Português',
  }).catch(() => { }); // ignora se já existir

  // ── 2. Quarto ─────────────────────────────────────────────────────────────
  let quartoId: number | undefined;
  try {
    const wifi = await createCatalogo(hotel.hotel_id, { nome: 'Wi-Fi FCM', categoria: 'COMODIDADE' });
    const cat = await createCategoriaQuarto(hotel.hotel_id, { nome: 'Standard FCM', capacidade_pessoas: 2, valor_diaria: 200 });
    await addItemToCategoria(hotel.hotel_id, cat.id, { catalogo_id: wifi.id, quantidade: 1 });
    const quarto = await createQuarto(hotel.hotel_id, { categoria_quarto_id: cat.id, numero: '001', valor_diaria: 200, descricao: 'Quarto de teste FCM.' });
    quartoId = quarto.id;
    console.log(`  ✅ Quarto criado: #${quartoId}`);
  } catch {
    const { rows: qRows } = await masterPool.query<{ id: number }>(
      `SELECT id FROM ${hotel.schema_name}.quarto WHERE deleted_at IS NULL LIMIT 1`,
    );
    quartoId = qRows[0]?.id;
    if (quartoId) console.log(`  ⚠️  Reutilizando quarto existente: #${quartoId}`);
  }

  // ── 3. Hóspede ────────────────────────────────────────────────────────────
  let guestId: string;
  try {
    const guest = await registerUsuario(GUEST as any);
    guestId = guest.user_id;
    console.log(`  ✅ Hóspede criado: ${guest.nome_completo} (${guestId})`);
  } catch (err: any) {
    if (err.message?.includes('duplicate key') || err.message?.includes('unique') || err.message?.includes('já cadastrado')) {
      const { rows } = await masterPool.query<{ user_id: string }>(
        `SELECT user_id FROM usuario WHERE email = $1`,
        [GUEST.email],
      );
      guestId = rows[0].user_id;
      console.log(`  ⚠️  Hóspede já existe — reutilizando (${guestId})`);
    } else {
      throw err;
    }
  }

  // ── 4. Verificar tokens FCM do hotel ─────────────────────────────────────
  const { rows: tokenRows } = await masterPool.query<{ fcm_token: string }>(
    `SELECT fcm_token FROM dispositivo_fcm WHERE hotel_id = $1`,
    [hotel.hotel_id],
  );

  if (tokenRows.length === 0) {
    console.log(`
╔══════════════════════════════════════════════════════════════════╗
║  ⚠️  Nenhum token FCM registrado para o hotel                    ║
╠══════════════════════════════════════════════════════════════════╣
║  Faça login no app com as credenciais abaixo e rode novamente:   ║
║                                                                  ║
║  Email: fcmtest@teste.com                                        ║
║  Senha: Seed@2026                                                ║
║                                                                  ║
║  O login registra o token FCM do dispositivo no backend.         ║
║  Após isso, rode: npm run db:seed:push                           ║
╚══════════════════════════════════════════════════════════════════╝
`);
    return;
  }

  console.log(`  ✅ ${tokenRows.length} token(s) FCM registrado(s) para o hotel`);

  // ── 5. Teste direto de FCM (antes da reserva) ─────────────────────────────
  const tokens = tokenRows.map(r => r.fcm_token);
  console.log(`  🔍 Tokens: ${tokens.map(t => t.slice(0, 20) + '...').join(', ')}`);
  console.log(`  🔍 FIREBASE_SERVICE_ACCOUNT definido: ${!!process.env.FIREBASE_SERVICE_ACCOUNT}`);

  console.log('  🔔 Enviando push de teste direto...');
  try {
    await sendPush(tokens, {
      title: '🔔 Teste FCM — ReservAqui',
      body:  'Se esta notificação chegou, o Firebase está funcionando!',
      data:  { tipo: 'NOVA_RESERVA', codigo_publico: 'teste-seed' },
    });
    console.log('  ✅ sendPush executado sem erro');
  } catch (fcmErr: any) {
    console.error('  ❌ sendPush falhou:', fcmErr.message);
  }

  // ── 6. Criar reserva → dispara NOVA_RESERVA push para o hotel ─────────────
  if (!quartoId) {
    console.log('  ❌ Nenhum quarto disponível para criar reserva');
    return;
  }

  const checkin = addDays(new Date(), 5);
  const checkout = addDays(new Date(), 7);

  const reserva = await createReservaUsuario(guestId, {
    hotel_id:     hotel.hotel_id,
    quarto_id:    quartoId,
    num_hospedes: 1,
    data_checkin:  checkin,
    data_checkout: checkout,
    valor_total:   400,
  });

  console.log(`
╔══════════════════════════════════════════════════════════════════╗
║          SEED push-fcm concluído com sucesso                     ║
╠══════════════════════════════════════════════════════════════════╣
║  Reserva criada: #${String(reserva.id).padEnd(44)}║
║  Período: ${checkin} → ${checkout}                    ║
║                                                                  ║
║  Push NOVA_RESERVA disparado para o hotel.                       ║
║  Verifique a notificação no app logado como:                     ║
║    Email: fcmtest@teste.com                                      ║
╚══════════════════════════════════════════════════════════════════╝
`);
}

if (require.main === module) {
  seedPushFcm()
    .catch((err) => { console.error('[seed/push-fcm] Erro fatal:', err); process.exit(1); })
    .finally(async () => { await masterPool.end(); process.exit(0); });
}
