# World Runner – UX Standards

> **Scope**: `world-runner/`. Surface patterns are defined in `ui-composition.md` and terms in `glossary.md`.

## Platform Targets

- Web app for desktop and mobile. Native mobile apps may come later.
- Offline functionality is a core product direction, not an afterthought.
- Admin-panel UI serves operators, not DMs. It reuses user components and follows the same standards.

## Context Awareness

The application contexts (User, Setting, In-Game, and the admin-only Public context) are defined in `product.md` § Application Contexts. That is the only context taxonomy; ux.md keeps no separate list of modes.

- **The user must always know which context they are in.** Moving to another context must be clear, easy to find, and never more than one interaction away.
- **Context Bar** (top): the Context Selector (Games grouped by Setting, Settings, recently used contexts, and a Manage section for Games and Settings), the Game Indicator (running game or "No Game", with a stop action), the In-Game Clock, and the user menu (theme and layout toggles, preferences).
- **Navigation Rail** (left, icons only; Mobile Drawer on narrow screens): shows only the surfaces of the current context. Designed-but-unbuilt surfaces appear disabled. The User context has no rail of its own; its screens overlay the last workspace.
- Switching context never stops the running game. Leaving the In-Game context and coming back restores where the DM was.
- Changing the active Setting is a client-side switch. Every Setting-scoped view must update without a reload.

## Optional Capabilities

A game opts into capabilities such as time. When a capability is off:
- Remove its entry points: the rail and drawer hide Timeline and Trackers, and the In-Game Clock does not render.
- Guard its routes server-side, redirecting to the Dashboard.
- Degrade without errors: queries return null and commands no-op (ADR-0021).
- Preserve its data. Turning a capability off never deletes anything, and turning it back on restores prior state.

Future optional domains (log, party) follow the same pattern.

## Session Context Persistence

Within a session, modals, controls, and menus remember what the user was doing.

- While creating or managing content, the app remembers the last selected options and entered text until the user leaves the session.
- Signing out or session expiry resets the UI.
- Persistence is **configured per screen or control**. One dropdown may keep its last selection after the user clicks away; another may reload fresh.
- Mechanisms:
  - `src/lib/sessionSelection.ts` (sessionStorage, `wr:selection:` prefix) for UI selections. Examples: pinned instant per game, Event Store filters, panel widths.
  - The active note is remembered **per context** (per Setting and per game) and dropped when the context changes.
  - `lastAppContext` and `recentContexts` back the preferences overlay and the Context Selector's recent list.
  - The `?note=<id>` deep link opens a specific note after navigation.
- Selections restored from storage after SSR must use the hydration-safe skeleton pattern (ADR-0011).

## Server State Management

All persisted data goes through a centralized server-state layer with query invalidation. Components subscribe to data. They are never refreshed by hand, and they never refresh sibling or parent components.

All persisted backend data is accessed through TanStack Query hooks (`useQuery`, `useInfiniteQuery`). Raw `fetch` for reads is not permitted in new code; a `fetch` inside a `queryFn` or `mutationFn` is fine.

All mutations must:
1. Use `useMutation`, not raw `fetch` with manual state.
2. Declare which query keys they invalidate in `onSuccess`/`onSettled`. Include **every cache that shows the same data** (e.g. a note created from the Rules View also invalidates the Archivist's `notes2.bySetting`/`byGame` lists).
3. Never directly manipulate unrelated UI state.
4. Never rely on `router.refresh()` as the only reconciliation when the data lives in a Query cache.

`router.refresh()` is:
- Required when a mutation affects server-rendered page-shell content outside Query-managed islands.
- Required after navigating to another route following a mutation (`router.push(...)` + `router.refresh()`).
- Not required when the data is fully managed by Query hooks; `invalidateQueries` is enough.

When adding a feature:
- Identify the affected server entities.
- Add or reuse query keys in `src/lib/queryKeys.ts`, the centralized factory. No ad-hoc key arrays.
- Make sure mutations invalidate those keys.
- For time-scoped data, use the Event Store from `@/lib/time` (`time-management.md`), not direct Query hooks.

### Legacy exceptions

Existing components that use raw `fetch` + `router.refresh()` are migrated when touched (ADR-0013). Known remaining spots include `TimePageContent`, `TrackersPage`, `TrackersPageContent`, `DaySchedule`, `EditTimelineForm`, `ProfileForm`, and parts of the admin shell. Do not reinforce the pattern in new code.

## Left-Handed Mode (ADR-0016)

Layout mode `inverted` sets `data-hand="left"` on `<html>`. The value comes from the `wr_layoutMode` cookie and `UserPreferences.layoutMode`, and a blocking head script applies it before paint. The flip is visual only. DOM order, tab order, and screen-reader order never change.

1. **Rows with a primary-action side use `FlippableRow`**: toolbars, action bars, modal footers, card action clusters, inline edit controls, and field + button pairs.
2. **Never flip reading order**: breadcrumbs, prose, tables and data grids, vertical layouts, sidebar navigation items, and ordered tab bars.
3. **Shells and compound layouts** (sidebar + content, rail, drawer, Aux-Panel, admin shell) flip through `[data-hand="left"]` CSS overrides on their container, not by wrapping them in `FlippableRow`.
4. **Directional icons** that point toward content (back arrows, "return to note") mirror with a `[data-hand="left"]` `transform: scaleX(-1)` override.
5. **Anchored floating UI** (dropdowns, context menus, popovers, hover menus) must be hand-aware: they open toward the content side and stay on screen in both modes.
6. **Single-child rows**: `row-reverse` does nothing when there is one child. Reposition it with a `[data-hand="left"]` justify/alignment override instead.
7. Children of a flipped row use `gap`, not directional margins. Check any `justify-content: flex-end` behavior in both modes.

## Theme

- Light and Dark themes use the design tokens (ADR-0015, `tech.md`).
- The theme is stored in the `wr_darkMode` cookie. With no cookie it follows the OS `prefers-color-scheme`. The head script sets `data-theme` before paint.
- The toggle lives in the user menu and does not close the menu.
- Eye Comfort, Auto, and language selection (EN / ES / EN-ES) are designed in FD-0014 and FD-0027 but not built.

## Personalization

- Preferences are global per user (FD-0027): text editing (Early Wrap), trackers, interface (theme, layout mode), aux-panel position, and home page.
- Changes apply immediately (optimistic), with no Save button. Dependent controls are disabled with an explanation.
- Modals and controls should be configurable, reusable, and personalizable.
- On mobile, the main interface may use personalized colors, and World Runner controls may be personalized (reordered, specific controls hidden).

## Icons and Feedback

- Icons come only from `@tabler/icons-react`. No emojis or Unicode symbols as icons.
- Destructive actions (permanent delete, archetype removal, keyword orphaning renames) show a confirmation that states the consequence.
- Every interactive element has visible hover, disabled, and `:focus-visible` states (`tech.md` § Completeness Rule).
