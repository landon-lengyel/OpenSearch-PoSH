function Remove-OSIndex {
    <#
    .SYNOPSIS
        Attempts to delete an index.

    .DESCRIPTION
        Delete's a specified index. Use NoConfirm parameter to bypass confirmation.
        Will redirect to Get-OSDataStream if Index is actually a data stream.

    .OUTPUTS
        Returns $null if index was successfully deleted.
        Returns $false if the index wasn't found.

    .PARAMETER Index
        Index you would like deleted.

    .PARAMETER NoConfirm
        Bypass deletion confirmation.

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
        [string]$Index,

        [switch]$NoConfirm,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Index must be lowercase - Otherwise it won't find the correct one to delete
    $Index = $Index.ToLower()

    # Check if index is a data stream
    $DataStream = Get-OSDataStream -DataStream $Index -Credential $Credential -Certificate $Certificate -OpenSearchURL $OpenSearchURL
    if ($null -ne $DataStream){
        if ($NoConfirm -eq $True){
            $Output = Remove-OSDataStream -DataStream $Index -NoConfirm -Credential $Credential -Certificate $Certificate -OpenSearchURL $OpenSearchURL
        }
        else {
            $Output = Remove-OSDataStream -DataStream $Index -Credential $Credential -Certificate $Certificate -OpenSearchURL $OpenSearchURL
        }
        
        return $Output
    }

    # Run deletion confirmation
    if ($NoConfirm -ne $True){
        if (Confirm-OSIndexExist -Index $Index -Credential $Credential -Certificate $Certificate -OpenSearchURL $OpenSearchURL){
            $DocCount = Get-OSIndexCount -Index $Index -Credential $Credential -Certificate $Certificate -OpenSearchURL $OpenSearchURL

            Write-Host "Please confirm that you want to delete index"
            Write-Host "Name: $Index"
            Write-Host "Document count: $($DocCount.count)"
            Write-Host ''
            Write-Host "Type `'YES`' to confirm deletion"
            $Confirmation = Read-Host

            if ($Confirmation -ne 'YES'){
                throw [System.Management.Automation.Host.HostException] "User did not confirm index deletion. Cancelling."
            }
        }
    }

    $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Index -Method "DELETE" -Credential $Credential -Certificate $Certificate

    # Return if successfully deleted
    if ($Response.StatusCode -eq 200){
        # index deleted successfully
        return
    }
    # Return $false if index doesn't exist
    elseif ($Response.StatusCode -eq 404){
        return $false
    }
    else{
        throw $Response
    }
}

Export-ModuleMember -Function Remove-OSIndex

