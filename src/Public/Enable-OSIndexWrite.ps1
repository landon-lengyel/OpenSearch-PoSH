function Enable-OSIndexWrite {
    <#
    .SYNOPSIS
        Un-blocks write operations on an index. Inverse of Disable-OSIndexWrite

    .DESCRIPTION
        Uses the index _settings to remove any blocked write operations. Essentially undoes all changes from Disable-OSIndexWrite

    .PARAMETER Index
        Index name to un-block writes.

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
        [Parameter(Mandatory=$true)]
        [string]$Index,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    $Request = $Index + '/_settings'

    $Body = @{
        'index.blocks.read_only_allow_delete' = $null
        'index.blocks.read_only' = $null
    } | ConvertTo-Json -Depth 100

    $Response = Invoke-OSCustomWebRequest -Request $Request -Body $Body -Method "PUT" -Credential $Credential -Certificate $Certificate -OpenSearchUrls $OpenSearchURL

    $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
    if ($Response.StatusCode -eq 200 -and
    $ResponseContent.acknowledged -eq $True){
        return $ResponseContent.acknowledged
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Enable-OSIndexWrite

