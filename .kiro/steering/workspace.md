# World Runner – Multi-Repo Workspace

## Repositories

The workspace root holds three repositories plus the workspace-level `.kiro/` folder.

| Repository | Purpose | Path |
|---|---|---|
| `world-runner` | Application code: Next.js product UI, API, services, Prisma schema | `world-runner/` |
| `world-runner-docs` | ADRs, feature designs, product docs, AI-DLC records, historical docs | `world-runner-docs/` |
| `aidlc-workflows` | Fork of AWS AI-DLC workflow rules (branch `world-runner-main`) plus the versioned copy of this steering | `aidlc-workflows/` |

## Workspace Layout

```
<workspace root>/
├── .kiro/
│   ├── steering/                  Live workspace steering (applies to all repos)
│   │   └── aws-aidlc-rules/       AI-DLC core workflow (synced from aidlc-workflows)
│   └── aws-aidlc-rule-details/    AI-DLC rule details (synced from aidlc-workflows)
├── world-runner/                  Application repo
├── world-runner-docs/             Documentation repo
└── aidlc-workflows/               AI-DLC rules + versioned steering
```

## Repository Boundaries

### `world-runner` (application)
- All product code: pages, components, API routes, services, Prisma schema, seed and scripts.
- Tech stack in `tech.md`; structure and standards in `structure.md`.
- Its README and `src/app/README.md` are stale (they still mention characters, item collections, currency, tRPC). Do not use them as a reference; steering and `world-runner-docs` win.
- `world-runner/aidlc-docs/` and `world-runner/aidlc/` are legacy AI-DLC output from before the docs moved. Never write new AI-DLC docs there (`aidlc-docs.md`).

### `world-runner-docs` (documentation)
- `adr/`: Architecture Decision Records (index in `adr/README.md`).
- `designs/`: Feature Designs `FD-NNNN-*.md` (template in `designs/TEMPLATE.md`).
- `main/`: product docs: `manifesto.md`, `mvp-plan.md`, `MVP-milestone-sequences.md`, `navigation-architecture.md`, `system-map.md`, `prep-workflow.md`, `production-readiness-plan.md`.
- `ai-dlc-docs/`: AI-DLC records per version and iteration (`aidlc-docs.md`).
- `control-center/`: architecture notes for the paused control-center project (reference only).
- `deprecated/`: read-only historical reference. Never the primary source for active work.
- No application code. No steering files.

### `aidlc-workflows` (process rules)
- `aidlc-rules/aws-aidlc-rules/` and `aidlc-rules/aws-aidlc-rule-details/`: source of the AI-DLC workflow, customized for World Runner.
- `.kiro/steering/`: versioned copy of the workspace steering.
- `sync-to-kiro.sh`: copies the AI-DLC rules into the workspace `.kiro/` (rule details + `steering/aws-aidlc-rules/`).
- `pull-from-kiro.sh`: copies the live top-level steering files (`.kiro/steering/*.md`) back into this repo so changes can be committed.
- **Commit steering changes.** After editing live steering, run `./pull-from-kiro.sh` and commit in `aidlc-workflows`. Uncommitted steering has been lost before.

## Cross-Repo Documentation

| Document Type | Location |
|---|---|
| Glossary (official terms) | `.kiro/steering/glossary.md` |
| Steering | `.kiro/steering/` (workspace root) |
| AI-DLC rule details | `.kiro/aws-aidlc-rule-details/` (workspace root) |
| ADRs | `world-runner-docs/adr/` |
| Feature Designs | `world-runner-docs/designs/` |
| Product docs | `world-runner-docs/main/` |
| AI-DLC records | `world-runner-docs/ai-dlc-docs/` |
| Deprecated docs | `world-runner-docs/deprecated/` |

## Path References in Steering

- Paths in `structure.md`, `tech.md`, `ux.md`, `commands.md`, `time-management.md`, `ui-composition.md`, `naming.md`, and `archetype-import-sync.md` are relative to `world-runner/`.
- ADR, FD, and product-doc references point into `world-runner-docs/`.

## Precedence

When sources conflict: **code and accepted docs** (ADRs, FDs, AI-DLC records) win over steering. Fix the steering when you find drift, and tell the owner.
