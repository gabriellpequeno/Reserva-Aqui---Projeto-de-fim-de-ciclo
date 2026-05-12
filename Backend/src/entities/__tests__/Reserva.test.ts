import { Reserva } from "../Reserva";

const validHotelId = "11111111-2222-3333-4444-555555555555";
const validUserId  = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";
const validCpf     = "529.982.247-25"; // CPF sintético com DV correto

const baseDates = {
  data_checkin:  "2026-05-12",
  data_checkout: "2026-05-15",
};

describe("Reserva.validateUsuario", () => {
  // Nota de contrato: validateUsuario chama validateValorTotal sem condição,
  // então valor_total é sempre obrigatório (Number(undefined) = NaN).
  describe("happy paths", () => {
    it("aceita o conjunto mínimo (com quarto_id e valor_total)", () => {
      const r = Reserva.validateUsuario({
        hotel_id: validHotelId,
        num_hospedes: 2,
        ...baseDates,
        quarto_id: 7,
        valor_total: 300,
      });
      expect(r.hotel_id).toBe(validHotelId);
      expect(r.num_hospedes).toBe(2);
      expect(r.data_checkin).toBe("2026-05-12");
      expect(r.data_checkout).toBe("2026-05-15");
      expect(r.quarto_id).toBe(7);
      expect(r.valor_total).toBe(300);
      expect(r.nome_hospede).toBeUndefined();
    });

    it("aceita reserva no nome de terceiro quando todos os 4 campos do hóspede estão presentes", () => {
      const r = Reserva.validateUsuario({
        hotel_id: validHotelId,
        num_hospedes: 1,
        ...baseDates,
        quarto_id: 1,
        valor_total: 300,
        nome_hospede: "Maria Silva",
        email_hospede: " MARIA@example.COM ",
        cpf_hospede: validCpf,
        telefone_contato: "(11) 99988-7766",
      });
      expect(r.nome_hospede).toBe("Maria Silva");
      expect(r.email_hospede).toBe("maria@example.com");
      expect(r.cpf_hospede).toBe("52998224725"); // sem máscara
      expect(r.telefone_contato).toBe("11999887766"); // só dígitos
    });

    it("aceita tipo_quarto + valor_total quando não há quarto_id", () => {
      const r = Reserva.validateUsuario({
        hotel_id: validHotelId,
        num_hospedes: 2,
        ...baseDates,
        tipo_quarto: "Suíte",
        valor_total: 450,
      });
      expect(r.tipo_quarto).toBe("Suíte");
      expect(r.valor_total).toBe(450);
      expect(r.quarto_id).toBeUndefined();
    });
  });

  describe("rejeições", () => {
    it("rejeita hotel_id que não é UUID", () => {
      expect(() =>
        Reserva.validateUsuario({
          hotel_id: "abc",
          num_hospedes: 1,
          ...baseDates,
          quarto_id: 1,
        })
      ).toThrow(/hotel_id inválido/);
    });

    it("rejeita num_hospedes <= 0", () => {
      expect(() =>
        Reserva.validateUsuario({
          hotel_id: validHotelId,
          num_hospedes: 0,
          ...baseDates,
          quarto_id: 1,
        })
      ).toThrow(/num_hospedes/);
    });

    it("rejeita num_hospedes não inteiro", () => {
      expect(() =>
        Reserva.validateUsuario({
          hotel_id: validHotelId,
          num_hospedes: 2.5,
          ...baseDates,
          quarto_id: 1,
        })
      ).toThrow(/num_hospedes/);
    });

    it("rejeita data fora do formato YYYY-MM-DD", () => {
      expect(() =>
        Reserva.validateUsuario({
          hotel_id: validHotelId,
          num_hospedes: 1,
          data_checkin: "12/05/2026",
          data_checkout: "2026-05-15",
          quarto_id: 1,
        })
      ).toThrow(/data_checkin inválido/);
    });

    it("rejeita checkout <= checkin", () => {
      expect(() =>
        Reserva.validateUsuario({
          hotel_id: validHotelId,
          num_hospedes: 1,
          data_checkin: "2026-05-15",
          data_checkout: "2026-05-15",
          quarto_id: 1,
          valor_total: 100,
        })
      ).toThrow(/data_checkout deve ser posterior/);
    });

    it("rejeita ausência de quarto_id E tipo_quarto", () => {
      expect(() =>
        Reserva.validateUsuario({
          hotel_id: validHotelId,
          num_hospedes: 1,
          ...baseDates,
          valor_total: 100,
        })
      ).toThrow(/Informe quarto_id ou tipo_quarto/);
    });

    it("rejeita valor_total ausente (validateValorTotal é incondicional)", () => {
      // Documenta o contrato: valor_total é mandatório em validateUsuario.
      // O check específico "Informe valor_total quando não há quarto_id"
      // existe na lógica, mas é alcançado apenas se validateValorTotal aceitasse undefined.
      expect(() =>
        Reserva.validateUsuario({
          hotel_id: validHotelId,
          num_hospedes: 1,
          ...baseDates,
          tipo_quarto: "Suíte",
        })
      ).toThrow(/valor_total/);
    });

    it("rejeita dados de hóspede parciais (regra TODOS-ou-NENHUM)", () => {
      expect(() =>
        Reserva.validateUsuario({
          hotel_id: validHotelId,
          num_hospedes: 1,
          ...baseDates,
          quarto_id: 1,
          valor_total: 100,
          nome_hospede: "Maria Silva",
          // faltando email_hospede, cpf_hospede, telefone_contato
        })
      ).toThrow(/Dados do hóspede incompletos/);
    });

    it("rejeita CPF inválido (dígito verificador errado)", () => {
      expect(() =>
        Reserva.validateUsuario({
          hotel_id: validHotelId,
          num_hospedes: 1,
          ...baseDates,
          quarto_id: 1,
          valor_total: 100,
          nome_hospede: "Maria Silva",
          email_hospede: "maria@x.com",
          cpf_hospede: "12345678900",
          telefone_contato: "11999887766",
        })
      ).toThrow(/cpf_hospede/);
    });
  });
});

describe("Reserva.validateGuest", () => {
  const baseGuest = {
    hotel_id: validHotelId,
    num_hospedes: 1,
    ...baseDates,
    valor_total: 200,
    quarto_id: 1,
    nome_hospede: "João Pereira",
    email_hospede: "joao@x.com",
    cpf_hospede: validCpf,
    telefone_contato: "11999887766",
  };

  it("aceita um guest completo e bem formado", () => {
    const r = Reserva.validateGuest(baseGuest);
    expect(r.nome_hospede).toBe("João Pereira");
    expect(r.email_hospede).toBe("joao@x.com");
    expect(r.valor_total).toBe(200);
  });

  it("exige nome_hospede (não pode reservar anonimamente)", () => {
    const { nome_hospede: _, ...sem } = baseGuest;
    expect(() => Reserva.validateGuest(sem)).toThrow(/nome_hospede/);
  });

  it("exige email_hospede", () => {
    const { email_hospede: _, ...sem } = baseGuest;
    expect(() => Reserva.validateGuest(sem)).toThrow(/email_hospede/);
  });

  it("rejeita email malformado", () => {
    expect(() =>
      Reserva.validateGuest({ ...baseGuest, email_hospede: "joaoexample" })
    ).toThrow(/email_hospede/);
  });

  it("rejeita CPF com 11 dígitos iguais (regra anti-fraude)", () => {
    expect(() =>
      Reserva.validateGuest({ ...baseGuest, cpf_hospede: "11111111111" })
    ).toThrow(/cpf_hospede/);
  });

  it("rejeita telefone com menos de 10 dígitos", () => {
    expect(() =>
      Reserva.validateGuest({ ...baseGuest, telefone_contato: "999887766" })
    ).toThrow(/telefone_contato/);
  });
});

describe("Reserva.validateWalkin", () => {
  const baseWalkin = {
    num_hospedes: 1,
    ...baseDates,
    valor_total: 100,
    quarto_id: 1,
  };

  it("aceita walk-in mínimo (sem hóspede identificado — bloqueia agenda)", () => {
    const r = Reserva.validateWalkin(baseWalkin);
    expect(r.num_hospedes).toBe(1);
    expect(r.valor_total).toBe(100);
    expect(r.nome_hospede).toBeUndefined();
  });

  it("rejeita nome sem cpf nem telefone (consistência)", () => {
    expect(() =>
      Reserva.validateWalkin({ ...baseWalkin, nome_hospede: "João Pereira" })
    ).toThrow(/cpf_hospede ou telefone_contato/);
  });

  it("aceita nome + telefone", () => {
    const r = Reserva.validateWalkin({
      ...baseWalkin,
      nome_hospede: "João Pereira",
      telefone_contato: "11999887766",
    });
    expect(r.nome_hospede).toBe("João Pereira");
    expect(r.telefone_contato).toBe("11999887766");
  });

  it("aceita user_id quando UUID válido", () => {
    const r = Reserva.validateWalkin({ ...baseWalkin, user_id: validUserId });
    expect(r.user_id).toBe(validUserId);
  });
});

describe("Reserva.validateStatus", () => {
  it.each([
    "SOLICITADA",
    "AGUARDANDO_PAGAMENTO",
    "APROVADA",
    "CANCELADA",
    "CONCLUIDA",
  ])("aceita status válido %s", (status) => {
    expect(Reserva.validateStatus({ status })).toEqual({ status });
  });

  it.each(["", "PENDING", "approved", "ANY", undefined, null])(
    "rejeita status inválido %p",
    (status) => {
      expect(() => Reserva.validateStatus({ status })).toThrow(/status inválido/);
    }
  );
});

describe("Reserva.validateAtribuirQuarto", () => {
  it("aceita inteiro positivo", () => {
    expect(Reserva.validateAtribuirQuarto({ quarto_id: 42 })).toEqual({
      quarto_id: 42,
    });
  });

  it("rejeita zero, negativo e não-inteiro", () => {
    expect(() => Reserva.validateAtribuirQuarto({ quarto_id: 0 })).toThrow();
    expect(() => Reserva.validateAtribuirQuarto({ quarto_id: -1 })).toThrow();
    expect(() => Reserva.validateAtribuirQuarto({ quarto_id: 1.5 })).toThrow();
  });
});
