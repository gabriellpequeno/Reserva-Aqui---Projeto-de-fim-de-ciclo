-- ============================================================
-- MASTER DATABASE SCHEMA — reservaqui_master
-- Tabelas globais: hoteis (anfitriões) e usuários (hóspedes)
-- Modelo: 1 hotel = 1 anfitriao = 1 banco tenant próprio
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- para gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "vector";     -- pgvector — busca por similaridade
CREATE EXTENSION IF NOT EXISTS "unaccent";   -- busca acento-insensitive

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

-- 2. Refresh Tokens de Usuário (JWT — server-side revocation)
--    Cada login emite um refresh token armazenado aqui.
--    O logout, o change-password e a desativação da conta invalidam todos os tokens do user.
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID            NOT NULL REFERENCES usuario(user_id) ON DELETE CASCADE,
    token_hash  VARCHAR(255)    NOT NULL UNIQUE,   -- SHA-256 do token (nunca armazenar o token raw)
    expires_at  TIMESTAMPTZ     NOT NULL,
    criado_em   TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens (user_id);

-- 3. Hotéis / Anfitriões
--    Cada hotel registra UMA única conta (o próprio hotel é o anfitriao).
--    O registo aqui provisiona automaticamente o banco tenant exclusivo do hotel.
CREATE TABLE IF NOT EXISTS anfitriao (
    hotel_id    UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    nome_hotel  VARCHAR(100)    NOT NULL,
    cnpj        VARCHAR(20)     UNIQUE NOT NULL,
    telefone    VARCHAR(20)     NOT NULL,
    email       VARCHAR(100)    UNIQUE NOT NULL,
    senha       VARCHAR(255)    NOT NULL,              -- hash argon2id
    cep         VARCHAR(8)      NOT NULL,
    uf          VARCHAR(2)      NOT NULL,
    cidade      VARCHAR(100)    NOT NULL,
    bairro      VARCHAR(100)    NOT NULL,
    rua         VARCHAR(100)    NOT NULL,
    numero      VARCHAR(10)     NOT NULL,
    complemento VARCHAR(100),
    saldo       DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    descricao   VARCHAR(1000),
    cover_storage_path TEXT,                       -- caminho relativo a UPLOAD_DIR (foto de capa)
    schema_name VARCHAR(150)    UNIQUE NOT NULL,       -- nome do schema lógico do tenant
    criado_em   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    ativo       BOOLEAN         NOT NULL DEFAULT TRUE
);

-- 4. Refresh Tokens de Hotel / Anfitrião (JWT — server-side revocation)
--    Isolado da tabela de usuários para evitar cruzamento de contextos de sessão.
--    Segue a mesma política de invalidação: logout, change-password e desativação revogam todos.
CREATE TABLE IF NOT EXISTS hotel_refresh_tokens (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    hotel_id    UUID            NOT NULL REFERENCES anfitriao(hotel_id) ON DELETE CASCADE,
    token_hash  VARCHAR(255)    NOT NULL UNIQUE,   -- SHA-256 do token (nunca armazenar o token raw)
    expires_at  TIMESTAMPTZ     NOT NULL,
    criado_em   TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hotel_refresh_tokens_hotel ON hotel_refresh_tokens (hotel_id);

-- 5. Chat Global (WhatsApp / App)
--    Amarrado via celular para não-logados ou user_id para logados.
CREATE TABLE IF NOT EXISTS sessao_chat (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    canal                   VARCHAR(20)     NOT NULL, -- 'WHATSAPP' ou 'APP'
    identificador_externo   VARCHAR(100),             -- WhatsApp Number ou App Device ID
    hotel_id                UUID            REFERENCES anfitriao(hotel_id) ON DELETE SET NULL,
    user_id                 UUID            REFERENCES usuario(user_id) ON DELETE SET NULL,
    status                  VARCHAR(20)     DEFAULT 'ABERTA', -- ABERTA, BOT_RESOLVIDO, FECHADA
    criado_em               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    atualizado_em           TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sessao_chat_identificador ON sessao_chat (identificador_externo);
CREATE INDEX IF NOT EXISTS idx_sessao_chat_canal_identificador_status
    ON sessao_chat (canal, identificador_externo, status);
CREATE INDEX IF NOT EXISTS idx_sessao_chat_hotel_identificador_status
    ON sessao_chat (hotel_id, identificador_externo, status);

CREATE TABLE IF NOT EXISTS mensagem_chat (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    sessao_chat_id  UUID            NOT NULL REFERENCES sessao_chat(id) ON DELETE CASCADE,
    origem          VARCHAR(20)     NOT NULL, -- 'CLIENTE', 'BOT_SISTEMA', 'ATENDENTE'
    conteudo        TEXT            NOT NULL,
    tipo_mensagem   VARCHAR(20)     NOT NULL DEFAULT 'TEXT',
    meta_message_id VARCHAR(100),
    meta_status     VARCHAR(30),
    metadata_json   JSONB,
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_msg_sessao ON mensagem_chat (sessao_chat_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_mensagem_chat_meta_message_id
    ON mensagem_chat (meta_message_id)
    WHERE meta_message_id IS NOT NULL;

-- 6. Roteamento de Reservas Públicas (Walk-in / WhatsApp)
--    Mapeia o codigo_publico → hotel_id + schema_name, permitindo ao backend
--    localizar o tenant correto antes de buscar os detalhes da reserva.
--    Os dados completos da reserva (incluindo walk-ins) vivem em reserva (tenant).
CREATE TABLE IF NOT EXISTS reserva_routing (
    codigo_publico  UUID            PRIMARY KEY,                              -- mesmo UUID que reserva.codigo_publico no tenant
    hotel_id        UUID            NOT NULL REFERENCES anfitriao(hotel_id) ON DELETE CASCADE,
    schema_name     VARCHAR(150)    NOT NULL,                                 -- schema do tenant (ex: schema_hotel_xyz)
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reserva_routing_hotel ON reserva_routing (hotel_id);

-- 7. Histórico de Reservas (Denormalização Global)
--    Sincronizado automaticamente pelo backend a partir do DB do Tenant.
--    Permite listagem rápida do histórico do hóspede sem iterar pelos bancos dos hotéis.
CREATE TABLE IF NOT EXISTS historico_reserva_global (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES usuario(user_id) ON DELETE CASCADE,
    hotel_id            UUID NOT NULL REFERENCES anfitriao(hotel_id) ON DELETE CASCADE,
    reserva_tenant_id   INT NOT NULL,                           -- O ID físico da reserva no banco do Tenant
    nome_hotel          VARCHAR(100) NOT NULL,                  -- Cache do nome (evita JOIN desnecessário)
    tipo_quarto         VARCHAR(100) NOT NULL,                  -- Cache do quarto ou categoria
    data_checkin        DATE NOT NULL,
    data_checkout       DATE NOT NULL,
    num_hospedes        INT NOT NULL DEFAULT 1,                 -- Cache do núm. de hóspedes
    valor_total         DECIMAL(10, 2) NOT NULL,
    status              VARCHAR(20) NOT NULL,                   -- APROVADA, CANCELADA, CONCLUIDA, etc
    criado_em           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (hotel_id, reserva_tenant_id)                        -- Previne a duplicação do log da mesma reserva
);

CREATE INDEX IF NOT EXISTS idx_historico_user ON historico_reserva_global (user_id);

-- 8. Central de Push Notifications (Firebase Cloud Messaging)
--    Rastreia aparelhos logados (tanto do app Hóspede quanto do Dashboard Anfitrião)
CREATE TABLE IF NOT EXISTS dispositivo_fcm (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            REFERENCES usuario(user_id) ON DELETE CASCADE,
    hotel_id        UUID            REFERENCES anfitriao(hotel_id) ON DELETE CASCADE,
    fcm_token       VARCHAR(255)    UNIQUE NOT NULL,
    origem          VARCHAR(50),    -- 'DASHBOARD_WEB', 'APP_IOS', 'APP_ANDROID'
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    atualizado_em   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_fcm_proprietario CHECK (
        (user_id IS NOT NULL AND hotel_id IS NULL) OR
        (user_id IS NULL AND hotel_id IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_fcm_user ON dispositivo_fcm (user_id);
CREATE INDEX IF NOT EXISTS idx_fcm_hotel ON dispositivo_fcm (hotel_id);

-- 9. Hotéis Favoritos do Usuário (Master DB)
CREATE TABLE IF NOT EXISTS hotel_favorito (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID            NOT NULL REFERENCES usuario(user_id) ON DELETE CASCADE,
    hotel_id    UUID            NOT NULL REFERENCES anfitriao(hotel_id) ON DELETE CASCADE,
    criado_em   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    UNIQUE (user_id, hotel_id) -- Previne o mesmo usuário favoritar o mesmo hotel duas vezes
);

CREATE INDEX IF NOT EXISTS idx_hotel_favorito_user ON hotel_favorito (user_id);

-- 10. Fotos de Capa do Hotel (Master DB)
--     Cada hotel pode ter até UPLOAD_MAX_HOTEL_COVER fotos por orientação.
--     Portrait e landscape são contados separadamente (5 portrait + 5 landscape = 10 total).
--     O Flutter seleciona a orientação correta conforme a tela do dispositivo.
CREATE TABLE IF NOT EXISTS foto_hotel (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    hotel_id        UUID            NOT NULL REFERENCES anfitriao(hotel_id) ON DELETE CASCADE,
    storage_path    TEXT            NOT NULL,     -- caminho relativo a UPLOAD_DIR (nunca URL pública)
    orientacao      VARCHAR(10)     NOT NULL,     -- 'portrait' | 'landscape'
    ordem           INT             NOT NULL DEFAULT 0,
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_foto_hotel_orientacao CHECK (orientacao IN ('portrait', 'landscape'))
);

CREATE INDEX IF NOT EXISTS idx_foto_hotel_hotel_id   ON foto_hotel (hotel_id);
CREATE INDEX IF NOT EXISTS idx_foto_hotel_orientacao ON foto_hotel (hotel_id, orientacao);

-- 11. Saldo de Transações do Hotel
--     Rastreia créditos (checkout), taxas (walk-in) e saques solicitados.
--     O campo saldo em anfitriao é o valor corrente; esta tabela é o audit trail.
CREATE TABLE IF NOT EXISTS saldo_transacao (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    hotel_id        UUID            NOT NULL REFERENCES anfitriao(hotel_id) ON DELETE CASCADE,
    tipo            VARCHAR(20)     NOT NULL,
    valor_bruto     DECIMAL(12, 2)  NOT NULL,
    taxa            DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    valor_liquido   DECIMAL(12, 2)  NOT NULL,
    descricao       VARCHAR(255)    NOT NULL,
    reserva_id      INT,
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_saldo_tipo  CHECK (tipo IN ('CREDITO_CHECKOUT', 'TAXA_WALKIN', 'SAQUE_SOLICITADO')),
    CONSTRAINT chk_saldo_bruto CHECK (valor_bruto > 0),
    CONSTRAINT chk_saldo_taxa  CHECK (taxa >= 0)
);

CREATE INDEX IF NOT EXISTS idx_saldo_transacao_hotel ON saldo_transacao (hotel_id, criado_em DESC);

-- 12. RAG Documentos de IA (pgvector)
--     Armazena fragmentos de texto (FAQ, políticas, amenidades) do hotel.
--     Usado pela IA via LangChain para similarity search (buscas contextuais).
CREATE TABLE IF NOT EXISTS documento_hotel (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    hotel_id        UUID            NOT NULL REFERENCES anfitriao(hotel_id) ON DELETE CASCADE,
    metadata        JSONB           NOT NULL DEFAULT '{}'::jsonb,
    content         TEXT            NOT NULL,
    embedding       VECTOR(3072),   -- 3072 é a dimensão padrão dos novos embeddings do Gemini (gemini-embedding-001 / 2)
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documento_hotel_id ON documento_hotel (hotel_id);
