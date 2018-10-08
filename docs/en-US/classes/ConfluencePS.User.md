---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePS.User/
---

# ConfluencePS.User

## SYNOPSIS
Defines an object for Users in Confluence.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePS.User [-Property @{}]

[ConfluencePS.User]@{}
```

## DESCRIPTION
**fix**The `User` is an object that describes users in Confluence.

## REFERENCES
The following classes use `User` for their properties:
- [`ConfluencePS.Version`](/docs/ConfluencePS/classes/ConfluencePS.Version/)

## CONSTRUCTORS
_This class does not have a constructor._

## PROPERTIES

### UserKey
The UserKey is the identifier of a `User` used by the Confluence server internally.

_This value can't be changed and is assigned by the server._

**It is recommended to use `UserName` as identifier when using this object.**

```yaml
Type: String
Required: True
Default value: None
```

### UserName
The UserName is the "public" identifier of a `User`.

_This value can be changed by an administrator._

```yaml
Type: String
Required: True
Default value: None
```

### DisplayName
The DisplayName is the chosen name that is display for the `User`.

_This value can be changed by the user himself._

```yaml
Type: String
Required: True
Default value: None
```

### ProfilePicture
The ProfilePicture contains the information about the `User`s profile picture / avatar.

_This value can be changed by the user himself._

```yaml
Type: ConfluencePS.Icon
Required: True
Default value: None
```

## METHODS

### ToString()
The method for casting an object of this class to string is overwritten.

When cast to string, this will return the `DisplayName` property's value.
