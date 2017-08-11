---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/Add-Label.md
locale: en-US
schema: 2.0.0
---
# Add-Label

## SYNOPSIS
Add a new global label to an existing Confluence page.

## SYNTAX

```powershell
Add-ConfluenceLabel -apiURi <Uri> -Credential <PSCredential> [[-PageID] <Int32[]>] -Label <Object> [-WhatIf] [-Confirm]
```

## DESCRIPTION
This allows the assignment of labels (one or more) to one Confluence pages (one or more).
If the label did not exist previously, it will be created. (Be aware of typos)

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
Add-ConfluenceLabel -PageID 123456 -Label alpha -Verbose
```

Description

-----------

Apply the label alpha to the wiki page with ID 123456.
-Verbose output provides extra technical details, if interested.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluencePage -SpaceKey SRV | Add-ConfluenceLabel -Label servers -WhatIf
```

Description

-----------

Simulates applying the label "servers" to all pages in the space with key SRV.
-WhatIf provides PageIDs of pages that would have been affected.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
Get-ConfluencePage -SpaceKey DEMO | Add-ConfluenceLabel -Label abc -Confirm
```

Description

-----------

Applies the label "abc" to all pages in the space with key DEMO.
-Confirm prompts Yes/No for each page that would be affected.

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
The ID of the page to which apply the label to.
Accepts multiple IDs, including via pipeline input.

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
Currently only supports labels of prefix "global".

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

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
