/**
 * Testes dos helpers puros do fluxo FAKE de pagamento.
 *
 * Contexto: o webhook real da InfinitePay existe no código mas não está
 * em uso (sem documentação de sandbox no momento). O fluxo que efetivamente
 * roda em dev/apresentação é o "fake" — ver `_createPagamentoFake`,
 * `_confirmarPagamentoFake`, `_cancelarPagamentoFake`. Estes testes cobrem
 * a fatia pura desse fluxo: validação de forma_pagamento, expiração de link
 * e formatação do resumo retornado ao frontend.
 *
 * Mockamos masterDb e schemaWrapper para que o módulo possa ser carregado
 * sem conexão real ao Postgres.
 */
jest.mock("../../database/masterDb", () => ({
  masterPool: { query: jest.fn() },
}));
jest.mock("../../database/schemaWrapper", () => ({
  withTenant: jest.fn(),
}));

import {
  MODALIDADES_FAKE,
  isFormaPagamentoValida,
  isLinkPagamentoExpirado,
  toPagamentoResumo,
} from "../pagamentoReserva.service";

describe("MODALIDADES_FAKE", () => {
  it("contém exatamente as três modalidades aceitas pelo simulador", () => {
    expect(MODALIDADES_FAKE).toEqual(["PIX", "CARTAO_CREDITO", "CARTAO_DEBITO"]);
  });
});

describe("isFormaPagamentoValida()", () => {
  it.each(["PIX", "CARTAO_CREDITO", "CARTAO_DEBITO"])(
    "aceita modalidade válida %s",
    (forma) => {
      expect(isFormaPagamentoValida(forma)).toBe(true);
    }
  );

  it.each([
    ["string desconhecida", "BOLETO"],
    ["lower-case", "pix"],
    ["mixed-case", "Pix"],
    ["string vazia", ""],
    ["null", null],
    ["undefined", undefined],
    ["número", 1],
    ["objeto", { forma: "PIX" }],
  ])("rejeita %s", (_label, value) => {
    expect(isFormaPagamentoValida(value)).toBe(false);
  });
});

describe("isLinkPagamentoExpirado()", () => {
  const NOW = new Date("2026-05-12T14:30:00.000Z");

  it("retorna false quando expires_at é null (canal APP, sem TTL)", () => {
    expect(isLinkPagamentoExpirado(null, NOW)).toBe(false);
  });

  it("retorna false quando expires_at é undefined", () => {
    expect(isLinkPagamentoExpirado(undefined, NOW)).toBe(false);
  });

  it("retorna false para Date no futuro", () => {
    const future = new Date(NOW.getTime() + 60_000);
    expect(isLinkPagamentoExpirado(future, NOW)).toBe(false);
  });

  it("retorna true para Date no passado", () => {
    const past = new Date(NOW.getTime() - 60_000);
    expect(isLinkPagamentoExpirado(past, NOW)).toBe(true);
  });

  it("aceita string ISO no futuro como não-expirada", () => {
    expect(isLinkPagamentoExpirado("2026-05-12T15:00:00.000Z", NOW)).toBe(false);
  });

  it("aceita string ISO no passado como expirada", () => {
    expect(isLinkPagamentoExpirado("2026-05-12T14:00:00.000Z", NOW)).toBe(true);
  });

  it("usa `new Date()` como now padrão quando não fornecido", () => {
    // Garantia: a ausência de `now` não muda o comportamento qualitativo.
    const farFuture = new Date(Date.now() + 24 * 60 * 60 * 1000);
    const farPast = new Date(Date.now() - 24 * 60 * 60 * 1000);
    expect(isLinkPagamentoExpirado(farFuture)).toBe(false);
    expect(isLinkPagamentoExpirado(farPast)).toBe(true);
  });

  it("trata 'expires_at exatamente igual a now' como NÃO-expirado (< estrito)", () => {
    const equal = new Date(NOW.getTime());
    expect(isLinkPagamentoExpirado(equal, NOW)).toBe(false);
  });
});

describe("toPagamentoResumo()", () => {
  it("monta o resumo completo a partir dos campos do row", () => {
    const r = toPagamentoResumo(
      {
        id: 42,
        reserva_id: 7,
        status: "PENDENTE",
        expires_at: null,
      },
      "ABC123",
      "199.90"
    );

    expect(r).toEqual({
      pagamento_id: 42,
      reserva_id: 7,
      codigo_publico: "ABC123",
      status: "PENDENTE",
      valor_total: "199.90",
      expires_at: null,
      modalidades: MODALIDADES_FAKE,
    });
  });

  it("converte expires_at do tipo Date para ISO string", () => {
    const expires = new Date("2026-05-12T18:00:00.000Z");
    const r = toPagamentoResumo(
      { id: 1, reserva_id: 1, status: "PENDENTE", expires_at: expires },
      "X",
      "100"
    );
    expect(r.expires_at).toBe("2026-05-12T18:00:00.000Z");
  });

  it("preserva expires_at quando já é string", () => {
    const r = toPagamentoResumo(
      {
        id: 1,
        reserva_id: 1,
        status: "PENDENTE",
        expires_at: "2026-05-12T18:00:00.000Z",
      },
      "X",
      "100"
    );
    expect(r.expires_at).toBe("2026-05-12T18:00:00.000Z");
  });

  it("retorna null quando expires_at é null", () => {
    const r = toPagamentoResumo(
      { id: 1, reserva_id: 1, status: "APROVADO", expires_at: null },
      "X",
      "100"
    );
    expect(r.expires_at).toBeNull();
  });

  it("propaga status APROVADO e CANCELADO sem alteração", () => {
    const aprovado = toPagamentoResumo(
      { id: 1, reserva_id: 1, status: "APROVADO", expires_at: null },
      "X",
      "100"
    );
    const cancelado = toPagamentoResumo(
      { id: 1, reserva_id: 1, status: "CANCELADO", expires_at: null },
      "X",
      "100"
    );
    expect(aprovado.status).toBe("APROVADO");
    expect(cancelado.status).toBe("CANCELADO");
  });

  it("expõe sempre todas as modalidades aceitas (mesmo após confirmação)", () => {
    const r = toPagamentoResumo(
      { id: 1, reserva_id: 1, status: "APROVADO", expires_at: null },
      "X",
      "100"
    );
    expect(r.modalidades).toEqual(MODALIDADES_FAKE);
  });
});
