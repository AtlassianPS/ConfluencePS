---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Get-Space/
Module Name: ConfluencePS
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Get-Space/
---
# Get-Space

## SYNOPSIS

Retrieve a listing of spaces in your Confluence instance.

## SYNTAX

```powershell
Get-ConfluenceSpace -apiURi <Uri> -Credential <PSCredential> [[-SpaceKey] <String[]>] [-PageSize <Int32>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
```

## DESCRIPTION

Return all Confluence spaces, optionally filtering by Key.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluenceSpace
```

Display the info of all spaces on the server.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceSpace -SpaceKey HOTH | Format-List *
```

Return only the space with key "HOTH" (case-insensitive).

`Format-List *` displays all of the object's properties.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
Get-ConfluenceSpace -ApiURi "https://myserver.com/wiki" -Credential $cred
```

Manually specifying a server and authentication credentials, list all
spaces found on the instance. `Set-ConfluenceInfo` usually makes this
unnecessary, unless you are actively maintaining multiple instances.

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

Filter results by key.

Supports wildcard matching on partial input.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Key

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize

Maximum number of results to fetch per call.

This setting can be tuned to get better performance according to the load on the server.

> Warning: too high of a PageSize can cause a timeout on the request.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 25
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeTotalCount

> NOTE: Not yet implemented.

Causes an extra output of the total count at the beginning.

Note this is actually a uInt64, but with a custom string representation.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Skip

Controls how many objects will be skipped before starting output.

Defaults to 0.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -First

> NOTE: Not yet implemented.

Indicates how many items to return.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 18446744073709551615
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### ConfluencePS.Space

## NOTES

Piped output into other cmdlets is generally tested and supported.

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
