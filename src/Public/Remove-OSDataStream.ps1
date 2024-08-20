function Remove-OSDataStream {
    <#
    .SYNOPSIS
        Deletes an existing data stream.

    .PARAMETER DataStream
        Name of the data stream to delete.

    .PARAMETER NoConfirm
        Bypass deletion confirmation.

    .DESCRIPTION
        Delete's a specified data stream and it's backign indices.

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
        [string]$DataStream,

        [switch]$NoConfirm,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    #Only lowercase names are allowed
    $DataStream = $DataStream.ToLower()

    # Run deletion confirmation
    if ($NoConfirm -ne $True){
        if (Confirm-OSIndexExist -Index $DataStream -Credential $Credential -Certificate $Certificate -OpenSearchURL $OpenSearchURL){
            $DocCount = Get-OSIndexCount -Index $DataStream -Credential $Credential -Certificate $Certificate -OpenSearchURL $OpenSearchURL

            Write-Host "Please confirm that you want to delete data stream"
            Write-Host "Name: $DataStream"
            Write-Host "Document count: $($DocCount.count)"
            Write-Host ''
            Write-Host "Type `'YES`' to confirm deletion"
            $Confirmation = Read-Host

            if ($Confirmation -ne 'YES'){
                throw [System.Management.Automation.Host.HostException] "User did not confirm index deletion. Cancelling."
            }
        }
    }

    # Build request
    $Request = '_data_stream'

    if ($DataStream -ne ''){
        $Request += "/$DataStream"
    }

    $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Method "DELETE" -Credential $Credential -Certificate $Certificate
    $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100

    # Return $null if successfully deleted
    if ($Response.StatusCode -eq 200){
        return
    }
    # Return $false if Data stream doesn't exist
    elseif ($Response.StatusCode -eq 404){
        return $false
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Remove-OSDataStream

