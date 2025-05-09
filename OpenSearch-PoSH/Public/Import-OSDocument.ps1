function Import-OSDocument {
    <#
    .SYNOPSIS
        Adds document to an index.

    .DESCRIPTION
        Adds a single specified document to an index. Returns an object describing the import.

    .PARAMETER Index
        Name of the index to add to.

    .PARAMETER Document
        Hashtable of data to add to the index.

    .PARAMETER DocumentId
        Optionally include an _id to index the document at. Do not specify to have OpenSearch generate one.

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
        [string]$Index,

        [Parameter(Mandatory, ValueFromPipeline)]
        [hashtable]$Document,

        [string]$DocumentId,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Only lowercase index names are allowed
    $Index = $Index.ToLower()

    # Build the request
    $Body = $Document | ConvertTo-Json -Depth 100

    # PUT needed for custom _id fields. Otherwise POST
    if ($DocumentId -ne ''){
        $Request = $Index + '/_doc/' + $DocumentId
        $Response = Invoke-OSCustomWebRequest -Method 'PUT' -Request $Request -OpenSearchUrls $OpenSearchURL -Credential $Credential -Certificate $Certificate -Body $Body
    }
    else {
        $Request = $Index + '/_doc'
        $Response = Invoke-OSCustomWebRequest -Method 'POST' -Request $Request -OpenSearchUrls $OpenSearchURL -Credential $Credential -Certificate $Certificate -Body $Body
    }

    if ($Response.StatusCode -eq '201' -or
    $Response.StatusCode -eq '200'){
        $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
        return $ResponseContent
    }
    else {
        throw $Response
    }

}

Export-ModuleMember -Function Import-OSDocument

