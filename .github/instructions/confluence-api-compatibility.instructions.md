---
applyTo: "ConfluencePS/Public/**/*.ps1,ConfluencePS/Private/**/*.ps1,Tests/**/*.ps1"
---

- Keep API changes compatible across Confluence Cloud and Data Center.
- Include tests for changed behavior.
- Do not bypass shared build/test tasks; validate with `Invoke-Build -Task Build, Test`.
