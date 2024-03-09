const config = {
  "**/*.ts?(x)": () => "tsc -p tsconfig.prod.json --noEmit",
  "*.{js,jsx,ts,tsx}": ["pnpm run lint", "vitest related --run"],
  "*.{md,json}": "prettier --write",
};

module.exports = config;
