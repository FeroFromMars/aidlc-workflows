# World Runner – Product Summary

World Runner is a web application for running tabletop RPG sessions with less bookkeeping overhead. It is not a virtual tabletop (VTT); it is an aid tool meant to complement any VTT setup or live, pen-and-paper play. It stands alone, compatible with any VTT platform or traditional tabletop game. It is aimed at Dungeon Masters and players who want practical tools for game-time operations, timed event tracking, note taking, notifications, asymmetric interactions between game master and players, and lean setup.

The product is being shaped around table-ready utility with consistent UX and aesthetics across the board. Desktop and mobile web are both in scope.

## Main Functionality Scopes

The product operates in specific scopes of functionality, delivering easy navigation for all options and features withing each scope. Scopes may also have their own rules for UX.

| Scope                  | Description                                                                                                       |
| ------------------------| -------------------------------------------------------------------------------------------------------------------|
| **Landing**            | Login required entry-point for all scopes, leads to landing page with navigation to other scopes.                 |
| **User**               | User pages like: profile, personalization and account settings, subscription management, etc.                     |
| **Content**            | General, game-agnostic content the user has access to like calendar configurations, timelines, coin systems, etc. |
| **Game Management**    | Manage and configure games (e.g. create, invite players, configure game with specific features)                   |
| **Game Running**       | Enage with a created game, trigger in-game mechanics, interact with players, update game state and notes.         |
| **Game Participation** | Participate in a game as a player.                                                                                |

## Permissions Model

- All screens and endpoints contemplate if a user can access them.
- Platform Admin: User's with administrator clearance are platform admin. These users can view and modify all content.
- Content - Read: Can be viewed by the user that created it (Owner ID), content without an owner ID associated can be viewed by any user.
- Content - Write: Only the user that created it can modify content. Publicly owned content can only be modified by platform admins.
- Game roles (in-game): users may be GM or Player. Only the game owner can configure participant roles and manage the game.
- Full opt-out: users can request deletion of their personal profile, content, games, and characters.
- Scope Permissions:
  - Landing: Unregistered users (Login and Registration only), and all registered users.
  - User: All registered users.
  - Content:
    - Registered Users: View public content, View and Manage their owned content.
    - Platform Admins: View and Manage public content.
  - Game Management: Users can view and manage the games they own.
  - Game Running: User participating in the game with the GM role.
  - Game Participation: User participating in the game with the Player role.

## Domain Concepts

- **Game**: the central entity. A DM creates a game; players join via invite code. A game has participants, a timeline, a currency system, and any other option managed in "Content".
- **Character**: owned by a player, optionally linked to a tabletop system's features. It's the vehicle for a player to participate and trigger in-game mechanics.
- **Content**: game agnostic content, publicly available or created and managed by a user. Managed in the Content scope, constantly growing and adding features. As it is made available in Content, it changes how a Game is configured and the in-game mechanics it can interact with.
- **Personalization** users, whether they own content, manage a game, or participate as players, may personalize their experience by changing the UI appearance, enabling user-level features, or deleting their account.

## Product Direction

World Runner is designed around a few core ideas:

- Separate clearly between managing a user profile, managing content, managing a game, running a game, and playing a game.
- Use ownership and permissions to determine what a user can view or control on each screen.
- Support reusable RPG content such as games, characters, item collections, and currency systems.
- Reduce overhead for mechanics that are often skipped at the table, especially time tracking, reminders, and other session-running aids.
- Design around asymmetric interaction between game master and players.
- Not a VTT — World Runner complements any VTT or traditional tabletop setup, never replaces it.

## Development Philosophy

Work is **incremental and supervised** using the aidlc workflow.

The human owner acts as Product, CTO, and QA. The AI acts as expert developer and architect within approved scope.

## Documentation System

| Layer                      | Purpose                                                | Where                                   |
| ----------------------------| --------------------------------------------------------| -----------------------------------------|
| ADRs                       | Architectural decisions and rationale                  | `world-runner-docs/adr/`                |
| Non-Construction Documents | Documentation related to spikes or miscellaneous notes | `world-runner-docs/world-runner/notes/` |
| Steering                   | Standards, norms, and process                          | `.kiro/steering/` (workspace root)      |

## Status

Early-stage prototype under active refactoring. The codebase has known structural debt (oversized components, inline styles, coupled screens) that is being systematically addressed. Do not reinforce existing anti-patterns when adding or changing code — follow the standards in `structure.md` even if surrounding code does not yet.
