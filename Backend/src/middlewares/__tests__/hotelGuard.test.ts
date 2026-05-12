/**
 * Testes do middleware hotelGuard.
 *
 * Valida que o guard:
 *   1. exige header Authorization (401 se ausente/malformado),
 *   2. exige assinatura válida (401),
 *   3. exige token expirado dá 401 específico,
 *   4. EXIGE payload de anfitrião (hotel_id) — token de usuário cai em 403,
 *   5. popula req.hotelId / req.hotelEmail no caminho feliz.
 */
process.env.JWT_SECRET = "test-secret-for-hotel-guard-suite-please-ignore";

import express from "express";
import request from "supertest";
import jwt from "jsonwebtoken";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { hotelGuard }: typeof import("../hotelGuard") = require("../hotelGuard");
type HotelRequest = import("../hotelGuard").HotelRequest;

const JWT_SECRET = process.env.JWT_SECRET!;

function createApp() {
  const app = express();
  app.use(express.json());
  app.get("/hotel-only", hotelGuard, (req, res) => {
    const r = req as HotelRequest;
    res.json({ ok: true, hotelId: r.hotelId, hotelEmail: r.hotelEmail });
  });
  return app;
}

function signToken(
  payload: Record<string, unknown>,
  options: jwt.SignOptions = { expiresIn: "1h" }
): string {
  return jwt.sign(payload, JWT_SECRET, options);
}

describe("hotelGuard", () => {
  let app: express.Application;

  beforeEach(() => {
    app = createApp();
  });

  describe("rejeições por header", () => {
    it("retorna 401 quando não há header Authorization", async () => {
      const res = await request(app).get("/hotel-only");
      expect(res.status).toBe(401);
      expect(res.body.error).toMatch(/Token não fornecido/i);
    });

    it("retorna 401 quando o header não começa com 'Bearer '", async () => {
      const token = signToken({ hotel_id: "h-1", email: "h@x.com" });
      const res = await request(app)
        .get("/hotel-only")
        .set("Authorization", token);
      expect(res.status).toBe(401);
      expect(res.body.error).toMatch(/formato inválido/i);
    });
  });

  describe("rejeições por token", () => {
    it("retorna 401 'Token inválido' quando a assinatura não bate", async () => {
      const t = jwt.sign(
        { hotel_id: "h-1", email: "h@x.com" },
        "outro-segredo",
        { expiresIn: "1h" }
      );
      const res = await request(app)
        .get("/hotel-only")
        .set("Authorization", `Bearer ${t}`);
      expect(res.status).toBe(401);
      expect(res.body.error).toBe("Token inválido");
    });

    it("retorna 401 'Token expirado' quando o token venceu", async () => {
      const expired = signToken(
        { hotel_id: "h-1", email: "h@x.com" },
        { expiresIn: "-1s" }
      );
      const res = await request(app)
        .get("/hotel-only")
        .set("Authorization", `Bearer ${expired}`);
      expect(res.status).toBe(401);
      expect(res.body.error).toBe("Token expirado");
    });
  });

  describe("rejeições por escopo (token de usuário, não de hotel)", () => {
    it("retorna 403 quando o payload não tem hotel_id (ex: token de usuário com user_id)", async () => {
      const userToken = signToken({
        user_id: "u-1",
        email: "u@x.com",
        papel: "usuario",
      });
      const res = await request(app)
        .get("/hotel-only")
        .set("Authorization", `Bearer ${userToken}`);
      expect(res.status).toBe(403);
      expect(res.body.error).toMatch(/anfitri/i);
    });

    it("retorna 403 quando hotel_id é string vazia (truthy check)", async () => {
      const t = signToken({ hotel_id: "", email: "h@x.com" });
      const res = await request(app)
        .get("/hotel-only")
        .set("Authorization", `Bearer ${t}`);
      expect(res.status).toBe(403);
    });

    it("retorna 403 quando token de admin (sem hotel_id) tenta entrar", async () => {
      const adminToken = signToken({
        user_id: "admin-1",
        email: "a@x.com",
        papel: "admin",
      });
      const res = await request(app)
        .get("/hotel-only")
        .set("Authorization", `Bearer ${adminToken}`);
      expect(res.status).toBe(403);
    });
  });

  describe("aceitação e propagação no req", () => {
    it("chama next() e popula req.hotelId/hotelEmail para token válido de anfitrião", async () => {
      const token = signToken({
        hotel_id: "hotel-uuid-42",
        email: "contato@meuhotel.com",
      });
      const res = await request(app)
        .get("/hotel-only")
        .set("Authorization", `Bearer ${token}`);
      expect(res.status).toBe(200);
      expect(res.body).toEqual({
        ok: true,
        hotelId: "hotel-uuid-42",
        hotelEmail: "contato@meuhotel.com",
      });
    });
  });
});
