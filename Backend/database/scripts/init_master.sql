-- ============================================================
-- MASTER DATABASE SCHEMA — reservaqui_master
-- Tabelas globais: hoteis (anfitriões) e usuários (hóspedes)
-- Modelo: 1 hotel = 1 anfitriao = 1 banco tenant próprio
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- para gen_random_uuid()

-- 1. Usuários Globais
--    Hóspedes que podem reservar em múltiplos hotéis
CREATE TABLE IF NOT EXISTS usuario (
    user_id         UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    nome_completo   VARCHAR(1000)   NOT NULL,
    email           VARCHAR(100)    UNIQUE NOT NULL,
    senha           VARCHAR(255)    NOT NULL,          -- hash bcrypt
    cpf             VARCHAR(14)     UNIQUE NOT NULL,
    numero_celular  VARCHAR(20),
    data_nascimento DATE            NOT NULL,
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    ativo           BOOLEAN         NOT NULL DEFAULT TRUE
);

-- 2. Hotéis / Anfitriões
--    Cada hotel registra UMA única conta (o próprio hotel é o anfitriao).
--    O registo aqui provisiona automaticamente o banco tenant exclusivo do hotel.
CREATE TABLE IF NOT EXISTS anfitriao (
    hotel_id    UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    nome_hotel  VARCHAR(100)    NOT NULL,
    cnpj        VARCHAR(20)     UNIQUE NOT NULL,
    telefone    VARCHAR(20)     NOT NULL,
    email       VARCHAR(100)    UNIQUE NOT NULL,
    senha       VARCHAR(255)    NOT NULL,              -- hash bcrypt
    cep         VARCHAR(8)      NOT NULL,
    uf          VARCHAR(2)      NOT NULL,
    cidade      VARCHAR(100)    NOT NULL,
    bairro      VARCHAR(100)    NOT NULL,
    rua         VARCHAR(100)    NOT NULL,
    numero      VARCHAR(10)     NOT NULL,
    complemento VARCHAR(100),
    saldo       DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    descricao   VARCHAR(1000),
    path        VARCHAR(1000),                         -- caminho logo/imagem
    db_name     VARCHAR(150)    UNIQUE NOT NULL,       -- nome do banco tenant PostgreSQL
    db_dir      VARCHAR(500)    NOT NULL,              -- caminho em bancos/{id}_{nome}/
    criado_em   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    ativo       BOOLEAN         NOT NULL DEFAULT TRUE
);
