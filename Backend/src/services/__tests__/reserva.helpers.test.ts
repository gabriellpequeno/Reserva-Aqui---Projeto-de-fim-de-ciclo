/**
 * Testes dos helpers puros de reserva.service.ts.
 *
 * Importante: o módulo reserva.service também exporta funções que tocam o DB.
 * Mockamos masterDb e schemaWrapper para que o import desses módulos não tente
 * conectar ao Postgres em ambiente de teste.
 */
jest.mock("../../database/masterDb", () => ({
  masterPool: { query: jest.fn() },
}));
jest.mock("../../database/schemaWrapper", () => ({
  withTenant: jest.fn(),
}));

import { calcDiarias, toISODate, canCancelReserva } from "../reserva.service";

describe("calcDiarias()", () => {
  it("retorna 1 para uma noite (12 → 13)", () => {
    expect(calcDiarias("2026-05-12", "2026-05-13")).toBe(1);
  });

  it("retorna 3 para um intervalo padrão de fim de semana estendido", () => {
    expect(calcDiarias("2026-05-12", "2026-05-15")).toBe(3);
  });

  it("retorna 0 quando checkin == checkout", () => {
    expect(calcDiarias("2026-05-12", "2026-05-12")).toBe(0);
  });

  it("trabalha através de bordas de mês", () => {
    expect(calcDiarias("2026-04-30", "2026-05-02")).toBe(2);
  });

  it("trabalha através de bordas de ano", () => {
    expect(calcDiarias("2026-12-30", "2027-01-02")).toBe(3);
  });

  it("trabalha em ano bissexto (29 de fevereiro)", () => {
    expect(calcDiarias("2024-02-28", "2024-03-01")).toBe(2);
  });
});

describe("toISODate()", () => {
  it("retorna string crua quando recebe 'YYYY-MM-DD'", () => {
    expect(toISODate("2026-05-12")).toBe("2026-05-12");
  });

  it("trunca string ISO completa para 'YYYY-MM-DD'", () => {
    expect(toISODate("2026-05-12T18:30:00.000Z")).toBe("2026-05-12");
  });

  it("converte Date para 'YYYY-MM-DD' (UTC)", () => {
    // Meio-dia UTC evita drift de fuso horário em CI.
    const d = new Date(Date.UTC(2026, 4, 12, 12, 0, 0));
    expect(toISODate(d)).toBe("2026-05-12");
  });

  it("preserva o componente de data quando o Date está em outra hora", () => {
    const d = new Date(Date.UTC(2026, 4, 12, 23, 59, 59));
    expect(toISODate(d)).toBe("2026-05-12");
  });
});

describe("canCancelReserva()", () => {
  it.each(["SOLICITADA", "APROVADA"] as const)(
    "permite cancelamento em %s",
    (status) => {
      expect(canCancelReserva(status)).toBe(true);
    }
  );

  it.each(["AGUARDANDO_PAGAMENTO", "CANCELADA", "CONCLUIDA"] as const)(
    "bloqueia cancelamento em %s",
    (status) => {
      expect(canCancelReserva(status)).toBe(false);
    }
  );
});
