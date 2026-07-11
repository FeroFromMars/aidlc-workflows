# World Runner – UX Standards

## Platform Targets

- Web-based for desktop and mobile.
- Future versions may migrate to native mobile apps.
- Offline functionality is a core product direction, not an afterthought.

## UI Mode Separation

There are five distinct modes of interaction. The user must always know which mode they are in, and navigation between modes must be clear and easy to find.

| Mode             | Description                                                     |
| ------------------| -----------------------------------------------------------------|
| Managing profile | User account, preferences, settings                             |
| Managing content | Creating/editing owned content (rules, characters, collections) |
| Managing a game  | Game configuration, participants, settings (GM only)            |
| Running a game   | Active session controls, time tracking, triggers (GM)           |
| Playing a game   | Player-facing controls during an active session                 |

The gateways to access these modes are clear and discoverable. It is never difficult to navigate to a different part of the application.

## Session Context Persistence

During the same session, modals, controls, and menus remember what the user was doing.

- If creating or managing content, as long as the user does not leave the session, the last selected options, entered text, etc. are remembered by the app.
- Signing out or having the session expire resets the UI.
- This is **configurable per-screen or control instance**. One dropdown may retain the last selection after the user clicks away; a different dropdown may reload fresh if not configured to remember.

All persisted data must use a centralized server-state layer with query invalidation. UI components must subscribe to data and never be manually refreshed.

# Server State Management Rules

Components must never manually refresh sibling or parent components.

All persisted backend data must be accessed through TanStack Query hooks (`useQuery`, `useInfiniteQuery`). Raw `fetch` for reads is not permitted in new code.

All mutations must:
1. Use `useMutation` hooks (not raw `fetch` with manual state management).
2. Declare which query keys they invalidate via `onSuccess`/`onSettled`.
3. Never directly manipulate unrelated UI state.
4. Never rely on `router.refresh()` as the sole reconciliation mechanism when the mutated data is owned by a Query cache.

`router.refresh()` usage:
- Required when a mutation affects server-rendered page shell content outside Query-managed islands.
- Required when navigating to a different route after a mutation (`router.push(...)` + `router.refresh()`).
- NOT required when the mutated data is fully managed by Query hooks — `invalidateQueries` is sufficient.

When adding a new feature:
- Identify affected server entities.
- Add or reuse query keys from `src/lib/queryKeys.ts` (centralized factory — no ad-hoc key arrays).
- Ensure mutations invalidate those keys.
- For time-scoped data, use the Event Store from `@/lib/time` (see `time-management.md`), not direct Query hooks.

### Exceptions (legacy)

Existing components that use raw `fetch` + `router.refresh()` are migrated opportunistically per ADR-0013. Do not reinforce this pattern in new code.

## Desktop Mode

- Main menus are standard and can only follow any personalization permitted to the user (if implemented).

## Personalization

- Configurable, reusable, and personalizable modals and controls.
- On mobile: main interface may use personalized colors. World Runner Controllers can be personalized (re-ordering, hiding specific controls).
