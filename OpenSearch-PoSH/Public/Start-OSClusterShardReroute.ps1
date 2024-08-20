function Start-OSClusterShardReroute {
    <#
    .SYNOPSIS
        Start a cluster reroute. For when failed nodes come back online.

    .DESCRIPTION
        Shards may not reroute automatically after a number of failures. This will start the reroute process again.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .PARAMETER Explain
        Output explanation why the shard is routed how it is. Defaults to True

    .PARAMETER RetryFailed
        Retry previously failed shards. You almost always want this, and defaults to True.
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param(
        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL,

        [Boolean]$Explain = $True,

        [Boolean]$RetryFailed = $True
    )

    # Build URL parametersq
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ($Explain -eq $True){
        [Void]$UrlParameter.Append("&explain=true")
    }
    if ($RetryFailed -eq $True){
        [Void]$UrlParameter.Append("&retry_failed=true")
    }
    $UrlParameterString = $UrlParameter.ToString()

    # First URL parameter should be '?' not '&'
    if ($UrlParameterString -ne ''){
        $UrlParameterString = $UrlParameterString.Substring(1)
        $UrlParameterString = '?' + $UrlParameterString
    }

    # Build request
    $Request = '/_cluster/reroute' + $UrlParameterString

    $Params = @{
        'Request' = $Request
        'Method' = 'POST'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $Response = Invoke-OSCustomWebRequest @params
    $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100

    if ($Response.StatusCode -eq 200){
        return $ResponseContent
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Start-OSClusterShardReroute

