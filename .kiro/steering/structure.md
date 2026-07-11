# World Runner – Project Structure & Coding Standards

> **Scope**: This file describes the `world-runner/` application repository.
> All paths below are relative to `world-runner/` unless otherwise noted.
> For the multi-repo workspace layout, see `workspace.md`.

## Directory Layout

```
src/
├── app/              Next.js App Router: routes, pages, layouts
│   ├── api/          Route Handlers (HTTP controllers only)
│   ├── admin/        Admin shell and sub-routes
│   ├── games/        Games listing and per-game routes
│   ├── characters/   Character management and builder
│   ├── content/      DM content management (collections, currency)
│   ├── profile/      User profile
│   ├── login/        Auth pages
│   └── register/
│
├── server/           All server-side business logic
│   ├── <domain>/     One folder per domain
│   │   ├── <useCase>.ts       Single-purpose service function
│   │   ├── <useCase>.test.ts  Co-located Vitest tests
│   │   └── schemas.ts         Zod schemas + inferred types
│   ├── auth/
│   ├── repositories/ (sparse; Prisma used directly in services for now)
│   └── api/trpc/     tRPC wiring (future)
│
├── components/       Shared, reusable UI components (no route logic)
└── lib/              Cross-cutting utilities
    ├── prisma.ts     Singleton PrismaClient — the ONLY place it is instantiated
    ├── displayName.ts
    └── sessionSelection.ts

prisma/
├── schema.prisma     Source of truth for all DB models
├── migrations/       Never edit manually
└── seed.js
```

---

## Architectural Layers

### 1. Route Handlers (`src/app/api/<domain>/route.ts`)

Controllers only. The entire handler body is:
1. Read `wr_userId` from cookies → 401 if absent
2. `safeParse` the request body with a Zod schema → 400 on failure
3. Call a service function → map result to HTTP response

No business logic. No Prisma imports. No `if/else` beyond auth and response mapping.

### 2. Server Services (`src/server/<domain>/`)

One file per use case (`createGame.ts`, `updateGame.ts`, `deleteCollection.ts`). Never a single monolithic `service.ts` that does everything in a domain.

Rules:
- Import `prisma` from `@/lib/prisma`. Never accept it as a parameter.
- Return typed discriminated unions: `{ ok: true; ... } | { ok: false; reason: 'REASON' }`.
- Use `prisma.$transaction` for all multi-step writes.
- For deletes: run a preflight "in-use" check, then delete dependents before the parent, all within a single transaction.
- Validate input defensively even if the route already validated — services should be usable from server components too.

### 3. Zod Schemas (`src/server/<domain>/schemas.ts`)

- Define alongside the domain; export inferred types with `z.infer<typeof schema>`.
- Required strings: `z.string().trim().min(1, 'Field is required.')`.
- Keep schemas server-side unless explicitly shared with the client.
- Do not re-test Zod itself in service tests.

### 4. Server Components / Pages (`src/app/`)

- Authenticate via `wr_userId` cookie; `redirect('/login')` if absent.
- Call domain services directly for data — no HTTP round-trips.
- Pass minimal, serializable props to client components.
- Server components must never be oversized. If a page has complex data-loading logic, extract it into a dedicated `loadPageData` service function.

### 5. Client Components

Named with the `'use client'` directive at the top. Rules:
- **No Prisma. No direct service imports.** Mutations go through `/api/...` route handlers.
- Keep state minimal. Extract sub-components aggressively (see Component Rules below).
- Fetch mutations with `fetch` + typed response shapes — define the expected response type inline.
- **All CRUD operations triggered from the UI must reflect their result in the UI when the operation returns** — the user must never need a manual page refresh to see the effect of a create, update, or delete they just performed.
  - After a successful mutation that stays on the same route, call `router.refresh()` to re-sync server-rendered state.
  - After a successful mutation that navigates to another route (e.g., delete that returns to a list), call `router.refresh()` in addition to `router.push(...)` so the destination is not served from a stale client cache.
  - For optimistic UI, update local state immediately and still reconcile with the server via `router.refresh()`.
- Use skeleton placeholders (from `src/components/Skeleton.tsx`) for any SSR-hydrated selections to prevent hydration mismatches.

---

## Component Rules

These rules exist because the previous AI generated oversized, monolithic components that became impossible to maintain.

### Hard size limit

**A single component file must not exceed 200 lines** (including JSX). If it does, split it.

### Decomposition pattern

Extract pieces when:
- A block of JSX has its own local state → new component
- A piece renders conditionally based on a `mode` or `isAdmin` prop → new component
- A modal, dialog, or overlay has its own state → new component
- A table and its row editing logic are embedded in a parent → new component

Name extracted components for what they do: `CollectionSelector`, `ItemTable`, `CreateCollectionModal`, `DeleteConfirmDialog`.

### Props discipline

- Props should be typed with an explicit local `type Props = { ... }`.
- Avoid prop drilling more than 2 levels — compose or co-locate state.
- A component that accepts a `mode: 'content' | 'adminShared'` prop to change its behavior is a warning sign. Prefer two focused components that share a child, or pass specific capability flags (`canEdit`, `canDelete`) instead of semantic modes.

### No inline styles

Use CSS class names from `globals.css` or a co-located CSS module. Inline `style={{}}` props are not permitted in new code. Existing instances are tech debt to be migrated progressively.

### Test IDs for automation

Add `data-testid` attributes to interactive elements (buttons, inputs, links, forms, selects). Use consistent naming: `{component}-{element-role}` (e.g., `login-form-submit-button`, `timeline-list-create-link`). Keep values stable across code changes — only rename when the element's purpose changes. Avoid dynamic or auto-generated IDs that change between renders.

### Shared components (`src/components/`)

Use this directory for truly reusable primitives: `SkeletonBlock`, `ContentNavigationSidebar`, etc. Do not put route-specific logic here. A component in `src/components/` must be usable by at least two unrelated screens.

---

## Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Domain folders | camelCase | `currencySystems`, `itemCollections` |
| Use-case files | verbNoun | `createGame.ts`, `listUserGames.ts` |
| Schema files | `schemas.ts` per domain | `src/server/games/schemas.ts` |
| API route files | `route.ts` (Next.js) | `src/app/api/games/route.ts` |
| Page files | `page.tsx` (Next.js) | `src/app/games/page.tsx` |
| Client components | PascalCase + noun | `GamesPageContent.tsx`, `CollectionSelector.tsx` |
| Test files | `<module>.test.ts` | `createGame.test.ts` |
| CSS classes | kebab-case, prefixed | `.content-shell`, `.builder-panel` |

---

## Prisma Rules

- `schema.prisma` is the single source of truth. Never edit migration SQL files manually.
- Run `npm run prisma:generate` after every schema change.
- `ownerUserId = null` on `CurrencySystem` / `ItemCollection` means it is a shared/global (admin-managed) record.
- Always use `select` or `include` explicitly — avoid returning entire Prisma model objects to the client.

---

## Security Baseline

- Auth is enforced at two places: the route handler (cookie check) and the service (ownership check). Both are required.
- Never trust client-supplied `userId`. Always read it from the server-side cookie.
- Uploads: treat as untrusted; validate MIME type server-side; enforce size limits; never store the raw uploaded file path as a URL without sanitization.
- Passwords: always bcrypt. Never log credentials or password hashes.

---

## Workflow & Scope

### Before starting any task
1. Read the relevant ADRs in `world-runner-docs/adr/` for the domain you're working in.
2. Read the Kiro spec for the current work item (`.kiro/specs/<spec-id>/` at the workspace root).

### Source of truth for work items

**Kiro specs are the authoritative source for all work items** — features, bugs, and tech debt.

- Features use the `<repo-prefix>-F<NNN>-<name>` naming convention (e.g., `WR1-F001-...`, `WRCC-F001-...`).
- Bugs and tech debt use the `<repo-prefix>-T<NNN>-<name>` naming convention (e.g., `WR1-T001-...`, `WRCC-T001-...`).
- Spikes are worked on directly in conversation without a spec.

### During implementation
- Implement exactly what the spec says. No extra features. No "while I'm here" refactors outside scope.
- After implementation, surface follow-ups as notes for the human owner. Do not act on them unilaterally.
- If a spec task is ambiguous, ask before coding.

### Documentation rules
- **New features** → Kiro spec in `.kiro/specs/<spec-id>/` (workspace root)
- **Bugs and tech debt** → Kiro spec in `.kiro/specs/<spec-id>/` (workspace root)
- **Architectural decisions** → ADR in `world-runner-docs/adr/`
- **`world-runner-docs/deprecated/`** → READ-ONLY historical reference. Never the primary source for active work.
