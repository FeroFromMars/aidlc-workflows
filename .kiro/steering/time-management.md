# World Runner – Centralized Time Management

> **Scope**: `world-runner/` only.
> **Authority**: ADR-0014 (Centralized Time Management with Pinned Instant), ADR-0021 (Optional Domain Capabilities), FD-0009 (Time), WR1-it1-S05/S06 (setting-scoped timelines, time opt-in).

## Architecture Overview

All time state, time-scoped data fetching, and time mutations go through `src/lib/time/`. Components never manage time state on their own.

```
GameTimeProvider (context, one per game, only when time is enabled)
├── Time State Controller  → currentInstant, pinnedInstant, effectiveInstant, undo/redo
├── Event Store            → events/trackers for the effective time window + filters
└── Command Bus            → typed interface for all time mutations
```

## Module Location

```
src/lib/time/
├── index.ts                    Public API barrel
├── types.ts                    TimeMode, TimeState, TimeCommands, EventStoreState/Actions, EventFilters, item types
├── GameTimeProvider.tsx        In-Game provider (state + commands + Event Store + sync)
├── TimelineViewProvider.tsx    Setting-context provider (read-only, pin, Event Store)
├── useTimeState.ts             Hook: time state
├── useTimeCommands.ts          Hook: command bus
├── useEventStore.ts            Hook: Event Store state + actions
├── eventStoreInternal.ts       Event Store implementation (TanStack Query under the hood)
├── timeStateReducer.ts         Time state transitions
├── syncEngine.ts               Debounced server sync, rollback on error
└── pinStorage.ts               Pin persistence via sessionSelection
```

Calendar math lives in `src/lib/fantasyTime/` (`FantasyCalendar`, `FantasyTimeline`, formatting). Time services live in `src/server/fantasyTime/`, and event services in `src/server/events/`.

## Time Is Optional Per Game

- `Game.timeEnabled` defaults to `false`. A game can enable time only when its Setting has a timeline. It then uses **that Setting's timeline**, since Setting ↔ Timeline is 1:1 (`Timeline.settingId` is unique).
- `GameTimeWrapper` mounts `GameTimeProvider` only when time is enabled. Otherwise children render without a provider, time consumers render nothing, and nothing throws.
- With time off, the rail and drawer hide Timeline and Trackers (`queryKeys.time.game(gameId)`), and `/dm/time` and `/dm/trackers` redirect to the Dashboard.
- **Disabling time preserves data.** Use `toggleGameTime` to disable; it flips the flag only. Never use the `assignGameTimeline` unassign branch to disable, because it clears `timelineId`, `currentInstant`, and the link. Changing a game's Setting resets its time link but keeps its events.
- `Game.canonical` (default true) decides whether the game's events appear by default in Setting-context views.

## Rules

### R1: Components never fetch or mutate time directly

No component calls `fetch('/api/games/.../time', { method: 'PATCH', ... })` or builds its own sync logic. Time reads come from `useTimeState()`. Time mutations go through `useTimeCommands()`.

```tsx
// ❌ Direct fetch for time mutation
await fetch(`/api/games/${gameId}/time`, { method: 'PATCH', body: ... });
// ❌ Local time state
const [currentInstant, setCurrentInstant] = useState(initialInstant);
// ❌ Constructing calendars in components
const calendar = useMemo(() => new FantasyCalendar(config), [config]);

// ✅
const { effectiveInstant, dateTime, calendar, timeline } = useTimeState();
const commands = useTimeCommands();
commands.advanceBy(3600);
commands.setDate(year, month, day);
commands.pin(someInstant);
```

### R2: Views read `effectiveInstant`, never `currentInstant`

`effectiveInstant = pinnedInstant ?? currentInstant`, so pin awareness is automatic. Only the Time State Controller and the pin indicator care about the difference.

### R3: `useTimeSync` is gone

It was deleted. Use `useTimeState()` / `useTimeCommands()` from `@/lib/time`.

### R4: `FantasyCalendar` and `FantasyTimeline` are owned by the provider

Components must not construct them. `GameTimeProvider` or `TimelineViewProvider` builds them once from `TimelineData` and exposes them through `useTimeState()`.

### R5: Undo/redo operates on `currentInstant` only

The undo/redo stack lives in the Time State Controller and tracks real game time changes. Pin navigation never creates undo entries. Components never keep their own time undo stacks; use `useTimeCommands().undo()` / `.redo()`.

### R6: Time-indexed data comes from the Event Store

Components that show events, trackers, or other time-indexed data use `useEventStore()`. They never call Query hooks for calendar data directly or build their own time query keys. The Event Store uses TanStack Query internally (ADR-0013) but exposes a domain interface.

### R7: Filter state belongs to the Event Store

`EventFilters` is `{ includeGame, includeGlobal, includeOtherGames, revealNonCanonical }`. The Event Store owns these filters and persists them through `sessionSelection`. Components that render filter controls call Event Store actions.

### R8: Setting-context event visibility is decided server-side

In Setting-context views:
- Base-history events (`gameId = null`) always show.
- Events from time-disabled games never show.
- Events from non-canonical games show only with `revealNonCanonical`.

The rule lives in the pure predicate `isEventVisibleInSettingContext` (`src/server/events/eventVisibility.ts`) and in `buildSettingContextFilter`. The full relative-to-viewer Own/Canon/Non-canon filter (FD-0009 FR-11/12) is designed but not built.

## Pinned Instant

A user-controlled virtual time position that every time-aware view displays instead of real game time. It lets the DM browse the timeline and draft events without moving the game clock or triggering trackers.

| Aspect | Behavior |
|---|---|
| Activation | Explicit pin control |
| Display | All views show pinned time; an indicator is always visible |
| Navigation commands | `advanceBy`, `setDate`, `setTime` move the pin, not real time |
| Real-time command | `setInstant` always moves real game time |
| Trackers | Never evaluated on pin changes |
| Persistence | `sessionStorage` per game, key `wr:selection:pinned-instant:<gameId>` |
| Clearing | Explicit unpin, session end, or sign-out |

While a pin is active, the UI shows a persistent indicator that (1) the displayed time is not real game time and (2) a one-click unpin is available.

## Provider Scopes

### `GameTimeProvider` (In-Game)

Mounted by `src/app/games/[gameId]/dm/GameTimeWrapper.tsx`, and only when time is enabled. Provides full time state, the full command bus, the Event Store, and the sync engine (debounced PATCH, rollback on error, tracker notification dispatch).

`TimeMode` is `'gm' | 'player' | 'readonly'`:
- `gm`: full read/write. This is the only mode in use.
- `readonly`: read-only, no pin, no commands.
- `player`: dormant code guard. Player scope is dropped (ADR-0028), so do not build on it.

### `TimelineViewProvider` (Setting context)

Mounted by the `/content/timelines` surface (`TimelineView`). The unlinked `/content/timelines/[id]` detail route also uses it. Provides the static timeline/calendar reference, the Event Store with the Setting-context filter and the Non-Canonical reveal toggle, and pin support. No sync, no command bus.

## Command Bus Reference

```typescript
type TimeCommands = {
  // Real game time (server sync + tracker evaluation)
  setInstant(instant: number): void;
  advanceBy(seconds: number): void;
  setDate(year: number, month: number, day: number): void;
  setTime(hour: number, minute: number, second: number): void;
  flush(): Promise<void>;
  undo(): void;
  redo(): void;
  // Pin control (local only)
  pin(instant: number): void;
  unpin(): void;
  isPinned(): boolean;
};
```

While pinned, `setDate` / `setTime` / `advanceBy` change `pinnedInstant`. `setInstant` always changes `currentInstant`, and `undo` / `redo` act on the `currentInstant` stack. Commands throw when used in `readonly` or `player` mode.

## Migration Status

| Consumer | Status | Notes |
|---|---|---|
| `DashboardDateDisplay` → `InGameClock` | Complete | Consumes context; renders null without a provider |
| `TimePageContent` | Partial | Uses context hooks; still calls `router.refresh()` |
| `CalendarView` → `InGameCalendar` | Complete | Event Store + TimeCommands. File is oversized (≈900 lines) — debt |
| `TimelineDetailContent` / `TimelineView` | Complete | Wrapped in `TimelineViewProvider` |
| `DayPanel` → `DaySchedule` | Partial | Event Store wired; `handleSetDate` still does a direct time PATCH (violates R1) → move to `useTimeCommands().setDate` |
| `TrackersPage` (`dm/trackers`) | Partial | Constructs `new FantasyCalendar(...)` (violates R4) and uses `router.refresh()` |

Update this table as the migration progresses.
