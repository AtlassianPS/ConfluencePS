# AI Instructions for ConfluencePS

## Quick Reference (Critical Rules)

### Commit Rules
- One functionality per commit: code + tests + docs + green tests.
- Do not commit until `Invoke-Build -Task Build, Test` passes.

### Branching and Release
- Primary branch: `master`.
- Release strategy: push a `v*` tag from `master` to trigger release workflow.
- Do not use `develop` for active work.

### Cloud vs Data Center
- Changes must continue to work for both Confluence Cloud and Data Center.
- Integration coverage is split into cloud and datacenter tracks in workflows.
- Keep API behavior differences explicit and test-covered.

### Build and Test
```powershell
./Tools/setup.ps1
Invoke-Build -Task Build, Test
Invoke-Build -Task TestIntegration
```

## Repository Layout

- Module code: `ConfluencePS/`
- Tests: `Tests/`
- Build and setup tooling: `Tools/`
- CI/CD workflows: `.github/workflows/`
- AI guidance and runbooks: `.github/ai-context/`

## CI/CD Model

- `ci.yml` runs lint, build, unit matrix, smoke integration, and an aggregate `CI Result`.
- `integration_tests.yml` runs full cloud/datacenter tracks on schedule or manual dispatch.
- `release.yml` runs on `v*` tags and publishes artifacts from successful CI.

## Dependency Automation

- Dependabot is used for dependency updates.
- Keep workflow action dependencies current.
