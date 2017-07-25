---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/Set-Info.md
locale: en-US
schema: 2.0.0
---

# Set-Info

## SYNOPSIS
Gather URI/auth info for use in this session's REST API requests.

## SYNTAX

```powershell
Set-Info [[-BaseURi] <Uri>] [[-Credential] <PSCredential>] [[-PageSize] <Int32>] [-PromptCredentials]
```

## DESCRIPTION
Unless allowing anonymous access to your instance, credentials are needed.
Confluence REST API supports passing basic authentication in headers.
(If you have a better suggestion for how to handle this, please reach out on GitHub!)

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
Set-Info -BaseURI 'https://brianbunke.atlassian.net/wiki' -PromptCredentials
```

Description

-----------

Declare your base install; be prompted for username and password.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
Set-Info -BaseURI $ConfluenceURL -Credential $MyCreds -PageSize 100
```

Description

-----------

Sets the url, credentials and default page size for the session.

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

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
