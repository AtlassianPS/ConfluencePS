---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/Set-Info.md
locale: en-US
schema: 2.0.0
---

# Set-Info

## SYNOPSIS
Specify wiki location and authorization for use in this session's REST API requests.

## SYNTAX

```powershell
Set-ConfluenceInfo [[-BaseURi] <Uri>] [[-Credential] <PSCredential>] [[-PageSize] <Int32>] [-PromptCredentials]
```

## DESCRIPTION
Set-ConfluenceInfo uses scoped variables and PSDefaultParameterValues to supply
URI/auth info to all other functions in the module (e.g. Get-ConfluenceSpace).
These session defaults can be overwritten on any single command, but using
Set-ConfluenceInfo avoids repetitively specifying -ApiUri and -Credential parameters.

Confluence's REST API supports passing basic authentication in headers.
(If you have a better suggestion for how to handle auth, please reach out on GitHub!)

Unless allowing anonymous access to your instance, credentials are needed.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
Set-ConfluenceInfo -BaseURI 'https://yournamehere.atlassian.net/wiki' -PromptCredentials
```

Description

-----------

Declare the URI of your Confluence instance; be prompted for username and password.
Note that Atlassian Cloud Confluence instances typically use the /wiki subdirectory.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
Set-ConfluenceInfo -BaseURI 'https://wiki.yourcompany.com'
```

Description

-----------

Declare the URI of your Confluence instance. You will not be prompted for credentials,
and other commands would attempt to connect anonymously with read-only permissions.

### -------------------------- EXAMPLE 3 --------------------------
```powershell
Set-ConfluenceInfo -BaseURI 'https://wiki.contoso.com' -PromptCredentials -PageSize 50
```

Description

-----------

Declare the URI of your Confluence instance; be prompted for username and password.
Set the default "page size" for all your commands in this session to 50 (see Notes).

## PARAMETERS

### -BaseURi
Address of your base Confluence install.
For Atlassian Cloud instances, include /wiki.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
The username/password combo you use to log in to Confluence.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
Default PageSize for the invocations.
More info in the Notes field of this help file.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
[https://github.com/AtlassianPS/ConfluencePS/issues/50](https://github.com/AtlassianPS/ConfluencePS/issues/50)
[https://github.com/AtlassianPS/ConfluencePS/pull/59](https://github.com/AtlassianPS/ConfluencePS/pull/59)
