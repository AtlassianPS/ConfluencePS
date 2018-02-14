---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/commands/Set-Attachment.md
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Set-Attachment/
---

# Set-Attachment

## SYNOPSIS
Updates an existing attachment with a new file.

## SYNTAX

```powershell
Set-Attachment -apiURi <Uri> -Credential <PSCredential> -Attachment <Attachment> -FilePath <String> [-WhatIf] [-Confirm]
```

## DESCRIPTION
Updates an existing attachment with a new file.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
$attachment = Get-ConfluenceAtachments -PageID 123456 -FileNameFilter test.png
Set-ConfluenceAttachment -Attachment $attachment -FileName newtest.png -Verbose -Confirm
```

Description

-----------

For the attachment test.png on page with ID 123456, replace the file with the file newtest.png.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
Get-ConfluenceAtachments -PageID 123456 -FileNameFilter test.png | Set-Attachment -FileName newtest.png -WhatIf
```

Description

-----------

Would replace the attachment test.png to the page with ID 123456.
-WhatIf reports on simulated changes, but does not modify anything.

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

### -Attachment
Attachment names to add to the content.

```yaml
Type: Atachment
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True
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
