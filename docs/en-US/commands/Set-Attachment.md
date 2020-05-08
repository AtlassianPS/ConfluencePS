---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Set-Attachment/
Module Name: ConfluencePS
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
Set-ConfluenceAttachment -ApiUri <Uri> -Credential <PSCredential> [-Attachment] <Attachment> -FilePath <String> [-WhatIf] [-Confirm]
```

## DESCRIPTION

Updates an existing attachment with a new file.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
$attachment = Get-ConfluenceAttachment -PageID 123456 -FileNameFilter test.png
Set-ConfluenceAttachment -Attachment $attachment -FilePath newTest.png -Verbose -Confirm
```

For the attachment test.png on page with ID 123456, replace the file with the file newTest.png.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceAttachment -PageID 123456 -FileNameFilter test.png | Set-ConfluenceAttachment -FilePath newTest.png -WhatIf
```

Would replace the attachment test.png to the page with ID 123456.
-WhatIf reports on simulated changes, but does not modify anything.

## PARAMETERS

### -ApiUri

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

### -Attachment

Attachment names to add to the content.

```yaml
Type: Attachment
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -FilePath

File to be updated.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
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

### ConfluencePS.Attachment

## NOTES

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
