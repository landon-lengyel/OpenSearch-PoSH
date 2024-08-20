function New-OSAlias {
    <#
    .SYNOPSIS
        Create new Index aliases.

    .DESCRIPTION
        Aliases allow users to address an Index or Data Stream by a different name. Use this function to create new aliases.
        Returns $null if successful.

    .PARAMETER Index
        Index or Data Stream name(s) for the alias to target.

    .PARAMETER Alias
        Alias name(s) to be created or updated.

    .PARAMETER IsHidden
        Hide alias from results that use wildcard expressions.

    .PARAMETER Filter
        Advanced filter so the Alias points to a filtered part of an index.

    .PARAMETER WriteIndex
        Alias can only point to one write Index. Use this to associate an Alias with one Index to handle write requests.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Index,

        [Parameter(Mandatory)]
        [array]$Alias,

        [switch]$IsHidden,

        [hashtable]$Filter,

        [string]$WriteIndex,

        # Not sure what these do, so not implementing them for now
        #[string]$Routing,
        #[string]$IndexRouting,
        #[string]$SearchRouting,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Index names must be lowercase
    for ($IndexCount=0; $IndexCount -lt $Index.Count; $IndexCount++){
        $Index[$IndexCount] = $Index[$IndexCount].ToLower()
    }
    if ('' -ne $WriteIndex){
        $WriteIndex = $WriteIndex.ToLower()
    }
    # Alias names must be lowercase
    for ($AliasCount=0; $AliasCount -lt $Alias.Count; $AliasCount++){
        $Alias[$AliasCount] = $Alias[$AliasCount].ToLower()
    }

    # Each alias creation needs an 'action' associated with it. 'Indices' supports array, 'Index' is a single index. Same with Aliases/Alias
    if ($Index.Count -gt 1){
        $IndexActionName = 'indices'
    }
    else {
        $IndexActionName = 'index'
        [string]$Index = $Index[0]
    }

    if ($Alias.Count -gt 1){
        $AliasActionName = 'aliases'
    }
    else {
        $AliasActionName = 'alias'
        [string]$Alias = $Alias[0]
    }

    # Build body
    $Body = @{
        'actions' = @(
            @{
                'add' = @{
                    $IndexActionName = $Index
                    $AliasActionName = $Alias
                }
            }
        )
    }

    if ('' -ne $WriteIndex){
        $Body.actions += @{
            'add' = @{
                'index' = $WriteIndex
                $AliasActionName = $Alias
                'is_write_index' = $true
            }
        }
    }

    if ($null -ne $Filter){
        $Body.filter = $Filter
    }

    if ($true -eq $IsHidden){
        $Body.is_hidden = $true
    }

    $Body = $Body | ConvertTo-Json -Depth 100

    # Build request
    $Request = '/_aliases'

    $Params = @{
        'Request' = $Request
        'Body' = $Body
        'Method' = 'POST'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }
    $Response = Invoke-OSCustomWebRequest @Params

    if ($Response.StatusCode -eq 200){
        $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
        if ($ResponseContent.acknowledged -eq $true){
            return
        }
        else {
            throw $ResponseContent
        }
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function New-OSAlias
