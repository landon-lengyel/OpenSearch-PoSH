function Find-OS {
    <#
    .SYNOPSIS
        (BETA) Advanced search function.

    .DESCRIPTION
        Advanced search function. Implements most options, but requires understanding how to use the search. BETA: Not all options have been thoroughly tested, and all are subject to breaking changes.
        More information: https://opensearch.org/docs/latest/api-reference/search/

    .PARAMETER Index
        Name of the OpenSearch index to search.

    .PARAMETER AllowNoIndices
        Ignore wildcards that don't match any indices.

    .PARAMETER AllowPartialSearchResults
        Return partial results if the request runs into an error or times out.

    .PARAMETER Analyzer
        Name of the analyzer to use in the query string. See: https://www.opensearch.org/docs/latest/analyzers/

    .PARAMETER AnalyzeWildcard
        Whether the operation should include wildcard and prefix queries in the analysis.

    .PARAMETER BatchedReduceSize
        How many shard results to reduce on a node.

    .PARAMETER CancelAfterSeconds
        The time after which the search request will be canceled, expressed in seconds. Request-level parameter takes precedence over cancel_after_time_interval cluster setting.

    .PARAMETER CcsMinimizeRoundtrips
        Whether to minimize roundtrips between a node and remote clusters.

    .PARAMETER DefaultOperator
        Indicates whether the default operator for a string query should be AND or OR.

    .PARAMETER DefaultField
        The default field in case a field prefix is not provided in the query string.

    .PARAMETER ExpandWildcards
        Specifies the type of index that wildcard expressions can match. Supports comma-separated values. Valid values are all (match any index), open (match open, non-hidden indexes), closed (match closed, non-hidden indexes), hidden (match hidden indexes), and none (deny wildcard expressions).

    .PARAMETER IgnoreThrottled
        Whether to ignore concrete, expanded, or indexes with aliases if indexes are frozen.

    .PARAMETER IgnoreUnavailable
     	Specifies whether to include missing or closed indexes in the response and ignores unavailable shards during the search request.

    .PARAMETER Lenient
        Specifies whether OpenSearch should accept requests if queries have format errors (for example, querying a text field for an integer).

    .PARAMETER MaxConcurrentShardRequests
        How many concurrent shard requests this request should execute on each node.

    .PARAMETER PhaseTook
        Whether to return phase-level took time values in the response.

    .PARAMETER PreFilterShardSize
        A prefilter size threshold that triggers a prefilter operation if the request exceeds the threshold.

    .PARAMETER Preference
        Prefer a shard or node on which to perform the search. Must be specified in a specific way, see: https://opensearch.org/docs/latest/api-reference/search/#the-preference-query-parameter

    .PARAMETER LuceneQuery
        Lucene query search syntax.

    .PARAMETER RequestCache
        Specifies whether OpenSearch should use the request cache. Default is whether it’s enabled in the index’s settings.

    .PARAMETER RestTotalHitsAsInteger
        Whether to return hits.total as an integer. Returns an object otherwise.

    .PARAMETER ScrollSeconds
        How long to keep the search context open, expressed in seconds.

    .PARAMETER SearchType
        Whether OpenSearch should use global term and document frequencies when calculating relevance scores. Valid choices are query_then_fetch and dfs_query_then_fetch. query_then_fetch scores documents using local term and document frequencies for the shard. It’s usually faster but less accurate. dfs_query_then_fetch scores documents using global term and document frequencies across all shards. It’s usually slower but more accurate.

    .PARAMETER FieldSort
        An array of hashtables for sorting fields. Each key should be a field, followed by a value of the direction to sort the field.

    .PARAMETER NoSource
        Do not include the _source field in the response.

    .PARAMETER SourceExcludes
        Array of source fields to exclude from the response.

    .PARAMETER SourceIncludes
        Array of source fields to include in the response.

    .PARAMETER StoredFields
        Whether the get operation should retrieve fields stored in the index.

    .PARAMETER SuggestFields
        Fields OpenSearch can use to look for similar terms.

    .PARAMETER SuggestMode
        The mode to use when searching. Available options are always (use suggestions based on the provided terms), popular (use suggestions that have more occurrences), and missing (use suggestions for terms not in the index).

    .PARAMETER SuggestCount
        How many suggestions to return.

    .PARAMETER SuggestText
        The source that suggestions should e based off of.

    .PARAMETER TrackScores
        Return document scores.

    .PARAMETER TrackTotalHits
        Return how many documents matched the query.

    .PARAMETER TypedKeys
        Whether returned aggregations and suggested terms should include their types in the response.

    .PARAMETER IncludeNamedQueriesScore
        Whether to return scores with named queries.

    .PARAMETER Aggregations
        In the optional aggs parameter, you can define any number of aggregations. Each aggregation is defined by its name and one of the types of aggregations that OpenSearch supports. For more information, see https://opensearch.org/docs/latest/aggregations/

    .PARAMETER DocValueFields
        The fields that OpenSearch should return using their docvalue forms. Specify a format to return results in a certain format, such as date and time.

    .PARAMETER Fields
        The fields to search for in the request. Specify a format to return results in a certain format, such as date and time.

    .PARAMETER Explain
        Return details about how OpenSearch computed the documents score.

    .PARAMETER FromIndex
        The starting index to search from. Default is 0.

    .PARAMETER BoostIndices
        Values used to boost the score of specified indexes. Specify in the format of <index> : <boost-multiplier>

    .PARAMETER MinScore
        Specify a score threshold to return only documents above the threshold.

    .PARAMETER DslQuery
        The DSL query to use in the request, represented as a hashtable. See: https://opensearch.org/docs/latest/query-dsl/

    .PARAMETER DslQueryJson
        The DSL query to use in the request, represented as JSON. Overrides Query parameter. See: https://opensearch.org/docs/latest/query-dsl/

    .PARAMETER SeqNoPrimaryTerm
        Whether to return sequence number and primary term of the last operation of each document hit.

    .PARAMETER Size
        Max number of results to return.

    .PARAMETER Stats
        Value to associate with the request for additional logging.

    .PARAMETER TerminateAfter
        The maximum number of documents OpenSearch should process before terminating the request. Default is 0.

    .PARAMETER Timeout
        How long to wait for a response expressed in seconds. Default is no timeout.

    .PARAMETER Version
        Include the document version in the response.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param(
        # URL Parameters
        [Parameter(Mandatory)]
        [string]$Index,

        [Boolean]$AllowNoIndices=$True,

        [Boolean]$AllowPartialSearchResults=$True,

        [string]$Analyzer,

        [switch]$AnalyzeWildcards,

        [Int64]$BatchedReduceSize=512,

        [Int64]$CancelAfterSeconds=-1,

        [boolean]$CcsMinimizeRoundtrips=$True,

        [ValidateSet('AND','OR')]
        [string]$DefaultOperator='OR',

        [string]$DefaultField,

        [ValidateSet('all','open','closed','hidden','none')]
        [String]$ExpandWildcards='open',

        [boolean]$IgnoreThrottled=$True,

        [switch]$IgnoreUnavailable,

        [switch]$Lenient,

        [Int64]$MaxConcurrentShardRequests=5,

        [boolean]$PhaseTook=$False,

        [Int64]$PreFilterShardSize=128,

        [string]$Preference,

        [string]$LuceneQuery,

        [boolean]$RequestCache,

        [switch]$RestTotalHitsAsInteger,

        [Int64]$ScrollSeconds,

        [ValidateSet('query_then_fetch','dfs_query_then_fetch')]
        [string]$SearchType='query_then_fetch',

        [switch]$NoSource,

        [array]$SourceExcludes,

        [array]$SourceIncludes,

        [switch]$StoredFields,

        [array]$SuggestFields,

        [ValidateSet('always','popular','missing')]
        [string]$SuggestMode,

        [Int64]$SuggestCount,

        [string]$SuggestText,

        [switch]$TrackScores,

        $TrackTotalHits,    # Boolean or integer

        [boolean]$TypedKeys=$True,

        [boolean]$IncludeNamedQueriesScore=$False,

        # Body Parameters
        [string]$Aggregations,

        [array]$DocValueFields,

        [array]$Fields,

        [switch]$Explain,

        [Int64]$FromIndex,

        [array]$BoostIndices,

        [Int64]$MinScore,

        [hashtable]$DslQuery,

        [String]$DslQueryJson,

        [switch]$SeqNoPrimaryTerm,

        [Int64]$Size=5,

        [string]$Stats,

        [Int64]$TerminateAfter,

        [Int64]$Timeout,

        [switch]$Version,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )
    # Index name needs to be lowercase
    $Index = $Index.ToLower()

    # Use output field seperator for casting arrays to strings with comma seperation
    $OldOfs = $ofs
    $ofs = ','

    # Build URL parameters - [Void] is necessary to prevent StringBuilder from outputting the object.
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ($AllowNoIndices -eq $False){
        [Void]$UrlParameter.Append('&allow_no_indices=false')
    }
    if ($AllowPartialSearchResults -eq $False){
        [Void]$UrlParameter.Append('&allow_partial_search_results=false')
    }
    if ($Analyzer -ne ''){
        [Void]$UrlParameter.Append("&analyzer=$Analyzer")
    }
    if ($AnalyzeWildcards -eq $True){
        [Void]$UrlParameter.Append('&analyze_wildcard=true')
    }
    if ($BatchedReduceSize -ne 512){
        [Void]$UrlParameter.Append("&batched_reduce_size=$BatchedReduceSize")
    }
    if ($CancelAfterSeconds -ne -1){
        $CancelAfterTimeInterval = ([String]$CancelAfterSeconds + 's')

        [Void]$UrlParameter.Append("&cancel_after_time_interval=$CancelAfterTimeInterval")
    }
    if ($CcsMinimizeRoundtrips -eq $False){
        [Void]$UrlParameter.Append('&ccs_minimize_roundtrips=false')
    }
    if ($DefaultOperator -ne 'OR'){
        [Void]$UrlParameter.Append('&default_operator=AND')
    }
    if ($DefaultField -ne ''){
        [Void]$UrlParameter.Append("&df=$DefaultField")
    }
    if ($ExpandWildcards -ne 'open'){
        [Void]$UrlParameter.Append("&expand_wildcards=$ExpandWildcards")
    }
    if ($IgnoreThrottled -eq $False){
        [Void]$UrlParameter.Append('&ignore_throttled=false')
    }
    if ($IgnoreUnavailable -eq $True){
        [Void]$UrlParameter.Append('&ignore_unavailable=true')
    }
    if ($Lenient -eq $True){
        [Void]$UrlParameter.Append('&lenient=true')
    }
    if ($MaxConcurrentShardRequests -ne 5){
        [Void]$UrlParameter.Append("&max_concurrent_shard_requests=$MaxConcurrentShardRequests")
    }
    if ($PhaseTook -eq $True){
        [Void]$UrlParameter.Append('&phase_took=true')
    }
    if ($PreFilterShardSize -ne 128){
        [Void]$UrlParameter.Append("&pre_filter_shard_size=$PreFilterShardSize")
    }
    if ($Preference -ne ''){
        [Void]$UrlParameter.Append("&preference=$Preference")
    }
    if ($LuceneQuery -ne ''){
        [Void]$UrlParameter.Append("&q=$LuceneQuery")
    }
    if ($RequestCache){
        $RequestCacheString = ([String]$RequestCache).ToLower()    # json requires that $True be lowercase 'true'

        [Void]$UrlParameter.Append("&request_cache=$RequestCacheString")
    }
    if ($RestTotalHitsAsInteger -eq $True){
        [Void]$UrlParameter.Append("&rest_total_hits_as_int=true")
    }
    if ($ScrollSeconds -ne 0){
        $ScrollSecondsTimeInterval = [String]$ScrollSeconds + 's'

        [Void]$UrlParameter.Append("&scroll=$ScrollSecondsTimeInterval")
    }
    if ($SearchType -eq 'dfs_query_then_fetch'){
        [Void]$UrlParameter.Append('&search_type=dfs_query_then_fetch')
    }
    if ($NoSource -eq $True){
        [Void]$UrlParameter.Append('&_source=true')
    }
    if ($null -ne $SourceExcludes){
        [Void]$UrlParameter.Append("&_source_excludes=$SourceExcludes")
    }
    if ($null -ne $SourceIncludes){
        [Void]$UrlParameter.Append("&_source_includes=$SourceIncludes")
    }
    if ($StoredFields -eq $True){
        [Void]$UrlParameter.Append('&stored_fields=true')
    }
    if ($null -ne $SuggestFields){
        [Void]$UrlParameter.Append("&suggest_field=$SuggestFields")
    }
    if ($SuggestMode -ne ''){
        [Void]$UrlParameter.Append("&suggest_mode=$SuggestMode")
    }
    if ($SuggestCount -ne 0){
        [Void]$UrlParameter.Append("&suggest_size=$SuggestCount")
    }
    if ($SuggestText -ne ''){
        [Void]$UrlParameter.Append("&suggest_text=$SuggestText")
    }
    if ($TrackScores -eq $True){
        [Void]$UrlParameter.Append('&track_scores=true')
    }
    if ($null -ne $TrackTotalHits){
        if ($TrackTotalHits.GetType().Name -notlike 'Int*' -and
        $TrackTotalHits.GetType().Name -ne 'Boolean'){
            throw [System.InvalidCastException] "TrackTotalHits needs to be of type boolean or integer."
        }

        if ($TrackTotalHits.GetType().Name -eq 'Boolean'){    # json requires that $True be lowercase 'true'
            $TrackTotalHits = ([String]$TrackTotalHits).ToLower()
        }

        [Void]$UrlParameter.Append("&track_total_hits=$TrackTotalHits")
    }
    if ($TypedKeys -eq $False){
        [Void]$UrlParameter.Append('&typed_keys=false')
    }
    if ($IncludeNamedQueriesScore -eq $True){
        [Void]$UrlParameter.Append('&include_named_queries_score=true')
    }
    $UrlParameterString = $UrlParameter.ToString()

    # First URL parameter should be '?' not '&'
    if ($UrlParameterString -ne ''){
        $UrlParameterString = $UrlParameterString.Substring(1)
        $UrlParameterString = '?' + $UrlParameterString
    }

    # Build body parameters
    $Body = @{}
    if ($Aggregations -ne ''){
        $Body.aggs = $Aggregations
    }
    if ($null -ne $DocValueFields){
        $Body.docvalue_fields = $DocValueFields
    }
    if ($null -ne $Fields){
        $Body.fields = $Fields
    }
    if ($Explain -eq $True){
        $Body.explain = $True
    }
    if ($null -ne $FromIndex){
        $Body.from = $FromIndex
    }
    if ($null -ne $BoostIndices){
        $Body.indices_boost = $BoostIndices
    }
    if ($null -ne $MinScore){
        $Body.min_score = $MinScore
    }
    if ($null -ne $DslQuery){
        # Prefer custom $DslQueryJson over $DslQuery if both are specified
        if ($DslQueryJson -eq ''){
            $Body.query = $DslQuery
        }
    }
    if ($DslQueryJson -ne ''){
        # Convert from Json since converting a string later will create escape characters. Needs to be valid Json anyways.
        $Body.query = $DslQueryJson | ConvertFrom-Json -Depth 100
    }
    if ($SeqNoPrimaryTerm -eq $True){
        $Body.seq_no_primary_term = $True
    }
    if ($Size -ne 5){
        $Body.size = $Size
    }
    if ($Stats -ne ''){
        $Body.stats = $Stats
    }
    if ($null -ne $TerminateAfter){
        $Body.terminate_after = $TerminateAfter
    }
    if ($null -ne $Timeout){
        $Body.timeout = $Timeout
    }
    if ($Version -eq $True){
        $Body.version = $True
    }

    $ofs = $OldOfs

    # Build request
    if ($Index -eq ''){
        $Request = '/_search' + $UrlParameter
    }
    else {
        $Request = $Index + '/_search' + $UrlParameterString
    }

    $Body = $Body | ConvertTo-Json -Depth 100
    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
	    'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
        'Body' = $Body
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

Export-ModuleMember -Function Find-OS

