---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Get-ServerInformation/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Get-ServerInformation/
---
# Get-ServerInformation

## SYNOPSIS

Retrieve system information for a Confluence instance.

## SYNTAX

```powershell
Get-ConfluenceServerInformation -ApiUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
```

## DESCRIPTION

Returns the Confluence system information resource from `settings/systemInfo` as a `ConfluencePS.ServerInfo` object.
Cloud responses include Cloud-specific fields such as `CloudId`; Data Center responses are mapped to `DeploymentType = DataCenter`.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluenceServerInformation
```

Return system information from the Confluence instance configured with `Set-ConfluenceInfo`.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceServerInformation -ApiUri "https://example.atlassian.net/wiki/rest/api"
```

Return system information from a specific Confluence API URL.

## PARAMETERS

### -ApiUri

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

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessToken

Confluence's Personal Access Token for authentication.
Value can be set persistently with Set-ConfluenceInfo.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Certificate

Certificate for authentication.

```yaml
Type: X509Certificate
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None

## OUTPUTS

### ConfluencePS.ServerInfo

## NOTES

## RELATED LINKS

[Online Version](https://atlassianps.org/docs/ConfluencePS/commands/Get-ServerInformation/)
