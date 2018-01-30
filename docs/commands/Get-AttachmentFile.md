---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/commands/Get-AttachmentFile.md
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
Get-ConfluenceAttachmentFile -apiURi <Uri> -Credential <PSCredential> [-Attachment] <Object> [-OutFile <string>]
```

## DESCRIPTION
Retrieves the binary Attachment for a given Attachment object.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
Get-ConfluenceAttachment -PageID 123456 | Get-ConfluenceAttachmentFile
```

Description

-----------

Save any attachments of page 123456 to the current directory with the filename stored in confluence for each attachment.

### -------------------------- EXAMPLE 2 --------------------------
```powershell
Get-ConfluenceAttachment -PageID 123456 | Get-ConfluenceAttachmentFile -OutFile "c:\temp_dir\{1}_{0}"
```

Description

-----------

Save any attachments of page 123456 to the temp_dir directory with a filename generated for each attachment 
using a combination of the Confluence attachment ID and the filename stored in Confluence.

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
Attachment object to download.

```yaml
Type: Attachment[]

Required: True
Position: 1
Default value: None
Accept pipeline input: True
Accept wildcard characters: False
```

### -OutFile
Override the naming scheme for the output files. The filename is generated using a format string with default of using 
the Confluence filename which is equivialent to an OutFile value of {0}.


Available values in the format string are:
  -  {0} the filename as stored in Confluence
  -  {1} the unique Confluence attachment ID 
  -  {2} the space key
  -  {3} the parent Page ID
  -  {4} the version number

```yaml
Type: String

Required: False
Position: Named
Default value: Use Confluence filename
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
