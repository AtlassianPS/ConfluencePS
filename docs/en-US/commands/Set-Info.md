---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Set-Info/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Set-Info/
---
# Set-Info

## SYNOPSIS

Specify wiki location and authorization for use in this session's REST API requests.

## SYNTAX

```powershell
Set-ConfluenceInfo [-BaseURi <Uri>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 [-PageSize <UInt32>] [-PromptCredentials]
```

## DESCRIPTION

Set-ConfluenceInfo uses scoped variables and PSDefaultParameterValues to supply
URI/auth info to all other functions in the module (e.g. Get-ConfluenceSpace).
These session defaults can be overwritten on any single command, but using
Set-ConfluenceInfo avoids repetitively specifying -ApiUri and -Credential parameters.

Confluence's REST API supports passing basic authentication in headers. For
Confluence Cloud, use your Atlassian account email address as the username and
an Atlassian API token as the password. Do not use your Atlassian account
password for Cloud authentication.

Unless allowing anonymous access to your instance, credentials are needed.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
$Cred = Get-Credential -UserName 'me@example.com'
Set-ConfluenceInfo -BaseURI 'https://yournamehere.atlassian.net/wiki' -Credential $Cred
```

Declare the URI of your Confluence Cloud instance and authenticate with an
Atlassian account email address and API token. When prompted, enter the API
token as the password. Cloud instances use the /wiki subdirectory.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Set-ConfluenceInfo -BaseURI 'https://wiki.yourcompany.com'
```

Declare the URI of your Confluence instance. You will not be prompted for credentials,
and other commands would attempt to connect anonymously with read-only permissions.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
Set-ConfluenceInfo -BaseURI 'https://wiki.contoso.com' -PromptCredentials -PageSize 50
```

Declare the URI of your Confluence instance; be prompted for username and password.
Set the default "page size" for all your commands in this session to 50 (see Notes).

### -------------------------- EXAMPLE 4 --------------------------

```powershell
$Cred = Get-Credential
Set-ConfluenceInfo -BaseURI 'https://wiki.yourcompany.com' -Credential $Cred
```

Declare the URI of your Confluence instance and the credentials. For Confluence
Cloud, the credential username is your Atlassian account email address and the
password is an Atlassian API token.

### -------------------------- EXAMPLE 5 --------------------------

```powershell
$Pat = 'NDU1MTk4NzUyNTg3Om1I/FR61TJBC8hhJKXpOgJBC0Jk'
Set-ConfluenceInfo -BaseURI 'https://wiki.yourcompany.com' -PersonalAccessToken $Pat
```

Declare the URI of your Confluence instance and the Personal Access Token. 
See: <https://confluence.atlassian.com/enterprise/using-personal-access-tokens-1026032365.html>

## PARAMETERS

### -BaseURi

Address of your base Confluence install.
For Atlassian Cloud instances, include /wiki.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

The username/password combo used to authenticate to Confluence. For Confluence
Cloud, use your Atlassian account email address as the username and an Atlassian
API token as the password.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessToken

The PersonalAccessToken you created in your Confluence User Settings. This is
for Confluence Data Center and Server personal access tokens. For Confluence
Cloud, use the -Credential parameter with your Atlassian account email address
and an Atlassian API token.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize

Default PageSize for the invocations.
More info in the Notes field of this help file.

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PromptCredentials

Prompt the user for credentials

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

The default page size for all commands is 25.
Using the -PageSize parameter changes the default for all commands in your current session.

Tweaking PageSize can help improve pipeline performance when returning many objects.
See related links for implementation discussion and details.

(If you don't know exactly what this means, feel free to ignore it.)

For Confluence Cloud authentication, create an API token at
https://id.atlassian.com/manage-profile/security/api-tokens. Use your Atlassian
account email address as the credential username and paste the API token as the
credential password. The BaseURI must include /wiki, for example
https://yournamehere.atlassian.net/wiki.

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

[ConfluencePS PR#59: Add proper Paging to Get functions](https://github.com/AtlassianPS/ConfluencePS/pull/59)

[Manage API tokens for your Atlassian account](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/)
