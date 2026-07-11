# World Runner – Centralized Time Management

> **Scope**: This file applies to `world-runner/` only.
> **Authority**: ADR-0014 (Centralized Time Management with Pinned Instant).

## Architecture Overview

All time-related state, data fetching, and mutations flow through a centralized system in `src/lib/time/`. Components never manage time state independently.

```
GameTimeProvider (context, one per game scope)
├── Time State Controller  → owns currentInstant, pinnedInstant, effectiveInstant
├── Event Store            → owns event/tracker data for the effective time window
└── Command Bus            → typed interface for all time mutations
```

## Module Location

```
src/lib/time/
├── index.ts                    # Public API barrel
├── types.ts                    # TimeState, TimeCommands, EventStoreState interfaces
├── GameTimeProvider.tsx        # Context provider (game scope)
├── TimelineViewProvider.tsx    # Context provider (content/timeline scope)
├── useTimeState.ts             # Hook: read time state from context
├── useTimeCommands.ts          # Hook: read command bus from context
├── useEventStore.ts            # Hook: read event store from context
├── timeStateReducer.ts         # Reducer logic for time state transitions
├── syncEngine.ts               # Server sync logic
└── pinStorage.ts               # Pin persistence via sessionStorage
```

## Rules

### R1: Components never fetch or mutate time directly

No component may call `fetch('/api/games/.../time', { method: 'PATCH', ... })` or construct its own time sync logic. All time reads come from `useTimeState()` and all time mutations go through `useTimeCommands()`.

**Prohibited patterns**:
```tsx
// ❌ Direct fetch for time mutation
const res = await fetch(`/api/games/${gameId}/time`, { method: 'PATCH', body: ... });

// ❌ Local time state management
const [currentInstant, setCurrentInstant] = useState(initialInstant);

// ❌ Constructing FantasyCalendar/FantasyTimeline in components
const calendar = useMemo(() => new FantasyCalendar(config), [config]);
```

**Correct patterns**:
```tsx
// ✅ Read from context
const { effectiveInstant, dateTime, calendar, timeline } = useTimeState();

// ✅ Mutate through commands
const commands = useTimeCommands();
commands.advanceBy(3600);
commands.setDate(year, month, day);
commands.pin(someInstant);
```

### R2: Views read `effectiveInstant`, never `currentInstant` directly

All display components and the Event Store use `effectiveInstant` (which equals `pinnedInstant ?? currentInstant`). This ensures pin-awareness is automatic — views never need conditional logic for "am I pinned?".

The only code that cares about the distinction between `currentInstant` and `pinnedInstant` is the Time State Controller itself and the pin-related UI indicator.

### R3: `useTimeSync` is deprecated — do not use in new code

The legacy hook at `src/components/time-controls/useTimeSync.ts` is deprecated per ADR-0014. All new time-consuming components must use `useTimeState()` and `useTimeCommands()` from `@/lib/time`.

Existing consumers are being migrated incrementally. Do not add new imports of `useTimeSync`.

### R4: FantasyCalendar and FantasyTimeline are owned by the provider

Components must not construct `FantasyCalendar` or `FantasyTimeline` instances. These are built once by `GameTimeProvider` (or `TimelineViewProvider`) from `TimelineData` and exposed via `useTimeState()`.

This eliminates redundant `useMemo(() => new FantasyCalendar(...))` across multiple components and ensures all components resolve instants consistently.

### R5: Undo/redo operates on `currentInstant` only

The undo/redo stack lives in the Time State Controller and tracks real game time changes. Pinned instant navigation does not create undo entries.

Components must not maintain their own undo/redo stacks for time changes. Use `useTimeCommands().undo()` and `useTimeCommands().redo()`.

### R6: Event data comes from the Event Store

Components that display events, trackers, or time-indexed data must use `useEventStore()` from `@/lib/time`. They must not call React Query hooks for calendar data directly or construct their own query keys for time-scoped data.

The Event Store internally uses TanStack Query (per ADR-0013) but exposes a domain-specific interface. Components subscribe to structured data, not raw query results.

### R7: Filter state belongs to the Event Store

Event visibility filters (`filterGame`, `filterGlobal`, `filterOther`) are managed by the Event Store, not by individual components. Components that render filter controls call Event Store actions to toggle filters.

## Pinned Instant

### Concept

The pinned instant is a user-controlled virtual time position that all time-aware views display instead of real game time. It allows browsing the timeline (viewing events at different dates, drafting new events) without moving the actual game clock or triggering trackers.

### Behavior

| Aspect | Behavior |
|---|---|
| Activation | User explicitly triggers via a pin control |
| Display | All views show pinned time; visual indicator is always visible |
| Navigation commands | `advanceBy`, `setDate`, `setTime` move the pin, not real time |
| Real time commands | `setInstant` always moves real game time regardless of pin state |
| Tracker evaluation | Never triggered by pin changes |
| Persistence | Survives refresh — stored in `sessionStorage` per game |
| Clearing | Explicit unpin, session end, or sign-out |

### Session Persistence

The pin is stored via `sessionStorage` using the `sessionSelection` utility:
- Key: `wr:selection:pinned-instant:<gameId>`
- Value: the pinned instant as a string integer
- On provider mount, reads and restores the pin if present
- On unpin, removes the key

### Visual Indicator

When a pin is active, the UI must display a persistent indicator that communicates:
1. The displayed time is NOT the real game time.
2. A one-click unpin/rollback action is available.

## Provider Scopes

### `GameTimeProvider` (in-game)

Mounted at the game layout level. Provides:
- Full time state (currentInstant, pinnedInstant, effectiveInstant, dateTime, timeline, calendar)
- Full command bus (mutations, pin control, undo/redo, flush)
- Event Store (events, trackers, filters)
- Server sync engine (debounced PATCH, rollback on error, tracker notification dispatch)

Mode variants:
- `gm` — full read/write access, all commands available
- `player` — read-only time state, pin available for browsing, no mutation commands
- `readonly` — read-only, no pin, no commands

### `TimelineViewProvider` (content scope)

Mounted at the content timeline detail page. Provides:
- Static timeline/calendar reference
- Event Store (read-only, no game filter)
- Pin support (for free browsing)
- No sync, no command bus, no game context

## Command Bus Reference

```typescript
interface TimeCommands {
  // Real game time mutations (trigger server sync + tracker eval)
  setInstant(instant: number): void;
  advanceBy(seconds: number): void;
  setDate(y: number, m: number, d: number): void;
  setTime(h: number, min: number, s: number): void;
  flush(): Promise<void>;
  undo(): void;
  redo(): void;

  // Pin control (local only, no server sync)
  pin(instant: number): void;
  unpin(): void;
  isPinned(): boolean;
}
```

**Command routing when pinned**:
- `setDate` / `setTime` / `advanceBy` → modify `pinnedInstant`
- `setInstant` → always modifies `currentInstant` (explicit game time set)
- `undo` / `redo` → operate on `currentInstant` stack
- `pin` / `unpin` → control pin state

## Migration Status

Consumers being migrated from `useTimeSync` to `GameTimeProvider`:

| Consumer | Status | Notes |
|---|---|---|
| `DashboardDateDisplay` | Pending | Smallest — migrate first |
| `TimePageContent` | Pending | Remove local query invalidation |
| `CalendarView` | Pending | Largest — remove PATCH calls, undo/redo, event fetching |
| `TimelineDetailContent` | Pending | Wire `TimelineViewProvider` |

Update this table as migration progresses.
