---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/ConvertTo-Table/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/ConvertTo-Table/
---
# ConvertTo-Table

## SYNOPSIS

Convert your content to Confluence's wiki markup table format.

## SYNTAX

```powershell
ConvertTo-ConfluenceTable [-Content] <Object> [-NoHeader]
```

## DESCRIPTION

Formats input as a table with a horizontal header row.
This wiki formatting is an intermediate step, and would still need
ConvertTo-ConfluenceStorageFormat called against it.

This work is performed locally, and does not perform a REST call.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-Service | Select-Object Name,DisplayName,Status -First 10 | ConvertTo-ConfluenceTable
```

List the first ten services on your computer, and convert to a table in Confluence markup format.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
$SvcTable = Get-Service | Select-Object Name,Status -First 10 |
    ConvertTo-ConfluenceTable | ConvertTo-ConfluenceStorageFormat
```

Following Example 1, convert the table from wiki markup format into storage format.
Store the results in $SvcTable for a later New-ConfluencePage/etc. command.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
Get-Alias | Where-Object {$_.Name.Length -eq 1} | Select-Object CommandType,DisplayName |
    ConvertTo-ConfluenceTable -NoHeader
```

Make a table of all one-character PowerShell aliases, and don't include the header row.

### -------------------------- EXAMPLE 4 --------------------------

```powershell
[PSCustomObject]@{Name = 'Max'; Age = 123} | ConvertTo-ConfluenceTable -Vertical
```

Output a vertical table instead. Property names will be a left header column
with bold highlighting. Property values will be in a normal right column.
Multiple objects will output as multiple tables, one on top of the next.

### -------------------------- EXAMPLE 5 --------------------------

```powershell
Get-Alias | Where-Object {$_.Name.Length -eq 1} | Select-Object Name,Definition |
    ConvertTo-ConfluenceTable -Vertical -NoHeader
```

Output one string containing four vertical tables (one for each object returned).
Property names are still displayed, but -NoHeader suppresses the bold highlighting.

## PARAMETERS

### -Content

The object array you would like to see displayed as a table on a wiki page.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Vertical

Create a vertical, two-column table.

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

### -NoHeader

Ignore the property names, keeping a table of values with no header row highlighting.

In a vertical table, the property names remain, but the bold highlighting is removed.

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

### System.String

## NOTES

Basically stolen verbatim from thomykay's PoshConfluence SOAP API module.
See links section.

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

[thomykay PoshConfluence](https://github.com/thomykay/PoshConfluence)
