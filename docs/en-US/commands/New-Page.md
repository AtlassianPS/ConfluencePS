---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/New-Page/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/New-Page/
---
# New-Page

## SYNOPSIS

Create a new page on your Confluence instance.

## SYNTAX

### byParameters (Default)

```powershell
New-ConfluencePage -apiURi <Uri> -Credential <PSCredential> -Title <String> [-ParentID <Int32>] [-Parent <Page>] [-SpaceKey <String>] [-Space <Space>] [-Body <String>] [-Convert] [-WhatIf] [-Confirm]
```

### byObject

```powershell
New-ConfluencePage -apiURi <Uri> -Credential <PSCredential> -InputObject <Page> [-WhatIf] [-Confirm]
```

## DESCRIPTION

Create a new page on Confluence.

Optionally include content in -Body.
Body content needs to be in "Confluence storage format" -- see also -Convert.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
New-ConfluencePage -Title 'Test New Page' -SpaceKey asdf
```

Create a new blank wiki page at the root of space "asdf".

### -------------------------- EXAMPLE 2 --------------------------

```powershell
New-ConfluencePage -Title 'Luke Skywalker' -Parent (Get-ConfluencePage -Title 'Darth Vader' -SpaceKey 'STARWARS')
```

Creates a new blank wiki page as a child page below "Darth Vader" in the specified space.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
New-ConfluencePage -Title 'Luke Skywalker' -ParentID 123456 -Verbose
```

Creates a new blank wiki page as a child page below the wiki page with ID 123456.

-Verbose provides extra technical details, if interested.

### -------------------------- EXAMPLE 4 --------------------------

```powershell
New-ConfluencePage -Title 'foo' -SpaceKey 'bar' -Body $PageContents
```

Create a new wiki page named 'foo' at the root of space 'bar'.
The wiki page will contain the data stored in $PageContents.

### -------------------------- EXAMPLE 5 --------------------------

```powershell
New-ConfluencePage -Title 'foo' -SpaceKey 'bar' -Body 'Testing 123' -Convert
```

Create a new wiki page named 'foo' at the root of space 'bar'.

The wiki page will contain the text "Testing 123".
-Convert will condition the -Body parameter's string into storage format.


### -------------------------- EXAMPLE 6 --------------------------

```powershell
$pageObject = [ConfluencePS.Page]@{
    Title = "My Title"
    Space = [ConfluencePS.Space]@{
        Key="ABC"
    }
}

# example 1
New-ConfluencePage -InputObject $pageObject
# example 2
$pageObject | New-ConfluencePage
```

Two different methods of creating a new page from an object `ConfluencePS.Page`.

Both examples should return identical results.

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

A ConfluencePS.Page object from which to create a new page.

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

> NOTE: This feature is not in the 5.8 REST API documentation, and should be considered experimental.

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

Supply a ConfluencePS.Page object to use as the parent page.

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

Only needed if you don't specify a parent page.

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

Only needed if you don't specify a parent page.

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

Optionally, convert the provided body to Confluence's storage format.
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

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
