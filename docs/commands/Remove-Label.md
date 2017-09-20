---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/commands/Remove-Label.md
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Remove-Label/
---

# Remove-Label

## SYNOPSIS
Remove a label from existing Confluence content.

## SYNTAX

```powershell
Remove-ConfluenceLabel -apiURi <Uri> -Credential <PSCredential> [-PageID] <Int32[]> [-Label <String[]>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Remove labels from Confluence content.
Does accept multiple pages piped via Get-ConfluencePage.
Untested against non-page content.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
Remove-ConfluenceLabel -PageID 123456 -Label 'seven' -Verbose -Confirm
```

Description

-----------

Remove label "seven" from the wiki page with ID 123456.
Verbose and Confirm flags both active; you will be prompted before deletion.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
Get-ConfluencePage -SpaceKey 'ABC' -Label 'asdf' | Remove-ConfluenceLabel -Label 'asdf' -WhatIf
```

Description

-----------

For all wiki pages in the ABC space, the label "asdf" would be removed.
WhatIf parameter prevents any modifications.

### -------------------------- EXAMPLE 3 --------------------------
```powershell
Get-ConfluenceChildPage -PageID 123456 | Remove-ConfluenceLabel
```

Description

-----------

For all wiki pages immediately below page 123456, remove all labels from each page.

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

### -PageID
The page ID to remove the label from.
Accepts multiple IDs via pipeline input.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases: ID

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Label
A single content label to remove from one or more pages.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### System.Boolean

## NOTES

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
