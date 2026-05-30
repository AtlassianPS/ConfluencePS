# AI Instructions for ConfluencePS

> **Single source of truth for AI coding assistants.**
> Tool-specific entry-point files in this repository reference this file.

## Quick Reference (Critical Rules)

1. **One functionality per commit**: implementation, tests, docs, and changelog move together.
2. **Keep REST calls behind ConfluencePS abstractions**: command implementations should route HTTP work through `Invoke-Method` (and its wrapper stack), not ad-hoc web calls.
3. **Preserve compatibility**: keep existing Cloud/Data Center behavior and public cmdlet parameter/output contracts unless the task explicitly changes them.
4. **Instruction-only changes still require local validation**: `.github/workflows/ci.yml` path filters can skip AI-instruction-only updates.
5. **Use the right test loop**: use targeted `Invoke-Pester` during iteration, then run full `Invoke-Build -Task Build, Test` before completion.
6. **Keep tests and docs aligned with behavior**: update focused tests in `Tests/`, docs in `docs/en-US/`, and `CHANGELOG.md` for user-visible changes.

## AI Tool Compatibility

| Tool | Entry point | Canonical references |
|------|-------------|----------------------|
| GitHub Copilot | `.github/copilot-instructions.md` | `AGENTS.md`, `.github/ai-context/powershell-rules.md` |
| GitHub Copilot (file rules) | `.github/instructions/confluence-api-compatibility.instructions.md` | `.github/ai-context/powershell-rules.md` |
| Cursor | `.cursor/rules/confluenceps.mdc` | `AGENTS.md`, `.github/ai-context/powershell-rules.md` |
| Claude Code | `CLAUDE.md` | `AGENTS.md`, `.github/ai-context/powershell-rules.md` |
| Gemini/Antigravity | `GEMINI.md` | `AGENTS.md`, `.github/ai-context/powershell-rules.md` |

## Repository Map

- Module source: `ConfluencePS/Public/*.ps1`, `ConfluencePS/Private/*.ps1`
- REST wrapper entrypoint: `ConfluencePS/Public/Invoke-Method.ps1`
- Build entrypoint: `ConfluencePS.build.ps1`
- Test suites: `Tests/*.Tests.ps1`, `Tests/Functions/Public/*.Unit.Tests.ps1`, `Tests/Functions/Private/*.Unit.Tests.ps1`
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
# After changing one function/helper, run the matching test file directly
Invoke-Build -Task Lint
Invoke-Pester -Path 'Tests/Functions/Public/Invoke-Method.Unit.Tests.ps1'

# After changing docs/help, run help tests directly
Invoke-Build -Task Lint
Invoke-Pester -Path 'Tests/Help.Tests.ps1'
```

Broader validation:

```powershell
# Optional broader pass while iterating
Invoke-Build -Task Test -Tag Unit
Invoke-Build -Task Test -Tag Documentation

# Integration tests (copy .env.example to .env first)
Invoke-Build -Task TestIntegration -Tag Cloud
Invoke-Build -Task TestIntegration -Tag DataCenter
Invoke-Build -Task StartConfluenceDocker
Invoke-Build -Task StopConfluenceDocker

# Required before commit/PR finalization
Invoke-Build -Task Build, Test
```

### Testing During Development

> **Rule**: Run the smallest relevant test loop after each change, then run the full suite before finalizing.

| What changed | Test command |
|---|---|
| Any code file (`.ps1`, `.psm1`) | `Invoke-Build -Task Lint` |
| Function/helper behavior | `Invoke-Pester -Path 'Tests/Functions/Public/<RelatedFile>.Unit.Tests.ps1'` or `Tests/Functions/Private/<RelatedFile>.Unit.Tests.ps1` |
| Test file under `Tests/` | `Invoke-Pester -Path '<path-to-that-test-file>'` |
| Documentation/help under `docs/**` | `Invoke-Pester -Path 'Tests/Help.Tests.ps1'` |
| Build/test plumbing | `Invoke-Pester -Path 'Tests/Build.Tests.ps1'` |

Examples:

```powershell
# After editing ConfluencePS/Public/Invoke-Method.ps1
Invoke-Build -Task Lint
Invoke-Pester -Path 'Tests/Functions/Public/Invoke-Method.Unit.Tests.ps1'

# After editing docs/en-US/commands/Set-Info.md
Invoke-Build -Task Lint
Invoke-Pester -Path 'Tests/Help.Tests.ps1'
```

Before committing: run full `Invoke-Build -Task Build, Test`.  
Before merging: ensure the Windows PowerShell 5.1 CI test job is green.

## Confluence Compatibility Guardrails

- For Cloud tenants, `Set-Info -BaseUri` must include `/wiki` (for example `https://tenant.atlassian.net/wiki`).
- Keep page bodies in `body.storage.value` with `representation = 'storage'`.
- Use `ConvertTo-StorageFormat` when converting wiki-style input to storage format in page create/update flows.
- Preserve page update version increments in `Set-Page` (`version.number` advances from current page version).

### Supported API References (Cloud + Data Center)

- Cloud track: Confluence Cloud REST API documentation (`/wiki/rest/api` surface): https://developer.atlassian.com/cloud/confluence/rest/
- Data Center/Server track: Confluence Server REST API documentation (`/rest/api` surface): https://docs.atlassian.com/ConfluenceServer/rest/latest/
- When researching or implementing API changes, verify both tracks and avoid Cloud-only endpoint assumptions unless the change explicitly scopes Cloud.

## CI/CD Alignment

- `.github/workflows/ci.yml` is the required PR/push quality gate.
- `.github/workflows/integration_tests.yml` runs full integration suites on a nightly schedule (Cloud + Dockerized Data Center) and manual dispatch.
- `.github/workflows/release.yml` publishes tagged releases.
- For instruction-only changes, run local validation before opening/updating a PR.

## Instruction Maintenance

- `AGENTS.md` is canonical for project-wide agent behavior.
- Keep the quick-reference section in sync across `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, and `.cursor/rules/confluenceps.mdc`.
- Keep `.github/instructions/confluence-api-compatibility.instructions.md` aligned with `.github/ai-context/powershell-rules.md`.

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
