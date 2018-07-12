---
layout: documentation
Module Name: ConfluencePS
permalink: /docs/ConfluencePS/classes/ConfluencePS.Icon/
---
# ConfluencePS.Icon

## SYNOPSIS

Defines an object for Icons in Confluence.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePS.Icon [-Property @{}]

[ConfluencePS.Icon]@{}
```

## DESCRIPTION

The `Icon` is an object that describes images in Confluence.
It is important to note, that the path to the resource is not absolute; but relative to the BaseUri of the Confluence server.

## REFERENCES

The following classes use `Icon` for their properties:

- [`ConfluencePS.User`](/docs/ConfluencePS/classes/ConfluencePS.User/)
- [`ConfluencePS.Space`](/docs/ConfluencePS/classes/ConfluencePS.Space/)

## CONSTRUCTORS

<!-- TODO -->
_This class does not have a constructor._

## PROPERTIES

### Path

The Path describes the path to the `Icon` resource relative to the BaseUri.

```yaml
Type: String
Required: True
Default value: None
```

### Width

The Width describes the width of the `Icon` resource in pixels.

```yaml
Type: Int32
Required: False
Default value: None
```

### Height

The Height describes the height of the `Icon` resource in pixels.

```yaml
Type: Int32
Required: False
Default value: None
```

### IsDefault

The IsDefault describes if the used `Icon` resource is the default icon from the server.

```yaml
Type: Boolean
Required: False
Default value: False
```

## METHODS

### ToString()

The method for casting an object of this class to string is overwritten.

When cast to string, this will return the `Path` property's value.
