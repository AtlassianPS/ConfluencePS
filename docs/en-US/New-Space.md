---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/New-Space.md
locale: en-US
schema: 2.0.0
---

# New-Space

## SYNOPSIS
Create a new blank space on your Confluence instance.

## SYNTAX

### byObject (Default)
```powershell
New-Space -apiURi <Uri> -Credential <PSCredential> -InputObject <Space> [-WhatIf] [-Confirm]
```

### byProperties
```powershell
New-Space -apiURi <Uri> -Credential <PSCredential> -SpaceKey <String> -Name <String>
 [-Description <String>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Create a new blank space.
Key and Name mandatory, Description recommended.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
[ConfluencePS.Space]@{key="TEST";Name="Test Space"} | New-Space -ApiURi "https://myserver.com/wiki" -Credential $cred
```

Description

-----------

Create the new blank space.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
New-Space -Key 'TEST' -Name 'Test Space' -Description 'New blank space via REST API' -Verbose
```

Description

-----------

Create the new blank space with the optional description and verbose output.

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

### -InputObject
Space Object from which to create the new space.

```yaml
Type: Space
Parameter Sets: byObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SpaceKey
Specify the short key to be used in the space URI.

```yaml
Type: String
Parameter Sets: byProperties
Aliases: Key

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Specify the space's name.

```yaml
Type: String
Parameter Sets: byProperties
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
A short description of the new space.

```yaml
Type: String
Parameter Sets: byProperties
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

### ConfluencePS.Space

## NOTES

## RELATED LINKS

[Get-Space]()
[Remove-Space]()

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

