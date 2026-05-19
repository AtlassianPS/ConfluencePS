# AI Instructions for ConfluencePS

> **Single source of truth for AI coding assistants.**
> Tool-specific entry-point files in this repository reference this file.

## Quick Reference (Critical Rules)

1. **One functionality per commit**: implementation, tests, docs, and changelog move together.
2. **Keep REST calls behind ConfluencePS abstractions**: command implementations should route HTTP work through `Invoke-Method` (and its wrapper stack), not ad-hoc web calls.
3. **Preserve compatibility**: keep existing Cloud/Data Center behavior and public cmdlet parameter/output contracts unless the task explicitly changes them.
4. **Instruction-only changes still require local validation**: `.github/workflows/ci.yml` path filters skip many AI-instruction files.
5. **Do not finalize on red builds**: run `Invoke-Build -Task Lint` and `Invoke-Build -Task Build, Test` before completion.
6. **Keep tests and docs aligned with behavior**: update focused tests in `Tests/`, docs in `docs/en-US/`, and `CHANGELOG.md` for user-visible changes.

## AI Tool Compatibility

| Tool | Entry point | Canonical references |
|------|-------------|----------------------|
| GitHub Copilot | `.github/copilot-instructions.md` | `AGENTS.md`, `.github/ai-context/powershell-rules.md` |
| Cursor | `.cursor/rules/confluenceps.mdc` | `AGENTS.md`, `.github/ai-context/powershell-rules.md` |
| Claude Code | `CLAUDE.md` | `AGENTS.md`, `.github/ai-context/powershell-rules.md` |
| Gemini/Antigravity | `GEMINI.md` | `AGENTS.md`, `.github/ai-context/powershell-rules.md` |

## Repository Map

- Module source: `ConfluencePS/Public/*.ps1`, `ConfluencePS/Private/*.ps1`
- REST wrapper entrypoint: `ConfluencePS/Public/Invoke-Method.ps1`
- Build entrypoint: `ConfluencePS.build.ps1`
- Test suites: `Tests/*.Tests.ps1`, `Tests/Functions/*.Tests.ps1`
- Docs/help sources: `docs/en-US/commands/*.md`, `docs/en-US/classes/*.md`
- Build helpers: `Tools/setup.ps1`, `Tools/BuildTools.psm1`

## Build and Test (Repository-Accurate)

Run from repo root:

```powershell
./Tools/setup.ps1
Invoke-Build -Task Lint
Invoke-Build -Task Build, Test
```

Focused validation while iterating:

```powershell
# Unit-focused test pass
Invoke-Build -Task Test -Tag Unit

# Help/docs checks (Help.Tests.ps1 and doc-related coverage)
Invoke-Build -Task Test -Tag Documentation

# Integration tests (requires WikiURI/WikiUser/WikiPass)
Invoke-Build -Task TestIntegration -Tag Cloud
Invoke-Build -Task TestIntegration -Tag DataCenter
```

## CI/CD Alignment

- `.github/workflows/ci.yml` is the required PR/push quality gate.
- `.github/workflows/release.yml` publishes tagged releases.
- Because CI path filters ignore instruction files, always include local validation evidence in instruction-only changes.

## Coding Standards

- Follow existing function naming, parameter, and output patterns in nearby cmdlets.
- Prefer extending existing helpers/converters over duplicating logic.
- Keep comments minimal and high-value.
- Use `#ToDo:<Category>` with actionable context for technical debt markers.
- Remove dead code instead of commenting it out.

## When Working on This Project

### Do

- Preserve public cmdlet behavior unless the change explicitly requires a breaking update.
- Add regression tests for bug fixes.
- Keep changelog entries concise and user-oriented.

### Do not

- Introduce new runtime dependencies without clear need.
- Bypass `Invoke-Method` in command implementations.
- Mix unrelated refactors into a focused task branch.
