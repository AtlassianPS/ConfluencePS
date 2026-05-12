# GitHub Copilot Entry Point

GitHub Copilot reads this file as repository-level instructions.

Canonical sources:
- Project rules: [AGENTS.md](../AGENTS.md)
- PowerShell rules: [ai-context/powershell-rules.md](ai-context/powershell-rules.md)
- Release process: [ai-context/releasing.md](ai-context/releasing.md)
- File-pattern rules: [instructions/](instructions/)

## Quick Reference

1. One functionality per commit.
2. Build before tests (`Invoke-Build -Task Build, Test`).
3. Keep Cloud and Data Center support aligned.
4. Use `master` + release tags (`v*`) only.
