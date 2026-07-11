# World Runner – Command Registry Standards

> **Scope**: This file applies to `world-runner/` only.

## Overview

All keyboard shortcuts are managed through a centralized command registry at `src/lib/commands/`. Components interact with keyboard events exclusively through the `useCommand` hook — never through ad-hoc `onKeyDown` handlers or `document.addEventListener('keydown', ...)` for standard actions.

## Rules

### R1: All form submissions must use `useCommand('confirm', handler)`

Every form, modal, or inline-edit component that has a "submit" or "confirm" action triggered by Enter must register it via:

```tsx
useCommand('confirm', handleSubmit);
```

Do NOT use `onKeyDown={(e) => { if (e.key === 'Enter') ... }}`.

Exception: Accessibility handlers on clickable divs (Enter/Space to simulate click) are not form submissions and may use standard `onKeyDown`.

### R2: All closeable modals/dialogs/panels must use `useCommand('cancel', handler)`

Every component that closes on Escape must register:

```tsx
useCommand('cancel', onClose);
```

Do NOT use `document.addEventListener('keydown', ...)` or `onKeyDown` to listen for Escape.

### R3: All save shortcuts must use `useCommand('save', handler)`

Any component implementing Ctrl/Cmd+S must register:

```tsx
useCommand('save', saveFunction);
```

Do NOT manually listen for `(e.ctrlKey || e.metaKey) && e.key === 's'`.

### R4: Conditional command registration

For inline edits (e.g., year input, time input, rename fields) that are only active during an editing state, use conditional registration:

```tsx
useCommand('confirm', isEditing ? handleSubmit : null);
useCommand('cancel', isEditing ? handleCancel : null);
```

Passing `null` as the handler skips registration. This ensures commands only fire when the component is in the appropriate state.

### R5: New keyboard shortcuts must go through the registry

When adding a new keyboard shortcut:
1. Add a `CommandDefinition` entry in `src/lib/commands/registry.ts`
2. Add the corresponding `CommandId` to the type union in `types.ts`
3. Use `useCommand(newId, handler)` in the relevant component
4. The shortcut will automatically appear in the Shortcut Guide (Alt+H)

Do NOT implement standalone keyboard listeners outside the command system.

### R6: No remaining ad-hoc keyboard handlers for Enter/Escape/Ctrl+S

The following patterns are prohibited in new code:

```tsx
// ❌ Prohibited
onKeyDown={(e) => { if (e.key === 'Enter') ... }}
onKeyDown={(e) => { if (e.key === 'Escape') ... }}
document.addEventListener('keydown', (e) => { if (e.key === 'Escape') ... })
document.addEventListener('keydown', (e) => { if ((e.ctrlKey || e.metaKey) && e.key === 's') ... })
```

Use the command system instead:

```tsx
// ✅ Correct
useCommand('confirm', handleSubmit);
useCommand('cancel', onClose);
useCommand('save', save);
```

## Architecture

- `src/lib/commands/registry.ts` — single source of truth for all command definitions
- `src/lib/commands/types.ts` — TypeScript types
- `src/lib/commands/useCommand.ts` — hook for binding handlers (LIFO stack semantics)
- `src/lib/commands/CommandProvider.tsx` — global listener + context + shortcut guide
- `src/components/ShortcutGuide.tsx` — shortcut cheatsheet overlay (Alt+H)

## LIFO Stack Semantics

When multiple components register the same command (e.g., nested modals both registering `cancel`), the most recently mounted handler wins. This naturally supports nested UI — the inner modal's Escape takes priority over the outer page.
