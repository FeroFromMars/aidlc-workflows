# World Runner – Tech Stack & Build System

> **Scope**: the `world-runner/` application repository. All paths and commands below are relative to `world-runner/`.

## Core Stack

| Layer | Technology |
|---|---|
| Framework | Next.js 14 (App Router, React Server Components) — ADR-0001 |
| UI | React 18, TypeScript 5 |
| API | Next.js Route Handlers (REST-style). No tRPC. |
| Server state (client) | TanStack Query v5 — ADR-0013 |
| Validation | Zod 3 (server-side schemas, `safeParse` at route boundaries) — ADR-0004 |
| ORM | Prisma 5 — ADR-0002 |
| Database | PostgreSQL 16 (Docker for local dev) |
| Auth | Cookie-based identity (`wr_userId`), bcryptjs — ADR-0029 (production blockers pending) |
| Editor | TipTap 3 / ProseMirror (block model, ADR-0018) |
| Icons | `@tabler/icons-react` |
| Images | `sharp` (server-side validation/re-encode) |
| Testing | Vitest 1, Testing Library, jsdom, fast-check (property-based) |

## Key Libraries

Runtime:
- `@prisma/client`: generated DB client. Import only via `@/lib/prisma`.
- `@tanstack/react-query` (+ `-devtools`): queries, mutations, and cache invalidation.
- `zod`: input validation and schema inference.
- `bcryptjs`: password hashing.
- `@tiptap/react`, `@tiptap/pm`, `@tiptap/starter-kit`, and the `@tiptap/extension-{color,highlight,placeholder,task-item,task-list,text-style,underline}` extensions: the note editor.
- `@dnd-kit/core`, `@dnd-kit/sortable`, `@dnd-kit/utilities`: drag and drop.
- `@tabler/icons-react`: the only icon set.
- `sharp`: image processing in `src/server/images/`.

Dev:
- `vitest`, `jsdom`, `@testing-library/react`, `@testing-library/jest-dom`: tests.
- `fast-check`: property-based testing, the sanctioned PBT framework.
- `prisma` (CLI), `typescript`, `@types/*`.

## Dependency Policy

**New libraries or tools need explicit approval from the human owner before they are added.**

Before proposing a dependency, check:
1. Is there a built-in or already-installed solution?
2. Is the package actively maintained, with a clear license?
3. Does it meaningfully reduce code compared with a small custom implementation?

If all three are yes, propose it with a justification. Do not add it unilaterally. Some candidates have already been evaluated and rejected (e.g. Floating UI, client compression libraries, 3D dice), so do not re-propose them without new reasons.

## Common Commands

```bash
# Development
npm run dev                # start Next.js dev server (run manually in a terminal)

# Build & Production
npm run build              # production build (don't run while the dev server is running; clear a stale .next if needed)
npm run start              # start production server

# Type check
npx tsc --noEmit           # full type check

# Database
docker compose up -d db    # start local PostgreSQL container
npm run prisma:migrate     # create and apply migrations (dev) — owner go-ahead required
npm run prisma:generate    # regenerate Prisma Client after schema changes
npm run prisma:studio      # open Prisma Studio
npm run prisma:seed        # idempotent dev seed

# Testing
npx vitest --run           # run all tests once (use for verification)
npx vitest --run <path>    # run a subset
npm run test               # Vitest watch mode (active development)
```

There are no lint or typecheck npm scripts. Use `npx tsc --noEmit`.

## Environment

Copy `.env.example` → `.env`. Required keys:
- `DATABASE_URL`: Prisma connection string (postgres).
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_PORT`: Docker Compose defaults.

Never commit `.env` or echo its values.

## TypeScript / Path Aliases

`@/` maps to `src/` (tsconfig and Vitest). Always use `@/` aliases. Never use relative `../` imports across domain boundaries. Strict mode is on.

## Testing Conventions

- Test files are **co-located** with the module they test.
- `*.test.tsx` runs in `jsdom` and `*.test.ts` runs in `node`. Rename a test to `.tsx` if it needs `document`.
- `src/test/setup.ts` provides the jest-dom matchers. Vitest globals are off, so import `describe`/`it`/`expect` and call `cleanup()` in `afterEach` for render tests.
- **Service tests** mock Prisma and run on typed inputs. Do not test Zod itself or Prisma queries directly.
- **Pure libraries** (`src/lib/*`, pure server helpers) get example tests plus property tests.
- **Source-analysis tests**, which read source and assert on patterns, are valid for structural rules, decommissions, and security routing (e.g. no `public` scope in user handlers).
- **Contract tests** (`*.contract.test.ts`) guard cross-module invariants (e.g. archetype import parity, see `archetype-import-sync.md`).
- There is no automated E2E harness and no test database. The owner runs manual integration checks, so document the manual path in the build-and-test summary.
- Known noise (not introduced by new work): an intermittent stackless jsdom-teardown "Unhandled Error", and pre-existing `tsc` errors in `src/lib/time/eventStoreInternal.test.ts`.

### Property-Based Testing (fast-check)

- Target pure logic: invariants, round-trips (serialization, import → block data), idempotence, and oracles.
- Name property tests `*.property.test.ts` and co-locate them. Keep example tests in separate `describe` blocks or files; examples pin the FD cases.
- Reuse domain arbitraries (`src/lib/dnd55e/testGenerators.ts`, `src/lib/archetypes/statblock/testGenerators.ts`, import `fixtures/generators.ts`) instead of raw primitives.
- Keep default shrinking and seed logging. A counterexample that exposes a bug becomes a permanent example test.
- UI and wiring layers are example-tested only.

### Component and Hook Testing

- Use `@testing-library/react`: `render` + screen queries for components, `renderHook` for hooks.
- Dispatch command-registry keyboard events on `document`.
- Guard `scrollIntoView`. jsdom lacks `caretPositionFromPoint`.

### React Query Testing

1. Create a fresh `QueryClient` per test. Never share clients across tests.
2. Wrap in `QueryClientProvider` with retry disabled and infinite staleTime:
   ```tsx
   const queryClient = new QueryClient({
     defaultOptions: { queries: { retry: false, staleTime: Infinity } },
   });
   <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
   ```
3. Mock `fetch` globally in `beforeEach` to return controlled responses.
4. Use `waitFor` for assertions on async results.
5. Invalidation tests: after `queryClient.invalidateQueries(...)`, assert refetch behavior with `waitFor`.
6. Test your hook or component's behavior, not React Query internals.

## CSS / Styling

- Global styles: `src/app/theme.css` (tokens, imported first) and `src/app/globals.css` (semantic classes). Use prefixed, BEM-like semantic class names (e.g. `.nav-rail`, `.rules-list-grid`).
- **CSS modules** are used for archetype displays (`src/lib/archetypes/**/*.module.css`) with dedicated per-archetype tokens (e.g. `--sb-*` for the stat block). Dark variants use `:global([data-theme='dark'])`. Other new UI uses `globals.css`.
- **No inline `style={{}}`** for static styling. Exceptions are listed in `structure.md` § Styling.
- Responsive rules:
  - Clamp panel width with `min(100%, 980px)` and enforce `box-sizing: border-box`.
  - Add `overflow-x: auto` on tables.
  - Clamp modal width with `min(Xpx, calc(100vw - 2rem))`.

### Theme Tokens Rule (Mandatory, ADR-0015)

**All CSS must use design tokens from `src/app/theme.css` for colors, backgrounds, and borders.** Hardcoded hex/rgb values and named colors are prohibited in new or modified rules.

Tokens have light and dark values under `:root, [data-theme='light']` and `[data-theme='dark']`. Categories:
- Surfaces: `--color-bg`, `--color-surface`, `--color-surface-raised`, `--color-surface-hover`
- Text: `--color-text`, `--color-text-secondary`, `--color-text-muted`, `--color-text-on-primary`
- Borders: `--color-border`, `--color-border-strong`
- Actions: `--color-primary`, `--color-primary-hover`, `--color-primary-surface`, `--color-accent`, `--color-accent-hover`, `--color-accent-surface`, `--color-arcane`, `--color-arcane-surface`
- Feedback: `--color-danger`, `--color-danger-hover`, `--color-danger-surface`, `--color-danger-border`, `--color-success`, `--color-success-surface`, `--color-warning`, `--color-warning-surface`
- Focus: `--color-focus`
- Event categories: `--event-color-{game,global,other}`, `--event-text-{game,global,other}`
- Note palette: `--note-color-{default,gray,brown,orange,yellow,green,blue,purple,pink,red}`, `--note-bg-{…same}`
- Brand/raw primitives (`--brand-*`, `--mist-*`, `--slate-*`, `--wizard-*`, `--starlight-*`, `--moon-white`): only for defining semantic tokens inside `theme.css`. Do not use them directly in component CSS.

If a needed semantic token does not exist, add it to `theme.css` with both light and dark values. The ADR-0015 migration phases are complete. About 25 domain-specific hex values remain as known debt; replace them when you touch those rules.

Archetype color themes: Spell → arcane (purple), Equipment and Magic Item → accent (blue), Rule → success (green).

### Completeness Rule

**Every `className` referenced in a component must have a matching CSS rule** in `globals.css` or its CSS module. Do not rely on browser defaults for layout, spacing, or typography.

Before calling a component complete, verify:
1. Every `className="..."` has a matching selector.
2. Interactive elements have explicit `:hover`, `:disabled`, and `:focus-visible` states.
3. Form inputs follow the field pattern: `padding: 0.5rem 0.75rem`, `border: 1px solid var(--color-border)`, `border-radius: 6px`, `font-size: 0.9rem`, `background: var(--color-surface-raised)`, `color: var(--color-text)`.
4. Primary buttons: `padding: 0.6rem 1rem`, `border-radius: 8px`, `background: var(--color-primary)`, `color: var(--color-text-on-primary)`, `font-weight: 600`.
5. Secondary/cancel buttons: `border: 1px solid var(--color-border)`, `background: var(--color-surface-raised)`, `color: var(--color-text)`.
6. Destructive buttons: `background: var(--color-danger)`, `border-color: var(--color-danger)`, `color: var(--color-text-on-primary)`.
7. Rows inside `FlippableRow` use `gap` for spacing, not directional margins. Left-handed overrides are defined where needed (`ux.md`).

### Visual Consistency Patterns

Reuse these patterns. Do not invent new spacing, color, or radius values.

| Element | Pattern |
|---|---|
| Page container | `width: min(100%, 980px); margin: 0 auto; box-sizing: border-box` |
| Card/panel | `background: var(--color-surface-raised); border: 1px solid var(--color-border); border-radius: 8px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,0.04)` |
| List row (clickable) | `padding: 0.75rem 1rem; border: 1px solid var(--color-border); border-radius: 8px; cursor: pointer` |
| List row hover | `background-color: var(--color-surface-hover)` |
| Table header | `background-color: var(--color-surface); font-weight: 600; color: var(--color-text-secondary); font-size: 0.9rem` |
| Modal backdrop | `position: fixed; inset: 0; background: rgba(0,0,0,0.45); z-index: 30+` |
| Modal panel | `width: min(Xpx, calc(100vw - 2rem)); border-radius: 10px; padding: 1.25rem; background: var(--color-surface-raised)` |
| Empty state | `padding: 2rem 1rem; text-align: center; color: var(--color-text-muted); border: 1px dashed var(--color-border); border-radius: 8px; background: var(--color-surface)` |
| Error banner | `background: var(--color-danger-surface); border: 1px solid var(--color-danger-border); color: var(--color-danger); border-radius: 6px` |
| Muted text | `color: var(--color-text-muted); font-size: 0.9rem` |
| Badge/pill | `padding: 0.15rem 0.5rem; border-radius: 999px; font-size: 0.75rem; font-weight: 600` (also used for the system decoration tag) |

Shadow and backdrop `rgba` values in this table are the only sanctioned non-token colors.
