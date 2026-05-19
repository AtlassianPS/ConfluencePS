# Claude Code Entry Point

Read this file first, then follow canonical sources:

- Project rules: [AGENTS.md](AGENTS.md)
- PowerShell rules: [.github/ai-context/powershell-rules.md](.github/ai-context/powershell-rules.md)

## Quick Reference

1. One functionality per commit (code + tests + docs + changelog).
2. Route command-level HTTP interactions through `Invoke-Method`.
3. Preserve Cloud/Data Center compatibility and existing cmdlet contracts (`/wiki` for Cloud `Set-Info -BaseUri`).
4. Instruction-only changes may be skipped by CI path filters; run local validation anyway.
5. During iteration, run targeted tests directly with `Invoke-Pester -Path '<affected test file>'`.
6. Before finalizing, run `Invoke-Build -Task Lint` and full `Invoke-Build -Task Build, Test`.
7. For behavior changes, update targeted tests in `Tests/` and docs in `docs/en-US/`.

## File Locations

- Public functions: `ConfluencePS/Public/`
- Private functions: `ConfluencePS/Private/`
- REST wrapper: `ConfluencePS/Public/Invoke-Method.ps1`
- Tests: `Tests/*.Tests.ps1`, `Tests/Functions/*.Tests.ps1`
- Docs: `docs/en-US/commands/`, `docs/en-US/classes/`
