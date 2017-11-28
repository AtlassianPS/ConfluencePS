---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePS.Space/
---

# ConfluencePS.Space

## SYNOPSIS
Defines an object for Spaces in Confluence.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePS.Space [-Property @{}]

[ConfluencePS.Space]@{}
```

## DESCRIPTION
**fix**The `Space` is an object that describes spaces in Confluence.

## REFERENCES
The following classes use `Space` for their properties:
- [`ConfluencePS.Page`](/docs/ConfluencePS/classes/ConfluencePS.Page/)

## CONSTRUCTORS
_This class does not have a constructor._

## PROPERTIES

### Id
The Id is the identifier used by the Confluence server internally.

_This value can't be changed for a space and it's value is assigned by the server._

**It is recommended to use `Key` as identifier when using this object.**

```yaml
Type: Int32
Required: True
Default value: None
```

### Key
The Key is the "public" identifier of a `Space`.

_This value can't be changed for a space but it's value is defined by the admin when creating the space._

```yaml
Type: String
Required: True
Default value: None
```

### Name
The Name describes the name of the `Space`.

_This value is defined by the admin when creating the space and can be changed by any user with 'space admin' permissions._

```yaml
Type: String
Required: True
Default value: None
```

### Icon
The Icon describes the icon of a `Space`.

_Any user with 'space admin' permissions can change this._

```yaml
Type: ConfluencePS.Icon
Required: True
Default value: None
```

### Type
The Type describes what kind of `Space` this is.

Values can be `global` or `personal`.

```yaml
Type: String
Required: True
Default value: global
```

### Description
The Description contains the description of the `Space`.

_Any user with 'space admin' permissions can change this._

```yaml
Type: String
Required: False
Default value: None
```

### Homepage
The Homepage contains the information about the homepage of the `Space`.

_Any user with 'space admin' permissions can change this._

```yaml
Type: ConfluencePS.Page
Required: True
Default value: None
```

## METHODS

### ToString()
The method for casting an object of this class to string is overwritten.

When cast to string, this will return `[$Key] $Name`.
