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
Invoke-Build -Task Test -Tag Unit
Invoke-Build -Task Test -Tag Documentation
Invoke-Build -Task TestIntegration -Tag Cloud
Invoke-Build -Task TestIntegration -Tag DataCenter
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

## Coding Conventions

- Prefer self-explanatory names and small functions.
- Add comments only for non-obvious constraints or decisions.
- Use `#ToDo:<Category>` markers for explicit debt/work tracking.
- Keep parameter behavior and output types backward compatible unless the task explicitly changes them.

## Documentation and CI Notes

- User-facing command docs belong in `docs/en-US/commands/*.md`.
- Include changelog updates for user-visible behavior changes.
- `.github/workflows/ci.yml` ignores many instruction files via `paths-ignore`; instruction updates still need local build/test validation.
