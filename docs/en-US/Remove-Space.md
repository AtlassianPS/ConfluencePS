---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/Remove-Space.md
locale: en-US
schema: 2.0.0
---

# Remove-Space

## SYNOPSIS
Remove an existing Confluence space.

## SYNTAX

```powershell
Remove-Space -apiURi <Uri> -Credential <PSCredential> [-SpaceKey] <String[]> [-Force] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Delete an existing Confluence space, including child content.
"The space is deleted in a long running task, so the space cannot be considered deleted when this resource returns."

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
Remove-Space -ApiURi "https://myserver.com/wiki" -Credential $cred -Key ABC,XYZ -Confirm
```

Description

-----------

Delete the space with key ABC and with key XYZ (note that key != name).
Confirm will prompt before deletion.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
Get-Space | Where {$_.Name -like "*old"} | Remove-Space -Verbose -WhatIf
```

Description

-----------

Get all spaces ending in 'old' and simulate the deletion of them.
Would simulate the removal of each space one by one with verbose output; -WhatIf flag active.

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

### -SpaceKey
The key (short code) of the space to delete.
Accepts multiple keys via pipeline input.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Force
Forces the deletion of the space without prompting for confirmation.

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

[Get-Space]()
[New-Space]()

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

