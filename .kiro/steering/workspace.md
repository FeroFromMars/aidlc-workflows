# World Runner – Multi-Repo Workspace

## Repositories

The World Runner platform is developed across four repositories, all present in the same workspace root.

| Repository | Purpose | Path |
|---|---|---|
| `world-runner` | Application code (Next.js, product UI, API, services) | `world-runner/` |
| `world-runner-cc` | Feature governance control center (policy, plans, snapshots) | `world-runner-cc/` |
| `world-runner-docs` | Architecture Decision Records and historical documentation | `world-runner-docs/` |
| `WorldRunnerControlFigma` | Figma Make export — readonly UI reference for `world-runner-cc` | `WorldRunnerControlFigma/` |

## Workspace Layout

```
KiroWorkspace/
├── .kiro/
│   └── steering/       Workspace-level steering (applies to all repos)
├── world-runner/       Application repo
├── world-runner-cc/    Control center repo
├── world-runner-docs/  Documentation repo
└── WorldRunnerControlFigma/  Figma UI source (readonly)
```

## Repository Boundaries

### `world-runner` (application)

- All product-facing code: pages, components, API routes, services, Prisma schema.
- Owns runtime enforcement of feature policy.
- Owns user preferences, session state, offline cache.
- Tech stack documented in `tech.md`.

### `world-runner-cc` (control center)

- Administrative control plane for feature governance.
- Owns feature definitions, global enable/disable state, subscription plans, entitlements, policy snapshots.
- Does NOT own user-facing product UI or runtime rendering.
- UI source comes from `WorldRunnerControlFigma` — see Figma Integration section below.
- Tech stack documented in `tech-cc.md`.

### `WorldRunnerControlFigma` (Figma UI source — readonly)

- Contains Figma Make export code: Vite + React + Tailwind CSS v4 + shadcn/ui.
- **Strictly readonly** — never edit files in this repo directly. Changes flow from Figma Make → this repo.
- Serves as the canonical UI reference for `world-runner-cc`.
- Components, styles, and theme tokens are copied into `world-runner-cc` as needed.
- No steering rules, no specs, no tests. This is a design artifact, not a product codebase.

### `world-runner-docs` (documentation)

- Architecture Decision Records in `adr/`.
- Historical/deprecated documentation in `deprecated/`.
- Control center architecture docs in `control-center/`.
- Scratch notes in `.scratches/`.
- No application code. No steering files. No specs.

## Shared Contract

The contract between `world-runner-cc` and `world-runner` is a **versioned policy snapshot** — not shared database tables, not live API calls at render time.

- `world-runner-cc` publishes snapshots.
- `world-runner` syncs, caches, and evaluates locally.
- Offline mode uses the last valid cached snapshot.

## Cross-Repo Documentation

| Document Type          | Location                                         |
| ------------------------| --------------------------------------------------|
| ADRs                   | `world-runner-docs/adr/`                         |
| AWS AIDLC RULE DETAILS | `.kiro/aws-aidlc-rule-details/` (workspace root) |
| Steering               | `.kiro/steering/` (workspace root)               |
| CC architecture docs   | `world-runner-docs/control-center/`              |
| Deprecated docs        | `world-runner-docs/deprecated/`                  |

## Path References in Steering

- Paths in `structure.md` and `tech.md` are relative to `world-runner/`.
- Paths in `tech-cc.md` are relative to `world-runner-cc/`.
- Paths in `WorldRunnerControlFigma/` are readonly references — never targets for edits.
- ADR references point to `world-runner-docs/adr/`.

## Figma Integration

The Figma power is used **exclusively for `world-runner-cc`**. The `world-runner` application retains its own styling approach (semantic CSS classes in `globals.css`).

### Workflow

```
Figma Make file ──export──▶ WorldRunnerControlFigma/ (readonly)
                                      │
                                      │ copy/adapt
                                      ▼
                              world-runner-cc/ (production)
```

1. UI designs are authored in Figma (Make or Design files).
2. Figma exports land in `WorldRunnerControlFigma/` — this repo is never manually edited.
3. When the Figma repo updates, relevant changes are copied into `world-runner-cc/`, adapting them to Next.js conventions (App Router pages, server/client split).
4. The Figma power's `get_design_context` and `get_screenshot` tools can also be used directly for incremental UI work in `world-runner-cc`.

### Figma-Sourced File Exemptions

Files copied verbatim or near-verbatim from `WorldRunnerControlFigma/` into `world-runner-cc/` are exempt from the following steering rules:

- **200-line component limit** — Figma-sourced components may exceed this to stay in sync with upstream. They are refactored only when the CC codebase wraps or extends them.
- **No inline `style={{}}` props** — Figma output uses inline styles for dynamic values and font stacks. These are acceptable in Figma-sourced files.
- **Semantic CSS class names** — Tailwind utility classes are the standard in `world-runner-cc` (matching Figma output).

These exemptions apply only to files in a designated Figma source directory within `world-runner-cc` (e.g., `src/components/figma/` or similar). Production components that wrap or extend Figma sources follow normal steering rules.
