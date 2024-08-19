function Get-OSClusterShardAllocation {
    <#
    .SYNOPSIS
        Explains why unassigned shards cannot be allocated to any nodes.

    .DESCRIPTION
        Explains why unassigned shards cannot be allocated to any nodes. Add parameters to explain why a specific shard was allocated to it's node.

    .PARAMETER Index
        Name of a shards index. Data streams are NOT supported - use the backing indices.

    .PARAMETER IncludeYesDecisions
        Includes the numerous 'yes' decisions when allocating a shard to a node. Defaults to false.

    .PARAMETER IncludeDiskInfo
        Includes information about disk usage. Defauls to false.

    .PARAMETER CurrentNode
        Explain why the shard is on a specific node. The node's name.

    .PARAMETER Primary
        Output explanation of the primary shard (true) or it's first replica (false).

    .PARAMETER ShardId
        The ID of a shard to explain.

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

        [Switch]$IncludeYesDecisions,

        [Switch]$IncludeDiskInfo,

        [String]$CurrentNode,

        [Boolean]$Primary=$True,

        [String]$ShardId,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Build URL parameters
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ($IncludeYesDecisions -eq $True){
        [Void]$Urlparameter.Append('&include_yes_decisions=true')
    }
    if ($IncludeDiskInfo -eq $True){
        [Void]$Urlparameter.Append('&include_disk_info=true')
    }
    $UrlParameterString = $Urlparameter.ToString()

    # First URL parameter should be '?' not '&'
    if ($UrlParameterString -ne ''){
        $UrlParameterString = $UrlParameterString.Substring(1)
        $UrlParameterString = '?' + $UrlParameterString
    }

    # Build the request
    $Request = '_cluster/allocation/explain' + $UrlParameterString

    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
	    'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
        'ErrorAction' = 'SilentlyContinue'
    }

    $Body = @{}
    if ($CurrentNode -ne ''){
        $Body.current_node = $CurrentNode
    }
    if ($Index -ne ''){
        $Body.index = $Index
        $Body.primary = $Primary
    }
    if ($ShardId -ne ''){
        $Body.shard = $ShardId
        $Body.primary = $Primary
    }

    if ($Body -ne @{}){
        $Body = $Body | ConvertTo-Json -Depth 100
        $Params.Body = $Body
    }

    $Response = Invoke-OSCustomWebRequest @params
    $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100

    if ($Response.StatusCode -eq 200){
        return $ResponseContent
    }
    elseif ($Response.StatusCode -eq 400 -and $ResponseContent.error.root_cause.reason -like 'unable to find any unassigned shards to explain*'){
        # All shards are assigned, return
        return
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Get-OSClusterShardAllocation

