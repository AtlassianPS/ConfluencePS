---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/Get-Page.md
locale: en-US
schema: 2.0.0
---

# Get-Page

## SYNOPSIS
Retrieve a listing of pages in your Confluence instance.

## SYNTAX

### byId (Default)
```powershell
Get-Page -ApiURi <Uri> -Credential <PSCredential> [-PageID] <Int32[]> [-PageSize <Int32>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
```

### byTitle
```powershell
Get-Page -ApiURi <Uri> -Credential <PSCredential> -Title <String> [-SpaceKey <String>] [-Space <Space>] [-PageSize <Int32>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
```

### byLabel
```powershell
Get-Page -ApiURi <Uri> -Credential <PSCredential> [-SpaceKey <String>] [-Space <Space>] -Label <String[]> [-PageSize <Int32>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
```

### bySpace
```powershell
Get-Page -ApiURi <Uri> -Credential <PSCredential> -SpaceKey <String> [-PageSize <Int32>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
```

### bySpaceObject
```powershell
Get-Page -ApiURi <Uri> -Credential <PSCredential> -Space <Space> [-PageSize <Int32>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
```

## DESCRIPTION
Fetch Confluence pages, optionally filtering by Name/Space/ID.
Piped output into other cmdlets is generally tested and supported.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
Get-Page -ApiURi "https://myserver.com/wiki" -Credential $cred | Select-Object ID, Title -first 500 | Sort-Object Title
```

Description

-----------

List the first 500 pages found in your Confluence instance.
Returns only each page's ID and Title, sorting results alphabetically by Title.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
Get-Page -Title Confluence -SpaceKey "ABC" -PageSize 100
```

Description

-----------

Get all pages with the word Confluence in the title in the 'ABC' sapce.
Each call to the server is limited to 100 pages.

### -------------------------- EXAMPLE 3 --------------------------
```powershell
Get-ConfluenceSpace -Name Demo | Get-Page
```

Description

-----------

Get all spaces with a name like *demo*, and then list pages from each returned space.

### -------------------------- EXAMPLE 4 --------------------------
```powershell
$FinalCountdown = Get-Page -PageID 54321
```

Description

-----------

Store the page's ID, Title, Space Key, Version, and Body for use later in your script.

### -------------------------- EXAMPLE 5 --------------------------
```powershell
$WhereIsShe = Get-Page -Title 'Rachel'
```

Description

-----------

Search for Rachel in order to find the correct page ID(s).

### -------------------------- EXAMPLE 6 --------------------------
```powershell
$meetingPages = Get-Page -Label "meeting-notes" -SpaceKey PROJ1
```

Description

-----------

Captures all the meeting note pages in the Proj1 Space.

## PARAMETERS

### -ApiURi
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
Best option if you already know the ID.

```yaml
Type: Int32[]
Parameter Sets: byId
Aliases: ID

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Title
Filter results by name.

```yaml
Type: String
Parameter Sets: byTitle
Aliases: Name

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SpaceKey
Filter results by space key.
Currently, this parameter is case sensitive.

```yaml
Type: String
Parameter Sets: byTitle, byLabel
Aliases: Key

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: bySpace
Aliases: Key

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Space
Filter results by space object(s), typically from the pipeline

```yaml
Type: Space
Parameter Sets: byTitle, byLabel
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

```yaml
Type: Space
Parameter Sets: bySpaceObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Label
Label(s) to use as search criteria to find pages

```yaml
Type: String[]
Parameter Sets: byLabel
Aliases:

Required: True
Position: Named
Default value: None
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
Currently not supported.
Indicates how many items to return.
Defaults to 100.

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

[New-Page]()
[Remove-Page]()
[Set-Page]()

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

