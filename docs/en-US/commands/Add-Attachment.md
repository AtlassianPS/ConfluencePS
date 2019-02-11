---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Add-Attachment/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Add-Attachment/
---
# Add-Attachment

## SYNOPSIS

Add a new attachment to an existing Confluence page.

## SYNTAX

```powershell
Add-ConfluenceAttachment -ApiUri <Uri> -Credential <PSCredential> [[-PageID] <Int32>] -FilePath <String> [-WhatIf] [-Confirm]
```

## DESCRIPTION

Add Attachments (one or more) to Confluence pages (one or more).
If the Attachment did not exist previously, it will be created.

This will not update an already existing Attachment; see Set-Attachment for updating a file.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Add-ConfluenceAttachment -PageID 123456 -FilePath test.png -Verbose
```

Adds the Attachment test.png to the wiki page with ID 123456.
-Verbose output provides extra technical details, if interested.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluencePage -SpaceKey SRV | Add-ConfluenceAttachment -FilePath test.png -WhatIf
```

Simulates adding the Attachment test.png to all pages in the space with key SRV.
-WhatIf provides PageIDs of pages that would have been affected.

## PARAMETERS

### -ApiUri

The URi of the API interface.
Value can be set persistently with Set-Info.

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

### -PageID

The ID of the page to which apply the Attachment to.
Accepts multiple IDs, including via pipeline input.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: ID

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -FilePath

One or more files to be added.

```yaml
Type: String[]
Parameter Sets: (All)

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

### ConfluencePS.Attachment

## NOTES

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
