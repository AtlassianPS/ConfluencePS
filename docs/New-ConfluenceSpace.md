---
external help file: ConfluencePS-help.xml
online version: https://github.com/brianbunke/ConfluencePS
schema: 2.0.0
---

# New-ConfluenceSpace

## SYNOPSIS
Create a new blank space in your Confluence instance.

## SYNTAX

### byObject (Default)
```
New-ConfluenceSpace -apiURi <Uri> -Credential <PSCredential> -InputObject <Space> [-WhatIf] [-Confirm]
```

### byProperties
```
New-ConfluenceSpace -apiURi <Uri> -Credential <PSCredential> -SpaceKey <String> -Name <String>
 [-Description <String>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Create a new blank space.
Key and Name mandatory, Description recommended.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
[ConfluencePS.Space]@{key="TEST";Name="Test Space"} | New-ConfluenceSpace -ApiURi "https://myserver.com/wiki" -Credential $cred
```

Create the new blank space.
Runs Set-ConfluenceInfo first if instance info unknown.

### -------------------------- EXAMPLE 2 --------------------------
```
New-ConfluenceSpace -Key 'TEST' -Name 'Test Space' -Description 'New blank space via REST API' -Verbose
```

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
Space Object

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

[https://github.com/brianbunke/ConfluencePS](https://github.com/brianbunke/ConfluencePS)

