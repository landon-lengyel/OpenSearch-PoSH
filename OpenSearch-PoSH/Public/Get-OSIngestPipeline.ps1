function Get-OSIngestPipeline {
    <#
    .SYNOPSIS
        Get a list of all ingest pipelines.

    .DESCRIPTION
        Ingest pipelines can process and transform data coming into OpenSearch. They can only be managed through the API.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param(
        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    $Request = "_ingest/pipeline"

    $Response = Invoke-OSCustomWebRequest -Method 'GET' -Request $Request -OpenSearchUrls $OpenSearchURL -Credential $Credential -Certificate $Certificate -Body $Body -ErrorAction SilentlyContinue

    if ($Response.StatusCode -eq 200){
        $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
        return $ResponseContent
    }
    elseif ($Response.StatusCode -eq 404){
        return $null
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Get-OSIngestPipeline

