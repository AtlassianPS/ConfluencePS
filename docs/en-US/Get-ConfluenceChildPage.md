---
external help file: ConfluencePS-help.xml
online version:
schema: 2.0.0
---

# Get-ConfluenceChildPage

## SYNOPSIS
For a given wiki page, list all child wiki pages.

## SYNTAX

```
Get-ConfluenceChildPage -apiURi <Uri> -Credential <PSCredential> [-PageID] <Int32> [-Recurse]
 [-PageSize <Int32>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
```

## DESCRIPTION
Pipeline input of ParentID is accepted.

This API method only returns the immediate children (results are not recursive).

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-ConfluenceChildPage -ParentID 1234 | Select-Object ID, Title | Sort-Object Title
```

For the wiki page with ID 1234, get all pages immediately beneath it.
Returns only each page's ID and Title, sorting results alphabetically by Title.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-ConfluencePage -Title 'Genghis Khan' | Get-ConfluenceChildPage -Limit 500
```

Find the Genghis Khan wiki page and pipe the results.
Get only the first 500 children beneath that page.

### -------------------------- EXAMPLE 3 --------------------------
```
Get-ConfluenceChildPage -ParentID 9999 -Expand -Limit 100
```

For each child page found, expand the results to also include properties
like Body and Version (Ver).
Typically, using -Expand will not return
more than 100 results, even if -Limit is set to a higher value.

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
Filter results by page ID.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: ID

Required: True
Position: 1
Default value: 0
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Recurse
Get all child pages recursively

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

### -PageSize
Defaults to 25 max results; can be modified here.
Numbers above 100 may not be honored if -Expand is used.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
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

### ConfluencePS.Page

## NOTES

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

