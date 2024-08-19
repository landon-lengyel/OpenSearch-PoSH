function Remove-OSIngestPipeline {
    <#
    .SYNOPSIS
        Deletes an Ingest Pipeline with the specified name.

    .PARAMETER PipelineName
        Name of the Ingest Pipeline to delete.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PipelineName,        
        
        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    $Request = "_ingest/pipeline/$PipelineName"

    $Response = Invoke-OSCustomWebRequest -Method 'DELETE' -Request $Request -OpenSearchUrls $OpenSearchURL -Credential $Credential -Certificate $Certificate
    if ($Response.StatusCode -eq 200){
        return
    }
    else {
        throw "Ingest pipeline failed to delete $Response"
    }
}

Export-ModuleMember -Function Remove-OSIngestPipeline

