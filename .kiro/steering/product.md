# World Runner – Product Summary

World Runner is a web application that helps Dungeon Masters prepare and run tabletop RPG sessions with less bookkeeping. It is not a virtual tabletop (VTT). It complements any VTT or live pen-and-paper play and never replaces them. It gives the DM practical tools for note taking, world preparation, time and event tracking, rules reference, dice, and at-a-glance session running, with lean setup.

World Runner is **DM-only** (ADR-0028). There is no player-facing scope, not even a deferred one.

Desktop and mobile web are both in scope. The product aims for table-ready utility with consistent UX and aesthetics. Its values are in `world-runner-docs/main/manifesto.md`: ease of use and less prep work win conflicts; information at a glance; shortcuts and quick access everywhere.

Terminology is defined in `glossary.md`. Use it.

## Application Contexts

The application has four contexts. Each has its own navigation, surfaces, and access rules. **The user must always know which context they are in.** `world-runner-docs/main/navigation-architecture.md` §2 holds the detailed definition. When writing requirements, tag each one with its context: **User**, **Setting**, **In-Game**, or **Public**. If a feature spans contexts, write separate requirements per context and note the shared service or data layer.

| Context | Purpose |
|---|---|
| **User** | Account-level concerns: user preferences (interface, text editing, trackers, home page), profile, games management, settings management, calendar configs. |
| **Setting** | Prepare resources inside the active Setting (world): write notes, manage the setting's timeline and trackers, browse rules and archetypes, import content. Default workspace after login. |
| **In-Game** | Prepare and run a specific game: dashboard, notes, time and trackers (when the game has time enabled), rules, import, game configuration. |

Authentication (`/login`, `/register`) is an entry gate, not a context. After login the user lands on their Home page preference, or on the games list when none is set.

### Admin Context (operator-only, not user-facing)

| Context | Purpose |
|---|---|
| **Public** | Platform admins manage shared, read-only reference content (public rules and archetypes, calendar configs) available to every user. |

The Admin Context has its own login gate (`/admin/login`) and its own shell (`/admin/(panel)/*`). The user-facing app never links into it. Admin changes to public content do not cascade into user copies.

### Route placement

| Context | Routes |
|---|---|
| Auth gate | `/login`, `/register` |
| User | `/preferences` (hub), `/preferences/games`, `/preferences/settings`, `/preferences/calendar-configs`, `/profile`. These render as overlays over the last workspace (`ui-composition.md`). `/settings` redirects to `/preferences`. |
| Setting | `/content/notes` (`/content` redirects here), `/content/timelines`, `/content/trackers`, `/content/rules/[category]`, `/content/import` |
| In-Game | `/games/[gameId]/dm` (Dashboard), `…/dm/notes`, `…/dm/time`, `…/dm/trackers`, `…/dm/rules/[category]`, `…/dm/import`. Time routes redirect to the Dashboard when the game has time off. |
| Public | `/admin/login`, `/admin/rules`, `/admin/rules/[category]`, `/admin/import`, `/admin/editor`, `/admin/calendars` |

Setting and game configuration open as modals from the rail's **Configure** item, not as routes.

## Permissions Model

- Every screen and endpoint checks whether the principal can access it. Rules are enforced in both the route handler and the service (`structure.md` § Security Baseline).
- **Registered users** own their content: settings, notes, games, timelines, calendar configs, trackers, keywords. Only the owner can read or modify owned content.
- **Public content** is readable by every user and never editable by non-admins.
  - Public notes and archetypes are owned by the system user (`ownerContext = PUBLIC`, no setting or game). Users see them filtered by the Setting's effective system set.
  - Public calendar configs and template timelines have `ownerUserId = null`.
- **Platform Admin**: a user with `User.isAdmin = true`. Admins manage public content only, through admin-gated entrypoints. They never see or edit user-owned content. Admin identity is verified server-side, never inferred from a route or a request-supplied scope.
- **Context access**:
  - Auth gate: unauthenticated users can only log in or register.
  - User, Setting: any registered user, over their own content plus public content.
  - In-Game: only the game's owner. There are no participant roles.
  - Public: platform admins only.
- **Full opt-out**: users can request deletion of their profile and all their content (settings, notes, games).

## Domain Concepts

Short summaries. The full definitions are in `glossary.md`.

- **Setting**: a game world and the top-level content boundary. Each Setting has a **main System** and optionally **additional Systems** whose public content it also surfaces.
- **System**: a versioned rules body such as D&D 5.5e (`dnd55e`) or D&D 5e 2014 (`dnd5e-2014`). It is the parent of archetype content. Users never create Systems.
- **Game**: a campaign inside one Setting, run by its owner. Time is opt-in per game. When enabled, the game uses its Setting's single timeline and may be canonical or non-canonical.
- **Note**: the core authoring unit, a structured document owned by a Setting, a game, or the public context. A note may carry one **archetype** (Monster, Spell, Equipment, Magic Item, Rule), which gives it structured data, a snippet, a search index entry, and a keyword.
- **Keyword**: a phrase with a type and an optional linked note. It gives hover snippets and a read-only view across notes.
- **Timeline / Calendar Config / Tracker**: in-world time, calendar math, and countdowns anchored to instants.
- **User Preferences**: global, per-user personalization (theme, layout mode, early wrap, tracker behavior, aux-panel position, home page).

## Product Direction

- Separate clearly between account configuration (User), world preparation (Setting), and running a game (In-Game). Keep public content administration out of the DM-facing app.
- Use ownership and server-verified identity to decide what a user can see or change on each screen.
- Keep prepared content reusable: notes, archetypes, keywords, rules, and timelines belong to a Setting and are available to all its games.
- Reduce overhead for mechanics that are often skipped at the table, especially time tracking, reminders, rules lookup, and dice.
- Treat optional capabilities (time today; log and party later) as opt-in per game. Hide their surfaces when they are off, and preserve their data.
- Not a VTT. World Runner complements any VTT or traditional tabletop setup.

The iteration roadmap (it0 Foundation Consolidation through it6 Encounters and Game Log) is in `world-runner-docs/main/mvp-plan.md`.

## Development Philosophy

Work is **incremental and supervised** using the AI-DLC workflow (`aidlc-docs.md`).

The human owner acts as Product, CTO, and QA. The AI acts as expert developer and architect within approved scope.

## Documentation System

| Layer | Purpose | Where |
|---|---|---|
| ADRs | Architectural decisions and rationale | `world-runner-docs/adr/` |
| Feature Designs (FDs) | Feature requirements and design; the source for work items | `world-runner-docs/designs/` |
| Main product docs | Manifesto, MVP plan, navigation architecture, system map, prep workflow, production readiness | `world-runner-docs/main/` |
| AI-DLC records | Iteration stories and per-work-item process docs | `world-runner-docs/ai-dlc-docs/` |
| Steering | Standards, norms, glossary, and process | `.kiro/steering/` (workspace root) |

## Status

Pre-MVP, under active iteration (WR1). The codebase still carries known structural debt: oversized components (e.g. `InGameCalendar.tsx`, `DaySchedule.tsx`), leftover inline styles, and legacy `router.refresh()` reconciliation. It is being addressed step by step. Do not reinforce existing anti-patterns. Follow the standards in `structure.md`, `tech.md`, and `ux.md` even when the surrounding code does not.
