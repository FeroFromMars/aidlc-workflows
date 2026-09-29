# AI-DLC Documentation Output

## Rule: Documentation Location

When running the AI-DLC workflow, all process documentation (state, audit, inception plans, requirements, questions, construction plans and summaries, build-and-test) is written to `world-runner-docs/`:

```
world-runner-docs/ai-dlc-docs/<version-prefix>/<iteration-folder>/<work-item-folder>/
```

Never write it to `world-runner/aidlc-docs/`, which is legacy, or to any application repository.

- `<version-prefix>`: the major version under development. `WR1` covers all work targeting `world-runner` 1.0.
- `<iteration-folder>`: the MVP iteration (`main/mvp-plan.md`): `WR1-it0`, `WR1-it1`, `WR1-it2`, `WR1-it3`, and so on. Each iteration folder holds a `stories.md` with the iteration's goal, stories, status, delivered summary, commits, and follow-ups.
- `WR1/WR1-0/` is the pre-iteration archive (`WR1-F005` to `WR1-F023`, `WR1-T001` to `WR1-T013`). Do not add to it.

## Work Item Folder Naming

Format: `<work-item-id>-<short-kebab-name>`, fixed during Workspace Detection and used unchanged afterwards.

| Work item kind | ID | Example folder |
|---|---|---|
| Iteration story | `WR1-itN-SNN` | `WR1/WR1-it2/WR1-it2-S07-spotlight/` |
| FD-driven feature | `WR1-F<NNN>` (recorded in the FD's "Work Item" field) | `WR1/WR1-it3/WR1-F029-editions-cross-edition-visibility/` |
| Tech debt | `WR1-T<NNN>` | `WR1/WR1-itN/WR1-T014-<name>/` |

A group of tiny related stories may share one folder (e.g. `WR1-it0-S06-to-S09-adr-and-decisions`). Spike-style or ad hoc stories may be recorded directly in `stories.md`, with commit hashes, instead of a full folder.

## Directory Structure Inside a Work Item Folder

```
<work-item-folder>/
├── aidlc-state.md
├── audit.md
├── inception/
│   ├── plans/execution-plan.md
│   └── requirements/
│       ├── requirements.md
│       ├── requirement-verification-questions.md
│       └── requirements-clarification-questions*.md    (when needed)
└── construction/
    ├── plans/*-code-generation-plan.md
    ├── <unit>/                                         (per unit, when units exist)
    │   ├── functional-design/ · nfr-requirements/ · nfr-design/
    │   └── code/*-summary.md
    └── build-and-test/build-and-test-summary.md        (+ instructions when useful)
```

Create only the folders a work item actually uses.

## FD-Referenced Fast-Track

When a work item implements an approved Feature Design (`world-runner-docs/designs/FD-NNNN-*.md`), the FD is the requirements and application design. Record this table in `aidlc-state.md`:

| Stage | Behavior |
|---|---|
| Workspace Detection | Normal (Known Workspace Fast Path applies) |
| Reverse Engineering | Skipped or targeted. Steering + prior AI-DLC artifacts + `main/system-map.md` are the architecture reference |
| Requirements Analysis | Fast-tracked: read the FD requirements, validate them against current code, ask only about real ambiguities, dependency/scope gaps, and the extension opt-ins |
| User Stories | Skipped. FD acceptance criteria serve this purpose |
| Workflow Planning | Fast-tracked. The FD design section informs the construction stages |
| Application Design | Skipped. The FD **is** the application design |
| Units Generation | Evaluated. Decompose when the FD scope warrants it |
| Construction | Normal. FD sections are cited as the authoritative source |

The same fast-track applies to a fully specified iteration story grounded in FDs: validate and fill gaps, do not re-derive.

- **FD vs code**: FDs can predate shipped code. When they disagree, requirements must reconcile explicitly (a "Reconciliation" table). Code and owner decisions win, and the FD is flagged for update.
- **Extensions**: Security, Resiliency, and Property-Based Testing are opted into per work item during Requirements Analysis and recorded in `aidlc-state.md`. With Security off, `structure.md` § Security Baseline (ADR-0029) still applies.

## Closing a Work Item

- Mark the story or feature complete in the iteration `stories.md`, with a delivered summary, verification (tests, build), commits, and follow-ups.
- Record any new or changed terms in `.kiro/steering/glossary.md`, and any steering drift in the relevant steering file.
- DB-mutating steps (migrations, backfills) are listed in the build-and-test summary for the owner to run or approve.

## No-Overwrite Rule

Each work item gets its own folder. **Never overwrite or reuse another work item's folder.** If a workflow is rerun for the same item (e.g. after a scope change), append a suffix: `WR1-F024-archetype-import-v2`.

## Application Code Stays in Application Repos

This rule covers only AI-DLC process documentation. Application source code is always written to `world-runner/`, never to `world-runner-docs/`. ADRs and FDs are written to `world-runner-docs/adr/` and `world-runner-docs/designs/` as normal documentation, not inside AI-DLC folders.
