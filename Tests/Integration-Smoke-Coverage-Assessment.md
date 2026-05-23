# Integration and smoke coverage assessment

Scope: `confluence-integration-smoke`, implemented and re-evaluated on branch `confluence-integration-smoke-coverage-eval`.

## What currently runs

| Pipeline | Command | Intent |
| --- | --- | --- |
| `.github/workflows/ci.yml` (`smoke_tests`) | `Invoke-Build -Task TestIntegration -Tag "Smoke"` | Fast PR/master gate using Cloud credentials |
| `.github/workflows/integration_tests.yml` (Cloud) | `Invoke-Build -Task TestIntegration -Tag 'Cloud'` | Full Cloud integration pass |
| `.github/workflows/integration_tests.yml` (DataCenter) | `Invoke-Build -Task TestIntegration -Tag 'DataCenter'` | Full Data Center integration pass |

## Current coverage summary

- Integration suite breadth: `Tests/Integration.Tests.ps1` contains **105** assertions across **21** cmdlet-focused contexts.
- Smoke suite breadth: `Tests/Configuration.Integration.Tests.ps1` contains **11** assertions under one `Smoke`-tagged describe block.
- Public cmdlets in module: **21**.
- Public cmdlets without dedicated integration context coverage: **0**.

## Implemented in this branch

1. Added integration coverage for `Invoke-ConfluenceMethod`:
   - direct API call with `GetParameters`
   - typed output conversion to `ConfluencePS.Space`
2. Added integration coverage for `ConvertTo-ConfluenceTable`:
   - table markup assertions
   - end-to-end compatibility check by creating and reading a real page using converted table storage markup
3. Added smoke write-path coverage:
   - page create/update checks
   - label add/remove lifecycle
   - attachment add/remove lifecycle
   - cleanup logic for disposable smoke page

## Remaining gap

- `Set-ConfluencePage` integration context is skipped for localhost-based runs, leaving Data Center coverage weaker for that path in current automation.

## Prioritized next step

1. Add a Data Center-safe variant for the `Set-ConfluencePage` integration path (or an equivalent Data Center write-path assertion) that can run against localhost Docker reliably.
