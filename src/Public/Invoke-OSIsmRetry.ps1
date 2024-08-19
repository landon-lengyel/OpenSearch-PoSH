function Invoke-OSIsmRetry {
    <#
    .SYNOPSIS
        Retry a failed Index State Management (ISM) action for a specified index.

    .DESCRIPTION
        Index State Managmenet (ISM) actions can fail due to various reason. This command tells OpenSearch to retry the failed command. Check if the current status is failed with Get-OSIsm

    .PARAMETER Index
        Name of an index or data stream to retry. Wildcards/Index Patterns are supported to retry multiple.

    .PARAMETER Format
        Return results in specified format.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [SupportsWildcards()]
        [String]$Index,

        [ValidateSet('JSON','YAML','CBOR','PSObject','Smile','PlainText')]
        [String]$Format='PSObject',

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Build URL parameters - [Void] is necessary to prevent StringBuilder from outputting the object.
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ('PlainText' -eq $Format){
        # Do nothing
    }
    elseif ('PSObject' -eq $Format){    # PSObject is custom, processed later
        [Void]$Urlparameter.Append('&format=JSON')
    }
    else {
        [Void]$Urlparameter.Append("&format=$Format")
    }
    $UrlParameterString = $UrlParameter.ToString()

    # First URL parameter should be '?' not '&'
    if ($UrlParameterString -ne ''){
        $UrlParameterString = $UrlParameterString.Substring(1)
        $UrlParameterString = '?' + $UrlParameterString
    }

    # Build request
    $Request = '_plugins/_ism/retry/' + $Index + $UrlParameterString

    $Params = @{
        'Request' = $Request
        'Method' = 'POST'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $Response = Invoke-OSCustomWebRequest @Params

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

Export-ModuleMember -Function Invoke-OSIsmRetry

