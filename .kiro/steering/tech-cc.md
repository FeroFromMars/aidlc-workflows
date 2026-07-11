# World Runner Control Center – Tech Stack & Build System

> **Scope**: This file describes the `world-runner-cc/` repository.
> All paths and commands below are relative to `world-runner-cc/`.
> For the main application, see `tech.md`.
> For the Figma UI source, see `WorldRunnerControlFigma/` (readonly).

## Core Stack

| Layer | Technology |
|---|---|
| Framework | Next.js 14 (App Router, React Server Components) |
| UI | React 18, TypeScript |
| Styling | Tailwind CSS v4, shadcn/ui (Radix primitives) |
| API | Next.js Route Handlers (REST-style) |
| Validation | Zod (server-side schemas, `safeParse` at route boundaries) |
| ORM | Prisma 5 |
| Database | PostgreSQL 16 (Docker for local dev) |
| Auth | TBD — admin-only access; likely shared cookie or token-based |
| Testing | Vitest |
| Language | TypeScript 5 end-to-end |

## Key Libraries

- `zod` – input validation and schema inference
- `@prisma/client` – generated DB client
- `tailwind-merge` – merge Tailwind classes without conflicts
- `class-variance-authority` – component variant management
- `clsx` – conditional class name composition
- `lucide-react` – icon set (matches Figma source)
- `@radix-ui/*` – accessible primitives (via shadcn/ui)

## Dependency Policy

Same as `world-runner`: **new libraries or tools require explicit approval from the human owner before being added.**

Exception: shadcn/ui component additions (which pull in specific `@radix-ui/*` packages) are pre-approved since the component library is already adopted.

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

# Testing
npx vitest --run           # run tests once (non-watch)
npm run test               # run Vitest in watch mode (for active development)
```

## Environment

Copy `.env.example` → `.env`. Expected variables:

- `DATABASE_URL` – Prisma connection string (postgres, separate DB from world-runner)
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_PORT` – Docker Compose defaults

The control center uses its own database, separate from `world-runner`. They communicate only through published policy snapshots.

## TypeScript / Path Aliases

`@/` maps to `src/`. Always use `@/` aliases. Never use relative `../` imports across domain boundaries.

## Testing Conventions

- Framework: Vitest
- Test files are **co-located** with the module they test
- Use `--run` flag for single-pass execution
- Tests belong at the service layer

## CSS / Styling

- **Tailwind CSS v4** is the styling system — utility-first classes are the standard.
- **shadcn/ui** provides the component primitives (built on Radix).
- Design tokens are defined as CSS custom properties in theme files (sourced from Figma).
- Fonts: DM Sans (body), JetBrains Mono (monospace/labels).
- No CSS modules or BEM. Tailwind utilities are the convention.
- Inline `style={{}}` props are acceptable in Figma-sourced files; avoid in production-authored code unless necessary for dynamic values.

**This differs from `world-runner`**, which uses semantic CSS classes. The CC adopts Tailwind because it matches Figma output and minimizes translation friction.

## Figma UI Source

The canonical UI reference lives in `WorldRunnerControlFigma/` (readonly repo). The workflow is:

1. Figma Make exports update `WorldRunnerControlFigma/`.
2. Relevant components, styles, and theme tokens are copied into `world-runner-cc/`.
3. Figma-sourced files live in a designated directory (e.g., `src/components/figma/`).
4. These files are exempt from the 200-line limit and inline style rules — see `workspace.md` for details.
5. Production components that wrap or extend Figma sources follow normal CC coding rules.

When the Figma repo updates, the diff is reviewed and relevant changes are propagated manually into `world-runner-cc`.

## Domain Boundaries

The control center is organized around bounded contexts:

| Context | Responsibility |
|---|---|
| `catalog` | Feature definitions (name, description, classification) |
| `policy` | Global state and entitlement rules |
| `plans` | Subscription tier definitions |
| `publication` | Snapshot generation, versioning, and serving |
| `audit` | Administrative event log |

## Architectural Constraints

- The control center does NOT import from or depend on `world-runner` code.
- The control center does NOT serve user-facing product UI.
- The only shared artifact is the published policy snapshot contract.
- The control center has its own Prisma schema and database — no shared tables with `world-runner`.
- Policy snapshots are the stable API boundary. Internal schema changes in CC do not break `world-runner`.

## Relationship to world-runner

```
world-runner-cc                    world-runner
┌─────────────────┐               ┌─────────────────┐
│ Feature catalog │               │                 │
│ Policy rules    │──publishes──▶ │ Cached snapshot │
│ Plan defs       │  snapshots    │ Local eval      │
│ Audit log       │               │ Offline-safe    │
└─────────────────┘               └─────────────────┘
```

`world-runner` pulls snapshots on a schedule or event trigger, caches locally, and evaluates policy without round-tripping to the control center.
