# World Runner – Tech Stack & Build System

> **Scope**: This file describes the `world-runner/` application repository.
> All paths and commands below are relative to `world-runner/`.
> For `world-runner-cc`, see `tech-cc.md`.

## Core Stack

| Layer | Technology |
|---|---|
| Framework | Next.js 14 (App Router, React Server Components) |
| UI | React 18, TypeScript |
| API | Next.js Route Handlers (REST-style); tRPC wired but not yet the primary transport |
| Validation | Zod (server-side schemas, `safeParse` at route boundaries) |
| ORM | Prisma 5 |
| Database | PostgreSQL 16 (Docker for local dev) |
| Auth | Custom cookie-based session (`wr_userId` cookie, bcryptjs for password hashing) |
| Testing | Vitest |
| Language | TypeScript 5 end-to-end |

## Key Libraries

- `bcryptjs` – password hashing
- `zod` – input validation and schema inference
- `@prisma/client` – generated DB client (import via `@/lib/prisma`)

## Dependency Policy

**New libraries or tools require explicit approval from the human owner before being added.**

Before proposing a new dependency, ask:
1. Does a built-in or already-installed solution exist?
2. Is the package actively maintained with a clear license?
3. Does it meaningfully reduce code vs. a small custom implementation?

If yes to all three, propose it with justification. Do not add it unilaterally.

## Common Commands

```bash
# Development
npm run dev               # start Next.js dev server (run manually in terminal)

# Build & Production
npm run build             # production build
npm run start             # start production server

# Database
docker compose up -d db   # start local PostgreSQL container
npm run prisma:migrate     # create and apply migrations (dev)
npm run prisma:generate    # regenerate Prisma Client after schema changes
npm run prisma:studio      # open Prisma Studio (DB browser)
npm run prisma:seed        # seed the database

# Testing
npx vitest --run           # run tests once (non-watch, use in CI or verification)
npm run test               # run Vitest in watch mode (for active development)
```

## Environment

Copy `.env.example` → `.env`. Required variables:

- `DATABASE_URL` – Prisma connection string (postgres)
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_PORT` – Docker Compose defaults

## TypeScript / Path Aliases

`@/` maps to `src/`. Always use `@/` aliases. Never use relative `../` imports across domain boundaries.

## Testing Conventions

- Framework: Vitest
- Test files are **co-located** with the module they test (e.g., `createGame.test.ts` next to `createGame.ts`)
- Do not test Zod schemas directly; service tests operate on typed inputs derived from schemas
- Use `--run` flag for single-pass execution
- Tests belong at the service layer; do not test Prisma queries directly

## CSS / Styling

- Global styles live in `src/app/globals.css`. Use semantic class names following existing BEM-like conventions (e.g., `.nav-bar`, `.content-shell`, `.builder-panel`).
- **Do not use inline `style={{}}` props** for new code. Move styles to `globals.css` or a co-located CSS module.
- Existing inline styles are tech debt to be migrated — do not add more.
- Responsive rules: clamp panel width with `min(100%, 980px)`, enforce `box-sizing: border-box`, add `overflow-x: auto` on tables, clamp modal width with `min(Xpx, calc(100vw - 2rem))`.

### Completeness Rule

**Every `className` referenced in a component MUST have a corresponding CSS rule in `globals.css` (or a co-located CSS module).** No class name should be added to JSX without an accompanying style definition. Relying on browser defaults for layout, spacing, or typography is not acceptable — elements must be explicitly styled.

Before considering a component complete, verify that:
1. Every `className="..."` in the JSX has a matching selector in the stylesheet.
2. Interactive elements (buttons, inputs, links acting as buttons) have explicit `:hover`, `:disabled`, and `:focus-visible` states defined.
3. New form inputs match the existing field pattern: `padding: 0.5rem 0.75rem`, `border: 1px solid #d1d5db`, `border-radius: 6px`, `font-size: 0.9rem`.
4. New primary action buttons match the existing pattern: `padding: 0.6rem 1rem`, `border-radius: 8px`, `background: #2563eb`, `color: #fff`, `font-weight: 600`.
5. New secondary/cancel buttons match: `border: 1px solid #d1d5db`, `background: #fff`, `color: #374151`.
6. Destructive buttons match: `background: #dc2626`, `border-color: #dc2626`, `color: #fff`.

### Visual Consistency Patterns

Reference these established patterns when styling new UI. Do not invent new spacing, color, or radius values.

| Element | Pattern |
|---|---|
| Page container | `width: min(100%, 980px); margin: 0 auto; box-sizing: border-box` |
| Card/panel | `background: white; border: 1px solid #e5e7eb; border-radius: 8px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,0.04)` |
| List row (clickable) | `padding: 0.75rem 1rem; border: 1px solid #e5e7eb; border-radius: 8px; cursor: pointer` |
| List row hover | `background-color: #f9fafb` |
| Table header | `background-color: #f9fafb; font-weight: 600; color: #374151; font-size: 0.9rem` |
| Modal backdrop | `position: fixed; inset: 0; background: rgba(0,0,0,0.45); z-index: 30+` |
| Modal panel | `width: min(Xpx, calc(100vw - 2rem)); border-radius: 10px; padding: 1.25rem` |
| Empty state | `padding: 2rem 1rem; text-align: center; color: #6b7280; border: 1px dashed #d1d5db; border-radius: 8px; background: #f9fafb` |
| Error banner | `background: #fef2f2; border: 1px solid #fecaca; color: #b91c1c; border-radius: 6px` |
| Muted text | `color: #6b7280; font-size: 0.9rem` |
| Badge/pill | `padding: 0.15rem 0.5rem; border-radius: 999px; font-size: 0.75rem; font-weight: 600` |
