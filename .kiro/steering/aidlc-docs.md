# AI-DLC Documentation Output

## Rule: Documentation Location

When running the AI-DLC workflow, all construction documentation (inception plans, requirements, code generation plans, build-and-test summaries, audit logs, state files) MUST be written to:

```
world-runner-docs/ai-dlc-docs/<version-prefix>/<feature-folder>/
```

**NOT** to `world-runner/aidlc-docs/` or any application repository.

The `<version-prefix>` corresponds to the current major version being developed:
- `WR1` — all features targeting version 1.0 of `world-runner`
- `WRCC1` — all features targeting version 1.0 of `world-runner-cc`

## Feature Folder Naming

The `<feature-folder>` is derived from the work item ID and short name:

- Format: `<work-item-id>-<short-kebab-name>`
- Examples:
  - `WR1-F003-active-game-navbar`
  - `WR1-F004-game-timelines-time-tracking`
  - `WRCC-F001-feature-catalog`

Full path examples:
- `world-runner-docs/ai-dlc-docs/WR1/WR1-F003-active-game-navbar/`
- `world-runner-docs/ai-dlc-docs/WR1/WR1-F004-game-timelines-time-tracking/`
- `world-runner-docs/ai-dlc-docs/WRCC1/WRCC-F001-feature-catalog/`

The folder name is determined during Workspace Detection (when the work item is assigned) and used consistently throughout the workflow.

## Directory Structure Inside Feature Folder

```
world-runner-docs/ai-dlc-docs/WR1/<feature-folder>/
├── aidlc-state.md
├── audit.md
├── inception/
│   ├── plans/
│   │   └── execution-plan.md
│   └── requirements/
│       ├── requirements.md
│       └── requirement-verification-questions.md
└── construction/
    ├── plans/
    │   └── *-code-generation-plan.md
    └── build-and-test/
        ├── build-instructions.md
        ├── unit-test-instructions.md
        ├── integration-test-instructions.md
        └── build-and-test-summary.md
```

## No-Overwrite Rule

Each AI-DLC workflow creates its own feature folder. **Never overwrite or reuse a previous feature's folder.** If a workflow is rerun for the same feature (e.g., after a scope change), append a suffix:

- First run: `WR1-F004-game-timelines-time-tracking`
- Rerun: `WR1-F004-game-timelines-time-tracking-v2`

## Application Code Stays in Application Repos

This rule applies ONLY to AI-DLC process documentation (plans, audits, requirements, summaries). Application source code is always written to the appropriate application repository (`world-runner/`, `world-runner-cc/`) — never to `world-runner-docs/`.
