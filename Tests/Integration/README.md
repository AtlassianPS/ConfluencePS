# ConfluencePS Integration Tests

This directory contains integration tests that exercise ConfluencePS against a real Confluence API.

## Test Tracks

The integration suite supports two deployment targets:

| Track | Target | Auth | Selector |
|---|---|---|---|
| Cloud | A live Confluence Cloud site configured through `CONFLUENCE_CLOUD_*` and `ATLASSIAN_CLOUD_*` values | Atlassian account email + API token | Default `CI_CONFLUENCE_TYPE=Cloud` and Pester tag `Cloud` |
| DataCenter | Dockerized local Confluence Data Center from `docker-compose.yml` | Basic auth (`admin/admin`) | `CI_CONFLUENCE_TYPE=DataCenter` and Pester tag `DataCenter` |

Every integration `Describe` block should include `Integration` plus the supported deployment tags.
Use `Integration`, `Cloud`, and `DataCenter` for tests expected to run on both tracks.

## Setup

Copy `.env.example` to `.env` and configure the Cloud track values:

```powershell
Copy-Item .env.example .env
```

Required Cloud variables:

```text
CONFLUENCE_CLOUD_URL=https://your-instance.atlassian.net/wiki
ATLASSIAN_CLOUD_USER=your-email@example.com
ATLASSIAN_CLOUD_PAT=your-api-token
```

The Data Center track is self-contained through Docker:

```powershell
Invoke-Build -Task StartConfluenceDocker
Invoke-Build -Task TestIntegration -Tag DataCenter
Invoke-Build -Task StopConfluenceDocker
```

`StartConfluenceDocker` sets `CI_CONFLUENCE_TYPE=DataCenter`, `CI_CONFLUENCE_URL`, `CI_CONFLUENCE_USER`, `CI_CONFLUENCE_PASSWORD`, and `CONFLUENCE_ALLOW_UNENCRYPTED_AUTH` when they are not already set.

## Running Tests

Use the build task for normal runs:

```powershell
Invoke-Build -Task TestIntegration
Invoke-Build -Task TestIntegration -Tag Smoke
Invoke-Build -Task TestIntegration -Tag Cloud
Invoke-Build -Task TestIntegration -Tag DataCenter
Invoke-Build -Task TestIntegration -IntegrationTestPath './Tests/Integration/Spaces.Integration.Tests.ps1'
Invoke-Build -Task TestIntegration -PesterVerbosity Detailed
```

The default integration runner remains sequential. Focused files own their disposable resources, but sequential execution avoids unnecessary load on shared Confluence test tenants.

Use the runner directly when debugging file-level execution:

```powershell
./Tests/Invoke-ParallelPester.ps1
./Tests/Invoke-ParallelPester.ps1 -Path './Tests/Integration/Pages.Integration.Tests.ps1' -Tag Integration -Output Detailed
```

Discovery-only validation should avoid live setup by using a tag that no tests have:

```powershell
Invoke-Pester -Path 'Tests/Integration/*.Integration.Tests.ps1' -Tag 'NoSuchTagForDiscoveryOnly'
```

## Fixture Pattern

Use `Helpers/ConfluenceIntegrationFixture.ps1` for new independent integration files.
It imports the module under test, initializes credentials from `.env`, creates disposable spaces/pages/labels/attachments, and removes created resources in `AfterAll`.

Each focused file should contain real `Describe`/`Context`/`It` blocks and create the spaces, pages, labels, or attachments it needs. Shared helpers may create and clean disposable fixtures, but should not hide the behavior contexts for a whole suite.
