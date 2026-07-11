# Content Validation Rules

## MANDATORY: Content Validation Before File Creation

**CRITICAL**: All generated content MUST be validated before writing to files to prevent parsing errors.

## ASCII Diagram Standards

**CRITICAL**: Before creating ANY file with ASCII diagrams:

1. **LOAD** `common/ascii-diagram-standards.md`
2. **VALIDATE** each diagram:
   - Count characters per line (all lines MUST be same width)
   - Use ONLY: `+` `-` `|` `^` `v` `<` `>` and spaces
   - NO Unicode box-drawing characters
   - Spaces only (NO tabs)
3. **TEST** alignment by verifying box corners align vertically

**See `common/ascii-diagram-standards.md` for patterns and validation checklist.**

## Mermaid Diagrams

**Do NOT generate Mermaid diagrams** in AI-DLC workflow artifacts. They consume significant tokens in both generation and validation without adding actionable value for the AI model. Use text-based stage checklists instead (see `inception/workflow-planning.md` Step 6).

If a user explicitly requests a Mermaid diagram outside the workflow, validate syntax before writing:
- Use alphanumeric + underscore only for node IDs
- Escape special characters in labels
- Include a text fallback if generation is uncertain

## General Content Validation

### Pre-Creation Validation Checklist
- [ ] Validate embedded code blocks (JSON, YAML)
- [ ] Check special character escaping
- [ ] Verify markdown syntax correctness
- [ ] Test content parsing compatibility

### Error Prevention Rules
1. **Always validate before using tools/commands to write files**: Never write unvalidated content
2. **Escape special characters**: Particularly in diagrams and code blocks
3. **Provide alternatives**: Include text versions of visual content
4. **Test syntax**: Validate complex content structures

## Validation Failure Handling

### When Validation Fails
1. **Log the error**: Record what failed validation
2. **Use fallback content**: Switch to text-based alternative
3. **Continue workflow**: Don't block on content validation failures
4. **Inform user**: Mention simplified content was used due to parsing constraints
