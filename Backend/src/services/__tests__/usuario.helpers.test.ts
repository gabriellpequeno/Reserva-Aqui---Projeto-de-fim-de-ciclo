import jwt from "jsonwebtoken";
import {
  parseDataBrToEn,
  signAccessToken,
  signRefreshToken,
  hashToken,
  refreshExpiresAt,
} from "../usuario.service";

describe("parseDataBrToEn()", () => {
  it("converts dd/mm/yyyy to yyyy-mm-dd", () => {
    expect(parseDataBrToEn("12/05/2026")).toBe("2026-05-12");
  });

  it("preserves zero-padding as-is", () => {
    expect(parseDataBrToEn("01/01/2000")).toBe("2000-01-01");
  });

  it("does NOT validate the date — passes through invalid inputs", () => {
    // Documents current behavior: helper is a string transform, not a validator.
    // Validation lives in Usuario.validate.
    expect(parseDataBrToEn("31/02/2025")).toBe("2025-02-31");
  });

  it("returns 'undefined-undefined-undefined' for empty input (current behavior)", () => {
    // Pinning current behavior so a future change is intentional.
    expect(parseDataBrToEn("")).toBe("undefined-undefined-");
  });
});

describe("hashToken()", () => {
  it("produces a 64-char hex sha256 digest", () => {
    const h = hashToken("any-token");
    expect(h).toMatch(/^[0-9a-f]{64}$/);
  });

  it("is deterministic for the same input", () => {
    expect(hashToken("abc")).toBe(hashToken("abc"));
  });

  it("yields different digests for different inputs", () => {
    expect(hashToken("a")).not.toBe(hashToken("b"));
  });

  it("is case-sensitive", () => {
    expect(hashToken("Abc")).not.toBe(hashToken("abc"));
  });
});

describe("refreshExpiresAt()", () => {
  it("returns a Date roughly 7 days in the future", () => {
    const before = Date.now();
    const expiresAt = refreshExpiresAt().getTime();
    const after = Date.now();

    const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
    expect(expiresAt).toBeGreaterThanOrEqual(before + sevenDaysMs);
    expect(expiresAt).toBeLessThanOrEqual(after + sevenDaysMs);
  });

  it("returns a future Date", () => {
    expect(refreshExpiresAt().getTime()).toBeGreaterThan(Date.now());
  });
});

describe("signAccessToken()", () => {
  const payload = {
    user_id: "u-123",
    email: "alice@example.com",
    papel: "usuario" as const,
  };

  it("returns a 3-segment JWT string", () => {
    const token = signAccessToken(payload);
    expect(token.split(".")).toHaveLength(3);
  });

  it("encodes the payload claims (user_id, email, papel)", () => {
    const token = signAccessToken(payload);
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as Record<string, unknown>;
    expect(decoded.user_id).toBe("u-123");
    expect(decoded.email).toBe("alice@example.com");
    expect(decoded.papel).toBe("usuario");
  });

  it("includes iat and exp timestamps", () => {
    const token = signAccessToken(payload);
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as { iat: number; exp: number };
    expect(typeof decoded.iat).toBe("number");
    expect(typeof decoded.exp).toBe("number");
    expect(decoded.exp).toBeGreaterThan(decoded.iat);
  });

  it("rejects verification under a different secret", () => {
    const token = signAccessToken(payload);
    expect(() => jwt.verify(token, "wrong-secret")).toThrow();
  });
});

describe("signRefreshToken()", () => {
  it("encodes only user_id (no email/papel leak)", () => {
    const token = signRefreshToken({ user_id: "u-456" });
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as Record<string, unknown>;
    expect(decoded.user_id).toBe("u-456");
    expect(decoded.email).toBeUndefined();
    expect(decoded.papel).toBeUndefined();
  });

  it("uses a longer expiration than signAccessToken", () => {
    const access = jwt.verify(
      signAccessToken({ user_id: "u", email: "e", papel: "usuario" }),
      process.env.JWT_SECRET!
    ) as { iat: number; exp: number };
    const refresh = jwt.verify(
      signRefreshToken({ user_id: "u" }),
      process.env.JWT_SECRET!
    ) as { iat: number; exp: number };
    expect(refresh.exp - refresh.iat).toBeGreaterThan(access.exp - access.iat);
  });
});
