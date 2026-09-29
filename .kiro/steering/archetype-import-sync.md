---
inclusion: fileMatch
fileMatchPattern: "world-runner/src/lib/archetypes/**/*.ts"
---

# World Runner – Archetype Import Schema Sync

> **Scope**: `world-runner/`. Paths are relative to `world-runner/`.
> **Authority**: FD-0020 (Archetype Import), § Import / Entity Separation: FR-Sep-1 to FR-Sep-5 and AC-20 to AC-24. Delivered in WR1-F024.
> This file is the human/AI-facing layer of a three-layer sync mechanism. It documents intent. It does not enforce parity; derivation and the contract test do.

| Layer | Mechanism | Guarantees |
|---|---|---|
| Derivation (FR-Sep-2) | `.extend()` on the shipped block schema | Block-field presence and type parity, enforced by Zod and the compiler |
| Contract test (FR-Sep-4) | `src/lib/archetypes/import/importSchemas.contract.test.ts` | Every archetype importable or explicitly excluded; fixtures round-trip; import-only fields explicit |
| Steering (FR-Sep-5) | This file | Review prompt whenever a block schema changes |

## The invariant: derive, don't copy; only add

- The **Archetype Block Schema** is the single source of truth for block `data`: `src/lib/archetypes/{spell,equipment,magicItem,rule}/schema.ts`, and for Monster the stat block template schema and `StatBlockDraft` type under `src/lib/archetypes/statblock/`.
- The **Import Schema** (`src/lib/archetypes/import/importSchemas.ts`) is a separate entity **derived** from the block schema. It may only **add** import-only note-content fields. Today that is just `description` for Spell, Equipment, and Magic Item, which becomes paragraph blocks below the archetype block.
- It must never redefine, remove, rename, relax, or diverge from block-field types. Field names are always WR-native. There is no alias or normalization layer (FR-8).
- Derivation form. Order matters: extend **before** strict, so import-only keys count as recognized (FR-9):

  ```ts
  const spellImportSchema = spellSchema.extend({ description: z.string().optional() }).strict();
  ```

- Never hand-copy block field definitions into import code.
- **Fix at the source.** If import rejects valid real-world data, fix the block schema, not the Import Schema. For example, a real item may have no weight. Optionality then flows into import automatically. Precedent: Equipment `cost`/`weight` became optional in `equipment/schema.ts` during WR1-F024.

## Parser split (FR-Sep-3)

`parseImportFile` returns `{ blockData, noteContent }` for each entry.

- `blockData` contains no import-only keys and must re-validate against the shipped schema (`blockValidators.validateBlockData`).
- `noteContent.description` is appended as paragraph `noteBlock`s below the archetype block. `archetypeToDocument` does this on top of `buildArchetypeNoteDoc`.

Validation is all-or-nothing for the batch. Unknown keys fail loudly, naming the key and the entry index.

## Monster exception (template-based, not derived)

Monster has no exported block schema to extend. Import works in three steps:

1. Validate a `StatBlockDraft`-shaped entry with `src/lib/archetypes/import/monsterDraftSchema.ts`. Its top level is `.strict()`, nested fields are lenient, and `schemaVersion: 1` is required.
2. Apply `applyImportOverrides` (`monsterDraftOverrides.ts`) so authored AC/HP/initiative values survive.
3. Run the template's `computeDerived`.

`monsterDraftSchema.ts` is a **hand-maintained mirror** of `StatBlockDraft`. Any change to the stat block draft type or template schema requires a manual review of `monsterDraftSchema.ts`, `monsterDraftOverrides.ts`, and the Monster guidance text.

## Change-review checklist

Run this whenever a file under `src/lib/archetypes/*/schema.ts` or the stat block draft/template schema changes, or when a new archetype is registered:

1. **Simple archetypes**: confirm the change flows into the Import Schema through `.extend()`. Do not duplicate it.
2. **Import-only fields**: do they still make sense for this archetype? Does it need one?
3. **Monster**: update `monsterDraftSchema.ts` and its overrides to mirror the draft change.
4. **Guidance**: update the static guidance. It is hand-written and **not** derived.
   - `src/lib/archetypes/guidance/schemaText.ts` must document every accepted field.
   - `src/lib/archetypes/guidance/prompts.ts` holds mapping hints, the preserve-all-data rule, and the worked example.
   - Precedent: incomplete Monster schema text caused silent lossy conversion during WR1-F024.
5. **Fixtures**: update `src/lib/archetypes/import/fixtures/` and the generators.
6. **New archetype**: add it to `IMPORT_SCHEMAS`, `blockValidators.ts`, and the guidance. Otherwise, as a deliberate decision, add it to `KNOWN_NON_IMPORTABLE` in the contract test (currently `rule`).
7. **Run the suites**:

   ```bash
   npx vitest --run src/lib/archetypes/import src/lib/archetypes/guidance src/server/archetypeImport src/server/admin
   ```

## Consumers

- User import: `POST /api/archetype-import` → `src/server/archetypeImport/`. Setting or game context.
- Public import: `POST /api/admin/archetype-import` → `src/server/admin/importPublicArchetypes.ts`. Admin-gated, bounded by `MAX_PUBLIC_IMPORT_ENTRIES`, stamped with the admin-selected System.
