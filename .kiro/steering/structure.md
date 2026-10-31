# World Runner – Project Structure & Coding Standards

> **Scope**: the `world-runner/` application repository. All paths below are relative to `world-runner/` unless noted.
> Workspace layout: `workspace.md`. Terms: `glossary.md`. Identifier naming: `naming.md`. UI patterns: `ui-composition.md`.

## Directory Layout

```
src/
├── app/                       Next.js App Router: routes, pages, layouts
│   ├── layout.tsx             Root layout: theme/hand bootstrap + global providers
│   ├── *Provider.tsx          Global client providers (Query, ActiveGame, ActiveSetting,
│   │                          UserPreferences, SettingConfigure)
│   ├── api/                   Route Handlers (HTTP controllers only), one folder per domain
│   ├── login/ register/       Auth gate
│   ├── preferences/           User context: hub, games, settings, calendar-configs
│   ├── profile/               User context: profile
│   ├── content/               Setting context: notes, timelines, trackers, rules, import
│   ├── games/[gameId]/dm/     In-Game context: dashboard, notes, time, trackers, rules, import
│   ├── admin/                 Public context: login, (panel)/ gated route group, components/
│   ├── settings/              Redirect stub → /preferences
│   ├── globals.css            Global semantic styles
│   └── theme.css              Design tokens (light/dark)
│
├── server/                    All server-side business logic, one folder per domain
│   ├── <domain>/<useCase>.ts       Single-purpose service function
│   ├── <domain>/<useCase>.test.ts  Co-located tests
│   ├── <domain>/schemas.ts         Zod schemas + inferred types
│   └── domains: admin, archetypeImport, archetypeIndex, auth, events, fantasyTime,
│                games, images, keywordTypes, keywords, notes2 (= Notes), rules,
│                settings, trackers, user, userPreferences
│
├── components/                Shared UI. Top level = app-wide primitives and shell
│   │                          (AppShell, ContextBar, ContextSelector, NavigationRail,
│   │                          MobileDrawer, FlippableRow, Skeleton, ShortcutGuide…)
│   └── <feature>/             Feature component folders: archivist, aux-panel, calendar,
│                              calendarConfig, dice, editor (Editor Core + WRText), game,
│                              import, keywords (keyword CRUD UI shared by the Aux-Panel
│                              and editors), notes, rules, snippets, spotlight, time-controls
│
├── lib/                       Client-safe and isomorphic libraries
│   ├── prisma.ts              Singleton PrismaClient — the ONLY place it is instantiated
│   ├── queryClient.ts, queryKeys.ts   TanStack Query client + centralized key factory
│   ├── commands/              Command registry (commands.md)
│   ├── time/                  Centralized time management (time-management.md)
│   ├── notes/                 NoteProvider, persist pipeline, migration, keywords, images
│   ├── richText/              Content Registry, Editor Profiles, validateRichTextDocument (isomorphic)
│   ├── archetypes/            Archetype registry + one folder per archetype, import, guidance
│   ├── snippets/              SnippetContent types + extraction
│   ├── dice/, diceRolling/    Pure dice math/roller; rollable-surface interaction layer
│   ├── dnd55e/                D&D 5.5e rules tables + options provider
│   ├── quickFormats/, rules/, fantasyTime/
│   └── sessionSelection.ts, lastAppContext.ts, recentContexts.ts, activeGame.ts, theme.ts, …
│
└── test/setup.ts              Vitest setup (jest-dom matchers)

prisma/
├── schema.prisma              Source of truth for all DB models
├── migrations/                Append-only. Never edit applied migrations manually
└── seed.js                    Idempotent dev seed (systems, keyword types, system user, dev admin)

scripts/                       One-off operational scripts (bootstrap-admin.js, backfills)
```

`src/server/api/trpc`, `src/server/repositories`, and `src/server/services` are empty placeholders. Do not add code there. tRPC is not used.

---

## Architectural Layers

### 1. Route Handlers (`src/app/api/<domain>/route.ts`)

Controllers only. The handler body is:
1. Authenticate: read `wr_userId` from cookies → 401 if absent. Admin routes gate through `requireAdmin` → 403.
2. `safeParse` the request body/query with a Zod schema → 400 on failure.
3. Call a service → map the discriminated-union result to an HTTP response.

No business logic. No Prisma imports. No `if/else` beyond auth and response mapping. GET handlers never mutate.

### 2. Server Services (`src/server/<domain>/`)

One file per use case (`createGame.ts`, `setGameCanonical.ts`, `deleteNote.ts`). Never a monolithic `service.ts`.

- Import `prisma` from `@/lib/prisma`. Never accept it as a parameter.
- Return typed discriminated unions: `{ ok: true; ... } | { ok: false; reason: 'REASON' }`.
- Use `prisma.$transaction` for multi-step writes.
- Deletes (ADR-0010): run a preflight "in use" check, then delete dependents before the parent in one transaction.
- Validate input and ownership defensively even if the route already did. Services are also called from server components.
- Extract decision logic into pure functions (e.g. `decideKeywordAction`, `isEventVisibleInSettingContext`, `buildArchetypeIndexWhere`) so it can be property-tested.
- Never return `BigInt` fields to JSON; select serializable fields explicitly.

### 3. Zod Schemas (`src/server/<domain>/schemas.ts`)

- Defined alongside the domain; export inferred types with `z.infer<typeof schema>`. A domain may split schemas by surface when it grows (e.g. `notes2/spotlightSchemas.ts`).
- Required strings: `z.string().trim().min(1, 'Field is required.')`. Bound lengths and bulk inputs.
- Keep schemas server-side unless explicitly shared.

### 4. Server Components / Pages (`src/app/`)

- Authenticate via the `wr_userId` cookie; `redirect('/login')` if absent. Admin panel pages are gated by `admin/(panel)/layout.tsx`.
- Call domain services directly. No HTTP round-trips.
- Pass minimal, serializable props to client components.
- Keep pages small. Move complex loading into a dedicated loader service.
- Resolve the active Setting server-side with `resolveActiveSettingId(userId, preferredSettingId)` from the `wr_settingId` cookie.

### 5. Client Components

Start with `'use client'`.

- **No Prisma. No server service imports.** All server access goes through `/api/...` route handlers.
- **Reads** use TanStack Query hooks keyed from `src/lib/queryKeys.ts`. **Mutations** use `useMutation` and invalidate every query key that displays the changed data. The full rules are in `ux.md` § Server State Management. The user must never need a manual refresh to see the result of a create, update, or delete.
- Time-scoped data comes from the Event Store and time commands (`time-management.md`), never from direct fetches.
- Setting-scoped UI must follow client-side Setting switches: key queries on the live `useActiveSetting()` value, and seed `initialData` only when it matches the server-rendered Setting.
- Use skeleton placeholders (`src/components/Skeleton.tsx`) for SSR-hydrated selections (ADR-0011).
- Keyboard handling goes through the command registry (`commands.md`).

---

## Component Rules

### Hard size limit (ADR-0007)
**A component file must not exceed 200 lines**, including JSX. If it does, split it. Files you touch must end at or under the limit. Known oversized legacy files (e.g. `InGameCalendar.tsx`, `DaySchedule.tsx`) are debt. Do not grow them.

### Decomposition pattern
Extract a piece when:
- A block of JSX has its own local state.
- It renders conditionally on a `mode` or `isAdmin` prop.
- A modal, dialog, or overlay has its own state.
- A table and its row editing logic are embedded in a parent.

Name extracted components for what they do: `RulesListGrid`, `ScopeToggle`, `DeleteConfirmDialog`, `GameTimeToggleFields`.

### Props discipline
- Type props with an explicit local `type Props = { ... }`.
- Avoid prop drilling deeper than 2 levels. Compose or co-locate state.
- **No semantic mode props** (`mode="adminShared"`). Inject transport and capabilities instead (`apiBase`, `endpoint`, `canEdit`, `editable`), or compose two focused components. The admin panel reuses user components this way.
- State and commands live in split contexts (`useXState` / `useXCommands`). Use `*Safe` hooks (no-op outside the provider) for optional providers.

### Styling
- No inline `style={{}}` for static styling (ADR-0008). Use `globals.css` or a co-located CSS module, with theme tokens (`tech.md` § CSS / Styling).
- Allowed inline exceptions: computed geometry (resize widths, measured absolute positions) and data-driven colors from user content (e.g. note color marks in the read-only renderer). Keep all static styling in CSS.
- Existing static inline styles are debt. Migrate them when you touch the file.

### Left-handed layout
Rows with a primary-action side use `FlippableRow`. Follow `ux.md` § Left-Handed Mode.

### Test IDs for automation
Add `data-testid` to interactive elements (buttons, inputs, links, forms, selects). Use the form `{component}-{element-role}` (e.g. `login-form-submit-button`). Keep values stable, and rename only when the element's purpose changes. No dynamic or generated IDs.

### Icons
Use `@tabler/icons-react` only. No emojis or Unicode symbols as icons.

### Component placement
- `src/components/` top level: app-wide primitives and shell pieces usable by unrelated screens (`FlippableRow`, `Skeleton`, `DeleteConfirmDialog`).
- `src/components/<feature>/`: feature component folders shared by more than one route or context (e.g. `rules/` serves Setting, In-Game, and Admin).
- Components used by a single route live next to that route in `src/app/`.
- When a route-local component gains a second consumer, move it to `src/components/`.

### Editor extensions
- Content node and mark types are declared once in the Content Registry (`src/lib/richText/contentRegistry.ts`) with a profile gate and read-only render kind, and get their TipTap extension in `src/components/editor/extensionFactories.ts`. `buildEditorExtensions(profile, options)` (`src/components/editor/`), the persist allowlist (`validateRichTextDocument`), and the read-only render model all derive from it; never add a parallel allowlist.
- Editor capabilities (headings, images, collapse, drag handle, size limits…) are switched by Editor Profiles (`src/lib/richText/editorProfiles.ts`), not by forking editors. New editors host the Editor Core (`useEditorCore`); `src/components/editor/**` never imports NoteProvider, the note save hook, or the Aux-Panel (source-analysis test).
- Interactive editor behavior belongs in ProseMirror plugins or NodeViews, not React event handlers.
- Vanilla NodeViews mount React with `createRoot` and talk to their host through CustomEvents on the per-editor bus (`dispatchEditorEvent` / `useEditorEvent` on `editor.view.dom`), never on `window`.

---

## Naming Conventions

Identifier rules (no abbreviations) are in `naming.md`.

| Thing | Convention | Example |
|---|---|---|
| Domain folders | camelCase | `fantasyTime`, `userPreferences`, `archetypeIndex` |
| Use-case files | verbNoun | `createGame.ts`, `listRulesForCategory.ts` |
| Schema files | `schemas.ts` per domain | `src/server/games/schemas.ts` |
| API route files | `route.ts` (Next.js) | `src/app/api/games/route.ts` |
| Page files | `page.tsx` (Next.js) | `src/app/content/notes/page.tsx` |
| Client components | PascalCase noun | `RulesView.tsx`, `CreateGameModal.tsx` |
| Tests | `<module>.test.ts(x)`; property tests `<module>.property.test.ts`; contract tests `<module>.contract.test.ts` | `eventVisibility.property.test.ts` |
| CSS classes | kebab-case, prefixed by component/area | `.rules-list-grid`, `.nav-rail` |

---

## Prisma Rules

- `schema.prisma` is the single source of truth. Never edit applied migration SQL. History is append-only.
- Run `npm run prisma:generate` after every schema change.
- DB-mutating steps (`prisma:migrate`, destructive migrations, backfill scripts) need the owner's go-ahead.
- Always use `select` or `include` explicitly. Never return whole model objects to the client. Notes use the ADR-0022 projections: `NOTE_METADATA_SELECT` for lists and search. Only the document loader returns `content`.
- Seeds and staged migrations use idempotent upserts (ADR-0012).
- Ownership conventions:
  - User content carries a required owner (`Setting`, `Game`, `Note` have a required `ownerUserId`).
  - Public notes are owned by `SYSTEM_USER_ID` with `ownerContext = PUBLIC` and no setting or game.
  - Public calendar configs and template timelines use `ownerUserId = null` (template timelines also have `settingId = null`).
- Note scope: exactly one of `settingId` / `gameId` is set (none for PUBLIC). Queries scope by gameId **or** settingId, never both; game rows have `settingId = null`.
- Archetype notes and their `ArchetypeIndex` rows are stamped with a `systemId`. User content gets the Setting's main system; public content gets the admin-selected system.

---

## Security Baseline

> **Authority**: ADR-0029 (supersedes ADR-0003). Applies to all code whether or not the AI-DLC Security extension is enabled. Items marked *production blocker* are tracked in `world-runner-docs/main/production-readiness-plan.md`. They are not done until that plan says so.

### Authentication and identity
- Identity comes only from the server-read `wr_userId` cookie (`httpOnly`, `sameSite=lax`, `path=/`). Never read a `userId` from a request body or query.
- Enforce auth in two places: the route handler (cookie → 401) and the service (ownership → `FORBIDDEN`/`NOT_FOUND`). Both are required.
- Passwords use bcryptjs (cost ≥ 10). Login returns a generic `INVALID_CREDENTIALS`, so accounts cannot be enumerated. Never log credentials or hashes.
- *Production blockers*: signed/encrypted session; `secure` flag, expiry, and server-side revocation; login brute-force protection; CSRF token.

### Admin and public content
- Admin capability is `User.isAdmin`, verified server-side with `requireAdmin` (`src/server/admin/requireAdmin.ts`). It fails closed.
- **No scope-as-authorization.** User-facing scope unions (e.g. `RulesScope = setting | game`) never gain `public`. A user handler that receives an unexpected scope rejects it.
- **Public writes only through admin-gated entrypoints** (`/api/admin/*` + `src/server/admin/*`). Each one re-verifies admin identity in the service. User-facing write handlers never gain a public branch.
- **Ownership is server-assigned** from the verified principal. Public ownership comes only from `publicNoteOwnership()`. Client payloads never carry owner, scope, or "make public" fields.
- Public reads are read-only for non-admins (`editable = false`). The public partition is strictly `ownerUserId = SYSTEM_USER_ID AND ownerContext = PUBLIC AND settingId IS NULL AND gameId IS NULL`. Never leak other users' rows.

### Injection and rendering
- Use the Prisma query builder only. No `$queryRaw`, `$executeRaw`, or raw SQL.
- Note content is ProseMirror JSON validated by `validateNoteContent` (structural allowlist). Never render user content as raw HTML.
- `dangerouslySetInnerHTML` is reserved for the theme bootstrap script. Snippets and keywords render with `createElement` + `textContent`, never `innerHTML`.
- Never persist `blob:` / `data:` image sources or `pending: true` image blocks.

### Requests and uploads
- GET handlers never mutate state.
- Validate all route input with Zod `safeParse`. Bound bulk inputs (e.g. `MAX_PUBLIC_IMPORT_ENTRIES`).
- Uploads are untrusted:
  - Enforce the pre-decode byte cap and magic-byte format detection. Reject SVG.
  - Re-encode server-side (sharp → WebP), clamp dimensions, and use server-generated filenames.
  - Client validation is UX only.
- *Production blockers*: JSON body-size cap, per-principal throttling on expensive operations, pagination bounds.

### Secrets and seed
- No hardcoded production secrets. Configuration comes from the environment. Never echo `.env` values.
- Dev-seed credentials are dev-only. *Production blocker*: the seed must refuse to run outside development. Production admins are bootstrapped with `node scripts/bootstrap-admin.js <email> <password> "Display Name"`.

---

## Workflow & Scope

### Source of truth for work items
- Work comes from **Feature Designs** (`world-runner-docs/designs/FD-NNNN-*.md`) and the iteration **stories** in `world-runner-docs/ai-dlc-docs/WR1/WR1-itN/stories.md`.
- Work item IDs:
  - Iteration stories: `WR1-itN-SNN`.
  - FD-driven features: `WR1-F<NNN>`. The FD's "Work Item" field records the ID.
  - Tech debt: `WR1-T<NNN>`.
- Every work item runs through the AI-DLC workflow. Its records go where `aidlc-docs.md` says. `.kiro/specs/` is not used.
- Spikes and small ad hoc changes may be done in conversation. Record them afterwards in the iteration `stories.md` with commit hashes.

### Before starting any task
1. Read the FD and the relevant ADRs in `world-runner-docs/adr/` for the domain.
2. Check `glossary.md` for the terms involved and `ui-composition.md` for the surface pattern.
3. Check `world-runner-docs/main/system-map.md` and `mvp-plan.md` when scope or dependencies are unclear.

### During implementation
- Implement exactly what the approved FD, story, or requirements say. No extra features. No "while I'm here" refactors outside scope.
- Surfaces you touch get brought up to current standards: TanStack Query + invalidation, `useCommand`, `FlippableRow`, theme tokens, no inline styles, `data-testid`, ≤ 200 lines.
- Surface follow-ups as notes for the owner. Do not act on them unilaterally.
- If a requirement is ambiguous, ask before coding.

### Documentation rules
- **Architectural decisions** → ADR in `world-runner-docs/adr/` (see its README for when). Write an ADR *before* destructive or domain-removing code work.
- **Feature design** → FD in `world-runner-docs/designs/`.
- **Process records** → AI-DLC folder (`aidlc-docs.md`).
- **New or changed terms** → `glossary.md`.
- **`world-runner-docs/deprecated/`** → read-only history. Never the primary source.
