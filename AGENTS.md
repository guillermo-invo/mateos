# AGENTS.md — Mateos Monorepo

This file tells agentic coding assistants how to work in this repo: build/lint/test commands (including single‑test runs) plus core style and architecture conventions.

## Repository layout & rules

- `automatizaciones/` — Express + TypeScript service for automations around transcriptions and strategic projects.
- `next-app/` — Next.js 15 app (App Router) exposing the main HTTP API and dashboard UI.
- `telegram-bot/` — Telegram bot in TypeScript that calls the Next.js API.
- Monorepo: each subdirectory has its own `package.json` and scripts; always run commands from the relevant package directory.
- Cursor / Copilot rules:
  - As of 2026‑01‑06 there are **no** Cursor rules (`.cursor/rules/`, `.cursorrules`) or Copilot rules (`.github/copilot-instructions.md`).
  - If you add any, document them here and treat them as higher priority than this file.

## Tooling and runtime

- Node.js: `>= 20.0.0` in all packages.
- npm: `>= 10.0.0`.
- Language: TypeScript everywhere, with `strict: true` enabled.
- Package manager: use `npm`; do **not** introduce `yarn` or `pnpm` without explicit user approval.

## Project: automatizaciones

- Location: `automatizaciones/`.
- Entry point: `src/index.ts` → `dist/index.js` after build.
- Scripts (run from `automatizaciones/`):
  - Dev: `npm run dev` (tsx watcher on `src/index.ts`).
  - Build: `npm run build` (runs `tsc` using `automatizaciones/tsconfig.json`, CommonJS out to `dist/`).
  - Start: `npm start` (runs `node dist/index.js`).
- Prisma:
  - `npm run prisma:generate` — generate Prisma client.
  - `npm run prisma:migrate` — dev migrations.
  - `npm run prisma:deploy` — deploy migrations.
  - `npm run prisma:studio` — open Prisma Studio.
- Tests & lint:
  - There is **no configured test or lint script** yet in this package.
  - When adding tests, prefer Jest or Vitest with TypeScript and expose them via `npm test`.
  - Recommended single‑test pattern (once tests exist): `npm test -- src/path/my-file.test.ts`.

## Project: next-app (Next.js + Prisma + Playwright)

- Location: `next-app/`.
- Scripts (run from `next-app/`):
  - Dev: `npm run dev` (runs `next dev`).
  - Build: `npm run build` (runs `prisma generate && next build`).
  - Start: `npm start` (runs `next start`, requires prior build).
  - Lint: `npm run lint` (runs `next lint`).
- Prisma:
  - `npm run prisma:generate`, `npm run prisma:migrate`, `npm run prisma:deploy`, `npm run prisma:studio`.
- Playwright e2e tests:
  - All tests: `npm run e2e` (alias for `playwright test`).
  - Single spec file: `npx playwright test e2e/my-feature.spec.ts`.
  - Single test by title: `npx playwright test --grep "my feature works"`.
  - File + title filter: `npx playwright test e2e/my-feature.spec.ts --grep "my feature works"`.
- Unit/integration tests:
  - Not configured yet. If you add Jest/Vitest, standardise on `npm test -- my-file.test.ts` for single tests.

## Project: telegram-bot

- Location: `telegram-bot/`.
- Scripts (run from `telegram-bot/`):
  - Dev: `npm run dev` (runs `ts-node src/index.ts`).
  - Build: `npm run build` (runs `tsc` using `telegram-bot/tsconfig.json`, CommonJS out to `dist/`).
  - Start: `npm start` (runs `node dist/index.js`).
  - Lint: `npm run lint` (runs `eslint . --ext .ts`).
- Tests:
  - No dedicated test script yet. If you add tests, expose them as `npm test` and support `npm test -- my-file.test.ts` for single tests.

## Single‑test quick reference

- Playwright (from `next-app/`):
  - Run a single e2e file: `npx playwright test e2e/my-feature.spec.ts`.
  - Run tests by title: `npx playwright test --grep "test title"`.
  - Combine file + title: `npx playwright test e2e/my-feature.spec.ts --grep "test title"`.
- Jest/Vitest (future, any package):
  - Run one test file: `npm test -- src/path/my-file.test.ts`.
  - Run tests matching a pattern: `npm test -- my-pattern`.

## TypeScript and module conventions

- `automatizaciones/` and `telegram-bot/`:
  - `module`: `commonjs`, `target`: `ES2022`, `rootDir`: `src`, `outDir`: `dist`.
  - `strict: true`, `esModuleInterop: true`, `skipLibCheck: true`.
  - Prefer `import x from 'y'` / `import { x } from 'y'` over `require`.
- `next-app/`:
  - `module`: `esnext`, `moduleResolution`: `bundler`, `jsx`: `preserve`, `noEmit: true`.
  - Path alias: `@/*` → `src/*`; use this alias for internal imports instead of long relative paths.
- General typing rules:
  - Avoid `any`; prefer `unknown` with proper narrowing.
  - Export reusable types from `src/types/` (for example `next-app/src/types/index.ts`, `telegram-bot/src/types.ts`).
  - Derive types from Zod schemas using `z.infer<typeof Schema>` where appropriate.
  - Prefer explicit return types for exported functions and public APIs.

## Imports and exports

- Import order within a file:
  1. Node core modules (if any).
  2. Third‑party packages (e.g. `express`, `next`, `node-telegram-bot-api`).
  3. Internal modules (e.g. `@/lib/prisma`, `./processor`).
- Group imports by these categories and separate groups with a blank line.
- Avoid duplicated import lines from the same module; consolidate into one.
- Prefer named exports for utilities and types; default exports are acceptable for React components and route handlers when consistent with existing files.

## Formatting and style

- Indentation: 2 spaces.
- Strings: prefer single quotes in TypeScript/JavaScript; JSX attributes follow Next.js conventions (double quotes in JSX).
- Always terminate statements with semicolons.
- Use trailing commas in multi‑line objects, arrays, and parameter lists when supported by the existing code style.
- Keep line length reasonable; split long expressions over multiple lines.
- Use descriptive names; avoid one‑letter variables except trivial indexes like `i`.
- Do **not** add new emojis in source code or logs unless explicitly requested; existing emojis can remain.

## Naming conventions

- Types/interfaces: `PascalCase` (for example `WebhookPayload`, `ProyectoData`).
- React components and classes: `PascalCase`.
- Functions, variables, and object properties: `camelCase`.
- Constants and environment variables: `SCREAMING_SNAKE_CASE` (for example `TELEGRAM_BOT_TOKEN`).
- Files:
  - TypeScript/TSX: `kebab-case` or `PascalCase` for React components, following current patterns (`KanbanTaskView.tsx`, `project-creator.ts`).

## Error handling

- Express service (`automatizaciones/src/index.ts`):
  - Wrap route handlers in `try/catch` and always send JSON responses.
  - Validate input with Zod schemas (for example `WebhookPayloadSchema`, `GenerarProyectoPayloadSchema`).
  - On validation errors, log details and respond with HTTP `400` plus a `details` array of Zod issues.
  - On unexpected errors, log the error and respond with HTTP `500` and a generic message.
  - In long‑running handlers, check `res.headersSent` before sending an error response.
- Next.js API routes (`next-app/src/app/api/.../route.ts`):
  - Wrap Prisma calls and external HTTP calls in `try/catch`.
  - Return via `NextResponse.json`, including at least `status`, `timestamp`, and a short `error` message on failure (see `src/app/api/health/route.ts` for a pattern).
- Telegram bot (`telegram-bot/src/index.ts`):
  - Catch and log errors around network calls and Telegram API interactions.
  - Send user‑friendly error messages in Spanish and avoid leaking internal stack traces to users.

## Logging

- `telegram-bot/` and `next-app/` include a `winston`‑based logger; use the shared `logger` utilities instead of raw `console.log` in these packages.
- `automatizaciones/` currently relies on `console.log` with ANSI coloring; when modifying existing logs, keep the style consistent and avoid introducing `winston` here unless explicitly requested.
- Log enough context to debug (ids, key parameters, durations) but avoid logging secrets, full JWTs, or large raw payloads.

## Database and Prisma usage

- Always `await` Prisma calls and handle errors with `try/catch`.
- In long‑running Node processes (`automatizaciones`, `telegram-bot`), create a single Prisma client per process and disconnect on shutdown if needed.
- In Next.js, use the existing helper at `next-app/src/lib/prisma.ts`, which manages a singleton client across hot reloads.
- When adding new queries, keep them in small, focused helper functions to make them easier to test and reuse.

## HTTP and API conventions

- `next-app` API routes live under `src/app/api/**/route.ts` (App Router handlers).
- Prefer RESTful naming and HTTP verbs (`GET` for reads, `POST` for creates/actions, etc.).
- Keep handlers small; delegate complex logic to helpers under `src/lib/` or domain modules.
- When returning errors, always include a machine‑readable `status` field and a human‑oriented `error` string in the JSON response.
- For user‑facing messages (bot responses, UI text), Spanish is preferred as in existing code.

## Agent workflow expectations

- Before changing code, identify which package you are operating in and run only the relevant commands (`npm run lint`, `npm run e2e`, etc.) in that package.
- For non‑trivial changes in `next-app`, at minimum run `npm run lint`; for E2E‑related changes, also run `npm run e2e` or the specific Playwright test you touched.
- For server changes in `automatizaciones/` or `telegram-bot/`, prefer lightweight manual checks (for example hitting health endpoints or starting the bot) if automated tests are unavailable.
- Make minimal, focused edits; avoid refactors that cross package boundaries unless explicitly requested.
- When you add new commands, tests, or global conventions, update this `AGENTS.md` file accordingly.
