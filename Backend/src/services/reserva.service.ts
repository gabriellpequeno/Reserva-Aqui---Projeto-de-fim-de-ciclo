import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import { setQuartoDisponivel } from './quarto.service';
import { creditarCheckout, debitarTaxaWalkin } from './saldo.service';
import { sendPush, getHotelTokens, getUserTokens } from './fcm.service';
import { insertNotificacao } from './notificacaoHotel.service';
import { sendApprovedReservationConfirmation } from './whatsappReservation.service';
import {
  Reserva,
  ReservaSafe,
  ReservaStatus,
  CreateReservaUsuarioInput,
  CreateReservaWalkinInput,
  UpdateStatusInput,
  AtribuirQuartoInput,
} from '../entities/Reserva';

// ── Tipos de Output ───────────────────────────────────────────────────────────

/** Resumo de reserva lido a partir de historico_reserva_global (master DB). */
export interface HistoricoReservaSafe {
  id:               string;
  hotel_id:         string;
  reserva_tenant_id: number;
  nome_hotel:       string;
  tipo_quarto:      string;
  data_checkin:     string;
  data_checkout:    string;
  num_hospedes:     number;
  valor_total:      string;
  status:           ReservaStatus;
  codigo_publico:   string;
  criado_em:        string;
  atualizado_em:    string;
}

// ── Filtros de listagem ───────────────────────────────────────────────────────

export interface ListReservasFilters {
  status?:             ReservaStatus;
  data_checkin_from?:  string;
  data_checkin_to?:    string;
  data_checkout_from?: string;
  data_checkout_to?:   string;
  nome_hospede?:       string;
  cpf_hospede?:        string;
}

// ── Funções Exportadas (Wrappers) ─────────────────────────────────────────────

export async function createReservaUsuario(
  userId:  string,
  input:   CreateReservaUsuarioInput,
): Promise<ReservaSafe> {
  return _createReservaUsuario(userId, input);
}

export async function createReservaWalkin(
  hotelId: string,
  input:   CreateReservaWalkinInput,
): Promise<ReservaSafe> {
  return _createReservaWalkin(hotelId, input);
}

export async function listReservas(
  hotelId: string,
  filters: ListReservasFilters,
): Promise<ReservaSafe[]> {
  return _listReservas(hotelId, filters);
}

export async function getReservaById(hotelId: string, reservaId: number): Promise<ReservaSafe> {
  return _getReservaById(hotelId, reservaId);
}

export async function getReservaByCodigoPublico(codigoPublico: string): Promise<ReservaSafe> {
  return _getReservaByCodigoPublico(codigoPublico);
}

export async function listReservasUsuario(userId: string): Promise<HistoricoReservaSafe[]> {
  return _listReservasUsuario(userId);
}

export async function updateStatus(
  hotelId:   string,
  reservaId: number,
  input:     UpdateStatusInput,
): Promise<ReservaSafe> {
  return _updateStatus(hotelId, reservaId, input);
}

export async function atribuirQuarto(
  hotelId:   string,
  reservaId: number,
  input:     AtribuirQuartoInput,
): Promise<ReservaSafe> {
  return _atribuirQuarto(hotelId, reservaId, input);
}

export async function registrarCheckin(hotelId: string, reservaId: number): Promise<ReservaSafe> {
  return _registrarCheckin(hotelId, reservaId);
}

export async function registrarCheckout(hotelId: string, reservaId: number): Promise<ReservaSafe> {
  return _registrarCheckout(hotelId, reservaId);
}

export async function cancelarReservaUsuario(
  userId:    string,
  codigoPublico: string,
): Promise<void> {
  return _cancelarReservaUsuario(userId, codigoPublico);
}

// ── Helpers Privados ──────────────────────────────────────────────────────────

function calcDiarias(checkin: string, checkout: string): number {
  const ms = new Date(checkout).getTime() - new Date(checkin).getTime();
  return Math.round(ms / 86_400_000);
}

async function _calcValorTotal(
  client: import('pg').PoolClient,
  quartoId: number,
  checkin: string,
  checkout: string,
): Promise<number> {
  const { rows } = await client.query<{ preco_diaria: string }>(
    `SELECT COALESCE(q.valor_override, cq.preco_base) AS preco_diaria
     FROM quarto q
     JOIN categoria_quarto cq ON cq.id = q.categoria_quarto_id
     WHERE q.id = $1 AND q.deleted_at IS NULL`,
    [quartoId],
  );
  if (!rows[0]) throw new Error('Quarto não encontrado');
  return parseFloat(rows[0].preco_diaria) * calcDiarias(checkin, checkout);
}

interface HotelInfo {
  schema_name: string;
  nome_hotel:  string;
}

async function _getHotelInfo(hotelId: string): Promise<HotelInfo> {
  const { rows } = await masterPool.query<HotelInfo>(
    `SELECT schema_name, nome_hotel FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  if (!rows[0]) throw new Error('Hotel não encontrado');
  return rows[0];
}

/**
 * Normaliza data_checkin/data_checkout para 'YYYY-MM-DD'. O node-pg retorna
 * colunas DATE como `Date`, e `String(dateObj)` produz "Fri May 01 2026 ..."
 * que o Postgres não aceita em colunas DATE no upsert de historico.
 */
function toISODate(value: Date | string): string {
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return value.slice(0, 10);
}

/** Garante que o usuário está registrado como hóspede neste hotel (cria se necessário). */
async function _ensureHospede(client: import('pg').PoolClient, userId: string): Promise<void> {
  await client.query(
    `INSERT INTO hospede (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING`,
    [userId],
  );
}

/** Registra no master o mapeamento codigo_publico → hotel para acesso público. */
async function _upsertReservaRouting(
  codigoPublico: string,
  hotelId:       string,
  schemaName:    string,
): Promise<void> {
  await masterPool.query(
    `INSERT INTO reserva_routing (codigo_publico, hotel_id, schema_name)
     VALUES ($1, $2, $3)
     ON CONFLICT (codigo_publico) DO NOTHING`,
    [codigoPublico, hotelId, schemaName],
  );
}

/** Sincroniza historico_reserva_global quando status da reserva muda. */
async function _upsertHistoricoGlobal(
  userId:          string,
  hotelId:         string,
  nomeHotel:       string,
  reservaTenantId: number,
  tipoQuarto:      string,
  dataCheckin:     string,
  dataCheckout:    string,
  valorTotal:      string,
  status:          ReservaStatus,
  numHospedes:     number,
  codigoPublico:   string,
): Promise<void> {
  await masterPool.query(
    `INSERT INTO historico_reserva_global
       (user_id, hotel_id, reserva_tenant_id, nome_hotel, tipo_quarto,
        data_checkin, data_checkout, num_hospedes, valor_total, status, codigo_publico)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     ON CONFLICT (hotel_id, reserva_tenant_id)
     DO UPDATE SET
       status         = EXCLUDED.status,
       tipo_quarto    = EXCLUDED.tipo_quarto,
       num_hospedes   = EXCLUDED.num_hospedes,
       codigo_publico = COALESCE(historico_reserva_global.codigo_publico, EXCLUDED.codigo_publico),
       atualizado_em  = NOW()`,
    [userId, hotelId, reservaTenantId, nomeHotel, tipoQuarto,
     dataCheckin, dataCheckout, numHospedes, valorTotal, status, codigoPublico],
  );
}

/** Resolve o texto de tipo_quarto: usa nome da categoria se quarto_id conhecido. */
async function _resolveTipoQuarto(
  client:    import('pg').PoolClient,
  quartoId:  number | null | undefined,
  tipoQuartoTexto: string | null | undefined,
): Promise<string> {
  if (quartoId) {
    const { rows } = await client.query<{ nome: string }>(
      `SELECT cq.nome
       FROM quarto q
       JOIN categoria_quarto cq ON cq.id = q.categoria_quarto_id
       WHERE q.id = $1`,
      [quartoId],
    );
    if (rows[0]) return rows[0].nome;
  }
  return tipoQuartoTexto ?? 'Quarto';
}

// ── Funções Privadas (Regras de Negócio) ─────────────────────────────────────

async function _createReservaUsuario(
  userId: string,
  input:  CreateReservaUsuarioInput,
): Promise<ReservaSafe> {
  Reserva.validateUsuario(input);
  const { schema_name, nome_hotel } = await _getHotelInfo(input.hotel_id);

  return withTenant(schema_name, async (client) => {
    // Garante hospede registrado no tenant
    await _ensureHospede(client, userId);

    // Verifica disponibilidade do quarto nas datas solicitadas (dentro da transação)
    if (input.quarto_id) {
      const { rows: dispRows } = await client.query<{ ocupado: boolean }>(
        `SELECT EXISTS (
           SELECT 1 FROM reserva
           WHERE quarto_id    = $1
             AND status       NOT IN ('CANCELADA')
             AND data_checkin  < $3
             AND data_checkout > $2
         ) AS ocupado`,
        [input.quarto_id, input.data_checkin, input.data_checkout],
      );
      if (dispRows[0]?.ocupado) {
        throw new Error('Quarto indisponível nas datas selecionadas.');
      }
    }

    const valorTotal = input.quarto_id
      ? await _calcValorTotal(client, input.quarto_id, input.data_checkin, input.data_checkout)
      : input.valor_total!;

    const { rows } = await client.query<ReservaSafe>(
      `INSERT INTO reserva
         (user_id, quarto_id, tipo_quarto, canal_origem,
          num_hospedes, data_checkin, data_checkout,
          valor_total, observacoes, p_turisticos, status)
       VALUES ($1, $2, $3, 'APP', $4, $5, $6, $7, $8, $9, 'SOLICITADA')
       RETURNING *`,
      [
        userId,
        input.quarto_id    ?? null,
        input.tipo_quarto  ?? null,
        input.num_hospedes,
        input.data_checkin,
        input.data_checkout,
        valorTotal,
        input.observacoes  ?? null,
        input.p_turisticos ? JSON.stringify(input.p_turisticos) : null,
      ],
    );
    const reserva = rows[0];

    // Routing público
    await _upsertReservaRouting(reserva.codigo_publico, input.hotel_id, schema_name);

    // Historico global
    const tipoQuarto = await _resolveTipoQuarto(client, input.quarto_id, input.tipo_quarto);
    await _upsertHistoricoGlobal(
      userId, input.hotel_id, nome_hotel, reserva.id,
      tipoQuarto, input.data_checkin, input.data_checkout,
      String(valorTotal), 'SOLICITADA', input.num_hospedes,
      reserva.codigo_publico,
    );

    // Notificações — fire-and-forget (falhas não interrompem o fluxo)
    Promise.all([
      getHotelTokens(input.hotel_id).then(tokens =>
        sendPush(tokens, {
          title: 'Nova reserva recebida',
          body:  `Nova solicitação para ${input.data_checkin} até ${input.data_checkout}.`,
          data:  { reserva_id: String(reserva.id), tipo: 'NOVA_RESERVA' },
        }),
      ),
      insertNotificacao(input.hotel_id, {
        titulo:   'Nova reserva recebida',
        mensagem: `Solicitação de reserva para ${input.data_checkin} até ${input.data_checkout}.`,
        tipo:     'NOVA_RESERVA',
        payload:  { reserva_id: reserva.id, codigo_publico: reserva.codigo_publico },
      }),
    ]).catch(() => {});

    return reserva;
  });
}

async function _createReservaWalkin(
  hotelId: string,
  input:   CreateReservaWalkinInput,
): Promise<ReservaSafe> {
  Reserva.validateWalkin(input);
  const { schema_name, nome_hotel } = await _getHotelInfo(hotelId);

  return withTenant(schema_name, async (client) => {
    // Hóspede registrado: garante entrada na tabela hospede
    if (input.user_id) {
      await _ensureHospede(client, input.user_id);
    }

    const valorTotal = input.quarto_id
      ? await _calcValorTotal(client, input.quarto_id, input.data_checkin, input.data_checkout)
      : input.valor_total!;

    const { rows } = await client.query<ReservaSafe>(
      `INSERT INTO reserva
         (user_id, nome_hospede, cpf_hospede, telefone_contato,
          quarto_id, tipo_quarto, canal_origem, sessao_chat_id,
          num_hospedes, data_checkin, data_checkout,
          valor_total, observacoes, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'BALCAO', $7, $8, $9, $10, $11, $12, 'APROVADA')
       RETURNING *`,
      [
        input.user_id          ?? null,
        input.nome_hospede     ?? null,
        input.cpf_hospede      ?? null,
        input.telefone_contato ?? null,
        input.quarto_id        ?? null,
        input.tipo_quarto      ?? null,
        input.sessao_chat_id   ?? null,
        input.num_hospedes,
        input.data_checkin,
        input.data_checkout,
        valorTotal,
        input.observacoes      ?? null,
      ],
    );
    const reserva = rows[0];

    // Routing público
    await _upsertReservaRouting(reserva.codigo_publico, hotelId, schema_name);

    // Taxa de serviço da plataforma (10%) debitada imediatamente no walk-in
    await debitarTaxaWalkin(client, hotelId, valorTotal, reserva.id);

    // Walk-in com quarto → marca indisponível
    if (input.quarto_id) {
      await setQuartoDisponivel(hotelId, input.quarto_id, false);
    }

    // Historico global (apenas se hóspede registrado)
    if (input.user_id) {
      const tipoQuarto = await _resolveTipoQuarto(client, input.quarto_id, input.tipo_quarto);
      await _upsertHistoricoGlobal(
        input.user_id, hotelId, nome_hotel, reserva.id,
        tipoQuarto, input.data_checkin, input.data_checkout,
        String(input.valor_total), 'APROVADA', input.num_hospedes,
        reserva.codigo_publico,
      );
    }

    return reserva;
  });
}

async function _listReservas(
  hotelId: string,
  filters: ListReservasFilters,
): Promise<ReservaSafe[]> {
  const { schema_name } = await _getHotelInfo(hotelId);

  return withTenant(schema_name, async (client) => {
    const conditions: string[] = [];
    const values: unknown[] = [];
    let idx = 1;

    if (filters.status) {
      conditions.push(`r.status = $${idx++}`);
      values.push(filters.status);
    }
    if (filters.data_checkin_from) {
      conditions.push(`r.data_checkin >= $${idx++}`);
      values.push(filters.data_checkin_from);
    }
    if (filters.data_checkin_to) {
      conditions.push(`r.data_checkin <= $${idx++}`);
      values.push(filters.data_checkin_to);
    }
    if (filters.data_checkout_from) {
      conditions.push(`r.data_checkout >= $${idx++}`);
      values.push(filters.data_checkout_from);
    }
    if (filters.data_checkout_to) {
      conditions.push(`r.data_checkout <= $${idx++}`);
      values.push(filters.data_checkout_to);
    }
    if (filters.nome_hospede) {
      conditions.push(`r.nome_hospede ILIKE $${idx++}`);
      values.push(`%${filters.nome_hospede}%`);
    }
    if (filters.cpf_hospede) {
      conditions.push(`r.cpf_hospede = $${idx++}`);
      values.push(filters.cpf_hospede);
    }

    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

    const { rows } = await client.query<ReservaSafe>(
      `SELECT r.*
       FROM reserva r
       ${where}
       ORDER BY r.criado_em DESC
       LIMIT 200`,
      values,
    );
    return rows;
  });
}

async function _getReservaById(hotelId: string, reservaId: number): Promise<ReservaSafe> {
  const { schema_name } = await _getHotelInfo(hotelId);

  return withTenant(schema_name, async (client) => {
    const { rows } = await client.query<ReservaSafe>(
      `SELECT * FROM reserva WHERE id = $1`,
      [reservaId],
    );
    if (!rows[0]) throw new Error('Reserva não encontrada');
    return rows[0];
  });
}

async function _getReservaByCodigoPublico(codigoPublico: string): Promise<ReservaSafe> {
  // Lookup no master para descobrir qual tenant
  const { rows: routing } = await masterPool.query<{ schema_name: string }>(
    `SELECT schema_name FROM reserva_routing WHERE codigo_publico = $1`,
    [codigoPublico],
  );
  if (!routing[0]) throw new Error('Reserva não encontrada');

  return withTenant(routing[0].schema_name, async (client) => {
    const { rows } = await client.query<ReservaSafe>(
      `SELECT * FROM reserva WHERE codigo_publico = $1`,
      [codigoPublico],
    );
    if (!rows[0]) throw new Error('Reserva não encontrada');
    return rows[0];
  });
}

async function _listReservasUsuario(userId: string): Promise<HistoricoReservaSafe[]> {
  const { rows } = await masterPool.query<HistoricoReservaSafe>(
    `SELECT
       h.id,
       h.hotel_id,
       h.reserva_tenant_id,
       h.nome_hotel,
       h.tipo_quarto,
       h.data_checkin,
       h.data_checkout,
       h.num_hospedes,
       h.valor_total,
       h.status,
       h.codigo_publico,
       h.criado_em,
       h.atualizado_em
     FROM historico_reserva_global h
     WHERE h.user_id = $1
     ORDER BY h.data_checkin DESC`,
    [userId],
  );
  return rows;
}

async function _updateStatus(
  hotelId:   string,
  reservaId: number,
  input:     UpdateStatusInput,
): Promise<ReservaSafe> {
  Reserva.validateStatus(input);
  const { schema_name, nome_hotel } = await _getHotelInfo(hotelId);

  return withTenant(schema_name, async (client) => {
    const { rows: current } = await client.query<ReservaSafe>(
      `SELECT * FROM reserva WHERE id = $1`,
      [reservaId],
    );
    if (!current[0]) throw new Error('Reserva não encontrada');

    const reserva = current[0];

    // Bloqueia transições inválidas a partir de estados terminais
    if (reserva.status === 'CONCLUIDA')
      throw new Error('Não é possível alterar o status de uma reserva concluída');
    if (reserva.status === 'CANCELADA' && input.status !== 'APROVADA')
      throw new Error('Reserva cancelada só pode ser reativada para APROVADA');

    const { rows } = await client.query<ReservaSafe>(
      `UPDATE reserva SET status = $1 WHERE id = $2 RETURNING *`,
      [input.status, reservaId],
    );
    const atualizada = rows[0];

    // Side effects de disponibilidade do quarto
    if (atualizada.quarto_id) {
      if (input.status === 'APROVADA') {
        await setQuartoDisponivel(hotelId, atualizada.quarto_id, false);
      } else if (input.status === 'CANCELADA' || input.status === 'CONCLUIDA') {
        await setQuartoDisponivel(hotelId, atualizada.quarto_id, true);
      }
    }

    // Sincroniza historico global (apenas hóspedes registrados)
    if (atualizada.user_id) {
      const tipoQuarto = await _resolveTipoQuarto(client, atualizada.quarto_id, atualizada.tipo_quarto);
      await _upsertHistoricoGlobal(
        atualizada.user_id, hotelId, nome_hotel, atualizada.id,
        tipoQuarto,
        toISODate(atualizada.data_checkin),
        toISODate(atualizada.data_checkout),
        atualizada.valor_total,
        input.status,
        atualizada.num_hospedes,
        atualizada.codigo_publico,
      );
    }

    // Notificações — fire-and-forget
    if (input.status === 'APROVADA' && atualizada.user_id) {
      // TODO: adicionar checkout_url ao data quando InfinitePay for integrado
      Promise.all([
        getUserTokens(atualizada.user_id).then(tokens =>
          sendPush(tokens, {
            title: 'Reserva aprovada!',
            body:  `Sua reserva em ${nome_hotel} foi aprovada. Em breve você receberá o link de pagamento.`,
            data:  { codigo_publico: atualizada.codigo_publico, tipo: 'APROVACAO_RESERVA' },
          }),
        ),
        insertNotificacao(hotelId, {
          titulo:   'Reserva aprovada',
          mensagem: `Reserva #${atualizada.id} aprovada para ${toISODate(atualizada.data_checkin)}.`,
          tipo:     'APROVACAO_RESERVA',
          payload:  { reserva_id: atualizada.id, codigo_publico: atualizada.codigo_publico },
        }),
      ]).catch(() => {});
    }

    if (input.status === 'APROVADA' && reserva.status !== 'APROVADA') {
      Promise.resolve()
        .then(() => sendApprovedReservationConfirmation({ hotelId, reservaId: atualizada.id }))
        .catch(() => {});
    }

    return atualizada;
  });
}

async function _atribuirQuarto(
  hotelId:   string,
  reservaId: number,
  input:     AtribuirQuartoInput,
): Promise<ReservaSafe> {
  Reserva.validateAtribuirQuarto(input);
  const { schema_name } = await _getHotelInfo(hotelId);

  return withTenant(schema_name, async (client) => {
    // Verifica existência e disponibilidade do quarto
    const { rows: quarto } = await client.query(
      `SELECT id FROM quarto WHERE id = $1 AND deleted_at IS NULL`,
      [input.quarto_id],
    );
    if (!quarto[0]) throw new Error('Quarto não encontrado');

    const { rows: current } = await client.query<ReservaSafe>(
      `SELECT * FROM reserva WHERE id = $1`,
      [reservaId],
    );
    if (!current[0]) throw new Error('Reserva não encontrada');

    const { rows } = await client.query<ReservaSafe>(
      `UPDATE reserva SET quarto_id = $1 WHERE id = $2 RETURNING *`,
      [input.quarto_id, reservaId],
    );
    const atualizada = rows[0];

    // Se reserva aprovada, marca quarto indisponível imediatamente
    if (atualizada.status === 'APROVADA') {
      await setQuartoDisponivel(hotelId, input.quarto_id, false);
    }

    return atualizada;
  });
}

async function _registrarCheckin(hotelId: string, reservaId: number): Promise<ReservaSafe> {
  const { schema_name } = await _getHotelInfo(hotelId);

  return withTenant(schema_name, async (client) => {
    const { rows: current } = await client.query<{ status: string }>(
      `SELECT status FROM reserva WHERE id = $1`,
      [reservaId],
    );
    if (!current[0]) throw new Error('Reserva não encontrada');
    if (current[0].status !== 'APROVADA')
      throw new Error('Só é possível registrar checkin em reservas com status APROVADA');

    const { rows } = await client.query<ReservaSafe>(
      `UPDATE reserva SET hora_checkin_real = NOW() WHERE id = $1 RETURNING *`,
      [reservaId],
    );
    return rows[0];
  });
}

async function _registrarCheckout(hotelId: string, reservaId: number): Promise<ReservaSafe> {
  const { schema_name, nome_hotel } = await _getHotelInfo(hotelId);

  return withTenant(schema_name, async (client) => {
    const { rows: current } = await client.query<ReservaSafe>(
      `SELECT * FROM reserva WHERE id = $1`,
      [reservaId],
    );
    if (!current[0]) throw new Error('Reserva não encontrada');

    const reserva = current[0];
    if (reserva.status !== 'APROVADA')
      throw new Error('Só é possível registrar checkout em reservas com status APROVADA');

    const { rows } = await client.query<ReservaSafe>(
      `UPDATE reserva
       SET hora_checkout_real = NOW(), status = 'CONCLUIDA'
       WHERE id = $1
       RETURNING *`,
      [reservaId],
    );
    const atualizada = rows[0];

    // Libera o quarto
    if (atualizada.quarto_id) {
      await setQuartoDisponivel(hotelId, atualizada.quarto_id, true);
    }

    // Credita saldo do hotel pelo valor total da reserva concluída
    await creditarCheckout(client, hotelId, parseFloat(atualizada.valor_total), atualizada.id);

    // Sincroniza historico como CONCLUIDA
    if (atualizada.user_id) {
      const tipoQuarto = await _resolveTipoQuarto(client, atualizada.quarto_id, atualizada.tipo_quarto);
      await _upsertHistoricoGlobal(
        atualizada.user_id, hotelId, nome_hotel, atualizada.id,
        tipoQuarto,
        toISODate(atualizada.data_checkin),
        toISODate(atualizada.data_checkout),
        atualizada.valor_total,
        'CONCLUIDA',
        atualizada.num_hospedes,
        atualizada.codigo_publico,
      );
    }

    return atualizada;
  });
}

async function _cancelarReservaUsuario(userId: string, codigoPublico: string): Promise<void> {
  // Lookup do tenant via routing
  const { rows: routing } = await masterPool.query<{ schema_name: string; hotel_id: string }>(
    `SELECT schema_name, hotel_id FROM reserva_routing WHERE codigo_publico = $1`,
    [codigoPublico],
  );
  if (!routing[0]) throw new Error('Reserva não encontrada');

  const { schema_name, hotel_id } = routing[0];

  // Busca nome_hotel para atualizar historico
  const { rows: hotelRows } = await masterPool.query<{ nome_hotel: string }>(
    `SELECT nome_hotel FROM anfitriao WHERE hotel_id = $1`,
    [hotel_id],
  );
  const nome_hotel = hotelRows[0]?.nome_hotel ?? '';

  await withTenant(schema_name, async (client) => {
    const { rows: current } = await client.query<ReservaSafe>(
      `SELECT * FROM reserva WHERE codigo_publico = $1`,
      [codigoPublico],
    );
    if (!current[0]) throw new Error('Reserva não encontrada');

    const reserva = current[0];

    // Verifica ownership
    if (reserva.user_id !== userId)
      throw new Error('sem permissão para cancelar esta reserva');

    // Só cancela se status permitir
    if (reserva.status !== 'SOLICITADA' && reserva.status !== 'APROVADA')
      throw new Error('Reserva não pode ser cancelada no status atual');

    await client.query(
      `UPDATE reserva SET status = 'CANCELADA' WHERE id = $1`,
      [reserva.id],
    );

    // Libera quarto se estava aprovada
    if (reserva.quarto_id) {
      await setQuartoDisponivel(hotel_id, reserva.quarto_id, true);
    }

    // Atualiza historico
    const tipoQuarto = await _resolveTipoQuarto(client, reserva.quarto_id, reserva.tipo_quarto);
    await _upsertHistoricoGlobal(
      userId, hotel_id, nome_hotel, reserva.id,
      tipoQuarto,
      toISODate(reserva.data_checkin),
      toISODate(reserva.data_checkout),
      reserva.valor_total,
      'CANCELADA',
      reserva.num_hospedes,
      reserva.codigo_publico,
    );

    // Notificações — fire-and-forget
    Promise.all([
      getHotelTokens(hotel_id).then(tokens =>
        sendPush(tokens, {
          title: 'Reserva cancelada pelo hóspede',
          body:  `A reserva #${reserva.id} foi cancelada pelo hóspede.`,
          data:  { reserva_id: String(reserva.id), tipo: 'RESERVA_CANCELADA' },
        }),
      ),
      insertNotificacao(hotel_id, {
        titulo:   'Reserva cancelada pelo hóspede',
        mensagem: `A reserva #${reserva.id} foi cancelada. Quarto liberado.`,
        tipo:     'RESERVA_CANCELADA',
        payload:  { reserva_id: reserva.id, codigo_publico: reserva.codigo_publico },
      }),
      getUserTokens(userId).then(tokens =>
        sendPush(tokens, {
          title: 'Cancelamento confirmado',
          body:  'Sua reserva foi cancelada com sucesso.',
          data:  { codigo_publico: reserva.codigo_publico, tipo: 'RESERVA_CANCELADA' },
        }),
      ),
    ]).catch(() => {});
  });
}
