---
external help file: ConfluencePS-help.xml
online version: https://github.com/brianbunke/ConfluencePS
schema: 2.0.0
---

# Add-ConfluenceLabel

## SYNOPSIS
Add a new global label to an existing Confluence page.

## SYNTAX

```
Add-ConfluenceLabel -apiURi <Uri> -Credential <PSCredential> [[-PageID] <Int32[]>] -Label <Object> [-WhatIf]
 [-Confirm]
```

## DESCRIPTION
Add one or more labels to one or more Confluence pages.
Label can be brand new.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Add-Label -ApiURi "https://myserver.com/wiki" -Credential $cred -Label alpha,bravo,charlie -PageID 123456 -Verbose
```

Apply the labels alpha, bravo, and charlie to the page with ID 123456.
Verbose output.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-Page -SpaceKey SRV | Add-Label -Label servers -WhatIf
```

Would apply the label "servers" to all pages in the space with key SRV.
-WhatIf flag supported.

## PARAMETERS

### -apiURi
The URi of the API interface.
Value can be set persistently with Set-Info.

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
Value can be set persistently with Set-Info.

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
The page ID to apply the label to.
Accepts multiple IDs via pipeline input.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases: ID

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Label
One or more labels to be added.
Currently supports labels of prefix "global."

```yaml
Type: Object
Parameter Sets: (All)
Aliases: Labels

Required: True
Position: Named
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

### ConfluencePS.ContentLabelSet

## NOTES

## RELATED LINKS

[https://github.com/brianbunke/ConfluencePS](https://github.com/brianbunke/ConfluencePS)

