function Get-OSIndexMapping {
    <#
    .SYNOPSIS
        Returns all index mappings.

    .DESCRIPTION
        Returns all data stored in index _mapping.

    .PARAMETER Index
        Index name to get settings.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .EXAMPLE
        PS>$MySettings = Get-OSIndexMapping -Index 'test-index'

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

    $Request = $Index + '/_mapping'

    $Response = Invoke-OSCustomWebRequest -Request $Request -Method "GET" -Credential $Credential -Certificate $Certificate -OpenSearchUrls $OpenSearchURL

    $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100 -AsHashtable
    if ($Response.StatusCode -eq 200){
        return $ResponseContent
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Get-OSIndexMapping

