import { PoolClient } from 'pg';
import { masterPool } from '../database/masterDb';

// ── Tipos ─────────────────────────────────────────────────────────────────────

export type SaldoTipo = 'CREDITO_CHECKOUT' | 'TAXA_WALKIN' | 'SAQUE_SOLICITADO';

export interface SaldoTransacaoSafe {
  id:            string;
  tipo:          SaldoTipo;
  valor_bruto:   string;
  taxa:          string;
  valor_liquido: string;
  descricao:     string;
  reserva_id:    number | null;
  criado_em:     string;
}

export interface SaldoInfo {
  saldo_atual:           string;
  taxa_saque_percentual: number;
  valor_taxa:            string;
  valor_a_receber:       string;
  transacoes:            SaldoTransacaoSafe[];
}

export interface SaqueResult {
  valor_sacado:   string;
  taxa:           string;
  valor_recebido: string;
}

const TAXA_PCT = 0.10;

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

// ── Funções chamadas dentro de transações existentes (withTenant) ─────────────

/**
 * Credita o saldo do hotel quando uma reserva APP é concluída (checkout).
 * Deve receber o client da transação em andamento para garantir atomicidade.
 */
export async function creditarCheckout(
  client:    PoolClient,
  hotelId:   string,
  valor:     number,
  reservaId: number,
): Promise<void> {
  await client.query(
    `UPDATE public.anfitriao SET saldo = saldo + $1 WHERE hotel_id = $2`,
    [valor, hotelId],
  );
  await client.query(
    `INSERT INTO public.saldo_transacao
       (hotel_id, tipo, valor_bruto, taxa, valor_liquido, descricao, reserva_id)
     VALUES ($1, 'CREDITO_CHECKOUT', $2, 0, $2, $3, $4)`,
    [hotelId, valor, `Checkout concluído — reserva #${reservaId}`, reservaId],
  );
}

/**
 * Debita a taxa de 10% do saldo do hotel para reservas walk-in (balcão).
 * O saldo pode ficar negativo — é compensado pelas reservas APP futuras.
 * Deve receber o client da transação em andamento para garantir atomicidade.
 */
export async function debitarTaxaWalkin(
  client:    PoolClient,
  hotelId:   string,
  valorTotal: number,
  reservaId: number,
): Promise<void> {
  const taxa = round2(valorTotal * TAXA_PCT);

  await client.query(
    `UPDATE public.anfitriao SET saldo = saldo - $1 WHERE hotel_id = $2`,
    [taxa, hotelId],
  );
  await client.query(
    `INSERT INTO public.saldo_transacao
       (hotel_id, tipo, valor_bruto, taxa, valor_liquido, descricao, reserva_id)
     VALUES ($1, 'TAXA_WALKIN', $2, $2, 0, $3, $4)`,
    [hotelId, taxa, `Taxa de serviço (10%) — walk-in reserva #${reservaId}`, reservaId],
  );
}

// ── Saque (transação própria com lock) ────────────────────────────────────────

/**
 * Registra a solicitação de saque do saldo total.
 * Usa SELECT … FOR UPDATE para bloquear a linha e impedir saques concorrentes.
 * O saldo vai a zero — a transferência ao hotel é feita manualmente.
 */
export async function sacarSaldo(hotelId: string): Promise<SaqueResult> {
  const client = await masterPool.connect();
  try {
    await client.query('BEGIN');

    const { rows } = await client.query<{ saldo: string }>(
      `SELECT saldo FROM public.anfitriao
       WHERE hotel_id = $1 AND ativo = TRUE
       FOR UPDATE`,
      [hotelId],
    );
    if (!rows[0]) throw new Error('Hotel não encontrado');

    const saldoAtual = parseFloat(rows[0].saldo);
    if (saldoAtual <= 0)
      throw new Error('Saldo insuficiente para realizar o saque');

    const taxa         = round2(saldoAtual * TAXA_PCT);
    const valorLiquido = round2(saldoAtual - taxa);

    await client.query(
      `UPDATE public.anfitriao SET saldo = 0 WHERE hotel_id = $1`,
      [hotelId],
    );

    await client.query(
      `INSERT INTO public.saldo_transacao
         (hotel_id, tipo, valor_bruto, taxa, valor_liquido, descricao)
       VALUES ($1, 'SAQUE_SOLICITADO', $2, $3, $4,
               'Saque solicitado — transferência pendente')`,
      [hotelId, saldoAtual, taxa, valorLiquido],
    );

    await client.query('COMMIT');

    return {
      valor_sacado:   saldoAtual.toFixed(2),
      taxa:           taxa.toFixed(2),
      valor_recebido: valorLiquido.toFixed(2),
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// ── Consulta ──────────────────────────────────────────────────────────────────

export async function getSaldo(hotelId: string): Promise<SaldoInfo> {
  const { rows } = await masterPool.query<{ saldo: string }>(
    `SELECT saldo FROM public.anfitriao WHERE hotel_id = $1 AND ativo = TRUE`,
    [hotelId],
  );
  if (!rows[0]) throw new Error('Hotel não encontrado');

  const saldoAtual    = parseFloat(rows[0].saldo);
  const taxa          = round2(saldoAtual * TAXA_PCT);
  const valorAReceber = round2(saldoAtual - taxa);

  const { rows: transacoes } = await masterPool.query<SaldoTransacaoSafe>(
    `SELECT id, tipo, valor_bruto, taxa, valor_liquido, descricao, reserva_id, criado_em
     FROM public.saldo_transacao
     WHERE hotel_id = $1
     ORDER BY criado_em DESC
     LIMIT 20`,
    [hotelId],
  );

  return {
    saldo_atual:           saldoAtual.toFixed(2),
    taxa_saque_percentual: TAXA_PCT * 100,
    valor_taxa:            taxa.toFixed(2),
    valor_a_receber:       saldoAtual > 0 ? valorAReceber.toFixed(2) : '0.00',
    transacoes,
  };
}
