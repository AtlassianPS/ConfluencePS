---
external help file: ConfluencePS-help.xml
online version:
schema: 2.0.0
---

# Get-ConfluenceSpace

## SYNOPSIS
Retrieve a listing of spaces in your Confluence instance.

## SYNTAX

```
Get-ConfluenceSpace -apiURi <Uri> -Credential <PSCredential> [[-SpaceKey] <String[]>] [-PageSize <Int32>]
 [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
```

## DESCRIPTION
Fetch all Confluence spaces, optionally filtering by Name/Key/ID.
Input for all parameters is not case sensitive.
Piped output into other cmdlets is generally tested and supported.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-ConfluenceSpace -ApiURi "https://myserver.com/wiki" -Credential $cred
```

Display the info of all spaces on the server.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-ConfluenceSpace -SpaceKey NASA
```

Display the info of the space with key "NASA".

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
Maximimum number of results to fetch per call.
This setting can be tuned to get better performance according to the load on the server.
Warning: too high of a PageSize can cause a timeout on the request.

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
Controls how many things will be skipped before starting output.
Defaults to 0.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -First
Currently not supported.
Indicates how many items to return.
Defaults to 100.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

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

