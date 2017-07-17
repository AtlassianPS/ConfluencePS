---
external help file: ConfluencePS-help.xml
online version: 
schema: 2.0.0
---

# New-ConfluencePage

## SYNOPSIS
Create a new page in your Confluence instance.

## SYNTAX

### byParameters (Default)
```
New-ConfluencePage -apiURi <Uri> -Credential <PSCredential> -Title <String> [-ParentID <Int32>]
 [-Parent <Page>] [-SpaceKey <String>] [-Space <Space>] [-Body <String>] [-Convert] [-WhatIf] [-Confirm]
```

### byObject
```
New-ConfluencePage -apiURi <Uri> -Credential <PSCredential> -InputObject <Page> [-WhatIf] [-Confirm]
```

## DESCRIPTION
Create a new page in Confluence.
Optionally include content in -Body.
Content needs to be in "Confluence storage format;" see also -Convert.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
My Title</h1><p>The body of my fancy new page.</p>"
```

Creates a new page with a given title and body content (in "confluence's storeage format").
The information of the created page is returned to the console.

### -------------------------- EXAMPLE 2 --------------------------
```
New-ConfluencePage -Title 'Test New Page' -ParentID 123456 -Body 'Hello world' -Convert -WhatIf
```

Creates a new page as a child member of existing page 123456 with one line of page text.
The Body defined is converted to Storage fromat by the "-Convert" parameter

### -------------------------- EXAMPLE 3 --------------------------
```
New-ConfluencePage -Title "Luke Skywalker" -Parent (Get-ConfluencePage -title "Darth Vader" -SpaceKey "STARWARS")
```

Creates a new page with an empty body as a child page of the "Parent Page" in the "space" page.

### -------------------------- EXAMPLE 4 --------------------------
```
[ConfluencePS.Page]@{Title="My Title";Space=[ConfluencePS.Space]@{Key="ABC"}} | New-ConfluencePage -ApiURi "https://myserver.com/wiki" -Credential $cred
```

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
Page Object of the parent page.

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
Accepts pipeline input by property name.

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
Optional flag to call ConvertTo-ConfluenceStorageFormat against your Body.

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

[Get-ConfluencePage]()

[ConvertTo-ConfluenceStorageFormat]()

[https://github.com/brianbunke/ConfluencePS](https://github.com/brianbunke/ConfluencePS)

