function Invoke-OSReIndex {
    <#
    .SYNOPSIS
        Starts a Re-index operation.

    .DESCRIPTION
        Starts a re-index operation on a specific index in the OpenSearch cluster. Re-index operations are how data is migrated, moved, combined, etc. If WaitForCompletion is $True it will return an object describing the re-index operation. If WaitForCompletion is $False (default) it will return a Task Id and run in the background. Regardless, stopping PowerShell execution will *not* stop reindex operation.

    .PARAMETER SourceIndex
        Name of the source index.

    .PARAMETER DestinationIndex
        Name of the destination index.

    .PARAMETER WaitForCompletion
        If $True, pause script execution until the re-index operation completes. This can take a long time. $False is default.

    .PARAMETER MaxDocs
        Maximum number of documents to re-index. Default is all.

    .PARAMETER Slices
        Number of sub-tasks to divide the task into. Default is 1. Set to 'auto' to automatically decide, or another number.

    .PARAMETER RequestsPerSecond
        Throttle requests per second. Default does not throttle.

    .PARAMETER SourceQuery
        Optional JSON DSL query to only re-index if it matches the query.

    .PARAMETER OpType
        'index' (default) copies everything missing from the source index. 'create' ignores documents with the same doc id. Data streams only support 'create'.

    .PARAMETER IngestPipeline
        Name of an ingest pipeline to use during reindex.

    .PARAMETER IgnoreConflicts
        Ignores version conflicts using the "proceed" option for conflicts.

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
        [Parameter(Mandatory)]
        [string]$SourceIndex,

        [Parameter(Mandatory)]
        [string]$DestinationIndex,

        [switch]$WaitForCompletion,

        [int]$MaxDocs=-1,

        $Slices,

        [int]$RequestsPerSecond=-1,

        [hashtable]$SourceQuery,

        [string]$OpType,

        [string]$IngestPipeline,

        [switch]$IgnoreConflicts,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Data validation
    if ($null -ne $Slices){
        if ($Slices.GetType().Name -eq 'String'){
            if ($Slices -ne 'auto'){
                throw "Slices must be either the string 'auto', or an integer."
            }
        }
        elseif ($Slices.GetType().Name -ne 'Int32' -and $Slices.GetType().Name -ne 'Int64'){
            throw "Slices must be either the string 'auto', or an integer."
        }
    }
    if ($OpType -ne ''){
        if ($OpType -ne 'index' -and $OpType -ne 'create'){
            throw "OpType must be either 'index' or 'create'"
        }
    }

    # Only lowercase index names are allowed
    $SourceIndex = $SourceIndex.ToLower()
    $DestinationIndex = $DestinationIndex.ToLower()

    # URL parameters
    $Request = '/_reindex'

    # Every parameter is seperated by an '&' unless it is the first parameter then '?'
    if ($null -ne $Slices){
        if ($Request -notmatch '\?') { $Request += '?' }
        else { $Request += '&' }
        $Request += "slices=$Slices"
    }
    if ($MaxDocs -ne -1){
        if ($Request -notmatch '\?') { $Request += '?' }
        else { $Request += '&' }
        $Request += "max_docs=$MaxDocs"
    }
    if ($RequestsPerSecond -ne -1){
        if ($Request -notmatch '\?') { $Request += '?' }
        else { $Request += '&' }
        $Request += "requests_per_second=$RequestsPerSecond"
    }
    if ($Request -match '_reindex$') { $Request += '?' }
    elseif ($Request -match '\?') { $Request += '&' }
    # Wait for completion will always be added - they claim 'false' is default but that's not the behavior I've seen
    if ($WaitForCompletion -ne $True){
        $Request += "wait_for_completion=false"
    }
    else {
        $Request += "wait_for_completion=true"
    }

    # Build body
    $Body = @{
        'source' = @{
            'index' = $SourceIndex
        }
        'dest' = @{
            'index' = $DestinationIndex
        }
    }

    # Body parameters
    if ($IngestPipeline -ne ''){
        $Body.dest.pipeline = $IngestPipeline
    }
    if ($OpType -ne ''){
        $Body.dest.op_type = $OpType
    }
    if ($null -ne $SourceQuery){
        # Very likely some will pass 'query' as the first hashtable, but not guranteed
        if ($SourceQuery.Keys[0] -eq 'query'){
            $Body.source += $SourceQuery
        }
        else {
            $Body.source.query = $SourceQuery
        }
    }
    if ($IgnoreConflicts -eq $true){
        $body.'conflicts' = 'proceed'
    }

    $Body = $Body | ConvertTo-Json -Depth 100

    $Response = Invoke-OSCustomWebRequest -Method 'POST' -Request $Request -OpenSearchUrls $OpenSearchURL -Credential $Credential -Certificate $Certificate -Body $Body

    # Return success and errors
    if ($Response.StatusCode -eq 200){
        $Response = $Response.Content | ConvertFrom-Json -Depth 100
        return $Response
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Invoke-OSReIndex

