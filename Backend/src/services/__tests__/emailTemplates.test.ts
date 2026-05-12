import {
  esc,
  fmtBRL,
  fmtDate,
  reservaPendentePagamentoTemplate,
  reservaConfirmadaTemplate,
  reservaExpiradaTemplate,
  type ReservaResumo,
} from "../emailTemplates";

const baseResumo: ReservaResumo = {
  nomeHotel: "Hotel Teste",
  tipoQuarto: "Suíte Master",
  dataCheckin: "2026-05-12",
  dataCheckout: "2026-05-15",
  numHospedes: 2,
  valorTotal: 1234.5,
};

describe("emailTemplates: helpers", () => {
  describe("esc()", () => {
    it("returns empty string for null and undefined", () => {
      expect(esc(null)).toBe("");
      expect(esc(undefined)).toBe("");
    });

    it("escapes the four HTML-sensitive characters", () => {
      expect(esc('<script>alert("x")</script>')).toBe(
        "&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;"
      );
    });

    it("escapes & before other entities to avoid double-encoding", () => {
      expect(esc("Tom & Jerry <kids>")).toBe("Tom &amp; Jerry &lt;kids&gt;");
    });

    it("coerces numbers to strings", () => {
      expect(esc(42)).toBe("42");
      expect(esc(0)).toBe("0");
    });

    it("does not touch safe characters", () => {
      expect(esc("Olá, mundo! 1+1=2")).toBe("Olá, mundo! 1+1=2");
    });
  });

  describe("fmtBRL()", () => {
    it("formats integer values with two decimals and BR comma", () => {
      expect(fmtBRL(100)).toBe("R$ 100,00");
    });

    it("formats decimals rounding to two places", () => {
      expect(fmtBRL(1234.5)).toBe("R$ 1234,50");
      expect(fmtBRL(0.1 + 0.2)).toBe("R$ 0,30"); // floating point sanity
    });

    it("accepts string inputs", () => {
      expect(fmtBRL("250.75")).toBe("R$ 250,75");
    });

    it("formats zero", () => {
      expect(fmtBRL(0)).toBe("R$ 0,00");
    });

    it("formats negative values", () => {
      expect(fmtBRL(-99.9)).toBe("R$ -99,90");
    });
  });

  describe("fmtDate()", () => {
    it("formats ISO date strings to dd/mm/yyyy", () => {
      expect(fmtDate("2026-05-12")).toBe("12/05/2026");
    });

    it("formats Date objects to dd/mm/yyyy (UTC)", () => {
      // Use noon UTC to avoid timezone day-shift drift.
      const d = new Date(Date.UTC(2026, 4, 12, 12, 0, 0));
      expect(fmtDate(d)).toBe("12/05/2026");
    });

    it("returns the raw input when string is shorter than 10 chars", () => {
      expect(fmtDate("2026")).toBe("2026");
    });

    it("returns empty string when value is null-ish (cast)", () => {
      // Function signature does not allow null at compile time, but runtime guards still apply.
      expect(fmtDate("" as unknown as string)).toBe("");
    });

    it("trims time component from full ISO timestamp", () => {
      expect(fmtDate("2026-05-12T18:30:00.000Z")).toBe("12/05/2026");
    });
  });
});

describe("emailTemplates: public templates", () => {
  describe("reservaPendentePagamentoTemplate()", () => {
    it("returns subject including the hotel name", () => {
      const { subject } = reservaPendentePagamentoTemplate({
        nomeHospede: "Maria",
        codigoPublico: "ABC123",
        pagamentoUrl: "https://pay.example/abc",
        resumo: baseResumo,
      });
      expect(subject).toBe("Reserva em Hotel Teste — pagamento pendente");
    });

    it("includes guest name, code, formatted amount and dates in the body", () => {
      const { html } = reservaPendentePagamentoTemplate({
        nomeHospede: "Maria Silva",
        codigoPublico: "ABC123",
        pagamentoUrl: "https://pay.example/abc",
        resumo: baseResumo,
      });
      expect(html).toContain("Maria Silva");
      expect(html).toContain("ABC123");
      expect(html).toContain("R$ 1234,50");
      expect(html).toContain("12/05/2026");
      expect(html).toContain("15/05/2026");
      expect(html).toContain("https://pay.example/abc");
    });

    it("renders the expiration warning only when expiresAt is provided", () => {
      const withExp = reservaPendentePagamentoTemplate({
        nomeHospede: "Maria",
        codigoPublico: "X",
        pagamentoUrl: "https://x",
        resumo: baseResumo,
        expiresAt: "2026-05-12T18:30:00.000Z",
      }).html;
      const withoutExp = reservaPendentePagamentoTemplate({
        nomeHospede: "Maria",
        codigoPublico: "X",
        pagamentoUrl: "https://x",
        resumo: baseResumo,
      }).html;
      expect(withExp).toContain("expira em 30 minutos");
      expect(withoutExp).not.toContain("expira em 30 minutos");
    });

    it("escapes injection attempts in user-controlled fields", () => {
      const { html } = reservaPendentePagamentoTemplate({
        nomeHospede: "<script>alert(1)</script>",
        codigoPublico: "X",
        pagamentoUrl: "https://x",
        resumo: { ...baseResumo, nomeHotel: 'A & B "Hotel"' },
      });
      expect(html).not.toContain("<script>alert(1)</script>");
      expect(html).toContain("&lt;script&gt;alert(1)&lt;/script&gt;");
      expect(html).toContain("A &amp; B &quot;Hotel&quot;");
    });
  });

  describe("reservaConfirmadaTemplate()", () => {
    it("returns subject with hotel name", () => {
      const { subject } = reservaConfirmadaTemplate({
        nomeHospede: "João",
        codigoPublico: "K9",
        ticketUrl: "https://app/ticket/k9",
        resumo: baseResumo,
      });
      expect(subject).toBe("Reserva confirmada — Hotel Teste");
    });

    it("includes the ticket URL in the body", () => {
      const { html } = reservaConfirmadaTemplate({
        nomeHospede: "João",
        codigoPublico: "K9",
        ticketUrl: "https://app/ticket/k9",
        resumo: baseResumo,
      });
      expect(html).toContain("https://app/ticket/k9");
      expect(html).toContain("Reserva confirmada");
    });
  });

  describe("reservaExpiradaTemplate()", () => {
    it("returns subject with the hotel name", () => {
      const { subject } = reservaExpiradaTemplate({
        nomeHospede: "Ana",
        codigoPublico: "EXP1",
        nomeHotel: "Pousada do Vale",
      });
      expect(subject).toBe("Reserva expirada — Pousada do Vale");
    });

    it("references the cancelled reservation code in the body", () => {
      const { html } = reservaExpiradaTemplate({
        nomeHospede: "Ana",
        codigoPublico: "EXP1",
        nomeHotel: "Pousada do Vale",
      });
      expect(html).toContain("EXP1");
      expect(html).toContain("Pousada do Vale");
    });
  });
});
