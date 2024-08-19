function New-OSIngestPipeline {
    <#
    .SYNOPSIS
        Creates an ingest pipeline with the provided options.

    .DESCRIPTION
        Ingest pipelines can process and transform data coming into OpenSearch. They can only be managed through the API. Note that failures, such as missing fields, will stop it without 'ignore_failure' set to $True on the processor.

    .PARAMETER PipelineName
        Name to create the Ingest Pipeline as.

    .PARAMETER PipelineDescription
        Description to assign to the Ingest Pipeline.

    .PARAMETER PipelineProcessors
        Array of hashtables containing processors to perform on the data. Include 'ignore_failure' to $True per-processor to ignore missing fields (among other failures).

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

        [Parameter(Mandatory)]
        [string]$PipelineDescription,

        [Parameter(Mandatory)]
        [array]$PipelineProcessors,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Basic data validation
    if ($PipelineProcessors[0].GetType().Name -ne 'Hashtable'){
        throw '$PipelineProcessors must be specified as an array that contains hashtables'
    }

    # Build the request
    $Body = @{
        'description' = $PipelineDescription
        'processors' = $PipelineProcessors
    } | ConvertTo-Json -Depth 100

    $Request = "_ingest/pipeline/$PipelineName"

    $Response = Invoke-OSCustomWebRequest -Method 'PUT' -Request $Request -OpenSearchUrls $OpenSearchURL -Credential $Credential -Certificate $Certificate -Body $Body
    if ($Response.StatusCode -eq 200){
        return
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function New-OSIngestPipeline

