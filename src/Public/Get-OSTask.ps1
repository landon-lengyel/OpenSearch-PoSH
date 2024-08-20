function Get-OSTask {
    <#
    .SYNOPSIS
        Get a running task, or list of running tasks. Returns task object or $null if not found (possibly due to completion).

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .PARAMETER TaskId
        The OpenSearch assigned ID of a specific task.

    .PARAMETER nodes
        A comma-separated list of node IDs or names to limit the returned information. Use _local to return information from the node you’re connecting to, specify the node name to get information from specific nodes, or keep the parameter empty to get information from all nodes.

    .PARAMETER Actions
        A comma-separated list or wildcard expression of types of actions that should be returned.

    .PARAMETER Detailed
        Set to $True to return detailed task information. $False is default.

    .PARAMETER ParentTaskId
        Return all tasks with this parent task ID.

    .PARAMETER WaitForCompletion
        Halt script execution until the specified task(s) completes. $False is default.
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param(
        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL,

        [string]$TaskId,

        [string]$Nodes,

        [SupportsWildcards()]
        [string]$Actions,

        [boolean]$Detailed=$False,

        [string]$ParentTaskId,

        [boolean]$WaitForCompletion=$False
    )

    # URL Parameters
    $Request = '_tasks'

    # Beginning of the URL string
    if ($TaskId -ne ''){
        $Request += "/$TaskId"
    }

    # Every parameter is seperated by an '&' unless it is the first parameter then '?'
    if ($Nodes -ne ''){
        if ($Request -notmatch '\?') { $Request += '?' }
        else { $Request += '&' }
        $Request += "nodes=$Nodes"
    }
    if ($Actions -ne ''){
        if ($Request -notmatch '\?') { $Request += '?' }
        else { $Request += '&' }
        $Request += "actions=$Actions"
    }
    # Always shows detailed if task is specified. Throws error with detailed.
    if ($Detailed -eq $True -and $TaskId -eq ''){
        if ($Request -notmatch '\?') { $Request += '?' }
        else { $Request += '&' }
        $Request += "detailed=true"
    }
    if ($ParentTaskId -ne ''){
        if ($Request -notmatch '\?') { $Request += '?' }
        else { $Request += '&' }
        $Request += "parent_task_id=$ParentTaskId"
    }
    if ($WaitForCompletion -eq $True){
        if ($Request -notmatch '\?') { $Request += '?' }
        else { $Request += '&' }
        $Request += "wait_for_completion=true"
    }

    $Response = Invoke-OSCustomWebRequest -Method 'GET' -Request $Request -OpenSearchUrls $OpenSearchURL -Credential $Credential -Certificate $Certificate

    # Return success and errors
    if ($Response.StatusCode -eq 200){
        $Response = $Response.Content | ConvertFrom-Json -Depth 100
        return $Response
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Get-OSTask

