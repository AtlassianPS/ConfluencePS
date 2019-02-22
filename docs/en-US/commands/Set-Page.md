---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Set-Page/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Set-Page/
---
# Set-Page

## SYNOPSIS

Edit an existing Confluence page.

## SYNTAX

### byParameters (Default)

```powershell
Set-ConfluencePage -ApiUri <Uri> -Credential <PSCredential> -PageID <Int32> [-Title <String>] [-Body <String>] [-Convert] [-ParentID <Int32>] [-Parent <Page>] [-WhatIf] [-Confirm]
```

### byObject

```powershell
Set-ConfluencePage -ApiUri <Uri> -Credential <PSCredential> -InputObject <Page> [-WhatIf] [-Confirm]
```

## DESCRIPTION

For existing page(s): Edit page content, page title, and/or change parent page.

Content needs to be in "Confluence storage format". Use `-Convert` if not preconditioned.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Set-ConfluencePage -PageID 123456 -Title 'Counting'
```

For existing wiki page 123456, change its name to "Counting".

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Set-ConfluencePage -PageID 123456 -Body 'Hello World!' -Convert
```

For existing wiki page 123456, update its page contents to "Hello World!"
-Convert applies the "Confluence storage format" to your given string.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
Set-ConfluencePage -PageID 123456 -ParentID 654321
Set-ConfluencePage -PageID 123456 -Parent (Get-ConfluencePage -PageID 654321)
```

Two different methods to set a new parent page.
Parent page 654321 will now have child page 123456.

### -------------------------- EXAMPLE 4 --------------------------

```powershell
$page = Get-ConfluencePage -PageID 123456
$page.Title = "New Title"

Set-ConfluencePage -InputObject $page
$page | Set-ConfluencePage
```

Two different methods to set a new parent page using a `ConfluencePS.Page`
object.

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

### -InputObject

Page Object which will be used to replace the current content.

```yaml
Type: Page
Parameter Sets: byObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PageID

The ID of the page to edit.

```yaml
Type: Int32
Parameter Sets: byParameters
Aliases: ID

Required: True
Position: Named
Default value: 0
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Title

Name of the page; existing or new value can be used.
Existing will be automatically supplied via Get-Page if not manually included.

```yaml
Type: String
Parameter Sets: byParameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body

The full contents of the updated body (existing contents will be overwritten).
If not yet in "storage format"--or you don't know what that is--also use -Convert.

```yaml
Type: String
Parameter Sets: byParameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Convert

Optional switch flag for calling ConvertTo-ConfluenceStorageFormat against your Body.

```yaml
Type: SwitchParameter
Parameter Sets: byParameters
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParentID

Optionally define a new parent page.
If unspecified, no change.

```yaml
Type: Int32
Parameter Sets: byParameters
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Parent

Optionally define a new parent page.
If unspecified, no change.

```yaml
Type: Page
Parameter Sets: byParameters
Aliases:

Required: False
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

### ConfluencePS.Page

## NOTES

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
