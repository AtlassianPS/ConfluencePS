---
external help file: ConfluencePS-help.xml
online version: https://github.com/brianbunke/ConfluencePS
schema: 2.0.0
---

# Remove-ConfluencePage

## SYNOPSIS
Trash an existing Confluence page.

## SYNTAX

```
Remove-ConfluencePage -apiURi <Uri> -Credential <PSCredential> [-PageID] <Int32[]> [-WhatIf] [-Confirm]
```

## DESCRIPTION
Delete existing Confluence content by page ID.
This trashes most content, but will permanently delete "un-trashable" content.
Untested against non-page content, but probably works anyway.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-ConfluencePage -Title Oscar | Remove-ConfluencePage -Confirm
```

Send Oscar to the trash.
Each matching page will ask you to confirm the deletion.

### -------------------------- EXAMPLE 2 --------------------------
```
Remove-ConfluencePage -ApiURi "https://myserver.com/wiki" -Credential $cred -PageID 12345,12346 -Verbose -WhatIf
```

Simulates the removal of two specifc pages.

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

[https://github.com/brianbunke/ConfluencePS](https://github.com/brianbunke/ConfluencePS)

