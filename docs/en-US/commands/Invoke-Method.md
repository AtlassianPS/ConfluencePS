---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Invoke-Method/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Invoke-Method/
---
# Invoke-Method

## SYNOPSIS

Invoke a specific call to a Confluence REST Api endpoint

## SYNTAX

```powershell
Invoke-ConfluenceMethod [-URi] <Uri> [[-Method] <WebRequestMethod>] [[-Body] <String>]
 [-RawBody] [[-Headers] <Hashtable>] [[-GetParameters] <Hashtable>] [[-InFile] <String>]
 [[-OutFile] <String>] [[-OutputType] <Type>] [-Credential] <PSCredential>
 [[-Caller] <Object>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
 [<CommonParameters>]
```

## DESCRIPTION

Make a call to a REST Api endpoint with all the benefits of ConfluencePS.

This cmdlet is what the other cmdlets call under the hood.
It handles the authentication, parses the
response, handles exceptions from Confluence, returns specific objects and
handles the differences between versions of Powershell and Operating Systems.

ConfluencePS does not support any third-party plugins on Confluence.
This cmdlet can be used to interact with REST Api enpoints which are not already
converted in ConfluencePS.
It allows for anyone to use the same technics as ConfluencePS uses internally
for creating their own functions or modules.
When used by a module, the Manifest (.psd1) can define the dependency to
ConfluencePS with the 'RequiredModules' property.
This will import the module if not already loaded or even download it from the
PSGallery.

## EXAMPLES

### EXAMPLE 1

```powershell
Invoke-ConfluenceMethod -Uri https://contoso.com/rest/api/content -Credential $cred
```

Executes a GET request on the defined URI and returns a collection of PSCustomObject

### EXAMPLE 2

```powershell
Invoke-ConfluenceMethod -Uri https://contoso.com/rest/api/content -OutputType [ConfluencePS.Page] -Credential $cred
```

Executes a GET request on the defined URI and returns a collection of ConfluencePS.Page

### EXAMPLE 3

```powershell
$params = @{
    Uri = "https://contoso.com/rest/api/content"
    Method = "POST"
    Credential = $cred
}
Invoke-ConfluenceMethod @params
```

Executes a POST request on the defined URI and returns a collection of ConfluencePS.Page.

This will example doesn't really do anything on the server,
as the content API needs requires a value for the BODY.
See next example

### EXAMPLE 4

```powershell
$body = '{"type": "page", "space": {"key": "TS"}, "title": "My New Page", "body": {"storage": {"representation": "storage"}, "value": "<p>LoremIpsum</p>"}}'
$params = @{
    Uri = "https://contoso.com/rest/api/content"
    Method = "POST"
    Body = $body
    Credential = $cred
}
Invoke-ConfluenceMethod @params
```

Executes a POST request with a JSON string in the BODY on the defined URI
and returns a collection of ConfluencePS.Page.

### EXAMPLE 5

```powershell
$params = @{
    Uri = "https://contoso.com/rest/api/content"
    GetParameters = @{
        expand = "space,version,body.storage,ancestors"
        limit  = 30
    }
    Credential = $cred
}
Invoke-ConfluenceMethod @params
```

Executes a GET request on the defined URI with a Get Parameter that is resolved to look like this:
?expand=space,version,body.storage,ancestors&limit=30

### EXAMPLE 6

```powershell
$params = @{
    Uri = "https://contoso.com/rest/api/content/10001/child/attachment"
    Method = "POST"
    OutputType = [ConfluencePS.Attachment]
    InFile = "c:\temp\confidentialData.txt"
    Credential = $cred
}
Invoke-ConfluenceMethod @params
```

Executes a POST request on the defined URI and uploads the InFile with a multipart/form-data request.
The response of the request will be cast to an object of type ConfluencePS.Attachment.

### EXAMPLE 7

```powershell
$params = @{
    Uri = "https://contoso.com/rest/api/content/10001/child/attachment/110001"
    Method = "GET"
    Headers    = @{"Accept" = "text/plain"}
    OutFile = "c:\temp\confidentialData.txt"
    Credential = $cred
}
Invoke-ConfluenceMethod @params
```

Executes a GET request on the defined URI and stores the output on the File System.
It also uses the Headers to define what mimeTypes are expected in the response.

## PARAMETERS

### -URi

URI address of the REST API endpoint.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Method

Method of the HTTP request.

```yaml
Type: WebRequestMethod
Parameter Sets: (All)
Aliases:
Accepted values: Default, Get, Head, Post, Put, Delete, Trace, Options, Merge, Patch

Required: False
Position: 2
Default value: GET
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body

Body of the HTTP request.

By default each character of the Body is encoded to a sequence of bytes.
This enables the support of UTF8 characters.
And was first reported here:
<https://stackoverflow.com/questions/15290185/invoke-webrequest-issue-with-special-characters-in-json>

This behavior can be changed with -RawBody.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RawBody

Keep the Body from being encoded.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Headers

Define a key-value set of HTTP headers that should be used in the call.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GetParameters

Define a key-value set of GET Parameters.

This is not mandatory, and can be integrated in the Uri.
This parameter exists to facilitate the addition and removal of parameters
in particular for paging

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InFile

Path to a file that will be uploaded with a multipart/form-data request.

This parameter does not validate the input in any way.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutFile

Path to the file where the response should be stored to.

This parameter does not validate the input in any way

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputType

Define the Type of the object that will be returned by the call.

The casting to custom classes is done in private functions as uses the cast
operator which throws a terminating error in case the response can't be casted.

```yaml
Type: Type
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Credentials to use for the authentication with the REST Api.

If no sessions is available, the request will be executed anonymously.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: True
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Caller

Context which will be used for throwing errors.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: $PSCmdlet
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeTotalCount

NOTE: Not yet implemented.
Causes an extra output of the total count at the beginning.
Note this is actually a uInt64, but with a custom string representation.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Skip

Controls how many objects will be skipped before starting output.
Defaults to 0.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -First

NOTE: Not yet implemented.
Indicates how many items to return.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (<http://go.microsoft.com/fwlink/?LinkID=113216>).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject

### ConfluencePS.Page

### ConfluencePS.Space

### ConfluencePS.Label

### ConfluencePS.Icon

### ConfluencePS.Version

### ConfluencePS.User

### ConfluencePS.Attachment

## NOTES

## RELATED LINKS

[Confluence Cloud API](https://developer.atlassian.com/cloud/confluence/rest/)

[Confluence Server API](https://docs.atlassian.com/ConfluenceServer/rest/latest/)
