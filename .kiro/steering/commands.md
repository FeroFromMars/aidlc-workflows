# World Runner – Command Registry Standards

> **Scope**: `world-runner/` only.

## Overview

All keyboard shortcuts go through a centralized command registry in `src/lib/commands/`. Components handle keyboard actions only through the `useCommand` hook. They never use ad-hoc `onKeyDown` handlers or `document.addEventListener('keydown', ...)` for standard actions.

## Registered Commands

`src/lib/commands/registry.ts` is the single source of truth. `mod` means Cmd on macOS and Ctrl elsewhere.

| CommandId | Shortcut | Purpose | Active |
|---|---|---|---|
| `confirm` | Enter | Confirm / submit (suppressed in a `<textarea>` or inside a `contenteditable` editor) | yes |
| `cancel` | Escape | Cancel / close | yes |
| `save` | Mod+S | Save | yes |
| `undo` | Mod+Z | Undo (time undo, TipTap history in the editor) | yes |
| `redo` | Mod+Shift+Z | Redo | yes |
| `showShortcutGuide` | Alt+H | Shortcut Guide (handled by `CommandProvider`) | yes |
| `archivist` | Alt+A | Open the Archivist | yes |
| `toggleDicePanel` | Alt+D | Toggle the Dice Roll Panel | yes |
| `spotlight` | Mod+K | Open Spotlight | yes |
| `spotlightPreview` | Shift+Enter | Preview the selected Spotlight result | yes |
| `contextSkip` / `contextSkipBack` | L / J | Reserved | no |

## Rules

### R1: Form submissions use `useCommand('confirm', handler)`

Every form, modal, or inline edit that submits on Enter registers:

```tsx
useCommand('confirm', handleSubmit);
```

Do not use `onKeyDown={(event) => { if (event.key === 'Enter') ... }}`.

Exception: accessibility handlers on clickable non-button elements (Enter/Space to simulate a click) are not submissions and may use `onKeyDown`.

### R2: Closeable modals, dialogs, and panels use `useCommand('cancel', handler)`

```tsx
useCommand('cancel', onClose);
```

Do not listen for Escape with `document.addEventListener` or `onKeyDown`.

### R3: Save shortcuts use `useCommand('save', handler)`

Do not listen for `(event.ctrlKey || event.metaKey) && event.key === 's'` by hand.

### R4: Conditional registration

Inline edits that are only active in an editing state register conditionally:

```tsx
useCommand('confirm', isEditing ? handleSubmit : null);
useCommand('cancel', isEditing ? handleCancel : null);
```

Passing `null` skips registration.

### R5: New shortcuts go through the registry

1. Add a `CommandDefinition` (`id`, `label`, `key`, `modifiers: { mod?, alt?, shift? }`, `active`) to `COMMANDS` in `registry.ts`.
2. Add the `CommandId` to the union in `types.ts`.
3. Call `useCommand(newId, handler)` in the component.
4. The shortcut then appears in the Shortcut Guide (Alt+H) automatically.

Check the table above for conflicts before choosing a key. Alt shortcuts are matched on `event.code`, so they work with the macOS Option key.

### R6: No ad-hoc Enter / Escape / Mod+S handlers

Prohibited in new code:

```tsx
// ❌
onKeyDown={(event) => { if (event.key === 'Enter') ... }}
onKeyDown={(event) => { if (event.key === 'Escape') ... }}
document.addEventListener('keydown', (event) => { if (event.key === 'Escape') ... })
document.addEventListener('keydown', (event) => { if ((event.ctrlKey || event.metaKey) && event.key === 's') ... })
```

```tsx
// ✅
useCommand('confirm', handleSubmit);
useCommand('cancel', onClose);
useCommand('save', save);
```

## Documented Exceptions

These are allowed. They are the only exceptions; any new one must be recorded here.

- **Editor-native shortcuts**: TipTap formatting shortcuts (bold, headings, callouts such as Mod+Alt+6) and the block keymap (Enter / Backspace / Tab / Shift+Tab in `BlockKeymap`) are TipTap/ProseMirror keymaps, not registry commands. The NoteEditor registers `undo`/`redo` but not `confirm`/`cancel`.
- **Rich text fields (WRText, FD-0030 FR-C6/C7)**: Enter inside any `contenteditable` never fires `confirm` (`matchEvent`), so it inserts a paragraph instead of submitting the host modal. In the `archetypeField` / `archetypeLore` profiles, Tab and Shift+Tab outside a list are left to the browser (focus moves; no keyboard trap) and inside a list indent/outdent (`BlockKeymap` `tabMovesFocus`). A focused WRText registers `undo`/`redo` for its own history, taking LIFO precedence over page-level undo (e.g. time undo).
- **Vanilla NodeViews** cannot reach React context, so they use local key handling. Example: the image subtitle editor (Enter commits, Shift+Enter inserts a newline, Escape cancels).
- **Input-local navigation**: arrow keys and Tab inside an input or list (e.g. `SpotlightInput` result navigation and ghost-text accept) may use `onKeyDown`.
- **Field-local autocomplete**: Alt+Enter quick-format autocomplete in stat block description fields.
- **Pointer modifiers**: Alt+click actions (forced keyword mark, text-scan dice roll) are handled in ProseMirror plugins or rollable-surface listeners. They are not keyboard shortcuts.
- **Double-click** uses plain `onDoubleClick`. The registry is keyboard-only.

## Architecture

- `src/lib/commands/registry.ts`: command definitions and `matchEvent`.
- `src/lib/commands/types.ts`: `CommandId`, `CommandDefinition`, `KeyModifiers`, `CommandHandler`.
- `src/lib/commands/useCommand.ts`: binds handlers with LIFO stack semantics.
- `src/lib/commands/CommandProvider.tsx`: global capture listener, context, and the Shortcut Guide toggle.
- `src/lib/commands/index.ts`: barrel.
- `src/components/ShortcutGuide.tsx`: the shortcut cheatsheet overlay.

## LIFO Stack Semantics

When several components register the same command (e.g. nested modals both registering `cancel`), the most recently mounted handler wins. So an inner modal's Escape closes it before the outer page, and Spotlight Preview closes before Spotlight.

In tests, dispatch keyboard events on `document`.
