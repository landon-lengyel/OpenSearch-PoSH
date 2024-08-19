function Get-OSNodeProperties {
    <#
    .SYNOPSIS
        Returns all node properties.

    .PARAMETER LocalNodeOnly
        Return only the locally querired node's properties.

    .PARAMETER ClusterManagerNodeOnly
        Return only the current cluster manager node's properties.

    .PARAMETER AllNode
        Return all nodes.
    
    .PARAMETER NodeName
        Return only the specified node's properties by name. Case senstitive, wildcards supported.

    .PARAMETER NodeHostName
        Return only the specified node's properties by hostname. Case senstitive, wildcards supported.

    .PARAMETER NodeIp
        Return only the specified node's properties by IP address. Wildcards supported.

    .PARAMETER NodeId
        Return only the specified node's properties by it's unique ID. Must be exact match.

    .PARAMETER NodeAttribute
        Filter to node(s) with specific attribute/value pair(s). Both attribute and value support wildcards.

    .PARAMETER CustomNodeFilter
        Advanced: Custom node filter to pass through pased on: https://opensearch.org/docs/latest/api-reference/nodes-apis/index/#node-filters

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding(DefaultParameterSetName="AllNode")]
    param(
        # Use parameter sets to prevent using conflicting parameters
        [Parameter(ParameterSetName = 'LocalNodeOnly',Mandatory)]
        [switch]$LocalNodeOnly,

        [Parameter(ParameterSetName = 'ClusterManagerNode',Mandatory)]
        [switch]$ClusterManagerNodeOnly,

        [Parameter(ParameterSetName = 'AllNode')]
        [bool]$AllNode=$True,

        [Parameter(ParameterSetName = 'NodeName',Mandatory)]
        [SupportsWildcards()]
        [string]$NodeName,

        [Parameter(ParameterSetName = 'NodeHostName',Mandatory)]
        [SupportsWildcards()]
        [string]$NodeHostName,

        [Parameter(ParameterSetName = 'NodeIp',Mandatory,ValueFromPipeline)]
        [SupportsWildcards()]
        [string]$NodeIp,

        [Parameter(ParameterSetName = 'NodeId',Mandatory)]
        [string]$NodeId,

        [Parameter(ParameterSetName = 'NodeAttribute',Mandatory)]
        [SupportsWildcards()]
        [hashtable]$NodeAttribute,

        [Parameter(ParameterSetName = 'CustomNodeFilter',Mandatory)]
        [SupportsWildcards()]
        [string]$CustomNodeFilter,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Build URL Request (only one can be used at a time)
    $RequestBuilder = [System.Text.StringBuilder]::new()
    [Void]$RequestBuilder.Append('/_nodes/')

    if ($PSCmdlet.ParameterSetName -eq 'AllNode'){
        # No parameter set means _all (default)
        [Void]$RequestBuilder.Append('_all')
    }
    elseif ($LocalNodeOnly -eq $True){
        [Void]$RequestBuilder.Append('_local')
    }
    elseif ($ClusterManagerNodeOnly -eq $True){
        [Void]$RequestBuilder.Append('_cluster_manager')
    }
    elseif ($NodeName -ne ''){
        [Void]$RequestBuilder.Append($NodeName)
    }
    elseif ($NodeHostName -ne ''){
        [Void]$RequestBuilder.Append($NodeHostName)
    }
    elseif ($NodeIp -ne ''){
        [Void]$RequestBuilder.Append($NodeIp)
    }
    elseif ($NodeId -ne ''){
        [Void]$RequestBuilder.Append($NodeId)
    }
    elseif ($null -ne $NodeAttribute){
        # Hashtable value requires a bit more formatting: Key:Value,Key2:Value2
        foreach ($Item in $NodeAttribute.GetEnumerator()){
            [Void]$RequestBuilder.Append($Item.Name)
            [Void]$RequestBuilder.Append(':')
            [Void]$RequestBuilder.Append($Item.Value)

            [Void]$RequestBuilder.Append(',')
        }
        
        # Remove final comma
        $FinalComma = $RequestBuilder.Length - 1
        [Void]$RequestBuilder.Remove($FinalComma, 1)
    }

    [Void]$RequestBuilder.Append('/_stats')

    # Build request
    $Request = $RequestBuilder.ToString()

    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
	    'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $Response = Invoke-OSCustomWebRequest @params

    # Handle response
    if ($Response.StatusCode -eq 200){
        $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
        return $ResponseContent
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Get-OSNodeProperties

