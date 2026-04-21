import type { Config } from "jest";

const config: Config = {
  preset: "ts-jest",
  testEnvironment: "node",
  rootDir: "src",
  testMatch: ["**/__tests__/**/*.test.ts"],
  moduleFileExtensions: ["ts", "js", "json"],
  clearMocks: true,
  setupFiles: ["<rootDir>/__tests__/setup.ts"],
  coverageDirectory: "../coverage",
  collectCoverageFrom: [
    "**/*.ts",
    "!app.ts",
    "!**/__tests__/**",
    "!**/entities/**",
  ],
};

export default config;
