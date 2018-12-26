---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Get-User/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Get-User/
---
# Get-User

## SYNOPSIS

Retrieve a listing of Users in your Confluence instance.

## SYNTAX

### byUsername (Default)

```powershell
Get-ConfluenceUser -ApiURi <uri> -Credential <pscredential> -Username <string> [-IncludeTotalCount] [-Skip <uint64>] [-First <uint64>]  [<CommonParameters>]
```

### byUserKey

```powershell
Get-ConfluenceUser -ApiURi <uri> -Credential <pscredential> -UserKey <string> [-IncludeTotalCount] [-Skip <uint64>] [-First <uint64>]  [<CommonParameters>]
```

## DESCRIPTION

Return Confluence Users, filtered by Username, or Key.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluenceUser -Username 'myUser'
```

Returns a user by name.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceUser -UserKey 123456
```

Returns the user with ID 123456.

## PARAMETERS

### -ApiURi

The URi of the API interface.
Value can be set persistently with Set-ConfluenceInfo.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Confluence's credentials for authentication.
Value can be set persistently with Set-ConfluenceInfo.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserKey

Filter results by User key.

```yaml
Type: string
Parameter Sets: byUserKey
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Username

Filter results by Username (case-insensitive).

```yaml
Type: String
Parameter Sets: byUsername
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

None

## OUTPUTS

### ConfluencePS.User

## NOTES

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
