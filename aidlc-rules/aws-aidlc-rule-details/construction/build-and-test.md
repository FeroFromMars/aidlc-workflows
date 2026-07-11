# Build and Test

**Purpose**: Verify that all generated code builds and tests pass.

## Prerequisites

- Code Generation must be complete for all units
- All code artifacts must be generated
- Project is ready for build and testing

---

## Execution Model

Build and Test is an **execution stage**, not a documentation stage. The AI executes the project's build and test commands directly and reports results — it does NOT generate instruction markdown files describing how to run them.

---

## Step 1: Determine Build and Test Commands

Identify the correct commands from the project's configuration:
- Check `package.json` scripts, `Makefile`, `pom.xml`, `build.gradle`, `Cargo.toml`, or equivalent
- Use the commands already established in the project (do not invent new ones)
- If no test framework exists, note this and skip test execution

Common patterns:
- **npm/Node.js**: `npm run build`, `npx vitest --run` (or `npm test -- --run`)
- **Maven**: `mvn clean install`
- **Gradle**: `./gradlew build`
- **Python**: `python -m pytest`
- **Rust**: `cargo build`, `cargo test`

---

## Step 2: Execute Build

1. Run the project's build command
2. If the build fails:
   - Diagnose the error from the output
   - Fix the issue in the generated code
   - Re-run the build until it succeeds
3. Record the final build status (pass/fail)

---

## Step 3: Execute Tests

1. Run the project's test command (single-pass, non-watch mode)
2. If tests fail:
   - Identify failing tests from the output
   - Determine if the failure is in new code or a regression
   - Fix the issue and re-run
3. Record the final test status (pass/fail, count of tests run)

---

## Step 4: Update State Tracking

Update `aidlc-docs/aidlc-state.md`:
- Mark Build and Test stage as complete
- Update current status

---

## Step 5: Present Results to User

Present completion message in this structure:

1. **Completion Announcement** (mandatory):

```markdown
# 🔨 Build and Test Complete
```

2. **Results Summary** (mandatory): Provide concise bullet-point results:
   - Build status (pass/fail)
   - Test status (pass/fail, number of tests)
   - Any issues encountered and fixed during the process

3. **Formatted Workflow Message** (mandatory): Always end with this exact format:

```markdown
> **🚀 <u>**WHAT'S NEXT?**</u>**
>
> **You may:**
>
> 🔧 **Request Changes** - Ask for modifications based on your review
> ✅ **Approve & Continue** - Approve build and test results and proceed to **Operations**

---
```

---

## Step 6: Log Interaction

**MANDATORY**: Log the stage completion in `aidlc-docs/audit.md`:

```markdown
## Build and Test Stage
**Timestamp**: [ISO timestamp]
**Build Command**: [Command used]
**Build Status**: [Success/Failed]
**Test Command**: [Command used]
**Test Status**: [X passed, Y failed]

---
```
