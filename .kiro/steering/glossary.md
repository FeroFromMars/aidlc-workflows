# World Runner – Glossary

Single source of truth for official terms. When a term appears in several FDs, ADRs, or steering files, this glossary gives the canonical meaning. Use these names in code, docs, UI copy, and conversation. If a term is missing or conflicts with a document, flag it and update this file.

> **Precedence**: code and accepted docs (ADRs, FDs, AI-DLC records in `world-runner-docs/`) win over this file. When this file is found stale, fix it here.
> **Status**: **I** implemented · **P** partially implemented · **D** designed only (FD/ADR exists, no code) · **R** retired (do not use; see § Retired Terms).
> **Sources**: FD = `world-runner-docs/designs/`, ADR = `world-runner-docs/adr/`, nav-arch = `world-runner-docs/main/navigation-architecture.md`.

Terms are alphabetical within each section. Add new terms to the section that owns the concept; do not restructure.

---

## 1. Product & Contexts

| Term | Definition | Code / Source | Status |
|---|---|---|---|
| **Admin Context** | Operator-only surface for the Public context, behind its own login gate. Not part of the DM-facing app. | `/admin/*`, FD-0028 | I |
| **Context** | One of the four application contexts: **User**, **Setting**, **In-Game**, **Public**. The only scope taxonomy. Every requirement is tagged with one. | `product.md`, nav-arch §2 | I |
| **DM / GM** | The single human operator of a game. World Runner is DM-only (ADR-0028). "DM" and "GM" are synonyms; prefer DM in UI copy. | ADR-0028 | I |
| **In-Game context** | Running and preparing a specific game: dashboard, notes, time, trackers, rules, import. Reached through the Context Selector. | `/games/[gameId]/dm/*` | I |
| **Public context** | Admin management of shared, read-only reference content (SRD rules, archetypes, calendar configs). | `/admin/*`, FD-0028 | I |
| **Setting context** | Preparing resources inside the active Setting (world): notes, timeline, trackers, rules, import. Default workspace after login. | `/content/*` | I |
| **User context** | Account-level configuration: preferences, profile, games management, settings management, calendar configs. | `/preferences/*`, `/profile` | I |

## 2. Worlds & Rules Systems

| Term | Definition | Code / Source | Status |
|---|---|---|---|
| **Active Setting** | The Setting the user is currently working in. Held client-side and in the `wr_settingId` cookie; setting-scoped UI must react to client-side switches. | `ActiveSettingProvider`, `useActiveSetting()`, FD-0012 | I |
| **Additional systems** | Extra Systems a Setting is configured to surface (consumption only; content is never stamped with them). | `Setting.additionalSystems`, FD-0029 | I |
| **Content system** | The System a single archetype note belongs to. | `Note.systemId`, `ArchetypeIndex.systemId` | I |
| **Cross-Setting View** | Toggle revealing content from other Settings alongside the active one. | FD-0012 | D |
| **Decoration label** | Short admin-set System label rendered as a tag span beside non-main-system items (never parenthetical text). Seeded `dnd5 24`, `dnd5 legacy` with no-break spaces. | `System.decorationLabel`, `.archetype-system-tag` | I |
| **Default Setting** | The Setting created for a new user; a creation marker only (renamable). | `Setting.isDefault` | I |
| **Effective system set** | `{ main system } ∪ additional systems`, resolved server-side at query time and used as an `IN` filter. Never stored on rows, never trusted from the client. | `effectiveSystems`, FD-0029 | I |
| **Main system** | The System a Setting is built on; transitive to its games. New archetype content is stamped with it. | `Setting.systemId` | I |
| **Setting** | A game world and the top-level content boundary. Owns notes, one timeline, games, keywords. Not to be confused with *preferences*. | `Setting` model, `src/server/settings/`, FD-0012 | I |
| **Setting configuration** | Owner edits of a Setting (name, description, include other systems). Opened as a floating modal. | `EditSettingModal`, `SettingConfigureProvider` | I |
| **System** | A versioned rules body (edition/ruleset), the parent of archetype content. "Edition" and "ruleset" are prose synonyms; code always says `System`. Seeded: `dnd55e` (default), `dnd5e-2014`. Users never create Systems. | `System` model, ADR-0030 | I |

## 3. Games & Time

| Term | Definition | Code / Source | Status |
|---|---|---|---|
| **Active Tracker** | A tracker instance running in a game, anchored to an instant. | `ActiveTracker` | I |
| **Base history** | Events with no game (`gameId = null`) on a timeline. | FD-0009 | I |
| **Calendar Config** | Calendar math (months, week length, leap rules, holidays). The one content type not scoped to a Setting; managed in the User context. Canonical API: `/api/fantasy-time/calendar-configs` (ADR-0023). | `CalendarConfig`, `/preferences/calendar-configs` | I |
| **Canonical** | Game flag: its events belong to the Setting's default history. Non-canonical events are tracked but hidden by default in Setting views (revealable). | `Game.canonical`, `revealNonCanonical` | I |
| **Command Bus** | The typed interface for all time mutations. | `TimeCommands`, `useTimeCommands()` | I |
| **currentInstant** | The real game time, persisted and evaluated by trackers. | `Game.currentInstant`, `TimeState` | I |
| **effectiveInstant** | `pinnedInstant ?? currentInstant`. What every time-aware view reads. | `TimeState` | I |
| **Epoch** | UI term for a Timeline Segment (a named era). | `TimelineSegment`, `Timeline.useEpochs` | I |
| **Event** | A dated occurrence on a timeline. All events are just Events; do not qualify by source (scheduled, encounter, game). | `TimelineEvent` | I |
| **Event Store** | Cache of events/trackers for the effective time window, with visibility filters. Components read time-scoped data only through it. | `useEventStore()`, `src/lib/time/eventStoreInternal.ts` | I |
| **Game** | A campaign run by its owner inside exactly one Setting. Time is optional per game. | `Game`, `src/server/games/` | I |
| **Game configuration** | Owner edits of a game (name, setting, time, canonical). Opened as a floating modal. Replaces the term "game settings". | `GameConfigureModal`, `GameSettingsForm` | I |
| **GameTimeProvider** | In-Game time context (state, commands, Event Store, sync). Mounted only when the game has time enabled. | `src/lib/time/GameTimeProvider.tsx`, `GameTimeWrapper` | I |
| **GameTimelineAssociation** | Future record linking a game to one of several timelines (dormancy, restoration, purge, `estimatedStartInstant`). Today a game has a single `timelineId`. | FD-0009 FR-24–34 | D |
| **In-Game Clock** | Context Bar affordance showing the current game date/time. Renders nothing without a time provider. | `InGameClock` | I |
| **Instant** | Integer point on a timeline's ruler; all time math uses instants. | `FantasyTimeline` | I |
| **Pinned Instant** | A user-controlled virtual "now" for browsing time without moving the game clock. Session-persisted per game; never triggers trackers. | `pinnedInstant`, ADR-0014 | I |
| **Reference Timeline** | A timeline viewed for context but not written to by the game. | FD-0009 | D |
| **Setting's timeline** | The single timeline of a Setting (1:1). Games with time enabled use it. | `Timeline.settingId` unique, `getSettingTimeline` | I |
| **Time opt-in** | Per-game optional time capability (default off). Off hides time surfaces and preserves data. | `Game.timeEnabled`, `toggleGameTime` | I |
| **Timeline** | A ruler of instants over a Calendar Config, owned by a Setting. Public template timelines have no owner and no Setting. | `Timeline`, `src/server/fantasyTime/` | I |
| **TimelineViewProvider** | Read-only time context for the Setting timeline surface: pin support, Event Store with the setting-context filter, no sync or commands. | `src/lib/time/TimelineViewProvider.tsx` | I |
| **Time State Controller** | Owner of `currentInstant`, `pinnedInstant`, `effectiveInstant`, and the undo/redo stack. | `timeStateReducer.ts` | I |
| **Tracker** | A countdown or timer anchored to an instant that fires when the game clock reaches it. | `ActiveTracker`, `src/server/trackers/` | I |
| **Tracker Collection / Tracker Definition** | Reusable tracker templates; a collection groups definitions and can be assigned to games. | `TrackerCollection`, `TrackerDefinition`, `GameTrackerCollection` | I |

## 4. Notes

| Term | Definition | Code / Source | Status |
|---|---|---|---|
| **ARI (Aligned Reference Image)** | Image display mode that offsets images into the gutter beside their anchor block, with a dotted guide line. Coupled to Early Wrap. | `AriLayer`, `computeAriSpacers`, FD-0017 | I |
| **Archivist** | The note browser, a floating modal (Alt+A). Hierarchy: Setting → Games → game. In-game it opens at the current game and shows only that game plus the Setting. | `src/components/archivist/` | I |
| **Block Model** | Note structure where `noteBlock` wrappers express hierarchy explicitly. Three-layer API: **BlockQueries** (reads), **BlockCommands** (TipTap commands), **BlockController** (React facade). | ADR-0018, `src/components/notes/blocks/` | I |
| **Breadcrumbs** | Note location path (e.g. Setting › Games › Game › Note). Clicking a segment opens the Archivist at that level. | `NoteEditor` | I |
| **contentVersion** | Integer version of a note document. New notes are v2; v1 upgrades lazily on load. | `Note.contentVersion`, `src/lib/notes/migration/` | I |
| **Early Wrap** | User preference limiting the text column to 720px. | `UserPreferences.earlyWrap` | I |
| **Expand View** | Floating overlay showing an image at maximum size. | `ImageExpandView` | I |
| **Image Block** | Atom node holding one stored image and an optional subtitle; occupies a full `noteBlock`. | `imageBlock`, `src/components/notes/extensions/ImageBlock.ts` | I |
| **Image Display Mode** | Note-level choice between **Inline** and **ARI** for all its images. | `Note.imageDisplayMode` | I |
| **Move to** | Selector (opened from the note subtitle) that reassigns a note to another Setting or game. | `moveNote` | I |
| **Note** | A user-owned structured document (TipTap/ProseMirror JSON) owned by exactly one context. | `Note`, `src/server/notes2/` | I |
| **Note Document / Note Metadata** | *Document* = the full row including `content`. *Metadata* = every column except `content`. Lists and searches load metadata only. | ADR-0022, `NOTE_METADATA_SELECT` | I |
| **NoteProvider** | Unified notes provider for Setting, game, and public contexts. All note management goes through it. | `src/lib/notes/NoteProvider.tsx` | I |
| **noteBlock** | The structural wrapper node of the block model; owns collapse state. | ADR-0018 | I |
| **Notes (domain)** | Canonical domain name. `src/server/notes2/` is a transition artifact pending rename to `notes/`. | `src/server/notes2/` | I |
| **Owning context** | The single owner of a note: `SETTING`, `GAME`, `PUBLIC` (plus reserved `MODULE`, `NONE`). Only one of `settingId`/`gameId` is set. | `NoteOwnerContext`, `Note.ownerContext` | I |
| **Paste Pipeline** | Clipboard HTML → `noteBlock` transform chain with per-source adapters. | FD-0018 | D |
| **Pending image / Deferred upload** | An inserted image held as a local blob until save, when it is uploaded and rewritten to a permanent path. Never persisted as `blob:`/`data:`. | `uploadPendingImages`, `persistPipeline` | I |
| **Persist Pipeline** | Save-time validation and projection: structural allowlist (`validateNoteContent`), one-archetype-per-note rule, snippet extraction, archetype index, keyword reconcile, system stamping. | `src/lib/notes/persistPipeline.ts`, `updateNote` | I |
| **Projection** | Typed Prisma select constant that bounds what a read returns. Only the document loader returns `content`. | ADR-0022, `noteProjections.ts` | I |
| **Read-only renderer** | Rich, non-editable rendering of a note (archetype display + formatted body). | `ReadOnlyNoteContent` | I |
| **Storage adapter** | Swappable image storage interface (local filesystem today). | `src/server/images/storageAdapter.ts` | I |
| **Subtitle** | (Note) the owning-context label under a note title. (Image) optional caption, also the alt-text source. | `NoteEditor`, `ImageBlockNodeView` | I |

## 5. Keywords & Snippets

| Term | Definition | Code / Source | Status |
|---|---|---|---|
| **Background Scanner** | Debounced scan of note text against the phrase index; fills the candidate list without altering the document. | `phraseScanner.ts` | I |
| **Candidate** | A text occurrence matching a keyword phrase (one list entry per keyword). | FD-0001 | I |
| **Forced Mark** | A keyword mark that carries only `using`, applied by Alt+click in mark mode. | FD-0001 | I |
| **Keyword** | A phrase + Keyword Type + optional linked note, scoped to exactly one of System, Setting, or game. | `Keyword`, `src/server/keywords/` | I |
| **Keyword lifecycle (archetype)** | Saving an archetype note creates or adopts its keyword; renames update the phrase (with an orphan warning); removing the archetype prompts delete/keep; deleting the note cascades. | `decideKeywordAction`, `reconcileArchetypeKeyword` | I |
| **Keyword Mark** | Identity-free mark `{ type: "keyword" }`, resolved by phrase at render time. Applied per occurrence, never automatically. | ADR-0019 | I |
| **Keyword Scope / Scope Transition** | Scope is implied by the populated FK (system, setting, or game). A transition broadens or narrows it. | `broadenKeywordScope`, `narrowKeywordScope` | I |
| **Keyword Type** | Formatting classification for keywords. Seeded: monster, npc, location, equipment, magicItem, spell, rule, custom. | `KeywordType` | I |
| **KeywordStore** | Client cache of visible keywords and types with O(1) phrase lookup and snippet preload. | `src/lib/notes/keywords/` | I |
| **Mark Tool / Mark Mode** | Keyword Panel control that highlights candidates and toggles marks by click. Escape exits. | `markToolPlugin.ts` | I |
| **Orphaned Mark** | A keyword mark whose text matches no keyword; rendered with a dashed underline and preserved on load. | FD-0001 | I |
| **Snippet** | Pre-extracted hover preview of a note, stored at save time. | `Note.snippet` | I |
| **SnippetContent** | Safe structured snippet format: `paragraph` fragments (bold/italic/code only) or `archetype` fields with an optional bounded body. No HTML, no ProseMirror JSON. | `src/lib/snippets/types.ts` | I |
| **Snippet Strategy** | How a note's snippet is extracted: `first-paragraph` (plain notes, the default when null) or the archetype's strategy. Never user-controlled. | `Note.snippetStrategy`, FD-0002 | I |
| **SnippetRenderer** | React snippet renderer with no ProseMirror dependency. The editor hover uses `renderSnippetToDOM` (DOM APIs, no `innerHTML`). | `src/components/snippets/` | I |
| **View Mode** | Keyword Panel toggle: **Highlighted** or **Plain**. | FD-0001 | I |

## 6. Archetypes, Rules & Import

| Term | Definition | Code / Source | Status |
|---|---|---|---|
| **Actor / Location / Sequence (archetypes)** | Future archetypes for NPCs, places, and narrative segments. | FD-0026 | D |
| **Archetype-fication** | Server step turning validated import data into a note (archetype block first, description paragraphs below). | `src/server/archetypeImport/archetypeToDocument.ts` | I |
| **Archetype Block** | The atom "header card" node in the first `noteBlock` of an archetype note; ends at its themed divider. Narrative text is regular note content below it. One per note. | `statBlock`, `spellBlock`, `equipmentBlock`, `magicItemBlock`, `ruleBlock` | I |
| **Archetype Block Schema** | The shipped Zod schema for an archetype's block `data`. Single source of truth. | `src/lib/archetypes/*/schema.ts` | I |
| **ArchetypeDefinition** | The contract every archetype registers (id, name, nodeType, keywordType, snippet/index extractors, fields, displays). | `src/lib/archetypes/types.ts` | I |
| **Archetype Index** | One denormalized search row per archetype note, written on save and filtered by scope and system. | `ArchetypeIndex`, `src/server/archetypeIndex/` | I |
| **Archetype Modal** | The shared, editor-independent form modal for creating/editing archetype data. Serves both the editor and Rules View "Create New". | `ArchetypeModal`, `ArchetypeAuthoringModal` | I |
| **Archetype registry** | Runtime lookup of registered archetypes. Every entry point must call `registerAllArchetypes()`. | `src/lib/archetypes/registry.ts` | I |
| **Equipment / Magic Item / Rule / Spell** | Informational archetypes (no computation). Themes: Equipment and Magic Item blue, Spell purple (arcane), Rule green. | `src/lib/archetypes/{equipment,magicItem,rule,spell}/` | I |
| **Homebrew** | Rule-block flag: true unless the content is public (admin-authored). | `isHomebrew` | I |
| **Import Context** | The owning context of imported notes: active Setting, or the game when in-game (or Public in admin). | FD-0020 | I |
| **Import Guidance** | Static per-archetype LLM prompt and schema text with Copy actions. | `src/lib/archetypes/guidance/` | I |
| **Import Parser** | Pure client library validating an import file and splitting each entry into `{ blockData, noteContent }`. | `parseImportFile` | I |
| **Import Schema** | Schema derived from the Archetype Block Schema via `.extend()`; may only add import-only fields (`description`). See `archetype-import-sync.md`. | `importSchemas.ts` | I |
| **Monster** | The archetype id of a creature/NPC stat block note. The block keeps the structural name `statBlock`; the archetype is `monster`. | `monsterArchetype.tsx` | I |
| **Note Archetype** | A classification decorating a note with one archetype block that defines its appearance, snippet, index, and keyword type. | FD-0013 | I |
| **Options provider** | Seam for system option sets (`getOptions(system, key)`), hard-coded today per ADR-0020. | `src/lib/dnd55e/optionsProvider.ts` | I |
| **Playing Rules** | Rules View category for game-mechanic rules (`rule` archetype), distinct from reference archetypes. | `src/lib/rules/categories.ts` | I |
| **Public archetype** | Archetype note owned by the system user (`ownerContext = PUBLIC`), read-only to non-admins, filtered by the effective system set. | FD-0028, FD-0029 | I |
| **Quick Format** | Stat block text helpers: Hit Roll, Save Roll, Damage Roll (Alt+Enter autocomplete in descriptions). | `src/lib/quickFormats/` | I |
| **Rule Family Tag** | Free-text grouping on a Rule block (e.g. "Weapon Mastery"). | `ruleBlock` | I |
| **Rule Replacement** | A user rule overriding a public rule. Only the dormant `Note.replacesNoteId` seam exists. | FD-0025 | D |
| **Rules View** | Main Content surface browsing the categories Playing Rules, Spells, Equipment, Magic Items, Monsters, with a read panel and "Create New". | `src/components/rules/`, `/content/rules/[category]` | I |
| **Stat Block** | The Monster archetype block: template-rendered creature data with computed values and Full/Compact/Snippet display modes. | `src/lib/archetypes/statblock/` | I |
| **StatBlockTemplate** | Game-system variant of the stat block (`dnd55e`). Monster-internal axis, not the archetype registry. | `statblock/registry.ts` | I |

## 7. Dice & Spotlight

| Term | Definition | Code / Source | Status |
|---|---|---|---|
| **Dice Formula** | A roll expression such as `2d6+3`. `kh`/`kl` are not supported. | `src/lib/dice/parser.ts` | I |
| **Dice Roll Panel** | Aux-Panel window logging session rolls (Alt+D). | `DiceRollPanel` | I |
| **DiceRollResult** | Outcome of a roll: formula, individual dice, modifier, total, timestamp, source label. | `src/lib/dice/types.ts` | I |
| **Preview (Spotlight)** | Full-screen read-only view of a result (Shift+Enter). | `SpotlightPreview` | I |
| **Quick Dice** | A formula typed into Spotlight; shows the average, Enter rolls and logs. | `SpotlightDiceResult` | I |
| **Rollable Surface** | A container registered for click-to-roll with one delegated listener. Marked formulas (`data-dice`) roll on click; text-scan needs Alt in editable surfaces. | `useRollableSurface`, `src/lib/diceRolling/` | I |
| **Spotlight** | Floating command bar (Mod+K): note search, subject filters, rules lookup, quick dice. Available in Setting and In-Game contexts. | `src/components/spotlight/` | I |
| **Subject Filter** | Spotlight prefix `<subject>:<query>` constraining search to an archetype (e.g. `monster:goblin`, `magic item:`). | `subjectDetector` | I |
| **Transient Result** | Page-centered, auto-dismissing roll display used when no Dice Roll Panel is open. | `TransientRollResult` | I |

## 8. Shell & UI Patterns

| Term | Definition | Code / Source | Status |
|---|---|---|---|
| **App Shell** | Layout frame: Context Bar, Navigation Rail, Main Content, Aux-Panel. Admin and auth routes render without the user shell. | `AppShell` | I |
| **Aux-Panel** | Persistent Panel host beside Main Content with up to 3 windows (compact, maximized, minimized). Position is a user preference. Mounted In-Game. | `src/components/aux-panel/`, `UserPreferences.auxPanelPosition` | I |
| **Configure** | Navigation Rail action opening Setting configuration (Setting context) or game configuration (In-Game) as a floating modal. | `SettingConfigureProvider` | I |
| **Content Tab** | Tabs inside the Dashboard's main area, one per play context. | FD-0021 | D |
| **Context Bar** | Thin top bar: Context Selector, Game Indicator, In-Game Clock, user menu. | `ContextBar` | I |
| **Context Selector** | Dropdown for switching contexts: Games (grouped by Setting), Settings, recently used, and a Manage section (Games, Settings). Switching does not stop the running game. | `ContextSelector`, `recentContexts.ts` | I |
| **Dashboard** | The In-Game running surface. Currently a placeholder page. | `/games/[gameId]/dm`, FD-0021 | P |
| **Design token** | Semantic CSS custom property with light/dark values. All colors use tokens. | `src/app/theme.css`, ADR-0015 | I |
| **Floating Modal** | UI pattern 3: on-demand overlay dismissed when done. See `ui-composition.md`. | — | I |
| **FlippableRow** | Row component that reverses visual order in left-handed layout via CSS only. | `src/components/FlippableRow.tsx`, ADR-0016 | I |
| **Game Indicator** | Context Bar element showing the running game or "No Game", with stop action. | `GameIndicator` | I |
| **Home page** | User preference for the post-login landing route (and Setting to activate). | `UserPreferences.homePath`, `homeSettingId` | I |
| **Keyword Panel / Read Panel** | Aux-Panel windows for keyword management and read-only linked-note content. | `KeywordPanel`, `ReadPanel` | I |
| **Layout mode** | User preference `standard` or `inverted` (left-handed). Drives `data-hand` on `<html>` via the `wr_layoutMode` cookie. | `UserPreferences.layoutMode` | I |
| **Main Content** | UI pattern 1: the route-owned primary workspace. See `ui-composition.md`. | — | I |
| **Mini-Calendar / Upcoming Trackers / Actors / Scribbles / Table of Contents / Outline** | Planned Aux-Panel windows. | nav-arch §4, §9 | D |
| **Navigation Rail** | Icon-only, context-aware left rail (Mobile Drawer on narrow screens). Hides time items when the game has time off. | `NavigationRail`, `MobileDrawer` | I |
| **Persistent Panel** | UI pattern 2: Aux-Panel window alongside Main Content. See `ui-composition.md`. | — | I |
| **Preferences overlay** | `/preferences/*` screens render as a modal over the last Setting/In-Game context, whose rail stays visible behind. | `PreferencesModal`, `lastAppContext.ts` | I |
| **Running game** | The game started via the Game Indicator. It stays active while the user browses other contexts. | `ActiveGameProvider` | I |
| **Shortcut Guide** | Overlay listing every registered command (Alt+H). | `ShortcutGuide` | I |
| **Theme mode** | Light or Dark today (cookie `wr_darkMode`, falls back to OS). Eye Comfort and Auto are designed. | `src/lib/theme.ts`, FD-0014 | P |

## 9. Users, Admin & Security

| Term | Definition | Code / Source | Status |
|---|---|---|---|
| **Admin-gated entrypoint** | An `/api/admin/*` route plus `src/server/admin/*` service that re-verifies admin identity. The only path for public writes. | `requireAdmin`, ADR-0029 §2 | I |
| **Capability contract** | Always-callable interface for an optional domain with a degraded (no-op) implementation when absent. Today time degrades via provider gating. | ADR-0021 (`src/lib/capabilities/` not built) | P |
| **Platform Admin** | A `User` with `isAdmin = true`. Manages public content only; never sees user-owned content. | `User.isAdmin`, FD-0028 | I |
| **Principal** | The authenticated user identified by the server-read `wr_userId` cookie. | ADR-0029 | I |
| **Public Content** | Pre-seeded, read-only content for all users: system-user notes (`ownerContext = PUBLIC`) plus unowned calendar configs and template timelines. | FD-0028 | I |
| **Scope-as-authorization** | Prohibited pattern: letting a request-supplied scope (e.g. `public`) grant capability. | ADR-0029 §2 | I |
| **System user** | The owner of public notes (`SYSTEM_USER_ID`). | `src/server/admin/constants.ts` | I |
| **User Preferences** | Global per-user settings (text editing, trackers, interface, aux-panel position, home page). Optimistic, no Save button. | `UserPreferences`, `UserPreferencesProvider`, FD-0027 | I |

## 10. Play & Prep (future)

All designed only unless noted. Keep these names when the features are built.

| Term | Definition | Source | Status |
|---|---|---|---|
| **Area / Region / Dungeon Play** | Numbered dungeon note sections, map polygons, and the synced map/room view. | FD-0005 | D |
| **Context Card / Event Feed / Resume Point** | Dashboard at-a-glance panels and persisted session state. | FD-0021 | D |
| **Encounter** | A named, ordered collection of Encounter Participants belonging to a game. | FD-0006 | D |
| **Encounter Participant** | An entry in an encounter (PC, monster, NPC, hazard, tracking row). Always qualified; never just "participant" in code or docs. PC identity is name + optional initiative modifier (ADR-0024). | FD-0006 | D |
| **Game Log / Logger** | Recorded occurrences of a game, written through scoped logger handles. | FD-0008 | D |
| **Module** | Reusable adventure content grouping notes, encounters, and sequences; replaces Book/Bookshelf. `NoteOwnerContext.MODULE` is reserved. | FD-0022 | D |
| **Programmed Element** | Inline interactive note element (skill check, encounter trigger, treasure) with prepared/active/resolved states. | FD-0023 | D |
| **Runner / Run Phase / Standby** | Surface-agnostic encounter execution flow, its internal stage, and a displaced running encounter. The runner lives in a Dashboard tab. | FD-0007 | D |
| **Session / Session Prep / Session Notes / Session Summary** | The period between starting and stopping a run, its preparation, notes captured during play, and the compiled summary. | FD-0021, FD-0022 | D |

---

## Retired Terms

Do not use these in new code, docs, or UI copy. Use the replacement.

| Retired | Replacement / reason |
|---|---|
| Book, Book Builder, Bookshelf, GameBookshelf | **Module** (FD-0022). Bookshelf models and routes removed. |
| Character, Character builder, CharacterClass/Subclass/Species | Removed (ADR-0024). Encounter participants use name + initiative modifier. |
| Companion view | Dropped. The encounter runner lives in a Dashboard tab. |
| Content scope, Global scope, Landing, Game Management, Game Running, Game Participation | The four contexts: User, Setting, In-Game, Public. Login/register is an auth gate, not a context. |
| ContentSource, ContentCreator | Removed (ADR-0026). |
| Currency System | Removed (ADR-0025). |
| DayPanel | **DaySchedule** (`src/components/calendar/DaySchedule.tsx`). |
| DMSidePanel, ContentNavigationSidebar | **Navigation Rail**. `ContentNavigationSidebar.tsx` is an unused leftover. |
| `dnd5.5e` (template id) | `dnd55e` (matches `System.slug`). |
| entityReference, entity registry, reference index | **Keyword Mark** system (ADR-0019). |
| Game settings (for game config) | **Game configuration**. "Setting" means the world. |
| GameNote, NotesPanel, tree view | **Note**, **NoteProvider**, **Archivist**. |
| GameNoteProvider | **NoteProvider**. |
| GameParticipant, Player role, player view | Dropped (ADR-0028). Models removed; `TimeMode 'player'` is a dormant code guard. |
| handMode, right/left-handed (as setting values) | **Layout mode** `standard` / `inverted`. "Left-handed" remains fine in prose. |
| Item, Item Collection, Item Category | Removed (ADR-0027). Use the Equipment / Magic Item archetypes. |
| `item` keyword type | `equipment` and `magicItem`. |
| Library (Archivist top level) | **Setting**. |
| noteType | **archetypeId** / Snippet Strategy. |
| Participant (unqualified) | **Encounter Participant**. |
| Resting storage, archive, `Note.archived` | Removed. Delete is permanent, with a warning. |
| `stat-block` / `statblock` (as archetype name) | **monster**. `statBlock` stays as the node name. |
| `/api/calendar-configs`, `/content/calendars` | `/api/fantasy-time/calendar-configs` (ADR-0023). |
| tRPC | Not installed. Route Handlers only. |
| UserSettings, `useUserSettings`, `/api/user-settings` | **UserPreferences**, `useUserPreferences`, `/api/user-preferences`. |
| useTimeSync | `useTimeState()` / `useTimeCommands()` from `@/lib/time`. |

## Deferred Terminology Decisions

- `src/server/notes2/` → `src/server/notes/` rename is pending (WR1-it0-S01 follow-up). Until then, "Notes" is the domain name and `notes2` is only a path.
- The Setting rail still shows a disabled "Books" item; it becomes "Modules" when FD-0022 lands.
- ADR-0019, ADR-0021, and ADR-0030 are still marked *Proposed* in the ADR index although their decisions are implemented.
