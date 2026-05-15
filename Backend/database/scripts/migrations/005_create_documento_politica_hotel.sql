-- Os arquivos salvos via POST /uploads/hotels/:hotel_id/policy são consumidos
-- pelo RagService para responder perguntas sobre política do hotel no chatbot.
-- Caminho físico: storage/hotels/:hotel_id/policies/
CREATE TABLE IF NOT EXISTS documento_politica_hotel (
  id            SERIAL PRIMARY KEY,
  hotel_id      UUID        NOT NULL REFERENCES anfitriao(hotel_id) ON DELETE CASCADE,
  storage_path  TEXT        NOT NULL,
  mime_type     TEXT        NOT NULL,
  nome_arquivo  TEXT        NOT NULL,
  criado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (hotel_id)
);
