function Find-OSAdvanced {
    <#
    .SYNOPSIS
        A thin wrapper around the search API to benefit from this modules authentication mechanism, but otherwise allow the user to build the query themselves.

    .DESCRIPTION
        A thin wrapper around the search API to benefit from this modules authentication mechanism, but otherwise allow the user to build the query themselves.
        Documentation of options found at OpenSearch: https://docs.opensearch.org/latest/api-reference/search-apis/search/

    .PARAMETER Index
        Name of the OpenSearch index to search.

    .PARAMETER QueryParameters
        Full URL paramters to pass along with the request. Options found under "Query parameters". Script will not further process this value, make sure they are URL encoded.

    .PARAMETER RequestBody
        Full body parameters to pass along with the request. Options found under "Request bdy". Script will not further process this value, make sure it is proper JSON.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param (
        [String]$Index,

        [String]$QueryParameters,

        [String]$RequestBody,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Index name needs to be lowercase
    $Index = $Index.ToLower()

    # Build request
    if ($Index -eq ''){
        $Request = '/_search' + $QueryParameters
    }
    else {
        $Request = $Index + '/_search' + $QueryParameters
    }

    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
	    'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
        'Body' = $RequestBody
    }

    $Response = Invoke-OSCustomWebRequest @Params

    # Handle response
    if ($Response.StatusCode -eq 200){
        $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100

        return $ResponseContent
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Find-OSAdvanced
