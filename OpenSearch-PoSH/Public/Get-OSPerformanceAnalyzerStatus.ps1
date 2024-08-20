function Get-OSPerformanceAnalyzerStatus {
    <#
    .SYNOPSIS
        See basic status of Performance Analyzer plugin.

    .DESCRIPTION
        See basic status of Performance Analzyer plugin, including whether or not it is enabled.
        If you've never changed cluster level Performance Analyzer settings in a multi-node cluster, the response may be inconsistent depending on which node you send the request to.

    .PARAMETER VerboseResponse
        Whether the output should include a more human readable Performance Analyzer status.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param(
        [bool]$VerboseResponse=$true,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Build URL parameters
    if ($VerboseResponse -eq $True){
        $UrlParameter = '?verbose'
    }

    # Build request
    $Request = '/_plugins/_performanceanalyzer/cluster/config' + $UrlParameter

    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $Response = Invoke-OSCustomWebRequest @params

    # Handle response
    $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100

    if ($Response.StatusCode -eq 200){
        # Combine the verbose response with the non-verbose response to create a more clean output
        if ($VerboseResponse -eq $True){
            $NewResponseContent = $ResponseContent.currentPerformanceAnalyzerClusterState

            foreach ($Member in $($ResponseContent | Get-Member -MemberType NoteProperty)){
                if ($Member.Name -ne 'currentPerformanceAnalyzerClusterState'){
                    $NewResponseContent | Add-Member -Name $Member.Name -Type NoteProperty -Value $ResponseContent.$($Member.Name)
                }
            }

            $ResponseContent = $NewResponseContent
        }

        return $ResponseContent
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Get-OSPerformanceAnalyzerStatus

