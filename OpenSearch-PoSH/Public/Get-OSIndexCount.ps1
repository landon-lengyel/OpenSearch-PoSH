function Get-OSIndexCount {
    <#
    .SYNOPSIS
        Returns count of documents and _shards in an index.

    .DESCRIPTION
        Returns an object describing the count of individual documents/entries in a specified index, as well as the _shard count for the index. Optionally can include queries to search for a count of documents that return. Supports data streams.

    .PARAMETER Index
        Index name to get count of, or comma seperated list of indices. Supports data streams.

    .PARAMETER AllowNoIndices
        If providing a list of indices, setting this to $false requires all indices are found to succeed. Defaults to $true.

    .PARAMETER Query
        JSON formatted search query to perform count against the index.

    .PARAMETER Analyzer
        Which analyzer to use with the query.

    .PARAMETER AnalyzeWildcard
        Analyze wildcards in queries. Default is $false.

    .PARAMETER ExpandWildcards
        Specify type of index to match. Supports comma seperated values: 'all' matches any index, 'open' match open, non-hidden indices, 'closed' match only closed, non-hidden indices, 'hidden' matchese hidden indices, and 'none' denies wildcard expressions (exact match). Default is 'open'.

    .PARAMETER DefaultOperator
        Default operator for string queries. Can be 'AND' or 'OR'. Defaults to 'OR'.

    .PARAMETER DefaultField
        Defaul field to use in case a field prefix is not provided in the query string.

    .PARAMETER IgnoreUnavailable
        Whether to include missing or closed indices in the response. Defaults to $false.

    .PARAMETER Lenient
        Whetehr to accept requests if queries have format errors, like querying text fields for integers. Defaults to $false.

    .PARAMETER MinScore
        Only includes documents with a minimum _score value based on the query.

    .PARAMETER Routing
        Route the search to a specific shard.

    .PARAMETER Preference
        Specifies which shard or node OpenSearch should perform the count on. Default is random.

    .PARAMETER TerminateAfter
        Maximum number of documents to count before terminating the request.

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
        [SupportsWildcards()]
        [string]$Index,

        [switch]$AllowNoIndices,

        [string]$Query,

        [string]$Analyzer,

        [switch]$AnalyzeWildcards,

        [string]$DefaultOperator,

        [string]$DefaultField,

        [switch]$IgnoreUnavailable,

        [switch]$Lenient,

        [int64]$MinScore,

        [string]$Routing,

        [string]$Preference,

        [int64]$TerminateAfter,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Index names must be lowercase
    $Index = $Index.ToLower()

    # Basic data validation
    if ($Query -eq ''){
        if ($Analyzer -ne ''){
            throw [System.ArgumentException] 'Analyzer cannot be specified if Query is empty'
        }
        if ($AnalyzeWildcards -ne $False){
            throw [System.ArgumentException] 'AnalyzeWildcards cannot be specified if Query is empty'
        }
        if ($DefaultOperator -ne ''){
            throw [System.ArgumentException] 'DefaultOperator cannot be specified if Query is empty'
        }
        if ($DefaultField -ne ''){
            throw [System.ArgumentException] 'DefaultField cannot be specified if Query is empty'
        }
        if ($Lenient -ne $False){
            throw [System.ArgumentException] 'Lenient cannot be specified if Query is empty'
        }
    }
    else {
        $QueryObj = $Query | ConvertFrom-Json -Depth 100

        # Users may not encase it in 'query' - do it for them
        if ($null -eq $QueryObj.query){
            $QueryObj = @{
                'query' = $QueryObj
            }
            $Query = $QueryObj | ConvertTo-Json -Depth 100
        }
    }

    # Build URL parameters
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ($AllowNoIndices -ne $False){
        [Void]$Urlparameter.Append("&allow_no_indices=true")
    }
    if ($Analyzer -ne ''){
        [Void]$Urlparameter.Append("&analyzer=$Analyzer")
    }
    if ($AnalyzeWildcards -ne $False){
        [Void]$Urlparameter.Append("&analyze_wildcard=true")
    }
    if ($DefaultOperator -ne ''){
        [Void]$Urlparameter.Append("&default_operator=$DefaultOperator")
    }
    if ($DefaultField -ne ''){
        [Void]$Urlparameter.Append("&df=$DefaultField")
    }
    if ($IgnoreUnavailable -ne $False){
        [Void]$Urlparameter.Append("&ignore_unavailable=true")
    }
    if ($Lenient -ne $False){
        [Void]$Urlparameter.Append("&lenient=true")
    }
    if ($MinScore -ne $null){
        [Void]$Urlparameter.Append("&min_score=$MinScore")
    }
    if ($Routing -ne ''){
        [Void]$Urlparameter.Append("&routing=$Routing")
    }
    if ($Preference -ne ''){
        [Void]$Urlparameter.Append("&preference=$Preference")
    }
    if ($TerminateAfter -ne ''){
        [Void]$Urlparameter.Append("&terminate_after=$TerminateAfter")
    }
    $UrlParameterString = $Urlparameter.ToString()

    # First URL parameter should be '?' not '&'
    if ($UrlParameterString -ne ''){
        $UrlParameterString = $UrlParameterString.Substring(1)
        $UrlParameterString = '?' + $UrlParameterString
    }

    # Build request
    $Request = $Index + '/_count' + $UrlParameterString

    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }
    if ($Query -ne ''){
        $Params.Body = $Query
    }
    $Response = Invoke-OSCustomWebRequest @params

    # Handle response
    $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
    if ($Response.StatusCode -eq 200){
        return $ResponseContent
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Get-OSIndexCount

