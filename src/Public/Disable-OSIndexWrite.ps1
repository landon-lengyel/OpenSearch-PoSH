function Disable-OSIndexWrite {
    <#
    .SYNOPSIS
        Blocks write operations on an index, optionally allows delete operations.

    .DESCRIPTION
        Uses the index _settings to block write operations. You can continue to allow delete operations, or you can block that too and make the index truly read-only.

    .PARAMETER Index
        Index name to block writes.

    .PARAMETER AllowDelete
        Enable allowing delete operations, while blocking all other write operations.
        
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
        [Parameter(Mandatory=$true)]
        [string]$Index,

        [switch]$AllowDelete,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )


    $Request = $Index + '/_settings'

    if ($AllowDelete -eq $True){
        $Body = @{
            'index.blocks.read_only_allow_delete' = $True
        }
    }
    else {
        $Body = @{
            'index.blocks.read_only' = $True
        }
    }
    $Body = $Body | ConvertTo-Json -Depth 100

    $Response = Invoke-OSCustomWebRequest -Request $Request -Body $Body -Method "PUT" -Credential $Credential -Certificate $Certificate -OpenSearchUrls $OpenSearchURL

    $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
    if ($Response.StatusCode -eq 200 -and
    $ResponseContent.acknowledged -eq $True){
        return $ResponseContent.acknowledged
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Disable-OSIndexWrite

