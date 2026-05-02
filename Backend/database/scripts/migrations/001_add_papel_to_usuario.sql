-- ============================================================
-- Migration 001 — Adiciona coluna `papel` à tabela `usuario`
-- Feature: admin-account-management (Fase 1)
-- ============================================================
-- Diferencia usuários comuns de administradores da plataforma.
-- Default 'usuario' garante que todos os registros existentes continuem válidos.
-- CHECK impede valores fora do enum.
-- ============================================================

ALTER TABLE usuario
  ADD COLUMN IF NOT EXISTS papel VARCHAR(20) NOT NULL DEFAULT 'usuario';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'usuario_papel_check'
  ) THEN
    ALTER TABLE usuario
      ADD CONSTRAINT usuario_papel_check CHECK (papel IN ('usuario', 'admin'));
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_usuario_papel ON usuario (papel) WHERE papel = 'admin';
