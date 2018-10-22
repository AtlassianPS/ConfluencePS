---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePS.Label/
---
<!-- markdownlint-disable MD036 -->

# ConfluencePS.Label

## SYNOPSIS

Defines an object for Labels in Confluence.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePS.Label [-Property @{}]

[ConfluencePS.Label]@{}
```

## DESCRIPTION

**fix**The `Label` is an object that describes labels in Confluence.

## REFERENCES

The following classes use `User` for their properties:

- [`ConfluencePS.ContentLabelSet`](/docs/ConfluencePS/classes/ConfluencePS.ContentLabelSet/)

## CONSTRUCTORS

_This class does not have a constructor._

## PROPERTIES

### Id

The Id is the identifier of a `Label` used by the Confluence server internally.

_This value can't be changed and is assigned by the server._

```yaml
Type: Int32
Required: True
Default value: None
```

### Prefix

_description missing_

```yaml
Type: String
Required: True
Default value: global
```

### Name

The name of the `Label`.

```yaml
Type: String
Required: True
Default value: None
```

## METHODS

### ToString()

The method for casting an object of this class to string is overwritten.

When cast to string, this will return the `Name` property's value.
