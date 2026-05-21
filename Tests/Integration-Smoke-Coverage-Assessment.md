# Integration and smoke coverage assessment

Scope: `confluence-integration-smoke` baseline, evaluated from branch `confluence-integration-smoke-coverage-eval`.

## What currently runs

| Pipeline | Command | Intent |
| --- | --- | --- |
| `.github/workflows/ci.yml` (`smoke_tests`) | `Invoke-Build -Task TestIntegration -Tag "Smoke"` | Fast PR/master gate using Cloud credentials |
| `.github/workflows/integration_tests.yml` (Cloud) | `Invoke-Build -Task TestIntegration -Tag 'Cloud'` | Full Cloud integration pass |
| `.github/workflows/integration_tests.yml` (DataCenter) | `Invoke-Build -Task TestIntegration -Tag 'DataCenter'` | Full Data Center integration pass |

## Current coverage summary

- Integration suite breadth: `Tests/Integration.Tests.ps1` contains **101** assertions across **19** cmdlet-focused contexts.
- Smoke suite breadth: `Tests/Configuration.Integration.Tests.ps1` contains **5** assertions under one `Smoke`-tagged describe block.
- Public cmdlets in module: **21**.
- Public cmdlets without dedicated integration context coverage: **2** (`ConvertTo-Table`, `Invoke-Method`).

## Gaps: what should be tested and is not yet

### Missing integration coverage

1. `Invoke-Method` has unit tests, but no integration assertions validating real API execution paths (status handling, pagination/expand behavior, and response shaping against live Confluence).
2. `ConvertTo-Table` has unit tests, but no integration assertions proving output remains compatible when embedded in real page create/update flows.

### Missing smoke coverage

Smoke currently validates configuration and read-path connectivity only. It does **not** yet cover critical write-path sanity checks that catch permission/scope regressions early.

Recommended smoke additions (small, fast, low-risk):

1. Minimal page write/read/delete cycle (`New-ConfluencePage`, `Get-ConfluencePage`, `Remove-ConfluencePage`) in a disposable test location.
2. Label lifecycle sanity (`Add-ConfluenceLabel`, `Get-ConfluenceLabel`, `Remove-ConfluenceLabel`) on that page.
3. Attachment lifecycle sanity (`Add-ConfluenceAttachment`, `Get-ConfluenceAttachment`, `Remove-ConfluenceAttachment`) using a tiny local file.
4. `Set-ConfluencePage` update sanity (single body update and version increment check).

### Track-specific blind spot

- `Set-ConfluencePage` integration context is skipped for localhost-based runs, leaving Data Center coverage weaker for that path in current automation.

## Prioritized next steps

1. Add integration contexts for `Invoke-Method` and `ConvertTo-Table`.
2. Add a dedicated smoke write-path context that performs one lightweight create/update/delete round trip.
3. Add a Data Center-safe variant for the `Set-ConfluencePage` integration path (or an equivalent Data Center write-path assertion).

