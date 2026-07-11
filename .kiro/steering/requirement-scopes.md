# World Runner – Requirement Scopes

When constructing or reviewing requirements, every requirement must be classified as either **In-Game** or **Global**. This distinction drives where the feature lives in the codebase, which UI flow hosts it, and what permissions govern it.

## In-Game

Requirements involving UI, controls, data, and functions that exist within the context of a specific game session.

- Accessed through Game Running (GM) or Game Participation (Player) flows.
- Scoped to a single game — the feature operates on or within a game entity.
- Subject to game-level permissions (game owner, GM role, Player role).
- Examples: advancing game time, triggering in-game events, viewing the game calendar, managing game-specific notes, interacting with game participants.

## Global

Requirements involving UI, controls, data, and functions that exist outside of any specific game — typically within the Content flow.

- Accessed through Content management or other non-game scopes (User, Landing).
- Not scoped to a single game — the feature operates on reusable, game-agnostic content.
- Subject to content ownership permissions (owner, platform admin, public read).
- Often the "equivalent version" of an in-game component but for standalone management: creating/editing calendars, timelines, item collections, currency systems, etc. outside of any game context.
- Examples: managing calendar configurations, editing a timeline's events globally, creating item collections, configuring currency systems.

## Why This Matters

Many features have both an in-game and a global variant. The calendar, for instance, appears in-game (scoped to the game's assigned timeline, with time-control interactions) and globally (standalone timeline management in Content, no game context). Requirements must be explicit about which scope they target because:

1. **Permissions differ** — in-game checks game role; global checks content ownership.
2. **Data context differs** — in-game has a `gameId` and game-specific state; global does not.
3. **UI host differs** — in-game lives under `/games/[gameId]/...`; global lives under `/content/...`.
4. **Controls may differ** — in-game variants may have game-specific actions (e.g., "Set to this date") that do not exist in the global variant.

When writing requirements, prefix or tag each requirement with its scope. If a feature spans both scopes, write separate requirements for each and note the shared underlying service/data layer.
