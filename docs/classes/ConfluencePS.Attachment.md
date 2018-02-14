---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePS.Attachment/
---

# ConfluencePS.Attachment

## SYNOPSIS
Defines an object for Attachments in Confluence.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePS.Attachment [-Property @{}]

[ConfluencePS.Attachment]@{}
```

## DESCRIPTION
**fix**The `Attachment` is an object that describes Attachments in Confluence.

## CONSTRUCTORS
_This class does not have a constructor._

## PROPERTIES

### Id
The Id is the unique identifier of the `Attachment`.

_This value can't be changed and is assigned by the server._

```yaml
Type: Int32
Required: True
Default value: None
```

### Status
The Status describes the current status of the `Attachment`.

Possible values are: `current`, `trashed` and `draft`.

```yaml
Type: String
Required: True
Default value: current
```

### Title
The filename / Title of the `Attachment`.

```yaml
Type: String
Required: True
Default value: None
```

### MediaType
The MIME media type of the `Attachment`.

```yaml
Type: String
Required: True
Default value: None
```

### FileSize
The file size of the `Attachment` in bytes.

```yaml
Type: Int32
Required: True
Default value: None
```

### SpaceKey
The Space key in where the `Attachment` is stored.

```yaml
Type: String
Required: True
Default value: None
```

### PageId
The page ID in where the `Attachment` is stored.

```yaml
Type: Int32
Required: True
Default value: None
```

### Version
Contains the information about the latest version of the `Attachment`.

```yaml
Type: ConfluencePS.Version
Required: True
Default value: None
```

### URL
Contains the URL under which the `Attachment` is accessible.

```yaml
Type: String
Required: True
Default value: None
```
## METHODS

### ToString()
The method for casting an object of this class to string is overwritten.

When cast to string, this will return `[$Id] $Title`.
