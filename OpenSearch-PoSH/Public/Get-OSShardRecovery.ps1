function Get-OSShardRecovery {
    <#
    .SYNOPSIS
        Gets all ongoing index and shard recoveries.

    .DESCRIPTION
        Gets all ongoing index and shard recoveries.

    .PARAMETER OpenSearchIndices
        Optional array of index names, to limit results.

    .PARAMETER VerboseResponse
        Add headers to columns and add some formatting. Only makes a difference when format is PlainText.

    .PARAMETER ActiveOnly
        Only shows actively recovering shards/indices. No historical recoveries are returned.

    .PARAMETER Headers
        Array of column headers to display.

    .PARAMETER ListHeaders
        List all possible header options and exit. Utilizes the Get-OSCatHeader function.

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

        [switch]$ListHeaders,

        [boolean]$ActiveOnly=$True,

        [ValidateSet('JSON','YAML','CBOR','Smile','PSObject','PlainText')]
        [String]$Format='PSObject',

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    if ($ListHeaders -eq $True){
        $Headers = Get-OSCatHeader -CatApi 'recovery'
        return $Headers
    }

    # Use output field seperator for casting arrays to strings with comma seperation
    # Used by building URL parameters and adding $Index to the request
    $OldOfs = $ofs
    $ofs = ','

    # Build URL parameters
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ($VerboseResponse -eq $True){
        [Void]$Urlparameter.Append('&v')
    }
    if ($Headers.Count -ge 1){
        [Void]$Urlparameter.Append("&h=$([String]$Headers)")
    }
    if ($ActiveOnly -eq $True){
        [Void]$Urlparameter.Append('&active_only')
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

    # Build request
    if ($Index.Count -ge 1){
        $Request = '/_cat/recovery/' + [String]$Index + $UrlParameterString
    }
    else {
        $Request = '/_cat/recovery' + $UrlParameterString
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

Export-ModuleMember -Function Get-OSShardRecovery

