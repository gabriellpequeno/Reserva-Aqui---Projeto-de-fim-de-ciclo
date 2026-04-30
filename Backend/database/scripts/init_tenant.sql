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

-- 2. Hóspedes (registro de membership local do hotel)
--    Dados pessoais (nome, CPF, email, etc.) ficam no master em public.usuario.
--    Esta tabela indica que o usuário já realizou ao menos uma reserva neste hotel.
--    Para dados pessoais: JOIN public.usuario ON public.usuario.user_id = hospede.user_id
CREATE TABLE IF NOT EXISTS hospede (
    user_id         UUID            PRIMARY KEY REFERENCES public.usuario(user_id) ON DELETE CASCADE,
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

-- 7. Itens do Quarto (quarto ↔ itens do catálogo com categoria 'COMODO' ou 'COMODIDADE')
--    Unifica cômodos e comodidades em uma só tabela — o campo catalogo.categoria discrimina o tipo.
--    Ex: Suíte 101 → 2 banheiros (COMODO), 2 camas king (COMODIDADE), 1 ar condicionado (COMODIDADE)
--
--    Filtrar cômodos:     JOIN catalogo WHERE categoria = 'COMODO'
--    Filtrar comodidades: JOIN catalogo WHERE categoria = 'COMODIDADE'
--    Listar tudo:         JOIN catalogo (sem WHERE, ordenado por categoria)
--
--    Nota: itens de categoria 'LAZER' pertencem ao hotel (via categoria_item), não ao quarto físico.
CREATE TABLE IF NOT EXISTS itens_do_quarto (
    quarto_id   INT     NOT NULL REFERENCES quarto(id)   ON DELETE CASCADE,
    catalogo_id INT     NOT NULL REFERENCES catalogo(id) ON DELETE RESTRICT,
    quantidade  INT     NOT NULL DEFAULT 1,
    PRIMARY KEY (quarto_id, catalogo_id),
    CONSTRAINT chk_qtd_item CHECK (quantidade > 0)
);

-- 8. Reservas (Unificada — cobre hóspedes registrados e walk-ins)
--
--    Hóspede registrado:  user_id preenchido, user_id IS NOT NULL
--    Walk-in:             user_id = NULL, usa nome_hospede + cpf_hospede como identificador
--    Quarto atribuído:    quarto_id preenchido
--    Quarto não definido: quarto_id = NULL, usa tipo_quarto como texto livre
--
--    Acesso ao ticket:
--      - Por hóspede registrado:    WHERE user_id = ?
--      - Por walk-in (CPF):         WHERE cpf_hospede = ?
--      - Por link público (app/WA): WHERE codigo_publico = ?  (+ lookup em reserva_routing no master)
--      - Por hotel:                 todas as reservas no próprio schema
CREATE TABLE IF NOT EXISTS reserva (
    id                  SERIAL          PRIMARY KEY,
    codigo_publico      UUID            UNIQUE NOT NULL DEFAULT gen_random_uuid(), -- link de acesso público (walk-in / app)

    -- Identificação do hóspede (registrado OU walk-in — pelo menos um campo obrigatório)
    user_id             UUID            REFERENCES hospede(user_id)  ON DELETE RESTRICT, -- NULL para walk-ins
    nome_hospede        VARCHAR(200),                                                     -- walk-in: nome completo
    cpf_hospede         VARCHAR(14),                                                      -- walk-in: CPF (identificador)
    telefone_contato    VARCHAR(20),                                                      -- walk-in: WhatsApp / telefone

    -- Origem da reserva
    canal_origem        VARCHAR(20)     NOT NULL DEFAULT 'APP',               -- 'APP', 'WHATSAPP', 'BALCAO'
    sessao_chat_id      UUID            REFERENCES public.sessao_chat(id) ON DELETE SET NULL,

    -- Quarto (atribuído OU textual — pelo menos um campo obrigatório)
    quarto_id           INT             REFERENCES quarto(id) ON DELETE RESTRICT, -- NULL até atribuição
    tipo_quarto         VARCHAR(100),                                               -- fallback textual (walk-in / pré-atribuição)

    -- Dados da estadia
    num_hospedes        INT             NOT NULL DEFAULT 1,
    data_checkin        DATE            NOT NULL,
    data_checkout       DATE            NOT NULL,
    hora_checkin_real   TIMESTAMPTZ,                                 -- preenchido na chegada real
    hora_checkout_real  TIMESTAMPTZ,                                 -- preenchido na saída real
    valor_total         DECIMAL(10, 2)  NOT NULL,
    observacoes         TEXT,
    p_turisticos        JSONB,                                       -- pontos turísticos (nullable para walk-ins)
    status              VARCHAR(20)     NOT NULL DEFAULT 'SOLICITADA',
    criado_em           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Integridade
    CONSTRAINT chk_datas        CHECK (data_checkout > data_checkin),
    CONSTRAINT chk_valor        CHECK (valor_total > 0),
    CONSTRAINT chk_num_hosp     CHECK (num_hospedes > 0),
    CONSTRAINT chk_status       CHECK (status IN ('SOLICITADA', 'AGUARDANDO_PAGAMENTO', 'APROVADA', 'CANCELADA', 'CONCLUIDA')),
    CONSTRAINT chk_canal        CHECK (canal_origem IN ('APP', 'WHATSAPP', 'BALCAO')),

    -- Identificação do hóspede opcional para walk-ins de balcão (bloqueio de agenda sem hóspede definido)
    CONSTRAINT chk_hospede_identificado CHECK (
        canal_origem = 'BALCAO'
        OR user_id IS NOT NULL
        OR (nome_hospede IS NOT NULL AND (cpf_hospede IS NOT NULL OR telefone_contato IS NOT NULL))
    ),

    -- Garante que o quarto pode ser determinado
    CONSTRAINT chk_quarto_identificado CHECK (
        quarto_id IS NOT NULL OR tipo_quarto IS NOT NULL
    )
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
    CONSTRAINT chk_nota_organizacao     CHECK (nota_organizacao     BETWEEN 1 AND 5),
    CONSTRAINT chk_nota_localizacao     CHECK (nota_localizacao     BETWEEN 1 AND 5)
);

-- ============================================================
-- ÍNDICES DE PERFORMANCE
-- ============================================================

-- Reservas: busca por hóspede, quarto, datas, status e acesso público
CREATE INDEX IF NOT EXISTS idx_reserva_user            ON reserva (user_id);
CREATE INDEX IF NOT EXISTS idx_reserva_quarto          ON reserva (quarto_id);
CREATE INDEX IF NOT EXISTS idx_reserva_datas           ON reserva (data_checkin, data_checkout);
CREATE INDEX IF NOT EXISTS idx_reserva_status          ON reserva (status);
CREATE INDEX IF NOT EXISTS idx_reserva_codigo_publico  ON reserva (codigo_publico);   -- acesso por link público
CREATE INDEX IF NOT EXISTS idx_reserva_cpf_hospede     ON reserva (cpf_hospede);      -- walk-in: busca por CPF
CREATE INDEX IF NOT EXISTS idx_reserva_canal           ON reserva (canal_origem);

-- Quartos: busca por disponibilidade e perfil
CREATE INDEX IF NOT EXISTS idx_quarto_disponivel       ON quarto (disponivel);
CREATE INDEX IF NOT EXISTS idx_quarto_categoria        ON quarto (categoria_quarto_id);

-- Catálogo: busca por categoria (COMODO / COMODIDADE / LAZER)
CREATE INDEX IF NOT EXISTS idx_catalogo_categoria      ON catalogo (categoria);

-- Itens do Quarto: busca por quarto
CREATE INDEX IF NOT EXISTS idx_itens_quarto_id         ON itens_do_quarto (quarto_id);

-- Avaliações: média por aspecto (relatórios de qualidade do hotel)
CREATE INDEX IF NOT EXISTS idx_avaliacao_reserva       ON avaliacao (reserva_id);

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

-- 13. Fotos dos Quartos
--    Cada quarto pode ter até 10 fotos (sem distincão de orientação).
--    O Flutter exibe as fotos em carrossel indistintamente.
--    Limite total controlado via UPLOAD_MAX_ROOM_PHOTOS no .env (default: 10).
CREATE TABLE IF NOT EXISTS quarto_foto (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    quarto_id       INT             NOT NULL REFERENCES quarto(id) ON DELETE CASCADE,
    storage_path    TEXT            NOT NULL,     -- caminho relativo a UPLOAD_DIR (nunca URL pública)
    ordem           INT             NOT NULL DEFAULT 0,  -- ordem de exibição (0 = primeiro)
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quarto_foto_quarto_id   ON quarto_foto (quarto_id);

