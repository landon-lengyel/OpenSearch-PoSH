function Get-OSDataStream {
    <#
    .SYNOPSIS
        Returns a list of a data streams, or an object describing a specific data stream.

    .OUTPUTS
        Returns PSCustomObject with basic data about data stream if found. Or array of PSCustomObjects if multiple found.
        Returns $null if not found.

    .PARAMETER DataStream
        Filter to a specific data stream or data streams if using wildcard.

    .PARAMETER Format
        Return results in one of the following formats: JSON, YAML, CBOR, PSObject

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param(
        [SupportsWildcards()]
        [string]$DataStream,

        [ValidateSet('JSON','YAML','CBOR','PSObject')]
        [String]$Format='PSObject',

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    #Only lowercase names are allowed
    $DataStream = $DataStream.ToLower()

    # Build URL Parameters - Even though only one is supported by the API currently, I suspect more will come so I will leave it like this
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ('PSObject' -eq $Format){    # PSObject is custom, processed later
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
    $Request = '_data_stream'

    if ($DataStream -ne ''){
        $Request += "/$DataStream"
    }
    if ($UrlParameterString -ne ''){
        $Request += $UrlParameterString
    }

    $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Method "GET" -Credential $Credential -Certificate $Certificate
    $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100

    if ($Response.StatusCode -eq 200){
        # Handle response
        if ('PSObject' -eq $Format){
            $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
            $ResponseContent = $ResponseContent.data_streams
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
    elseif ($Response.StatusCode -eq 404){
        return $null
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Get-OSDataStream

