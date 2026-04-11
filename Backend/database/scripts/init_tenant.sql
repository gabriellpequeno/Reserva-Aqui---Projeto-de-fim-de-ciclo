-- ============================================================
-- TENANT DATABASE SCHEMA — Executado para cada novo hotel
-- Este banco pertence a UM único hotel (o próprio hotel é o anfitriao).
-- Dados de registo do hotel vivem no banco master (tabela anfitriao).
-- Aqui ficam os dados operacionais exclusivos de cada hotel.
-- ============================================================

-- 1. Configuração Operacional Local do Hotel
--    Dados operácionais que o hotel gere no dia a dia.
--    Dados de cadastro (CNPJ, email, endereço...) ficam no master DB.
CREATE TABLE IF NOT EXISTS configuracao_hotel (
    hotel_id            UUID            PRIMARY KEY,   -- mesmo UUID do master (anfitriao.hotel_id)
    horario_checkin     TIME            NOT NULL DEFAULT '14:00',
    horario_checkout    TIME            NOT NULL DEFAULT '12:00',
    max_dias_reserva    INT             NOT NULL DEFAULT 30,
    telefone_recepcao   VARCHAR(20),                   -- contacto p/ hóspede (pode diferir do registo)
    politica_cancelamento TEXT,                        -- regras de cancelamento do hotel
    aceita_animais      BOOLEAN         NOT NULL DEFAULT FALSE,
    idiomas_atendimento VARCHAR(200)    NOT NULL DEFAULT 'Português',
    CONSTRAINT chk_max_dias CHECK (max_dias_reserva > 0)
);

-- 2. Hóspedes (registo local do hotel)
CREATE TABLE IF NOT EXISTS hospede (
    user_id         UUID            PRIMARY KEY,
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
    CONSTRAINT chk_categoria    CHECK (categoria IN ('COMODO', 'COMODIDADE', 'LAZER')),
    CONSTRAINT uq_catalogo      UNIQUE (nome, categoria)  -- impede item duplicado na mesma categoria
);

-- 4. Categorias de Quarto (Perfis / Tipos de quarto)
CREATE TABLE IF NOT EXISTS categoria_quarto (
    id                  SERIAL          PRIMARY KEY,
    nome                VARCHAR(50)     NOT NULL,
    preco_base          DECIMAL(10, 2)  NOT NULL,
    capacidade_pessoas  INT             NOT NULL,
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
    status          VARCHAR(20)     NOT NULL DEFAULT 'PENDENTE',
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    p_turisticos    JSONB           NOT NULL,
    CONSTRAINT chk_datas            CHECK (data_checkout > data_checkin),
    CONSTRAINT chk_valor            CHECK (valor_total > 0),
    CONSTRAINT chk_num_hosp         CHECK (num_hospedes > 0),
    CONSTRAINT chk_status           CHECK (status IN ('PENDENTE', 'CONFIRMADA', 'CANCELADA', 'CONCLUIDA'))
);

-- 10. Avaliações (apenas após reserva concluída)
CREATE TABLE IF NOT EXISTS avaliacao (
    id                      SERIAL          PRIMARY KEY,
    user_id                 UUID            NOT NULL REFERENCES hospede(user_id)  ON DELETE CASCADE,
    reserva_id              INT             NOT NULL REFERENCES reserva(id)       ON DELETE CASCADE,
    nota_limpeza            INT             NOT NULL,
    nota_atendimento        INT             NOT NULL,
    nota_conforto           INT             NOT NULL,
    nota_organizacao        INT             NOT NULL,
    nota_localizacao        INT             NOT NULL,
    nota_total              INT             NOT NULL,
    comentario              TEXT,
    criado_em               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, reserva_id),                              -- uma avaliação por estadia
    CONSTRAINT chk_nota_limpeza         CHECK (nota_limpeza         BETWEEN 1 AND 5),
    CONSTRAINT chk_nota_atendimento     CHECK (nota_atendimento     BETWEEN 1 AND 5),
    CONSTRAINT chk_nota_conforto        CHECK (nota_conforto        BETWEEN 1 AND 5),
    CONSTRAINT chk_nota_custo           CHECK (nota_custo_beneficio BETWEEN 1 AND 5),
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
