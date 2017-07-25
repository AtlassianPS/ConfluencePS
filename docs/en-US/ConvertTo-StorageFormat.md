---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/ConvertTo-StorageFormat.md
locale: en-US
schema: 2.0.0
---

# ConvertTo-StorageFormat

## SYNOPSIS
Convert your content to Confluence's storage format.

## SYNTAX

```powershell
ConvertTo-StorageFormat -apiURi <Uri> -Credential <PSCredential> [-Content] <String>
```

## DESCRIPTION
To properly create/edit pages, content should be in the proper "XHTML-based" format.
Invokes a POST call to convert from a "wiki" representation, receiving a "storage" response.
https://confluence.atlassian.com/doc/confluence-storage-format-790796544.html

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
$Body = ConvertTo-StorageFormat -Content 'Hello world!'
```

Description

-----------

Stores the returned value '\<p\>Hello world!\</p\>' in $Body for use in New-ConfluencePage/Set-ConfluencePage/etc.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
Get-Date -Format s | ConvertTo-StorageFormat -ApiURi "https://myserver.com/wiki" -Credential $cred
```

Description

-----------

Returns the current date/time in sortable format, and converts via pipeline input.

### -------------------------- EXAMPLE 3 --------------------------
```powershell
New-ConfluencePage -Title 'Loner Page' -SpaceKey TEST -Body $Body -Convert -Verbose
```

Description

-----------

Creates a new page at the root of the specified space (no parent page).
Need to invoke ConvertTo-StorageFormat on $Body to prep it for page creation.
(including verbose output)

## PARAMETERS

### -apiURi
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

### -Content
A string (in plain text and/or wiki markup) to be converted to storage format.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### System.String

## NOTES

## RELATED LINKS

[New-ConfluencePage]()

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

