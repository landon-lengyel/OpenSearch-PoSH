function Get-OSIndexSetting {
    <#
    .SYNOPSIS
        Returns all index settings

    .DESCRIPTION
        Returns all data stored in index _settings. Settings are unecessarily buried in the return object with an index, but this is so it can support data streams as well.

    .PARAMETER Index
        Index name to get settings.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .EXAMPLE
        PS>$MySettings = Get-OSIndexSetting -Index 'test-index'
        PS>$MySettings.'test-index'.settings.index.blocks

        Check for blocked index.

    .EXAMPLE
        PS>$MySettings = Get-OSIndexSetting -Index 'test-index'
        PS>$UnixEpoch = $MySettings.'test-index'.settings.index.creation_date
        PS>(([System.DateTimeOffset]::FromUnixTimeMilliseconds($UnixEpoch)).DateTime.ToLocalTime())

        Get local time of index creation.
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Index,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Index name must be lowercase
    $Index = $Index.ToLower()

    $Request = $Index + '/_settings'

    $Response = Invoke-OSCustomWebRequest -Request $Request -Method "GET" -Credential $Credential -Certificate $Certificate -OpenSearchUrls $OpenSearchURL

    $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
    if ($Response.StatusCode -eq 200){
        return $ResponseContent
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Get-OSIndexSetting

