-- ============================================================
-- TENANT SCHEMA PLAN — Executado dentro de um novo SCHEMA para cada hotel
-- Este script roda no banco de dados MASTER, isolado em um SCHEMA (ex: schema_hotel_xyz).
-- Dados globais de faturamento ficam no schema 'public' (tabela anfitriao).
-- Aqui ficam os dados operacionais exclusivos de cada hotel.
-- ============================================================

-- 1. Configuração Operacional Local do Hotel
--    Dados operácionais que o hotel gere no dia a dia.
--    Dados de cadastro (CNPJ, email, endereço...) ficam no master DB.
CREATE TABLE IF NOT EXISTS configuracao_hotel (
    hotel_id              UUID            PRIMARY KEY REFERENCES public.anfitriao(hotel_id) ON DELETE CASCADE,   -- mesmo UUID do master (anfitriao.hotel_id)
    horario_checkin       TIME            NOT NULL DEFAULT '14:00',
    horario_checkout      TIME            NOT NULL DEFAULT '12:00',
    max_dias_reserva      INT             NOT NULL DEFAULT 30,
    telefone_recepcao     VARCHAR(20),                   -- contacto p/ hóspede (pode diferir do registo)
    politica_cancelamento TEXT,                        -- regras de cancelamento do hotel
    aceita_animais        BOOLEAN         NOT NULL DEFAULT FALSE,
    idiomas_atendimento   VARCHAR(200)    NOT NULL DEFAULT 'Português',
    CONSTRAINT chk_max_dias CHECK (max_dias_reserva > 0)
);

-- 2. Hóspedes (registo local do hotel)
CREATE TABLE IF NOT EXISTS hospede (
    user_id         UUID            PRIMARY KEY REFERENCES public.usuario(user_id) ON DELETE CASCADE,
    nome_completo   VARCHAR(1000)   NOT NULL,
    cpf             VARCHAR(14)     UNIQUE NOT NULL,
    data_nascimento DATE            NOT NULL,
    email           VARCHAR(100)    UNIQUE,
    telefone        VARCHAR(20),
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- 3. Catálogo Local (O hotel define cômodos, comodidades e lazer)
CREATE TABLE IF NOT EXISTS catalogo (
    id          SERIAL          PRIMARY KEY,
    nome        VARCHAR(100)    NOT NULL,
    categoria   VARCHAR(30)     NOT NULL,    -- 'COMODO' | 'COMODIDADE' | 'LAZER'
    deleted_at  TIMESTAMPTZ,
    CONSTRAINT chk_categoria    CHECK (categoria IN ('COMODO', 'COMODIDADE', 'LAZER')),
    CONSTRAINT uq_catalogo      UNIQUE (nome, categoria)  -- impede item duplicado na mesma categoria
);

-- 4. Categorias de Quarto (Perfis / Tipos de quarto)
CREATE TABLE IF NOT EXISTS categoria_quarto (
    id                  SERIAL          PRIMARY KEY,
    nome                VARCHAR(50)     NOT NULL,
    preco_base          DECIMAL(10, 2)  NOT NULL,
    capacidade_pessoas  INT             NOT NULL,
    deleted_at          TIMESTAMPTZ,
    CONSTRAINT chk_preco    CHECK (preco_base > 0),
    CONSTRAINT chk_cap      CHECK (capacidade_pessoas > 0)
);

-- 5. Itens do Molde (Categoria ↔ Catálogo)
CREATE TABLE IF NOT EXISTS categoria_item (
    categoria_quarto_id INT     REFERENCES categoria_quarto(id) ON DELETE CASCADE,
    catalogo_id         INT     REFERENCES catalogo(id)         ON DELETE RESTRICT,
    quantidade          INT     NOT NULL DEFAULT 1,
    PRIMARY KEY (categoria_quarto_id, catalogo_id),
    CONSTRAINT chk_qtd CHECK (quantidade > 0)
);

-- 6. Quarto Físico
CREATE TABLE IF NOT EXISTS quarto (
    id                  SERIAL          PRIMARY KEY,
    categoria_quarto_id INT             REFERENCES categoria_quarto(id) ON DELETE RESTRICT,
    numero              VARCHAR(10)     NOT NULL UNIQUE,
    disponivel          BOOLEAN         NOT NULL DEFAULT TRUE,
    descricao           VARCHAR(500),                          -- descrição individual do quarto
    valor_override      DECIMAL(10, 2),                       -- preço customizado (sobrescreve preco_base do perfil)
    deleted_at          TIMESTAMPTZ,
    CONSTRAINT chk_valor_override CHECK (valor_override IS NULL OR valor_override > 0)
);

-- 7. Cômodos do Quarto (quarto ↔ itens do catálogo com categoria 'COMODO')
--    Ex: Suíte 101 possui 2 banheiros, 1 sala de estar, 3 quartos
CREATE TABLE IF NOT EXISTS comodos_do_quarto (
    quarto_id   INT     NOT NULL REFERENCES quarto(id)   ON DELETE CASCADE,
    catalogo_id INT     NOT NULL REFERENCES catalogo(id) ON DELETE RESTRICT,
    quantidade  INT     NOT NULL DEFAULT 1,
    PRIMARY KEY (quarto_id, catalogo_id),
    CONSTRAINT chk_qtd_comodo CHECK (quantidade > 0)
);

-- 8. Comodidades do Quarto (quarto ↔ itens do catálogo com categoria 'COMODIDADE')
--    Ex: Suíte 101 possui 2 camas king, 1 ar condicionado, Wi-Fi, kit de higiene
CREATE TABLE IF NOT EXISTS comodidades_do_quarto (
    quarto_id   INT     NOT NULL REFERENCES quarto(id)   ON DELETE CASCADE,
    catalogo_id INT     NOT NULL REFERENCES catalogo(id) ON DELETE RESTRICT,
    quantidade  INT     NOT NULL DEFAULT 1,
    PRIMARY KEY (quarto_id, catalogo_id),
    CONSTRAINT chk_qtd_comodidade CHECK (quantidade > 0)
);

-- 9. Reservas
CREATE TABLE IF NOT EXISTS reserva (
    id              SERIAL          PRIMARY KEY,
    user_id         UUID            NOT NULL REFERENCES hospede(user_id)  ON DELETE RESTRICT,
    quarto_id       INT             NOT NULL REFERENCES quarto(id)        ON DELETE RESTRICT,
    data_checkin    DATE            NOT NULL,
    data_checkout   DATE            NOT NULL,
    valor_total     DECIMAL(10, 2)  NOT NULL,
    num_hospedes    INT             NOT NULL DEFAULT 1,
    observacoes     TEXT,                                     -- pedidos especiais do hóspede
    status          VARCHAR(20)     NOT NULL DEFAULT 'SOLICITADA',
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    p_turisticos    JSONB           NOT NULL,
    CONSTRAINT chk_datas            CHECK (data_checkout > data_checkin),
    CONSTRAINT chk_valor            CHECK (valor_total > 0),
    CONSTRAINT chk_num_hosp         CHECK (num_hospedes > 0),
    CONSTRAINT chk_status           CHECK (status IN ('SOLICITADA', 'AGUARDANDO_PAGAMENTO', 'APROVADA', 'CANCELADA', 'CONCLUIDA'))
);

-- 10. Avaliações (apenas após reserva concluída)
CREATE TABLE IF NOT EXISTS avaliacao (
    id                      SERIAL          PRIMARY KEY,
    user_id                 UUID            NOT NULL REFERENCES hospede(user_id)  ON DELETE CASCADE,
    reserva_id              INT             NOT NULL REFERENCES reserva(id)       ON DELETE CASCADE,
    nota_limpeza            INT             NOT NULL,
    nota_geral              INT             NOT NULL,
    nota_conforto           INT             NOT NULL,
    nota_organizacao        INT             NOT NULL,
    nota_localizacao        INT             NOT NULL,
    nota_total              INT             NOT NULL,
    comentario              TEXT,
    criado_em               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, reserva_id),                              -- uma avaliação por estadia
    CONSTRAINT chk_nota_limpeza         CHECK (nota_limpeza         BETWEEN 1 AND 5),
    CONSTRAINT chk_nota_geral           CHECK (nota_geral           BETWEEN 1 AND 5),
    CONSTRAINT chk_nota_conforto        CHECK (nota_conforto        BETWEEN 1 AND 5),
    CONSTRAINT chk_nota_organizacao     CHECK (nota_organizacao     BETWEEN 1 AND 5),
    CONSTRAINT chk_nota_localizacao     CHECK (nota_localizacao     BETWEEN 1 AND 5)
);

-- ============================================================
-- ÍNDICES DE PERFORMANCE
-- ============================================================

-- Reservas: busca por hóspede, quarto e intervalo de datas (queries mais frequentes)
CREATE INDEX IF NOT EXISTS idx_reserva_user         ON reserva (user_id);
CREATE INDEX IF NOT EXISTS idx_reserva_quarto       ON reserva (quarto_id);
CREATE INDEX IF NOT EXISTS idx_reserva_datas        ON reserva (data_checkin, data_checkout);
CREATE INDEX IF NOT EXISTS idx_reserva_status       ON reserva (status);

-- Quartos: busca por disponibilidade e perfil
CREATE INDEX IF NOT EXISTS idx_quarto_disponivel    ON quarto (disponivel);
CREATE INDEX IF NOT EXISTS idx_quarto_categoria     ON quarto (categoria_quarto_id);

-- Catálogo: busca por categoria (COMODO / COMODIDADE / LAZER)
CREATE INDEX IF NOT EXISTS idx_catalogo_categoria   ON catalogo (categoria);

-- Avaliações: média por aspecto (relatórios de qualidade do hotel)
CREATE INDEX IF NOT EXISTS idx_avaliacao_reserva    ON avaliacao (reserva_id);

-- 11. Pagamento de Reservas (Tracking Financeiro do Hotel)
CREATE TABLE IF NOT EXISTS pagamento_reserva (
    id                  SERIAL          PRIMARY KEY,
    reserva_id          INT             NOT NULL REFERENCES reserva(id) ON DELETE CASCADE,
    valor_pago          DECIMAL(10, 2)  NOT NULL,
    forma_pagamento     VARCHAR(50)     NOT NULL, -- Ex: 'PIX', 'CARTAO_CREDITO', 'DINHEIRO'
    status              VARCHAR(20)     NOT NULL DEFAULT 'APROVADO', -- 'PENDENTE', 'APROVADO', 'ESTORNADO'
    checkout_url        TEXT,                                 -- Link de pagamento (InfinitePay)
    infinite_invoice_slug VARCHAR(100),                       -- Código da fatura (Webhook)
    transaction_nsu     VARCHAR(100),                         -- NSU da transação (Webhook)
    metodo_captura      VARCHAR(50),                          -- credit_card ou pix (Webhook)
    recibo_url          TEXT,                                 -- receipt_url (Webhook)
    data_pagamento      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    
    CONSTRAINT chk_valor_pago CHECK (valor_pago > 0)
);

CREATE INDEX IF NOT EXISTS idx_pagamento_reserva_id ON pagamento_reserva (reserva_id);

-- Índices de Soft Delete (Para otimizar visualizações do frontend ocultando lixeiras)
CREATE INDEX IF NOT EXISTS idx_quarto_ativo           ON quarto (deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_cat_quarto_ativo       ON categoria_quarto (deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_catalogo_ativo         ON catalogo (deleted_at) WHERE deleted_at IS NULL;

-- 12. Inbox de Notificações Corporativas do Hotel (Fallback do Push/App)
CREATE TABLE IF NOT EXISTS notificacao_hotel (
    id              SERIAL          PRIMARY KEY,
    titulo          VARCHAR(200)    NOT NULL,
    mensagem        TEXT            NOT NULL,
    tipo            VARCHAR(50)     NOT NULL, -- Ex: 'NOVA_RESERVA', 'MENSAGEM_CHAT', 'APROVACAO_RESERVA'
    lida_em         TIMESTAMPTZ,              -- Se NULL, indica mensagem não lida
    acao_requerida  VARCHAR(100),             -- Se a notificacao for acionavel (ex: 'GERAR_PAGAMENTO_INFINITEPAY')
    acao_concluida  BOOLEAN         NOT NULL DEFAULT FALSE,
    payload         JSONB,                    -- Permite armazenar metadados para cliques na interface
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notificacao_pendente ON notificacao_hotel (lida_em) WHERE lida_em IS NULL;
