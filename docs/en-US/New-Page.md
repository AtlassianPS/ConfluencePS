---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/New-Page.md
locale: en-US
schema: 2.0.0
---

# New-Page

## SYNOPSIS
Create a new page on your Confluence instance.

## SYNTAX

### byParameters (Default)
```powershell
New-Page -apiURi <Uri> -Credential <PSCredential> -Title <String> [-ParentID <Int32>] [-Parent <Page>] [-SpaceKey <String>] [-Space <Space>] [-Body <String>] [-Convert] [-WhatIf] [-Confirm]
```

### byObject
```powershell
New-Page -apiURi <Uri> -Credential <PSCredential> -InputObject <Page> [-WhatIf] [-Confirm]
```

## DESCRIPTION
Create a new page on Confluence.
Optionally include content in -Body.
Content needs to be in "Confluence storage format;" see also -Convert.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```powershell
New-Page -Title 'Test New Page' -ParentID 123456 -Body 'Hello world' -Convert -WhatIf
```

Description

-----------

Creates a new page as a child member of existing page 123456 with one line of page text.
The Body defined is converted to Storage format by the "-Convert" parameter

### -------------------------- EXAMPLE 2 --------------------------
```powershell
New-Page -Title "Luke Skywalker" -Parent (Get-Page -title "Darth Vader" -SpaceKey "STARWARS")
```

Description

-----------

Creates a new page with an empty body as a child page of the "Darth Vader" page in Space "STARWARS".

### -------------------------- EXAMPLE 3 --------------------------
```powershell
[ConfluencePS.Page]@{Title="My Title";Space=[ConfluencePS.Space]@{Key="ABC"}} | New-Page -ApiURi "https://myserver.com/wiki" -Credential $cred
```

Description

-----------

Creates a new page "My Title" in the space "ABC" with an empty body.

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
A Page Object from which to create a new page.

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

### -Title
Name of your new page.

```yaml
Type: String
Parameter Sets: byParameters
Aliases: Name

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ParentID
The ID of the parent page.
NOTE: This feature is not in the 5.8 REST API documentation, and should be considered experimental.

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
Parent page as Page Object.

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

### -SpaceKey
Key of the space where the new page should exist.
Only needed if you don't utilize ParentID.

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

### -Space
Space Object in which to create the new page.

```yaml
Type: Space
Parameter Sets: byParameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body
The contents of your new page.

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
Convert the provided body to Confluence's storage format.
Optional flag.
Has the same effect as calling ConvertTo-ConfluenceStorageFormat against your Body.

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
[Remove-Page]()
[Set-Page]()

[ConvertTo-ConfluenceStorageFormat]()

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)

