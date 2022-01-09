---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Get-AttachmentFile/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Get-AttachmentFile/
---
# Get-AttachmentFile

## SYNOPSIS

Retrieves the binary Attachment for a given Attachment object.

## SYNTAX

```powershell
Get-ConfluenceAttachmentFile -ApiUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 [-Attachment] <Attachment[]> [-Path <string>]
```

## DESCRIPTION

Retrieves the binary Attachment for a given Attachment object.

As the files are stored in a location of the server that requires authentication,
this functions allows the download of the Attachment in the same way as the rest of the module authenticates with the server.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluenceAttachment -PageID 123456 | Get-ConfluenceAttachmentFile
```

Save any attachments of page 123456 to the current directory with each filename constructed
with the page ID and the attachment filename.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceAttachment -PageID 123456 | Get-ConfluenceAttachmentFile -Path "c:\temp_dir"
```

Save any attachments of page 123456 to a specific directory with each filename constructed
with the page ID and the attachment filename.

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

### -PersonalAccessToken

Confluence's Personal Access Token for authentication.
Value can be set persistently with Set-ConfluenceInfo.

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

Attachment object to download.

```yaml
Type: Attachment[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Path

Override the path used to save the files.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Use current directory
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
