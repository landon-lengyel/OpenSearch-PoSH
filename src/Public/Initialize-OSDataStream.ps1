function Initialize-OSDataStream {
    <#
    .SYNOPSIS
        Attempts to create a DataStream

    .DESCRIPTION
        Has no real advantage over simply writing documents to a data stream, as it will be created from the template regardless.
        DataTypes and mappings must be defined in teh Data Stream template. Not this function.
        Failure to create it due to it already existing is considered success.

    .PARAMETER Index
        Index you would like the data to be added to.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DataStreamName,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    #Only lowercase names are allowed
    $DataStreamName = $DataStreamName.ToLower()

    $Request = '/_data_stream/' + $DataStreamName
    $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Method "PUT" -Credential $Credential -Certificate $Certificate

    if ($Response.StatusCode -eq 200){
        # index created successfully
        return
    }
    elseif ($Response.StatusCode -eq 400){
        $ResponseObj = $Response.Content | ConvertFrom-Json -Depth 100
        if ($ResponseObj.error.type -eq 'resource_already_exists_exception'){
            # index already exists
            return
        }
        else {
            throw $Response
        }
    }
    else{
        throw $Response
    }
}

Export-ModuleMember -Function Initialize-OSDataStream

