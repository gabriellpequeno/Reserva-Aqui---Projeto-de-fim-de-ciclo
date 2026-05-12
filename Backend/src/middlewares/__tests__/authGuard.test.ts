/**
 * Testes do middleware authGuard.
 *
 * IMPORTANTE: authGuard.ts captura `process.env.JWT_SECRET` no momento do
 * import. Definimos o segredo ANTES de qualquer require dos módulos sob teste.
 */
process.env.JWT_SECRET = "test-secret-for-auth-guard-suite-please-ignore";

import express from "express";
import request from "supertest";
import jwt from "jsonwebtoken";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { authGuard }: typeof import("../authGuard") = require("../authGuard");
type AuthRequest = import("../authGuard").AuthRequest;

const JWT_SECRET = process.env.JWT_SECRET!;

function createApp() {
  const app = express();
  app.use(express.json());
  app.get("/protected", authGuard, (req, res) => {
    const r = req as AuthRequest;
    res.json({
      ok: true,
      userId: r.userId,
      userEmail: r.userEmail,
      userPapel: r.userPapel,
    });
  });
  return app;
}

function signToken(
  payload: Record<string, unknown>,
  options: jwt.SignOptions = { expiresIn: "1h" }
): string {
  return jwt.sign(payload, JWT_SECRET, options);
}

describe("authGuard", () => {
  let app: express.Application;

  beforeEach(() => {
    app = createApp();
  });

  describe("rejeições", () => {
    it("retorna 401 quando não há header Authorization", async () => {
      const res = await request(app).get("/protected");
      expect(res.status).toBe(401);
      expect(res.body.error).toMatch(/Token não fornecido/i);
    });

    it("retorna 401 quando o header não começa com 'Bearer '", async () => {
      const token = signToken({ user_id: "u1", email: "u@x.com" });
      const res = await request(app)
        .get("/protected")
        .set("Authorization", token); // sem o prefixo
      expect(res.status).toBe(401);
      expect(res.body.error).toMatch(/formato inválido/i);
    });

    it("retorna 401 com 'Token inválido' quando a assinatura não bate", async () => {
      const tokenWrongSecret = jwt.sign(
        { user_id: "u1", email: "u@x.com" },
        "outro-segredo",
        { expiresIn: "1h" }
      );
      const res = await request(app)
        .get("/protected")
        .set("Authorization", `Bearer ${tokenWrongSecret}`);
      expect(res.status).toBe(401);
      expect(res.body.error).toBe("Token inválido");
    });

    it("retorna 401 com 'Token expirado' quando o token está vencido", async () => {
      const expired = signToken(
        { user_id: "u1", email: "u@x.com" },
        { expiresIn: "-1s" }
      );
      const res = await request(app)
        .get("/protected")
        .set("Authorization", `Bearer ${expired}`);
      expect(res.status).toBe(401);
      expect(res.body.error).toBe("Token expirado");
    });

    it("retorna 401 quando o token é uma string aleatória (não-JWT)", async () => {
      const res = await request(app)
        .get("/protected")
        .set("Authorization", "Bearer nao-eh-um-jwt");
      expect(res.status).toBe(401);
      expect(res.body.error).toBe("Token inválido");
    });
  });

  describe("aceitações e propagação no req", () => {
    it("chama next() e popula req.userId/userEmail/userPapel para um token válido de usuário", async () => {
      const token = signToken({
        user_id: "u-123",
        email: "alice@x.com",
        papel: "usuario",
      });
      const res = await request(app)
        .get("/protected")
        .set("Authorization", `Bearer ${token}`);
      expect(res.status).toBe(200);
      expect(res.body).toEqual({
        ok: true,
        userId: "u-123",
        userEmail: "alice@x.com",
        userPapel: "usuario",
      });
    });

    it("preserva papel='admin' quando o token é admin", async () => {
      const token = signToken({
        user_id: "admin-1",
        email: "a@x.com",
        papel: "admin",
      });
      const res = await request(app)
        .get("/protected")
        .set("Authorization", `Bearer ${token}`);
      expect(res.status).toBe(200);
      expect(res.body.userPapel).toBe("admin");
    });

    it("token legado sem campo papel cai no fallback seguro 'usuario'", async () => {
      // Garantia documentada no comentário do middleware: nunca dá admin por engano.
      const token = signToken({ user_id: "u-old", email: "o@x.com" });
      const res = await request(app)
        .get("/protected")
        .set("Authorization", `Bearer ${token}`);
      expect(res.status).toBe(200);
      expect(res.body.userPapel).toBe("usuario");
    });

    it("papel desconhecido (ex: 'superuser') também cai no fallback 'usuario'", async () => {
      const token = signToken({
        user_id: "u-x",
        email: "x@x.com",
        papel: "superuser",
      });
      const res = await request(app)
        .get("/protected")
        .set("Authorization", `Bearer ${token}`);
      expect(res.status).toBe(200);
      expect(res.body.userPapel).toBe("usuario");
    });
  });
});
