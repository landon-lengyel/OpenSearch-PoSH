function Disable-OSPerformanceAnalyzer {
    <#
    .SYNOPSIS
        Disable the Performance Analyzer plugin.

    .DESCRIPTION
        Disable the Performance Analyzer plugin. This only runs the disable commmands, pauses and waits for you to complete node action(s): https://opensearch.org/docs/latest/monitoring-your-cluster/pa/index/#disable-performance-analyzer

    .PARAMETER VerboseResponse
        Whether the output should include a more human readable Performance Analyzer status.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
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

    # Disable any Root Cause Analysis (RCA) agents
    # Build request
    $Request = '/_plugins/_performanceanalyzer/rca/cluster/config' + $UrlParameter

    $Params = @{
        'Request' = $Request
        'Method' = 'POST'
        'Body' = $Body
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $Response = Invoke-OSCustomWebRequest @params

    if ($Response.StatusCode -ne 200){
        throw $Response
    }

    Write-Warning "You should now stop any Performance Analyzer RCA Agent on your nodes with:`nkill `$(ps aux | grep -i 'PerformanceAnalyzerApp' | grep -v grep | awk '{print `$2}')"
    pause

    # Disable Performance Analzyer Plugin
    # Build request
    $Request = '/_plugins/_performanceanalyzer/cluster/config' + $UrlParameter

    $Body = @{
        'enabled' = $False
    } | ConvertTo-Json

    $Params = @{
        'Request' = $Request
        'Method' = 'POST'
        'Body' = $Body
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $RcaResponse = Invoke-OSCustomWebRequest @params

    if ($RcaResponse.StatusCode -ne 200){
        throw $RcaResponse
    }

    # Data seems to change since it runs the enable command, so double check after a few seconds
    Start-Sleep -Seconds 5
    $CurrentStatus = Get-OSPerformanceAnalyzerStatus -VerboseResponse $True -Credential $Credential -Certificate $Certificate -OpenSearchURL $OpenSearchURL

    # Handle Response - Successfully disabled
    if ($CurrentStatus.PerformanceAnalyzerEnabled -eq $False -and
    $CurrentStatus.RcaEnabled -eq $False){
        return $CurrentStatus
    }
    # Handle Response - Failed disabling
    else {
        throw 'Unable to disable Performance Analyzer for an unknown reason. Check your OpenSearch server and OpenSearch Performance Analyzer service logs. ' + $CurrentStatus
    }
}

Export-ModuleMember -Function Disable-OSPerformanceAnalyzer

