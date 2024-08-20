function Enable-OSPerformanceAnalyzer {
    <#
    .SYNOPSIS
        Enable the Performance Analyzer plugin.

    .DESCRIPTION
        Enable the Performance Analyzer plugin. This only runs the enable commmand, you may need to do more to configure it: https://opensearch.org/docs/latest/monitoring-your-cluster/pa/index/

    .PARAMETER RcaFramework
        Whether to enable the RCA (Root Cause Analysis) framework as well. https://opensearch.org/docs/latest/monitoring-your-cluster/pa/rca/index/

    .PARAMETER VerboseResponse
        Whether the output should include a more human readable Performance Analyzer status.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .LINK
        https://opensearch.org/docs/latest/monitoring-your-cluster/pa/index/

    .LINK
        https://opensearch.org/docs/latest/monitoring-your-cluster/pa/rca/index/

    .EXAMPLE
        Enable-OSPerformanceAnalyzer -RcaFramework

        Enable the Performance Analyzer plugin and Root Cause Analysis Framework
    #>
    [CmdletBinding()]
    param(
        [switch]$RcaFramework,

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

    $Body = @{
        'enabled' = $True
    } | ConvertTo-Json

    $Params = @{
        'Request' = $Request
        'Method' = 'POST'
        'Body' = $Body
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $Response = Invoke-OSCustomWebRequest @params

    # Optionally enable RCA Framework
    if ($Response.StatusCode -eq 200 -and
    $RcaFramework -eq $True){
        # Delay seems to be necessary for some reason
        Start-Sleep -Seconds 5

        # Build request
        $Request = '/_plugins/_performanceanalyzer/rca/cluster/config' + $UrlParameter

        $Body = @{
            'enabled' = $True
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
        $RcaResponseContent = $RcaResponse.Content | ConvertFrom-Json -Depth 100

        if ($RcaResponse.StatusCode -ne 200){
            throw $RcaResponseContent
        }
    }

    # Data seems to change since it runs the enable command, so double check after a few seconds
    Start-Sleep -Seconds 5
    $CurrentStatus = Get-OSPerformanceAnalyzerStatus -VerboseResponse $True -Credential $Credential -Certificate $Certificate -OpenSearchURL $OpenSearchURL

    # Handle Response - Successfully enabled
    if ($RcaFramework -eq $True){
        # Check that both were successfully enabled
        if ($CurrentStatus.PerformanceAnalyzerEnabled -eq $True -and
        $CurrentStatus.RcaEnabled -eq $True){
            Write-Warning 'Performance Analyzer and RCA framework are enabled, but additional configuration may be necessary: https://opensearch.org/docs/latest/monitoring-your-cluster/pa/index/'

            return $CurrentStatus
        }

    }
    else {
        if ($CurrentStatus.PerformanceAnalyzerEnabled -eq $True){
            Write-Warning 'Performance Analyzer is enabled, but additional configuration may be necessary: https://opensearch.org/docs/latest/monitoring-your-cluster/pa/index/'

            return $CurrentStatus
        }
    }

    # Handle Response - Failed enabling
    if ($Response.StatusCode -ne 200) {
        $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100

        throw $ResponseContent
    }
    else {
        throw 'Unable to enable Performance Analyzer for an unknown reason. Check your OpenSearch server and OpenSearch Performance Analyzer service logs. ' + $CurrentStatus
    }
}

Export-ModuleMember -Function Enable-OSPerformanceAnalyzer

