function Get-OSStorageAllocation {
    <#
    .SYNOPSIS
        Show current storage stats on nodes.

    .DESCRIPTION
        Show current storage stats on nodes.

    .PARAMETER NodeName
        Name of a node to limit output to.

    .PARAMETER VerboseResponse
        Add headers to columns and add some formatting. Only makes a difference when format is PlainText.

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
        [String]$NodeName,

        [boolean]$VerboseResponse=$True,

        [Array]$Headers,

        [switch]$ListHeaders,

        [ValidateSet('JSON','YAML','CBOR','Smile','PSObject','PlainText')]
        [String]$Format='PSObject',

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    if ($ListHeaders -eq $True){
        $Headers = Get-OSCatHeader -CatApi 'allocation'
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
    if ($null -ne $Headers){
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

    $ofs = $OldOfs

    # Build request
    if ($NodeName -ne ''){
        $Request = '_cat/allocation/' + $NodeName + $UrlParameterString
    }
    else{
        $Request = '_cat/allocation' + $UrlParameterString
    }

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

Export-ModuleMember -Function Get-OSStorageAllocation

