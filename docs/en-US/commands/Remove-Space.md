---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Remove-Space/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Remove-Space/
---
# Remove-Space

## SYNOPSIS

Remove an existing Confluence space.

## SYNTAX

```powershell
Remove-ConfluenceSpace -ApiUri <Uri> -Credential <PSCredential> [-SpaceKey] <String[]> [-Force] [-WhatIf] [-Confirm]
```

## DESCRIPTION

Delete an existing Confluence space, including child content.

> Note: The space is deleted in a long running task, so the space cannot be considered deleted when this resource returns.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Remove-ConfluenceSpace -SpaceKey ABC -WhatIf
```

Simulates the deletion of wiki space ABC and all child content.
-WhatIf parameter prevents removal of content.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Remove-ConfluenceSpace -SpaceKey XYZ -Force
```

Delete wiki space XYZ and all child content below it.

By default, you will be prompted to confirm removal. ("Are you sure? Y/N")
-Force suppresses all confirmation prompts and carries out the deletion.

## PARAMETERS

### -ApiUri

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

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessToken

Confluence's Personal Access Token for authentication.
Value can be set persistently with Set-ConfluenceInfo.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Certificate

Certificate for authentication.

```yaml
Type: X509Certificate
Parameter Sets: (All)
Aliases:

Required: False
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

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
