ALTER TABLE historico_reserva_global
  ADD COLUMN IF NOT EXISTS codigo_publico UUID;

-- Preenche registros existentes via join com reserva_routing (codigo_publico → hotel_id).
-- Um hotel pode ter N reservas; a junção usa hotel_id como aproximação pois
-- reserva_routing não armazena reserva_tenant_id. Registros sem match ficam NULL
-- e serão preenchidos no próximo upsert quando o status mudar.
UPDATE historico_reserva_global h
   SET codigo_publico = rr.codigo_publico
  FROM reserva_routing rr
 WHERE rr.hotel_id = h.hotel_id
   AND h.codigo_publico IS NULL;
