# World Runner – Naming Rules

> **Scope**: `world-runner/` code (TypeScript, TSX, CSS class names, test names).
> **Origin**: WR1-T012 (block model unification). Cited by every later AI-DLC story as "no abbreviations per `naming.md`".
> Domain vocabulary comes from `glossary.md`. File, folder, and component naming conventions are in `structure.md` § Naming Conventions.

## N1: No abbreviated identifiers

Use full words for variables, parameters, functions, properties, and types.

| Do not use | Use |
|---|---|
| `pos` | `position` |
| `attrs` | `attributes` |
| `tr` | `transaction` |
| `sel` | `selection` |
| `opts` | `options` |
| `e`, `evt` | `event` |
| `el` | `element` |
| `idx`, `i` (outside tiny loops) | `index` |
| `btn`, `msg`, `cfg`, `ctx`, `res`, `req` | `button`, `message`, `config`, `context`, `response`, `request` |

Applies to library callbacks too: `(transaction) => …`, not `(tr) => …`, even where the library's own docs abbreviate.

## N2: Established acronyms are allowed, with a trailing comment on first use

Widely understood acronyms and project terms may stay short (`id`, `url`, `api`, `dom`, `json`, `html`, `css`, `pbt`, `ari`, `dm`, `ac` in stat-block fields). Where one is used in a non-obvious identifier, add a short trailing comment the first time it appears in a file:

```ts
const userId = cookieStore.get('wr_userId')?.value; // user identifier
const ariWidth = 240; // aligned reference image gutter width (px)
```

Identifiers already fixed by external contracts are exempt: Prisma field names, API payload keys, D&D-native schema keys (`str`, `dex`, `ac`, `hp`), library APIs, and quick-format tokens (`hit`, `sav`, `dmg`).

## N3: Use glossary terms

Name things with their glossary term, and never with a retired one (`glossary.md` § Retired Terms). Examples: `archetypeId` not `noteType`; `layoutMode` not `handMode`; `monster` not `statblock` for the archetype; `EncounterParticipant` not `Participant`.

## N4: Booleans and handlers

- Booleans read as predicates: `isPinned`, `hasTimeline`, `canConfigure`, `timeEnabled`.
- Event handler props are `onX`; their implementations are `handleX`.
