---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/Remove-Label.md
locale: en-US
schema: 2.0.0
---

# Remove-Label

## SYNOPSIS
Remove a label from existing Confluence content.

## SYNTAX

```powershell
Remove-Label -apiURi <Uri> -Credential <PSCredential> [-PageID] <Int32[]> [-Label <String[]>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Remove labels from Confluence content.
Does accept multiple pages piped via Get-ConfluencePage.
Specifically tested against pages, but should work against all content IDs.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
Remove-Label -ApiURi "https://myserver.com/wiki" -Credential $cred -Label seven -PageID 123456 -Verbose -Confirm
```

Description

-----------

Would remove label "seven" from the page with ID 123456.
Verbose and Confirm flags both active.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
Get-ConfluencePage -SpaceKey "ABC" | Remove-Label -Label asdf -WhatIf
```

Description

-----------

Would remove the label "asdf" from all pages in the ABC space.

### -------------------------- EXAMPLE 3 --------------------------
```powershell
(Get-ConfluenceSpace "ABC").Homepage | Remove-Label
```

Description

-----------

Removes all labels from the homepage of the ABC space.

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

[Add-Label]()
[Get-Label]()
[Set-Label]()

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

