function Confirm-OSIndexExist {
    <#
    .SYNOPSIS
        Check whether index exists or not. Returns $true or $false

    .DESCRIPTION
        Checks whether an index exists or not. Returns $true or $false. Includes Data Streams (aliases).
        Can expand wildcards by default, but that can be disabled by changing ExpandWildcards to 'none'
        Will return closed and missing indices by default, but that can be disabled by setting IgnoreUnavailable.

    .PARAMETER Index
        Name of the index to confirm.

    .PARAMETER ExpandWildcards
        Expands wildcard expressions to different indexes. Combine multiple values with commas. Available values are all (match all indexes), open (match open indexes), closed (match closed indexes), hidden (match hidden indexes), and none (do not accept wildcard expressions). Default is open.

    .PARAMETER IgnoreUnavailable
        Optionally ignore indices that are missing or closed.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        An array of strings, or just a string of OpenSearch URLs.
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [SupportsWildcards()]
        [string]$Index,

        [ValidateSet('all','open','closed','hidden','none')]
        [String]$ExpandWildcards='open',

        [switch]$IgnoreUnavailable,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Only lowercase index names are allowed
    $Index = $Index.ToLower()

    # Build request
    $Body = @{
        'expand_wildcards' = $ExpandWildcards
    }
    if ($IgnoreUnavailable){
        $Body = $Body + @{
            'ignore_unavailable' = 'true'
        }
    }
    $Body = $Body | ConvertTo-Json -Depth 100
    $Request = $Index

    $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Credential $Credential -Certificate $Certificate -Method 'HEAD' -Body $Body

    if ($Response.StatusCode -eq 200){
        return $True
    }
    elseif ($Response.StatusCode -eq 404){
        return $False
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Confirm-OSIndexExist

