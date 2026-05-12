# PowerShell Rules

These rules apply to `*.ps1`, `*.psm1`, and `*.psd1` in this repository.

## Build and Test

- Run setup before development tasks: `./Tools/setup.ps1`.
- Unit tests run against the built module in `Release/`.
- Run `Invoke-Build -Task Build, Test` before commit.
- Run `Invoke-Build -Task TestIntegration` for integration changes.

## Cloud and Data Center

- Keep request/response behavior compatible across Confluence Cloud and Data Center.
- Do not ship API changes that only work on one deployment target without explicit handling.
- Use integration test tags and workflows to validate both tracks.

## CI

- Keep `CI Result` as the required branch-protection check.
- Do not bypass linting, build, unit matrix, or smoke integration checks.
