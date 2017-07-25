---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/ConvertTo-Table.md
locale: en-US
schema: 2.0.0
---

# ConvertTo-Table

## SYNOPSIS
Convert your content to Confluence's wiki markup table format.

## SYNTAX

```powershell
ConvertTo-Table [-Content] <Object> [-NoHeader]
```

## DESCRIPTION
Formats input as a table with a horizontal header row.
This wiki formatting is an intermediate step, and would still need ConvertTo-ConfluenceStorageFormat called against it.
This work is performed locally, and does not perform a REST call.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
Get-Service | Select Name,DisplayName,Status -First 10 | ConvertTo-Table
```

Description

-----------

List the first ten services on your computer, and convert to a table in Confluence markup format.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
$SvcTable = Get-Service | Select Name,Status -First 10 | ConvertTo-Table | ConvertTo-ConfluenceStorageFormat
```

Description

-----------

Following Example 1, convert the table from wiki markup format into storage format.
Store the results in variable $SvcTable for a later New-ConfluencePage/Set-ConfluencePage command.

### -------------------------- EXAMPLE 3 --------------------------
```powershell
Get-Alias | Where {$_.Name.Length -eq 1} | Select CommandType,DisplayName | ConvertTo-Table -NoHeader
```

Description

-----------

Make a table of all the one-character PowerShell aliases, and don't include the header row.

## PARAMETERS

### -Content
Object array you would like to see displayed as a table on a wiki page.

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

### -NoHeader
Ignore the property names, and just have a table of values with no header row highlighting.

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
See link below.

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

[https://github.com/thomykay/PoshConfluence](https://github.com/thomykay/PoshConfluence)

