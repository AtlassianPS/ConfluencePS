---
layout: documentation
Module Name: ConfluencePS
permalink: /docs/ConfluencePS/classes/ConfluencePS.Page/
---
# ConfluencePS.Page

## SYNOPSIS

Defines an object for Pages in Confluence.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePS.Page [-Property @{}]

[ConfluencePS.Page]@{}
```

## DESCRIPTION

<!-- TODO -->
The `Page` is an object that describes pages in Confluence.

## REFERENCES

The following classes use `Page` for their properties:

- [`ConfluencePS.ContentLabelSet`](/docs/ConfluencePS/classes/ConfluencePS.ContentLabelSet/)
- [`ConfluencePS.Page`](/docs/ConfluencePS/classes/ConfluencePS.Page/)
- [`ConfluencePS.Space`](/docs/ConfluencePS/classes/ConfluencePS.Space/)

## CONSTRUCTORS

<!-- TODO -->
_This class does not have a constructor._

## PROPERTIES

### Id

The Id is the unique identifier of the `Page`.

_This value can't be changed and is assigned by the server._

```yaml
Type: Int32
Required: True
Default value: None
```

### Status

The Status describes the current status of the `Page`.

Possible values are: `current`, `trashed` and `draft`.

```yaml
Type: String
Required: True
Default value: current
```

### Title

The Name / Title of the `Page`.

```yaml
Type: String
Required: True
Default value: None
```

### Space

The Space in which the `Page` is in.

```yaml
Type: ConfluencePS.Space
Required: True
Default value: None
```

### Version

Contains the information about the latest version of the `Page`.

Values can be `global` or `personal`.

```yaml
Type: ConfluencePS.Version
Required: True
Default value: None
```

### Body

The Content / Body of the `Page`.

_The content is in Confluence's storage format, which must be a valid XHTML string._

```yaml
Type: String
Required: True
Default value: null
```

### Ancestors

Contains the hierarchy of the `Page` in the navigation by describing it's ancestors / parent pages.

```yaml
Type: ConfluencePS.Page
Required: False
Default value: None
```

### URL

Contains the URL under which the `Page` is accessible.

```yaml
Type: String
Required: True
Default value: None
```

### ShortURL

Contains a shortened URL under which the `Page` is accessible.

```yaml
Type: String
Required: True
Default value: None
```

## METHODS

### ToString()

The method for casting an object of this class to string is overwritten.

When cast to string, this will return `[$Id] $Title`.
