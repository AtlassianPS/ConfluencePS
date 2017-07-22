---
external help file: ConfluencePS-help.xml
online version:
schema: 2.0.0
---

# Get-Label

## SYNOPSIS
Returns the list of labels.

## SYNTAX

```
Get-Label -apiURi <Uri> -Credential <PSCredential> [-PageID] <Int32[]> [-PageSize <Int32>]
 [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
```

## DESCRIPTION
View all labels applied to a content.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-Label -PageID 123456 -PageSize 500 -ApiURi "https://myserver.com/wiki" -Credential $cred
```

Lists the labels applied to page 123456.
This also increases the size of the result's page from 25 to 500.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-ConfluencePage -SpaceKey NASA | Get-Label -Verbose
```

Get all pages that exist in NASA space (literally?).
Search all of those pages (piped to -PageID) for all of their active labels.
Verbose flag would be good here to keep track of the request.

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
List the PageID number to check for labels.
Accepts piped input.

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

### ConfluencePS.ContentLabelSet

## NOTES

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

