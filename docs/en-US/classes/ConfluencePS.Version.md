---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePS.Version/
---

# ConfluencePS.Version

## SYNOPSIS
Defines an object for Versions in Confluence.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePS.Version [-Property @{}]

[ConfluencePS.Version]@{}
```

## DESCRIPTION
**fix**The `Version` is an object that describes versions in Confluence.

## REFERENCES
The following classes use `Version` for their properties:
- [`ConfluencePS.Page`](/docs/ConfluencePS/classes/ConfluencePS.Page/)

## CONSTRUCTORS
_This class does not have a constructor._

## PROPERTIES

### By
Contains the information of the author of the `Version`.

```yaml
Type: ConfluencePS.User
Required: True
Default value: None
```

### When
Contains the Date and Time of when the `Version` was created.

```yaml
Type: DateTime
Required: True
Default value: None
```

### FriendlyWhen
Contains a string that is easy to read about the creation of the `Version`.

```yaml
Type: String
Required: True
Default value: None
```

### Number
The numeric identifier of the `Version` of the resource.

```yaml
Type: Int32
Required: True
Default value: None
```

### Message
The message / comment left by the author about the changes in the `Version`.

```yaml
Type: String
Required: False
Default value: None
```

### MinorEdit
Whether the changes in the `Version` were minor.

```yaml
Type: Boolean
Required: True
Default value: False
```

## METHODS

### ToString()
The method for casting an object of this class to string is overwritten.

When cast to string, this will return the `Number` property's value.
