-- Migration: adiciona coluna ativo à categoria_quarto em todos os schemas de tenant
-- Categorias existentes são marcadas como ativas por padrão.
-- Executar uma vez em cada schema de tenant (ou via script que itera todos os schemas).

DO $$
DECLARE
  schema_rec RECORD;
BEGIN
  FOR schema_rec IN
    SELECT schema_name FROM anfitriao WHERE ativo = TRUE
  LOOP
    EXECUTE format(
      'ALTER TABLE %I.categoria_quarto ADD COLUMN IF NOT EXISTS ativo BOOLEAN NOT NULL DEFAULT TRUE',
      schema_rec.schema_name
    );
  END LOOP;
END;
$$;
