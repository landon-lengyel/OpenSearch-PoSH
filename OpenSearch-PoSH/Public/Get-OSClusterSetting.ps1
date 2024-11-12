function Get-OSClusterSetting {
    <#
    .SYNOPSIS
        Shows all cluster level settings.

    .DESCRIPTION
        Shows all cluster level settings.

    .PARAMETER IncludeDefaults
        Enable to include default settings in the response.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeDefaults,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    $Request = "_cluster/settings"

    if ($IncludeDefaults -eq $true){
        $Request += '?include_defaults=true'
    }

    # Build web request parameters
    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }
    $Response = Invoke-OSCustomWebRequest @Params

    $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
    if ($Response.StatusCode -eq 200){
        return $ResponseContent
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Get-OSClusterSetting
