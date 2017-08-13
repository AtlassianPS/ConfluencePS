---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/Remove-Page.md
locale: en-US
schema: 2.0.0
---

# Remove-Page

## SYNOPSIS
Trash an existing Confluence page.

## SYNTAX

```powershell
Remove-ConfluencePage -apiURi <Uri> -Credential <PSCredential> [-PageID] <Int32[]> [-WhatIf] [-Confirm]
```

## DESCRIPTION
Delete existing Confluence content by page ID.
This trashes most content, but will permanently delete "un-trashable" content.
Untested against non-page content.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
Remove-ConfluencePage -PageID 123456 -Verbose -Confirm
```

Description

-----------

Trash the wiki page with ID 123456.
Verbose and Confirm flags both active; you will be prompted before removal.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
Get-ConfluencePage -SpaceKey ABC -Title '*test*' | Remove-ConfluencePage -WhatIf
```

Description

-----------

For all wiki pages in space ABC with "test" somewhere in the name,
simulate the each page being trashed. -WhatIf prevents any removals.

### -------------------------- EXAMPLE 3 --------------------------
```powershell
Get-ConfluencePage -Label 'deleteme' | Remove-ConfluencePage
```

Description

-----------

For all wiki pages with the label "deleteme" applied, trash each page.

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
The page ID to delete.
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
