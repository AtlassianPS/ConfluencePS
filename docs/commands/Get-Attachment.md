---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Get-Attachment/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Get-Attachment/
---

# Get-Attachment

## SYNOPSIS
Retrieve the child Attachments of a given wiki Page.

## SYNTAX

```powershell
Get-ConfluenceAttachment -apiURi <Uri> -Credential <PSCredential> [-PageID] <Int32[]> [-FileNameFilter <string>] [-MediaTypeFilter <string>] [-Skip <UInt64>] [-First <UInt64>] [-PageSize <UInt64>] [-IncludeTotalCount]
```

## DESCRIPTION
Return all Attachments directly below the given Page.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
Get-ConfluenceAttachment -PageID 123456
Get-ConfluencePage -PageID 123456 | Get-ConfluenceAttachment
```

Description

-----------

Two different methods to return all Attachments directly below Page 123456.
Both examples should return identical results.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
Get-ConfluenceAttachment -PageID 123456, 234567
Get-ConfluencePage -PageID 123456, 234567 | Get-ConfluenceAttachment
```

Description

-----------

Similar to the previous example, this shows two different methods to return the Attachments of multiple pages.
Both examples should return identical results.

### -------------------------- EXAMPLE 3 --------------------------
```powershell
Get-ConfluenceAttachment -PageID 123456 -FileNameFilter "test.png"
```

Description

-----------

Returns the Attachment called test.png from Page 123456 if it exists.

### -------------------------- EXAMPLE 4 --------------------------
```powershell
Get-ConfluenceAttachment -PageID 123456 -MediaTypeFilter "image/png"
```

Description

-----------

Returns any attachments of mime type image/png from Page 123456.

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
Return attachments for a list of page IDs.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -FileNameFilter
Filter results by filename (case sensitive).
Does not support wildcards (*).

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

### -MediaTypeFilter
Filter results by media type (case insensitive).
Does not support wildcards (*).

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
NOTE: Not yet implemented.
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

### -IncludeTotalCount
NOTE: Not yet implemented.
Causes an extra output of the total count at the beginning.
Note this is actually a uInt64, but with a custom string representation.

```yaml
Type: SwitchParameter

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```
## INPUTS

## OUTPUTS

### ConfluencePS.Attachment

## NOTES
Confluence uses hierarchy to help organize content.
This command is meant to help provide the intended context from the command line.

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
