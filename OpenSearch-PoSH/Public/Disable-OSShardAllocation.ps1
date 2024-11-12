function Disable-OSShardAllocation {
    <#
    .SYNOPSIS
        Disable automatic cluster shard allocation for your cluster.

    .DESCRIPTION
        Disable automatic cluster shard allocation for your cluster. This is useful when performing cluster changes. Returns no value if successful, otherwise throws an error.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param(
        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    $Request = "_cluster/settings"

    $Body = @{
        'persistent' = @{
            'cluster.routing.allocation.enable' = 'none'
        }
    } | ConvertTo-Json -Depth 100

    # Build web request parameters
    $Params = @{
        'Request' = $Request
        'Method' = 'PUT'
        'Body' = $Body
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }
    $Response = Invoke-OSCustomWebRequest @Params

    $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
    if ($Response.StatusCode -eq 200 -and
    $ResponseContent.acknowledged -eq $True){
        return
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Disable-OSShardAllocation
