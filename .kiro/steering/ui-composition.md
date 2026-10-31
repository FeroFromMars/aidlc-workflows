# World Runner – UI Composition Patterns

> **Scope**: `world-runner/`. Paths are relative to `world-runner/`.
> **Sources**: `world-runner-docs/main/navigation-architecture.md` §3–§14, WR1-it0-S03, later AI-DLC records, and current code.
> Complements `ux.md` (contexts, persistence, server state) and `glossary.md` (term definitions). Does not replace them.

Every UI surface is exactly one of three patterns. When you add a surface, declare its pattern in the requirements or design, and follow that pattern's rules. There is no "companion view" pattern.

| Pattern | Behavior | Lifetime |
|---|---|---|
| **1. Main Content** | The primary workspace the user is working in. Navigating replaces it. | Until navigation |
| **2. Persistent Panels** (Aux-Panel) | Reference or tool windows alongside Main Content. Never replace it. | Session-scoped, user-arranged |
| **3. Floating Modals** | Focused, on-demand interactions over the current workspace. | Single interaction |

Draggable or resizable does not make something a panel. Classify by lifecycle: if it opens on demand and is dismissed when done, it is a Floating Modal.

---

## Pattern 1 — Main Content

**Use when** the surface *is* the task: authoring, browsing a category, viewing a timeline, running the game. One is active at a time.

**Structure**
- Route-based. Each surface is a route rendered in the main region of the App Shell.
- Reached through the context-aware Navigation Rail (Mobile Drawer on narrow screens). The rail only shows surfaces available in the current context and hides disabled capabilities (e.g. Timeline and Trackers when a game has time off).
- In-surface sub-views (category tabs, an inline read panel, a list that shrinks from 4 to 2 columns) stay inside Main Content. They are not Aux-Panel windows. Example: the Rules View read panel.
- Content Tabs inside the Dashboard are designed (FD-0021) but not built.

**Persistence**
- State belongs to the route. Leaving the In-Game context does not stop the running game; returning restores it.
- In-surface selections are remembered per `ux.md` § Session Context Persistence.
- To open a specific note after navigating, use the `?note=<id>` deep link (`useOpenNoteFromParam`), not sessionStorage.

**Dismissal**: none. It is replaced by navigation.

**Lifecycle**: mounts on route entry, unmounts on navigation. Server data comes through TanStack Query or the Event Store.

## Pattern 2 — Persistent Panels (Aux-Panel)

**Use when** content must stay visible while the user works in Main Content, for example keyword management, a read-only linked note, or a roll log.

**Structure**
- Hosted by the Aux-Panel (`src/components/aux-panel/`): up to 3 stacked windows, each compact, maximized, or minimized. Window types live in the `AuxWindowType` union and are rendered by `AuxPanelHost.renderWindow`.
- Current windows: Keyword Panel, Read Panel, Dice Roll Panel. Planned windows: Trackers, Table of Contents, Outline, Mini-Calendar, Upcoming Trackers, Actors, Scribbles.
- The Aux-Panel is mounted **In-Game** (`NoteProviderWrapper`) and in the Admin editor (Keyword and Read only). The Setting context has no Aux-Panel today. Features that normally log to a panel must degrade there; for example, dice use the Transient Result.
- A panel window's content follows the active Main Content. Keyword Panel follows the active note; Read Panel shows the clicked keyword's linked note.

**Persistence**: session-scoped and user-arranged. Aux-Panel position (`near-sidebar` / `far-sidebar`) is a DB-backed user preference. Planned per-surface default panels are listed in nav-arch §6 and §9.

**Dismissal**: the user closes or minimizes individual windows. Closing one never affects Main Content.

**Lifecycle**: toggle-mounted inside its provider. Windows open through `AuxPanelCommands.openWindow(type)`, for example from a registered command such as `toggleDicePanel`.

## Pattern 3 — Floating Modals

**Use when** the interaction is focused and single-purpose: find, command, create/edit/delete, configure, confirm, preview.

**Structure**
- A full-screen backdrop dialog, or a portal-based floating window that may be draggable or resizable (e.g. the Archivist).
- Modals are editor-independent. They take props like `mode` / `initialData` / `onSubmit` / `onClose` / `onDelete`, so the same modal works from any host (e.g. `ArchetypeModal` serves both the editor and Rules View "Create New").
- Styling follows the Modal backdrop/panel patterns in `tech.md`.

**Persistence**: a modal never persists after it closes. Form inputs or last selections may be remembered within the session only where a control is explicitly configured to (`ux.md`).

**Dismissal**
- Escape via `useCommand('cancel', onClose)` and confirm via `useCommand('confirm', ...)` (`commands.md`). A backdrop click or an explicit close button also dismisses.
- **No stacking** as a default. One modal at a time. Documented exceptions: a blocking confirm dialog opened from its own modal (e.g. delete confirm); Spotlight Preview above Spotlight; and the keyword CRUD modals (`CreateKeywordModal`, `EditKeywordModal`, `DeleteKeywordDialog`) above a Floating Modal that hosts a WRText field, one keyword modal at a time, returning focus to the originating field on close (FD-0030). All rely on the command registry's LIFO semantics, so the innermost modal closes first.

**Lifecycle**: mounts on trigger (shortcut, button, contextual action), unmounts on dismiss.

### Overlay-rendered routes and configuration

- **Configuration is a Floating Modal.** Setting configuration (`EditSettingModal`) and game configuration (`GameConfigureModal`) open from the rail's **Configure** item through `SettingConfigureProvider`. There is no `/games/[gameId]/settings` route.
- **User-context screens overlay the last workspace.** `/preferences/*` routes render inside `PreferencesModal` over the last Setting/In-Game context (`lastAppContext.ts`), with that context's rail still visible behind. They are routes for linking and bookmarking, but they behave as Floating Modals.

---

## Not Patterns: Shell Chrome and Anchored UI

These are not content surfaces and are not classified:

- **Shell chrome**: Context Bar (Context Selector, Game Indicator, In-Game Clock, user menu), Navigation Rail, Mobile Drawer.
- **Anchored floating UI**: tooltips (keyword hover), dropdown menus, context menus (`BlockContextMenu`), NodeView hover menus, `ForcedMarkSearchBar`. These must be hand-aware (`ux.md` § Left-Handed Mode).
- **Transient feedback**: Transient Result (dice), toasts. Auto-dismissing, no interaction.

## Surface Classification

| Surface | Context | Pattern |
|---|---|---|
| Notes editor (`/content/notes`, `/games/[gameId]/dm/notes`) | Setting, In-Game | 1 |
| Timeline (`/content/timelines`, `/games/[gameId]/dm/time`) | Setting, In-Game | 1 |
| Trackers (`/content/trackers`, `/games/[gameId]/dm/trackers`) | Setting, In-Game | 1 |
| Rules View (`…/rules/[category]`), including its read panel | Setting, In-Game, Public | 1 |
| Import (`/content/import`, `/games/[gameId]/dm/import`, `/admin/import`) | Setting, In-Game, Public | 1 |
| Dashboard (`/games/[gameId]/dm`, placeholder) | In-Game | 1 |
| Admin rules, editor, calendars (`/admin/(panel)/*`) | Public | 1 |
| Profile (`/profile`) | User | 1 |
| Keyword Panel, Read Panel, Dice Roll Panel | In-Game (Keyword/Read also in Admin editor) | 2 |
| Archivist (Alt+A) | Setting, In-Game | 3 |
| Spotlight (Mod+K), Spotlight Preview | Setting, In-Game | 3 |
| Preferences hub, Games, Settings, Calendar Configs (`/preferences/*`) | User | 3 (route overlay) |
| Setting configuration, game configuration (Configure) | Setting, In-Game | 3 |
| Create Game, Create Setting | User | 3 |
| Archetype / Stat Block modals, keyword CRUD modals, rename/removal keyword dialogs | Setting, In-Game, Public | 3 |
| Event and Tracker modals, Calendar Config modal, Delete confirm dialogs | Setting, In-Game, User, Public | 3 |
| Image Expand View, Shortcut Guide (Alt+H) | any | 3 |
| Encounters, Logs, Modules/Books | In-Game, Setting | 1 (designed, rail items disabled) |
| Calendar quick view, Mini-Calendar | In-Game | 3 / 2 (designed) |

Update this table when a surface is added or reclassified.
