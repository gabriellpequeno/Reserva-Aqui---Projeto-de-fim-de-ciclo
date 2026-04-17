import { masterPool } from '../database/masterDb';
import { withTenant } from '../database/schemaWrapper';
import {
  Avaliacao,
  AvaliacaoSafe,
  CreateAvaliacaoInput,
  UpdateAvaliacaoInput,
} from '../entities/Avaliacao';

// ── Funções Exportadas (Wrappers) ─────────────────────────────────────────────

export async function createAvaliacao(
  userId: string,
  input:  CreateAvaliacaoInput,
): Promise<AvaliacaoSafe> {
  return _createAvaliacao(userId, input);
}

export async function updateAvaliacao(
  userId:        string,
  codigoPublico: string,
  input:         UpdateAvaliacaoInput,
): Promise<AvaliacaoSafe> {
  return _updateAvaliacao(userId, codigoPublico, input);
}

export async function listAvaliacoes(hotelId: string): Promise<AvaliacaoSafe[]> {
  return _listAvaliacoes(hotelId);
}

// ── Helpers Privados ──────────────────────────────────────────────────────────

interface TenantRouting {
  schema_name: string;
  hotel_id:    string;
}

/** Resolve schema_name e hotel_id a partir do codigo_publico da reserva. */
async function _getTenantRouting(codigoPublico: string): Promise<TenantRouting> {
  const { rows } = await masterPool.query<TenantRouting>(
    `SELECT schema_name, hotel_id FROM reserva_routing WHERE codigo_publico = $1`,
    [codigoPublico],
  );
  if (!rows[0]) throw new Error('Reserva não encontrada');
  return rows[0];
}

/** Resolve schema_name a partir do hotel_id. */
async function _getSchemaName(hotelId: string): Promise<string> {
  const { rows } = await masterPool.query<{ schema_name: string }>(
    `SELECT schema_name FROM anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  if (!rows[0]) throw new Error('Hotel não encontrado');
  return rows[0].schema_name;
}

// ── Funções Privadas (Regras de Negócio) ─────────────────────────────────────

async function _createAvaliacao(
  userId: string,
  input:  CreateAvaliacaoInput,
): Promise<AvaliacaoSafe> {
  Avaliacao.validate(input);
  const { schema_name } = await _getTenantRouting(input.codigo_publico);

  return withTenant(schema_name, async (client) => {
    // Busca a reserva pelo codigo_publico
    const { rows: reservaRows } = await client.query<{
      id:      number;
      user_id: string | null;
      status:  string;
    }>(
      `SELECT id, user_id, status FROM reserva WHERE codigo_publico = $1`,
      [input.codigo_publico],
    );
    if (!reservaRows[0]) throw new Error('Reserva não encontrada');

    const reserva = reservaRows[0];

    // Apenas o dono da reserva pode avaliar
    if (reserva.user_id !== userId)
      throw new Error('sem permissão para avaliar esta reserva');

    // Reserva deve estar concluída
    if (reserva.status !== 'CONCLUIDA')
      throw new Error('Só é possível avaliar reservas com status CONCLUIDA');

    // Verifica se já existe avaliação para esta reserva
    const { rows: existing } = await client.query(
      `SELECT id FROM avaliacao WHERE user_id = $1 AND reserva_id = $2`,
      [userId, reserva.id],
    );
    if (existing[0]) throw new Error('Você já avaliou esta reserva');

    const nota_total = Avaliacao.calcularTotal(
      input.nota_limpeza,
      input.nota_atendimento,
      input.nota_conforto,
      input.nota_organizacao,
      input.nota_localizacao,
    );

    const { rows } = await client.query<AvaliacaoSafe>(
      `INSERT INTO avaliacao
         (user_id, reserva_id, nota_limpeza, nota_atendimento, nota_conforto,
          nota_organizacao, nota_localizacao, nota_total, comentario)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        userId,
        reserva.id,
        input.nota_limpeza,
        input.nota_atendimento,
        input.nota_conforto,
        input.nota_organizacao,
        input.nota_localizacao,
        nota_total,
        input.comentario ?? null,
      ],
    );

    return rows[0];
  });
}

async function _updateAvaliacao(
  userId:        string,
  codigoPublico: string,
  input:         UpdateAvaliacaoInput,
): Promise<AvaliacaoSafe> {
  Avaliacao.validatePartial(input);
  const { schema_name } = await _getTenantRouting(codigoPublico);

  return withTenant(schema_name, async (client) => {
    // Busca a reserva para obter o reserva_id
    const { rows: reservaRows } = await client.query<{ id: number; user_id: string | null }>(
      `SELECT id, user_id FROM reserva WHERE codigo_publico = $1`,
      [codigoPublico],
    );
    if (!reservaRows[0]) throw new Error('Reserva não encontrada');

    const reserva = reservaRows[0];

    if (reserva.user_id !== userId)
      throw new Error('sem permissão para editar esta avaliação');

    // Busca avaliação atual para mesclar as notas não enviadas
    const { rows: current } = await client.query<AvaliacaoSafe>(
      `SELECT * FROM avaliacao WHERE user_id = $1 AND reserva_id = $2`,
      [userId, reserva.id],
    );
    if (!current[0]) throw new Error('Avaliação não encontrada');

    const base = current[0];

    // Mescla: usa o valor enviado se presente, senão mantém o valor atual do banco
    const limpeza     = input.nota_limpeza     ?? base.nota_limpeza;
    const atendimento = input.nota_atendimento ?? base.nota_atendimento;
    const conforto    = input.nota_conforto    ?? base.nota_conforto;
    const organizacao = input.nota_organizacao ?? base.nota_organizacao;
    const localizacao = input.nota_localizacao ?? base.nota_localizacao;

    const nota_total = Avaliacao.calcularTotal(
      limpeza, atendimento, conforto, organizacao, localizacao,
    );

    // comentario: undefined = não mudar; null = limpar; string = novo valor
    const comentario = input.comentario !== undefined ? input.comentario : base.comentario;

    const { rows } = await client.query<AvaliacaoSafe>(
      `UPDATE avaliacao
       SET nota_limpeza     = $1,
           nota_atendimento = $2,
           nota_conforto    = $3,
           nota_organizacao = $4,
           nota_localizacao = $5,
           nota_total       = $6,
           comentario       = $7
       WHERE user_id = $8 AND reserva_id = $9
       RETURNING *`,
      [
        limpeza, atendimento, conforto, organizacao, localizacao,
        nota_total, comentario,
        userId, reserva.id,
      ],
    );

    return rows[0];
  });
}

async function _listAvaliacoes(hotelId: string): Promise<AvaliacaoSafe[]> {
  const schemaName = await _getSchemaName(hotelId);

  return withTenant(schemaName, async (client) => {
    const { rows } = await client.query<AvaliacaoSafe>(
      `SELECT *
       FROM avaliacao
       ORDER BY criado_em DESC`,
    );
    return rows;
  });
}
