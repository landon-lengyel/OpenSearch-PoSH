function Get-OSNode {
    <#
    .SYNOPSIS
        Gets a list of all nodes in the cluster.

    .DESCRIPTION
        Gets a list of all nodes in the cluster.
        A few important node metrics are pid, name, cluster_manager, ip, port, version, build, jdk, along with disk, heap, ram, and file_desc.

    .PARAMETER FullId
        If true it will return the full Node ID. Otherwise the truncated version.

    .PARAMETER Headers
        Array of column headers to display.

    .PARAMETER ListHeaders
        List all possible header options and exit. Utilizes the Get-OSCatHeader function.

    .PARAMETER Format
        Return results in specified format.

    .PARAMETER VerboseResponse
        Add headers to columns and add some formatting. Only makes a difference when format is PlainText.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param(
        [switch]$FullId,

        [Array]$Headers=@('name','id','ip','heap.percent','ram.percent','cpu','load_1m','load_5m','load_15m','node.role','node.roles','cluster_manager'),

        [switch]$ListHeaders,

        [ValidateSet('JSON','YAML','CBOR','Smile','PSObject','PlainText')]
        [String]$Format='PSObject',

        [switch]$VerboseResponse,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    if ($ListHeaders -eq $True){
        $Headers = Get-OSCatHeader -CatApi 'nodes'
        return $Headers
    }

    # Use output field seperator for casting arrays to strings with comma seperation
    # Used by building URL parameters and adding $Index to the request
    $OldOfs = $ofs
    $ofs = ','

    # Build URL parameters
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ($FullId -eq $True){
        [Void]$Urlparameter.Append('&full_id=true')
    }
    if ($VerboseResponse -eq $True){
        [Void]$Urlparameter.Append('&v')
    }
    if ($Headers.Count -ge 1){
        [Void]$Urlparameter.Append("&h=$([String]$Headers)")
    }
    if ('PlainText' -eq $Format){
        # Do nothing
    }
    elseif ('PSObject' -eq $Format){    # PSObject is custom, processed later
        [Void]$Urlparameter.Append('&format=JSON')
    }
    else {
        [Void]$Urlparameter.Append("&format=$Format")
    }
    $UrlParameterString = $Urlparameter.ToString()

    # First URL parameter should be '?' not '&'
    if ($UrlParameterString -ne ''){
        $UrlParameterString = $UrlParameterString.Substring(1)
        $UrlParameterString = '?' + $UrlParameterString
    }

    $ofs = $OldOfs

    # Build request
    $Request = '/_cat/nodes' + $UrlParameterString

    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
	    'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $Response = Invoke-OSCustomWebRequest @params

    # Handle response
    if ($Response.StatusCode -eq 200){
        # Handle response
        if ('PSObject' -eq $Format){
            $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
        }
        elseif ('JSON' -eq $Format){
            $ResponseContent = $Response.Content
        }
        else {     # All other types store it in RawContent
            # Use singeline regex to remove header information
            $ResponseContent = $Response.RawContent -replace '(?s)^(.|\n)*Content-Length: \d*....', ''
        }

        return $ResponseContent
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Get-OSNode

