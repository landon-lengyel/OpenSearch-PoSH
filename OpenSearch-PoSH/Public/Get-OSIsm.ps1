function Get-OSIsm {
    <#
    .SYNOPSIS
        Show the current Index State Management policy state for a specific index.

    .DESCRIPTION
        Get the current state of the index as it relates to the user defined Index State Management Policies.
        IndexName can be an individual index, or data stream. Data streams will show the results for the backing indices.

    .PARAMETER Index
        Name of an index or data stream to limit results to.

    .PARAMETER ShowPolicy
        Shows the policy that is currently applied to the index. Useful to see if it is the same as the current version of the policy.

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
        [String]$Index,

        [switch]$ShowPolicy,

        [ValidateSet('JSON','YAML','CBOR','PSObject','Smile','PlainText')]
        [String]$Format='PSObject',

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Build URL parameters - [Void] is necessary to prevent StringBuilder from outputting the object.
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ($ShowPolicy -eq $True){
        [Void]$UrlParameter.Append('&show_policy=true')
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
    $UrlParameterString = $UrlParameter.ToString()

    # First URL parameter should be '?' not '&'
    if ($UrlParameterString -ne ''){
        $UrlParameterString = $UrlParameterString.Substring(1)
        $UrlParameterString = '?' + $UrlParameterString
    }

    # Build request
    $Request = '_plugins/_ism/explain/' + $Index + $UrlParameterString

    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $Response = Invoke-OSCustomWebRequest @Params

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

Export-ModuleMember -Function Get-OSIsm

