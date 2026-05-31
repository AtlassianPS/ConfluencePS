# Private Function Tests

This directory contains unit tests for private ConfluencePS helpers in `ConfluencePS/Private/*.ps1`.

## Naming

Use one file per private helper named `<HelperName>.Unit.Tests.ps1`.

Examples:

- `Test-ServerResponse.Unit.Tests.ps1` tests `ConfluencePS/Private/Test-ServerResponse.ps1`
- `ConvertTo-Page.Unit.Tests.ps1` would test `ConfluencePS/Private/ConvertTo-Page.ps1`

## Structure

Private helper tests should usually focus on:

- Pure conversion behavior and custom type names.
- Edge cases and malformed input.
- Pipeline handling when the helper supports it.
- Minimal mocking, only where the helper calls another private function or external boundary.

## Helpers

Dot-source shared test helpers with `../../Helpers/<HelperName>.ps1` from files in this directory.
Use `Initialize-TestEnvironment` in `BeforeDiscovery`, then test inside `InModuleScope ConfluencePS`.

See [`.template.ps1`](.template.ps1) for a starting point.
