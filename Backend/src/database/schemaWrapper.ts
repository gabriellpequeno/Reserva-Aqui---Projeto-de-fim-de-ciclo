import { PoolClient } from 'pg';
import { masterPool } from './masterDb';

/**
 * Função responsável por executar operações de banco de dados
 * isoladamente dentro do contexto lógico de um tenant (schema).
 * 
 * Ela adquire um Client do Pool global, define o `search_path`
 * para o schema do hotel em questão, executa a função desejada
 * e, antes de devolver o client ao Pool, reseta o ambiente
 * prevenindo vazamento de dados entre os tenants.
 *
 * @param schemaName Nome do schema lógico do hotel
 * @param callback   Operação de acesso aos dados que será executada
 */
export async function withTenant<T>(
  schemaName: string,
  callback: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await masterPool.connect();

  try {
    await client.query(`SET search_path TO "${schemaName}"`);
    return await callback(client);
  } finally {
    // RESET garante segurança contra vazamento em reutilização de conexão
    await client.query('RESET search_path');
    client.release();
  }
}
