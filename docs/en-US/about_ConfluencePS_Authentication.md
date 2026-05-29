---
locale: en-US
layout: documentation
online version: https://atlassianps.org/docs/ConfluencePS/about/authentication.html
Module Name: ConfluencePS
permalink: /docs/ConfluencePS/about/authentication.html
---
# Authentication

## about_ConfluencePS_Authentication

# SHORT DESCRIPTION

Configure authentication for ConfluencePS commands against Confluence Cloud, Data Center, or Server.

# LONG DESCRIPTION

ConfluencePS sends requests to Confluence's REST API.
Most commands accept `-ApiUri`, `-Credential`, `-PersonalAccessToken`, or `-Certificate` directly.
For repeated commands, use `Set-ConfluenceInfo` once per PowerShell session to set default connection and authentication parameters.

The authentication method depends on where Confluence is hosted:

- Confluence Cloud: Atlassian account email address plus an Atlassian API token through `-Credential`.
- Confluence Data Center or Server: username/password through `-Credential`, or a personal access token through `-PersonalAccessToken` when your instance supports it.
- Certificate-based authentication: use `-Certificate` on commands that expose it when your environment requires client certificates.

## Confluence Cloud

Confluence Cloud uses Atlassian account API tokens for scripts and automation.
Create an API token at https://id.atlassian.com/manage-profile/security/api-tokens.
Use your Atlassian account email address as the credential username and the API token as the credential password.

Cloud site URLs must include `/wiki` when passed to `Set-ConfluenceInfo`.
For example, use `https://yournamehere.atlassian.net/wiki`, not only `https://yournamehere.atlassian.net`.

```powershell
$credential = Get-Credential -UserName 'me@example.com'
Set-ConfluenceInfo -BaseURI 'https://yournamehere.atlassian.net/wiki' -Credential $credential
```

When prompted, paste the Atlassian API token as the password.
Do not use your Atlassian account password for Cloud authentication.

For non-interactive scripts, create the `PSCredential` from a secret source such as an environment variable or a vault.

```powershell
$token = ConvertTo-SecureString -String $env:ATLASSIAN_CLOUD_API_TOKEN -AsPlainText -Force
$credential = [PSCredential]::new($env:ATLASSIAN_CLOUD_EMAIL, $token)
Set-ConfluenceInfo -BaseURI $env:CONFLUENCE_CLOUD_URL -Credential $credential
```

Store the full Cloud URL, including `/wiki`, in `CONFLUENCE_CLOUD_URL`.

## Confluence Data Center and Server

For Confluence Data Center or Server, use the authentication method configured for your instance.
Username/password authentication uses the `-Credential` parameter.

```powershell
$credential = Get-Credential
Set-ConfluenceInfo -BaseURI 'https://wiki.yourcompany.com' -Credential $credential
```

If your Confluence Data Center or Server instance supports personal access tokens, pass the token to `-PersonalAccessToken`.
ConfluencePS sends this value as bearer-token authentication.

```powershell
$pat = Read-Host -Prompt 'Confluence personal access token'
Set-ConfluenceInfo -BaseURI 'https://wiki.yourcompany.com' -PersonalAccessToken $pat
```

Atlassian API tokens for Cloud and personal access tokens for Data Center or Server are different credential types.
For Cloud, use `-Credential` with your email address and API token.
For Data Center or Server PATs, use `-PersonalAccessToken`.

## Anonymous Access

If your Confluence instance allows anonymous access, you can set only the base URI.
Commands then run without credentials and can access only content available to anonymous users.

```powershell
Set-ConfluenceInfo -BaseURI 'https://wiki.yourcompany.com'
```

## Per-Command Overrides

`Set-ConfluenceInfo` configures defaults for the current PowerShell session.
You can still pass `-ApiUri`, `-Credential`, `-PersonalAccessToken`, or `-Certificate` to an individual command to override the defaults.

```powershell
Get-ConfluenceSpace -ApiUri 'https://otherwiki.example.com/rest/api' -Credential $otherCredential
```

## Security Notes

Use HTTPS for authenticated connections.
Avoid hardcoding passwords, API tokens, or personal access tokens in scripts.
Prefer environment variables, secret-management modules, or CI/CD secret storage.

# SEE ALSO

[Set-ConfluenceInfo](/docs/ConfluencePS/commands/Set-Info/)

[Get-ConfluenceServerInformation](/docs/ConfluencePS/commands/Get-ServerInformation/)

[Manage API tokens for your Atlassian account](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/)

[Using personal access tokens](https://confluence.atlassian.com/enterprise/using-personal-access-tokens-1026032365.html)
