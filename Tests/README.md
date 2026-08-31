# ConfluencePS Testing Guide

This guide explains the test layout used by ConfluencePS.

## Test Structure

ConfluencePS uses Pester 5.9.x for new and modernized tests.
Tests are organized to mirror the module structure:

- `Tests/Functions/Public/` contains unit tests for exported cmdlets in `ConfluencePS/Public/`.
- `Tests/Functions/Private/` contains unit tests for internal helpers and converters in `ConfluencePS/Private/`.
- `Tests/Integration/` contains live Confluence Cloud and Data Center integration tests.

## Test Templates

Use the templates in the target folder when adding new function tests:

- `Tests/Functions/Public/.template.ps1` for public cmdlets that call Confluence APIs.
- `Tests/Functions/Private/.template.ps1` for private conversion or helper functions.

Public cmdlet tests should normally cover signature, behavior, and input validation.
Private helper tests should normally cover object conversion, property mapping, and pipeline behavior.

## Running Tests

Focused validation while iterating:

```powershell
Invoke-Build -Task Lint
Invoke-Pester -Path 'Tests/Functions/Public/<Cmdlet>.Unit.Tests.ps1'
Invoke-Pester -Path 'Tests/Functions/Private/<Helper>.Unit.Tests.ps1'
Invoke-Pester -Path 'Tests/Build.Tests.ps1'
```

Full non-live validation before committing:

```powershell
Invoke-Build -Task Build, Test
```

Integration tests require Cloud credentials or a local Dockerized Data Center instance.
See `Tests/Integration/README.md` for integration setup and runner details.
