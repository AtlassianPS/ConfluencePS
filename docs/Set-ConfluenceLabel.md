---
external help file: ConfluencePS-help.xml
online version:
schema: 2.0.0
---

# Set-ConfluenceLabel

## SYNOPSIS
Sets the label for an existing Confluence content.

## SYNTAX

```
Set-ConfluenceLabel -apiURi <Uri> -Credential <PSCredential> [-PageID] <Int32[]> -Label <String[]> [-WhatIf]
 [-Confirm]
```

## DESCRIPTION
Sets the label for Confluence content.
All previous labels will be removed in the process.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Set-ConfluenceLabel -ApiURi "https://myserver.com/wiki" -Credential $cred -Label seven -PageID 123456 -Verbose -Confirm
```

Would remove any label previously assigned to the page with ID 123456 and would add the label "seven"
Verbose and Confirm flags both active.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-ConfluencePage -SpaceKey "ABC" | Set-ConfluenceLabel -Label "asdf","qwer" -WhatIf
```

Would remove all labels and adds "asdf" and "qwer" to all pages in the ABC space.

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
Label names to add to the content.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
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

### ConfluencePS.ContentLabelSet

## NOTES

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

