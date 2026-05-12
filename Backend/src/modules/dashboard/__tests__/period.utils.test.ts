import { isPeriod, resolvePeriod, ALL_PERIODS } from "../period.utils";

describe("isPeriod()", () => {
  it.each(ALL_PERIODS)("accepts the valid period %s", (p) => {
    expect(isPeriod(p)).toBe(true);
  });

  it.each([
    ["unknown string", "yesterday"],
    ["empty string", ""],
    ["uppercase variant", "TODAY"],
    ["null", null],
    ["undefined", undefined],
    ["number", 7],
    ["object", { period: "today" }],
  ])("rejects %s", (_label, value) => {
    expect(isPeriod(value)).toBe(false);
  });
});

describe("resolvePeriod()", () => {
  // Pin "now" to a deterministic instant. Mid-month, mid-day, weekday — avoids
  // boundary ambiguity for assertions that compare against constructed Dates.
  const FIXED_NOW = new Date(2026, 4, 12, 14, 30, 0); // 2026-05-12 14:30 local

  beforeEach(() => {
    jest.useFakeTimers();
    jest.setSystemTime(FIXED_NOW);
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  describe('"today"', () => {
    it("starts at midnight of the current day", () => {
      const { start } = resolvePeriod("today");
      expect(start.getFullYear()).toBe(2026);
      expect(start.getMonth()).toBe(4);
      expect(start.getDate()).toBe(12);
      expect(start.getHours()).toBe(0);
      expect(start.getMinutes()).toBe(0);
      expect(start.getSeconds()).toBe(0);
    });

    it("ends at midnight of the next day", () => {
      const { end } = resolvePeriod("today");
      expect(end.getFullYear()).toBe(2026);
      expect(end.getMonth()).toBe(4);
      expect(end.getDate()).toBe(13);
      expect(end.getHours()).toBe(0);
    });

    it("crosses month boundary correctly", () => {
      jest.setSystemTime(new Date(2026, 4, 31, 23, 0, 0)); // 2026-05-31
      const { start, end } = resolvePeriod("today");
      expect(start.getDate()).toBe(31);
      expect(start.getMonth()).toBe(4);
      expect(end.getDate()).toBe(1);
      expect(end.getMonth()).toBe(5);
    });

    it("crosses year boundary correctly", () => {
      jest.setSystemTime(new Date(2026, 11, 31, 10, 0, 0)); // 2026-12-31
      const { start, end } = resolvePeriod("today");
      expect(start.getFullYear()).toBe(2026);
      expect(start.getDate()).toBe(31);
      expect(end.getFullYear()).toBe(2027);
      expect(end.getDate()).toBe(1);
      expect(end.getMonth()).toBe(0);
    });
  });

  describe('"last7"', () => {
    it("ends at the current instant (now)", () => {
      const { end } = resolvePeriod("last7");
      expect(end.getTime()).toBe(FIXED_NOW.getTime());
    });

    it("starts exactly 7*24h before now", () => {
      const { start } = resolvePeriod("last7");
      const expected = FIXED_NOW.getTime() - 7 * 24 * 60 * 60 * 1000;
      expect(start.getTime()).toBe(expected);
    });
  });

  describe('"current_month"', () => {
    it("starts at the first day of the current month at midnight", () => {
      const { start } = resolvePeriod("current_month");
      expect(start.getFullYear()).toBe(2026);
      expect(start.getMonth()).toBe(4);
      expect(start.getDate()).toBe(1);
      expect(start.getHours()).toBe(0);
    });

    it("ends at the first day of the next month at midnight", () => {
      const { end } = resolvePeriod("current_month");
      expect(end.getFullYear()).toBe(2026);
      expect(end.getMonth()).toBe(5);
      expect(end.getDate()).toBe(1);
    });

    it("rolls year forward when current month is December", () => {
      jest.setSystemTime(new Date(2026, 11, 15, 10, 0, 0));
      const { start, end } = resolvePeriod("current_month");
      expect(start.getFullYear()).toBe(2026);
      expect(start.getMonth()).toBe(11);
      expect(end.getFullYear()).toBe(2027);
      expect(end.getMonth()).toBe(0);
    });
  });

  describe('"last30"', () => {
    it("ends at the current instant (now)", () => {
      const { end } = resolvePeriod("last30");
      expect(end.getTime()).toBe(FIXED_NOW.getTime());
    });

    it("starts exactly 30*24h before now", () => {
      const { start } = resolvePeriod("last30");
      const expected = FIXED_NOW.getTime() - 30 * 24 * 60 * 60 * 1000;
      expect(start.getTime()).toBe(expected);
    });
  });

  it("returns start strictly before end for every period", () => {
    for (const p of ALL_PERIODS) {
      const { start, end } = resolvePeriod(p);
      expect(start.getTime()).toBeLessThan(end.getTime());
    }
  });
});
