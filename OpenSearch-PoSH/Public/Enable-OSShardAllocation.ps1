function Enable-OSShardAllocation {
    <#
    .SYNOPSIS
        Enables automatic cluster shard allocation for your cluster.

    .DESCRIPTION
        Enables automatic cluster shard allocation for your cluster. This is useful after performing cluster changes. Returns no value if successful, otherwise throws an error.

    .PARAMETER ShardType
        What shard type to enable shard allocation for.
            - all: Allows shard allocation for all types of shards.
            - primaries: Allows shard allocation for primary shards only.
            - new_primaries: Allows shard allocation for primary shards for new indices only.
            - none: No shard allocations are allowed for any indices. Use Disable-OSShardAllocation for this option.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('all','primaries','new_primaries')]
        [string]$ShardType='all',

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    $Request = "_cluster/settings"

    $Body = @{
        'persistent' = @{
            'cluster.routing.allocation.enable' = $ShardType
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

Export-ModuleMember -Function Enable-OSShardAllocation
