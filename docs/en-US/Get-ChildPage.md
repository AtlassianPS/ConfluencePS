---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/Get-ChildPage.md
locale: en-US
schema: 2.0.0
---

# Get-ChildPage

## SYNOPSIS
List all child pages of a specific wiki page.

## SYNTAX

```powershell
Get-ChildPage -apiURi <Uri> -Credential <PSCredential> [-PageID] <Int32> [-Recurse] [-PageSize <Int32>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
```

## DESCRIPTION
Get all pages that are descendants of a given page.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
Get-ChildPage -ParentID 1234 | Select-Object ID, Title | Sort-Object Title
```

Description

-----------

For the wiki page with ID 1234, get all pages immediately beneath it.
Returns only each page's ID and Title, sorting results alphabetically by Title.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
Get-Page -Title 'Genghis Khan' | Get-ChildPage | Select -First 500
```

Description

-----------

Find the Genghis Khan wiki page and pipe the results.
Get only the first 500 children beneath that page.

### -------------------------- EXAMPLE 3 --------------------------
```powershell
Get-ChildPage -ParentID 9999 -Recurse
```

Description

-----------
Fetch all child pages of page 9999 recursively.

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
Maximum number of results to fetch per call.
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
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -First
Indicates how many items to return.
Currently not supported.

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

### ConfluencePS.Page

## NOTES

## RELATED LINKS

[Get-Page]()

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

