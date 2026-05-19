# ConfluencePS PowerShell Rules

Practical coding/build/test rules shared across AI entry points.

## Build and Test Commands

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
Invoke-Pester -Path 'Tests/Functions/Invoke-Method.Tests.ps1'

# After changing docs/help, run help tests directly
Invoke-Build -Task Lint
Invoke-Pester -Path 'Tests/Help.Tests.ps1'

# Optional broader pass while iterating
Invoke-Build -Task Test -Tag Unit
Invoke-Build -Task Test -Tag Documentation
Invoke-Build -Task TestIntegration -Tag Cloud
Invoke-Build -Task TestIntegration -Tag DataCenter

# Required before commit/PR finalization
Invoke-Build -Task Build, Test
```

Integration runs require `WikiURI`, `WikiUser`, and `WikiPass` environment variables.

## Source and Test Layout

- Public cmdlets: `ConfluencePS/Public/*.ps1`
- Private helpers/converters: `ConfluencePS/Private/*.ps1`
- REST wrapper entrypoint: `ConfluencePS/Public/Invoke-Method.ps1`
- Build script: `ConfluencePS.build.ps1`
- Tests: `Tests/*.Tests.ps1`, `Tests/Functions/*.Tests.ps1`
- Docs/help sources: `docs/en-US/commands/*.md`, `docs/en-US/classes/*.md`

## API and REST Conventions

- Route command-level HTTP calls through `Invoke-Method`.
- Do not add ad-hoc `Invoke-RestMethod`/`Invoke-WebRequest` calls in cmdlet implementations.
- Keep authentication, pagination, and error-handling patterns aligned with existing commands.

## Confluence Compatibility Guardrails

- Keep Cloud/Data Center behavior compatible unless the change explicitly scopes one deployment type.
- For Cloud tenants, `Set-Info -BaseUri` must include `/wiki`.
- For page writes, keep the request shape rooted at `body.storage.value` and `representation = 'storage'`.
- Use `ConvertTo-StorageFormat` when converting wiki-style markup in `New-Page` / `Set-Page`.
- Preserve page version increment behavior when updating pages.

## Coding Conventions

- Prefer self-explanatory names and small functions.
- Add comments only for non-obvious constraints or decisions.
- Use `#ToDo:<Category>` markers for explicit debt/work tracking.
- Keep parameter behavior and output types backward compatible unless the task explicitly changes them.

## Documentation and CI Notes

- User-facing command docs belong in `docs/en-US/commands/*.md`.
- Include changelog updates for user-visible behavior changes.
- `.github/workflows/ci.yml` path filters can skip instruction-only changes.
- Run local validation before opening/updating PRs when changing instruction files.
