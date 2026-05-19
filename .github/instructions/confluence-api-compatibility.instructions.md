---
applyTo: "**/*.ps1"
---

# PowerShell File Rules (GitHub Copilot)

This file applies to all `.ps1` files. It references shared rules.

**Canonical source**: [.github/ai-context/powershell-rules.md](../ai-context/powershell-rules.md)

## Quick Reference

1. **Cloud AND Data Center** — keep command behavior compatible unless the task explicitly scopes one deployment type.
2. **Cloud Base URI** — for Cloud tenants, `Set-Info -BaseUri` requires `/wiki` (for example `https://tenant.atlassian.net/wiki`).
3. **Page body format** — keep page payloads in `body.storage.value` with `representation = 'storage'`.
4. **Content conversion** — use `ConvertTo-StorageFormat` for wiki-style content conversion.
5. **REST calls** — route command-level HTTP interactions through `Invoke-Method`.
6. **Tests required** — during iteration run targeted `Invoke-Pester` (for example `Invoke-Pester -Path 'Tests/Functions/Invoke-Method.Tests.ps1'`); before finalizing run `Invoke-Build -Task Lint` plus full `Invoke-Build -Task Build, Test`.

For full rules, read `.github/ai-context/powershell-rules.md`.
