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

-- 3. Refresh Tokens (JWT — server-side revocation)
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
    schema_name VARCHAR(150)    UNIQUE NOT NULL,       -- nome do schema lógico do tenant
    criado_em   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    ativo       BOOLEAN         NOT NULL DEFAULT TRUE
);

-- 4. Chat Global (WhatsApp / App)
--    Amarrado via celular para não-logados ou user_id para logados.
CREATE TABLE IF NOT EXISTS sessao_chat (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    canal                   VARCHAR(20)     NOT NULL, -- 'WHATSAPP' ou 'APP'
    identificador_externo   VARCHAR(100),             -- WhatsApp Number ou App Device ID
    user_id                 UUID            REFERENCES usuario(user_id) ON DELETE SET NULL,
    status                  VARCHAR(20)     DEFAULT 'ABERTA', -- ABERTA, BOT_RESOLVIDO, FECHADA
    criado_em               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    atualizado_em           TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sessao_chat_identificador ON sessao_chat (identificador_externo);

CREATE TABLE IF NOT EXISTS mensagem_chat (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    sessao_chat_id  UUID            NOT NULL REFERENCES sessao_chat(id) ON DELETE CASCADE,
    origem          VARCHAR(20)     NOT NULL, -- 'CLIENTE', 'BOT_SISTEMA', 'ATENDENTE'
    conteudo        TEXT            NOT NULL,
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_msg_sessao ON mensagem_chat (sessao_chat_id);

-- 5. Tickets de Reserva Global
--    Atende reservas feitas sem cadastro prévio (boca do caixa, WhatsApp).
--    Fica no Master pois independe de estrutura rígida do Tenant e serve como entrada global.
CREATE TABLE IF NOT EXISTS ticket_reserva_global (
    codigo_ticket       UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Código único (usado para o link público do hóspede)
    user_id             UUID REFERENCES usuario(user_id) ON DELETE SET NULL, -- Caso ele tenha conta global (NULL se walk-in)
    hotel_id            UUID NOT NULL REFERENCES anfitriao(hotel_id) ON DELETE CASCADE, -- Qual hotel ele vai ficar
    nome_hospede        VARCHAR(200) NOT NULL,                  -- Nome do hóspede avulso
    telefone_contato    VARCHAR(20),                            -- Telefone/WhatsApp do cliente
    sessao_chat_id      UUID REFERENCES sessao_chat(id) ON DELETE SET NULL, -- Qual papo gerou a reserva
    tipo_quarto         VARCHAR(100) NOT NULL,                  -- Descrição textual ou codificação do quarto
    num_hospedes        INT NOT NULL DEFAULT 1,                 -- Regra de Negócio: Obrigatório
    observacoes         TEXT,                                   -- Pedidos especiais
    data_checkin        DATE NOT NULL,
    data_checkout       DATE NOT NULL,
    hora_checkin_real   TIMESTAMPTZ,                            -- Nulo até a chegada real do hóspede
    hora_checkout_real  TIMESTAMPTZ,                            -- Nulo até a saída
    valor_total         DECIMAL(10, 2) NOT NULL,
    status              VARCHAR(20) DEFAULT 'SOLICITADA',         -- SOLICITADA, AGUARDANDO_PAGAMENTO, APROVADA, CANCELADA, CONCLUIDA
    criado_em           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT chk_datas_ticket CHECK (data_checkout > data_checkin),
    CONSTRAINT chk_status_ticket CHECK (status IN ('SOLICITADA', 'AGUARDANDO_PAGAMENTO', 'APROVADA', 'CANCELADA', 'CONCLUIDA'))
);

CREATE INDEX IF NOT EXISTS idx_ticket_hotel ON ticket_reserva_global (hotel_id);

-- 5. Histórico de Reservas (Denormalização Global)
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
    valor_total         DECIMAL(10, 2) NOT NULL,
    status              VARCHAR(20) NOT NULL,                   -- APROVADA, CANCELADA, CONCLUIDA, etc
    criado_em           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE (hotel_id, reserva_tenant_id)                        -- Previne a duplicação do log da mesma reserva
);

CREATE INDEX IF NOT EXISTS idx_historico_user ON historico_reserva_global (user_id);

-- 6. Central de Push Notifications (Firebase Cloud Messaging)
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

-- 7. Hotéis Favoritos do Usuário (Master DB)
CREATE TABLE IF NOT EXISTS hotel_favorito (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID            NOT NULL REFERENCES usuario(user_id) ON DELETE CASCADE,
    hotel_id    UUID            NOT NULL REFERENCES anfitriao(hotel_id) ON DELETE CASCADE,
    criado_em   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    
    UNIQUE (user_id, hotel_id) -- Previne o mesmo usuário favoritar o mesmo hotel duas vezes
);

CREATE INDEX IF NOT EXISTS idx_hotel_favorito_user ON hotel_favorito (user_id);
