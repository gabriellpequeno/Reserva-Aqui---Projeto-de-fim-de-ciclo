-- Migration: adiciona coluna foto_perfil em usuario e anfitriao
-- Executar uma única vez no banco existente.

ALTER TABLE usuario   ADD COLUMN IF NOT EXISTS foto_perfil TEXT;
ALTER TABLE anfitriao ADD COLUMN IF NOT EXISTS foto_perfil TEXT;
