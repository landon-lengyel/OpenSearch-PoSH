function Get-OSClusterHealth {
    <#
    .SYNOPSIS
        Gets an overview of your clusters health.

    .DESCRIPTION
        Gets an overview of your clusters health.
         - Green: All primary and replica shards are allocated.
         - Yellow: All primary shards are allocated, some replicas are not.
         - Red: At least one primary shard is not allocated.

    .PARAMETER Index
        Return health related to a particular index.

    .PARAMETER ExpandWildcards
        Expands wildcard expressions to different indexes. Combine multiple values with commas. Available values are all (match all indexes), open (match open indexes), closed (match closed indexes), hidden (match hidden indexes), and none (do not accept wildcard expressions). Default is open.

    .PARAMETER Level
        The level of detail for returned health information.

    .PARAMETER AwarenessAttribute
        The name of the awareness attribute, for which to return cluster health (for example, zone). Applicable only if level is set to awareness_attributes.

    .PARAMETER LocalNodeOnly
        Set to True to return information from the LocalNodeOnly node only, instead of the cluster manager node.

    .PARAMETER ClusterManagerTimeout
        Amount of time to wait for a connection to the cluster manager node, expressed in seconds. Default is 30.

    .PARAMETER Timeout
        Amount of time to wait for a response, expressed in seconds. Default is 30.

    .PARAMETER WaitForActiveShards
        Wait until a specific number of shards is active before returning a response. Overridden by WaitForAllActiveShards.

    .PARAMETER WaitForAllActiveShards
        Wait for all shards are active before returning a response. Overrides WaitForActiveShards.

    .PARAMETER WaitForNodes
        Wait for this number of nodes. Supports exact match (ex: 12) or ranges (ex: <12) (ex: >12)

    .PARAMETER WaitForEvents
        Wait until all currently queued events with the given priority are processed.

    .PARAMETER WaitForNoRelocatingShards
        Whether to wait until there are no relocating shards in the cluster. Default is false.

    .PARAMETER WaitForNoInitializingShards
        Whether to wait until there are no initializing shards in the cluster. Default is false.

    .PARAMETER WaitForStatus
        Wait until the cluster health reaches the specified status or better.

    .PARAMETER Weights
        (JSON Object) Assigns weights to attributes within the request body of the PUT request. Weights can be set in any ration, for example, 2:3:5. In a 2:3:5 ratio with three zones, for every 100 requests sent to the cluster, each zone would receive either 20, 30, or 50 search requests in a random order. When assigned a weight of 0, the zone does not receive any search traffic.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .EXAMPLE
        Get-OSClusterHealth

    .EXAMPLE
        Get-OSClusterHealth -Indices @('MyFirstIndex','MySecondIndex')

    .EXAMPLE
        Get-OSClusterHealth -Indices 'MyIndex'
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param(
        [Array]$Index,

        [ValidateSet('all','open','closed','hidden','none')]
        [String]$ExpandWildcards='open',

        [ValidateSet('cluster','indices','shards','awareness_attributes')]
        [String]$Level='cluster',

        [String]$AwarenessAttribute,

        [Boolean]$LocalNodeOnly=$False,

        [Int64]$ClusterManagerTimeout=30,

        [Int64]$Timeout=30,

        [Int64]$WaitForActiveShards=0,

        [Boolean]$WaitForAllActiveShards=$False,

        [String]$WaitForNodes,

        [ValidateSet('immediate','urgent','high','normal','low','languid')]
        [String]$WaitForEvents,

        [Boolean]$WaitForNoRelocatingShards = $False,

        [Boolean]$WaitForNoInitializingShards = $False,

        [ValidateSet('green','yellow','red')]
        [String]$WaitForStatus,

        [String]$Weights,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Index names must be lowercase
    if ($null -ne $Index){
        for ($IndexCount=0; $IndexCount -lt $Index.Count; $IndexCount++){
            $Index[$IndexCount] = $Index[$IndexCount].ToLower()
        }
    }

    # Build URL parametersq
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ($ExpandWildcards -ne 'open'){
        [Void]$UrlParameter.Append("&expand_wildcards=$ExpandWildcards")
    }
    if ($Level -ne 'cluster'){
        [Void]$UrlParameter.Append("&level=$Level")
    }
    if ($AwarenessAttribute -ne ''){
        [Void]$UrlParameter.Append("&awareness_attribute=$AwarenessAttribute")
    }
    if ($LocalNodeOnly -ne $False){
        [Void]$UrlParameter.Append('&local=true')
    }
    if ($ClusterManagerTimeout -ne 30){
        [Void]$UrlParameter.Append("&cluster_manager_timeout=$ClusterManagerTimeout")
    }
    if ($Timeout -ne 30){
        [Void]$UrlParameter.Append("&timeout=$Timeout")
    }
    if ($WaitForActiveShards -ne 0 -and $WaitForAllActiveShards -eq $False){
        [Void]$UrlParameter.Append("&wait_for_active_shards=$WaitForActiveShards")
    }
    elseif($WaitForAllActiveShards -eq $True){
        [Void]$UrlParameter.Append('&wait_for_active_shards=all')
    }
    if ($WaitForNodes -ne ''){
        [Void]$UrlParameter.Append("&wait_for_nodes=$WaitForNodes")
    }
    if ($WaitForEvents -ne ''){
        [Void]$UrlParameter.Append("&wait_for_events=$WaitForEvents")
    }
    if ($WaitForNoRelocatingShards -ne $False){
        [Void]$UrlParameter.Append('&wait_for_no_relocating_shards=true')
    }
    if ($WaitForNoInitializingShards -ne $False){
        [Void]$UrlParameter.Append('&wait_for_no_initializing_shards=true')
    }
    if ($WaitForStatus -ne ''){
        [Void]$UrlParameter.Append("&wait_for_status=$WaitForStatus")
    }
    if ($weights -ne ''){
        [Void]$UrlParameter.Append("&weights=$Weights")
    }
    $UrlParameterString = $UrlParameter.ToString()

    # First URL parameter should be '?' not '&'
    if ($UrlParameterString -ne ''){
        $UrlParameterString = $UrlParameterString.Substring(1)
        $UrlParameterString = '?' + $UrlParameterString
    }


    # Adjust the output field seperator (ofs) to cast array as string
    $OldOfs = $OFS
    $ofs = ','

    # Build request
    if ($Index -ne ''){
        $Request = '/_cluster/health/' + [String]$Index + $UrlParameterString
    }
    else {
        $Request = '/_cluster/health' + $UrlParameterString
    }

    $ofs = $OldOfs

    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
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

Export-ModuleMember -Function Get-OSClusterHealth

