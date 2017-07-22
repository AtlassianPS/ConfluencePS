---
external help file: ConfluencePS-help.xml
online version:
schema: 2.0.0
---

# Set-Page

## SYNOPSIS
Edit an existing Confluence page.

## SYNTAX

### byParameters (Default)
```
Set-Page -apiURi <Uri> -Credential <PSCredential> -PageID <Int32> [-Title <String>] [-Body <String>]
 [-Convert] [-ParentID <Int32>] [-Parent <Page>] [-WhatIf] [-Confirm]
```

### byObject
```
Set-Page -apiURi <Uri> -Credential <PSCredential> -InputObject <Page> [-WhatIf] [-Confirm]
```

## DESCRIPTION
For existing page(s): Edit page content, page title, and/or change parent page.
Content needs to be in "Confluence storage format." Use -Convert if not preconditioned.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-Page -Title 'My First Page' -Expand | Set-Page -Body 'Hello World!' -Convert
```

Probably the easiest edit method, overwriting contents with a short sentence.
Use Get-Page -Expand to pipe in PageID & CurrentVersion.
(See "Get-Help Get-Page -Examples" for help with -Expand and \>100 pages.)
-Convert molds the sentence into a format Confluence will accept.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-Page -Title 'Lew Alcindor' -Limit 100 -Expand | Set-Page -Title 'Kareem Abdul-Jabbar' -Verbose
```

Change the page's name.
Body remains the same, via piping the existing contents.
Verbose flag active for additional screen output.

### -------------------------- EXAMPLE 3 --------------------------
```
Get-Page -SpaceKey MATRIX | Set-Page -Body 'Agent Smith' -Convert -WhatIf
```

Overwrites the contents of all pages in the MATRIX space.
WhatIf flag tells you how many pages would have been affected.

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

### -InputObject
Page Object

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
The ID of the page to edit

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

[Get-Page]()

[ConvertTo-ConfluenceStorageFormat]()

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

