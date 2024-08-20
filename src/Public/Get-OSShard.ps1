function Get-OSShard {
    <#
    .SYNOPSIS
        Gets all ongoing index and shard recoveries.

    .DESCRIPTION
        Gets all ongoing index and shard recoveries.
        Use -UnassignedHeaders switch to see why shards are unassigned.

    .PARAMETER OpenSearchIndices
        Optional array of index names, to limit results.

    .PARAMETER VerboseResponse
        Add headers to columns and add some formatting. Only makes a difference when format is PlainText.

    .PARAMETER Headers
        Array of column headers to display.

    .PARAMETER ListHeaders
        List all possible header options and exit. Utilizes the Get-OSCatHeader function.

    .PARAMETER UnassignedHeaders
        Returns the following headers (overrides Headers parameter): index,node,shard,prirep,state,unassigned.reason

    .PARAMETER Format
        Return results in specified format.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param(
        [Array]$Index,

        [boolean]$VerboseResponse=$True,

        [Array]$Headers,

        [Switch]$UnassignedHeaders,

        [switch]$ListHeaders,

        [ValidateSet('JSON','YAML','CBOR','Smile','PSObject','PlainText')]
        [String]$Format='PSObject',

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    if ($ListHeaders -eq $True){
        $Headers = Get-OSCatHeader -CatApi 'shards'
        return $Headers
    }

    # Use output field seperator for casting arrays to strings with comma seperation
    # Used by building URL parameters and adding $Index to the request
    $OldOfs = $ofs
    $ofs = ','

    # Build URL parameters
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ($VerboseResponse -eq $True){
        [Void]$UrlParameter.Append('&v')
    }
    if ($ActiveOnly -eq $True){
        [Void]$UrlParameter.Append('&active_only')
    }
    if ($UnassignedHeaders -eq $True){
        # Override $Headers
        [Void]$UrlParameter.Append('&h=index,node,shard,prirep,state,unassigned.reason')
    }
    elseif ($Headers.Count -ge 1){
        [Void]$UrlParameter.Append("&h=$([String]$Headers)")
    }
    if ('PlainText' -eq $Format){
        # Do nothing
    }
    elseif ('PSObject' -eq $Format){    # PSObject is custom, processed later
        [Void]$UrlParameter.Append('&format=JSON')
    }
    else {
        [Void]$UrlParameter.Append("&format=$Format")
    }
    $UrlParameterString = $UrlParameter.ToString()

    # First URL parameter should be '?' not '&'
    if ($UrlParameterString -ne ''){
        $UrlParameterString = $UrlParameterString.Substring(1)
        $UrlParameterString = '?' + $UrlParameterString
    }

    # Build request
    if ($Index.Count -ge 1){
        $Request = '/_cat/shards/' + [String]$Index + $UrlParameterString
    }
    else {
        $Request = '/_cat/shards' + $UrlParameterString
    }

    $ofs = $OldOfs

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

Export-ModuleMember -Function Get-OSShard

