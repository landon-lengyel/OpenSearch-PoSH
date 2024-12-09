function New-OSIndex {
    <#
    .SYNOPSIS
        Create new Index.

    .DESCRIPTION
        Creates a new Index. Useful if you want to have non-default settings or mappings. Otherwise you can just index data to a new index name and it will create automatically.

    .PARAMETER Index
        New index name.

    .PARAMETER ConfigHash
        Hashtable of the Json config for the index.

    .PARAMETER ConfigJson
        Json config for the index.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NoConfig')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'NoConfig')]
        [Parameter(Mandatory, ParameterSetName = 'ConfigHash')]
        [Parameter(Mandatory, ParameterSetName = 'ConfigJson')]
        [array]$Index,

        [Parameter(Mandatory, ParameterSetName = 'ConfigHash')]
        [hashtable]$ConfigHash,

        [Parameter(Mandatory, ParameterSetName = 'ConfigJson')]
        [string]$ConfigJson,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Index names must be lowercase
    $Index = $Index.ToLower()
    
    # Build request
    $Request = "/$Index"

    $Params = @{
        'Request' = $Request
        'Method' = 'PUT'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    # Build body
    if ($PSCmdlet.ParameterSetName -eq 'ConfigJson'){
        # Check if JSON can be parsed
        try { $TestConfig = $ConfigJson | ConvertFrom-Json -Depth 100 }
        catch {
            throw [System.ArgumentException]::new('ConfigJson variable must contain valid JSON', 'ConfigJson')
        }

        $Params.Body = $ConfigJson
        
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'ConfigHash'){
        $Params.Body = $ConfigHash | ConvertTo-Json -Depth 100
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

Export-ModuleMember -Function New-OSIndex
