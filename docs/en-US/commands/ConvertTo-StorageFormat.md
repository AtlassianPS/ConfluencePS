---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/ConvertTo-StorageFormat/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/ConvertTo-StorageFormat/
---
# ConvertTo-StorageFormat

## SYNOPSIS

Convert your content to Confluence's storage format.

## SYNTAX

```powershell
ConvertTo-ConfluenceStorageFormat -ApiUri <Uri> -Credential <PSCredential> [-Content] <String>
```

## DESCRIPTION

To properly create/edit pages, content should be in the proper "XHTML-based" format.
Invokes a POST call to convert from a "wiki" representation, receiving a "storage" response.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
$Body = ConvertTo-ConfluenceStorageFormat -Content 'Hello world!'
```

Stores the returned value '\<p\>Hello world!\</p\>' in $Body for use
in New-ConfluencePage/Set-ConfluencePage/etc.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-Date -Format s | ConvertTo-ConfluenceStorageFormat
```

Pipe the current date/time in sortable format, returning the converted string.

## PARAMETERS

### -ApiUri

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

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Certificate

Certificate for authentication.

```yaml
Type: X509Certificate
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Content

A string (in plain text and/or wiki markup) to be converted to storage format.

```yaml
Type: String[]
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

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

[Confluence Storage Format](https://confluence.atlassian.com/confcloud/confluence-storage-format-724765084.html)
