---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/New-Space/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/New-Space/
---
# New-Space

## SYNOPSIS

Create a new blank space on your Confluence instance.

## SYNTAX

### byObject (Default)

```powershell
New-ConfluenceSpace -ApiUri <Uri> -Credential <PSCredential> -InputObject <Space> [-WhatIf] [-Confirm]
```

### byProperties

```powershell
New-ConfluenceSpace -ApiUri <Uri> -Credential <PSCredential> -SpaceKey <String> -Name <String>
 [-Description <String>] [-WhatIf] [-Confirm]
```

## DESCRIPTION

Create a new blank space.

A value for `Key` and `Name` is mandatory. Not so for `Description`, although recommended.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
New-ConfluenceSpace -Key 'HOTH' -Name 'Planet Hoth' -Description "It's really cold" -Verbose
```

Create a new blank space with an optional description and verbose output.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
$spaceObject = [ConfluencePS.Space]@{
    Key         = "HOTH"
    Name        = "Planet Hoth"
    Description = "It's really cold"
}

# example 1
New-ConfluenceSpace -InputObject $spaceObject
# example 2
$spaceObject | New-ConfluenceSpace
```

Two different methods of creating a new space from an object `ConfluencePS.Space`.

Both examples should return identical results.

## PARAMETERS

### -ApiUri

The URi of the API interface.
Value can be set persistently with `Set-ConfluenceInfo -BaseURi`.

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
Value can be set persistently with `Set-ConfluenceInfo -Credential`.

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

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
